---
layout: post
title:  "Real Time FFT Ocean Rendering in DirectX 12"
summary: "A deep dive into building a real time physically based ocean renderer from scratch."
author: Timethy Hyman
date: '2026-03-08 13:23:23 +0000'
thumbnail: /assets/img/projects/EV/cascadeThumb.webp
keywords: ocean rendering, FFT ocean, DirectX 12, HLSL, JONSWAP, wave simulation, PBR, subsurface scattering, foam, EV-Engine, graphics programming
permalink: /blog/fft-ocean-rendering/
usemathjax: true
---

<!-- HERO IMAGE -->
<!-- [ Add a full-width screenshot of your final ocean render here ] -->

---

## Introduction

Oceans can be one of the most relaxing phenomena that nature provides us. Hearing the crashing waves, seeing small water ripples and light refraction through the water surface can take hours of my day when sitting at a beach. This is one of the reasons why this project came to life. 

As a graphics programmer, I often ask myself how real life scenarios would translate to a digital implementation. Usually I have a rough idea, but oceans seemed so complex, non-uniform and variable dependent that I decided to ask google instead. This led to a rabbit hole of papers regarding Fourier Transforms, Euler's formula and scary math which I will be elaborating on in this blogpost. 

So if you've ever looked at an ocean and wondered how films such as [Titanic](https://youtu.be/BTff04cFsRw?t=99), AAA games such as [Horizon Forbidden West](https://www.youtube.com/watch?v=XT-xhCNalPc) and [Sea of Thieves](https://www.reddit.com/r/Seaofthieves/comments/184f1le/the_ocean_of_sea_of_thieves_is_insane_enjoy_it/) recreated it, then this blogpost is for you. 

## Table of Contents

1. [Wave Simulation: JONSWAP & the FFT Pipeline](#chapter-1-wave-simulation-jonswap--the-fft-pipeline)
3. [Rendering & Shading](#chapter-2-rendering--shading)
4. [Foam](#chapter-3-foam)
2. [Wave Cascades: Multi Scale Detail](#chapter-4-wave-cascades-multi-scale-detail)
5. [Skybox & Environment](#chapter-5-skybox--environment)
7. [Major Struggles & Lessons Learned](#chapter-7-major-struggles--lessons-learned)
8. [Results & Next Steps](#chapter-8-results--next-steps)


## Understanding the basics


<details>
<summary>  How does a sine wave work?</summary>

The ocean wave implementation is heavily based on using multiple sine waves to get interesting displacements. 
Sine waves are oscillators, which means they generate a repetitive wave signal that stays within its amplitude. Three important terms regarding a wave is its amplitude, its wavelength and its frequency.  
Amplitude is the peak of the wave, the highest value that the signal can reach. Wavelength is the distance between two of these peaks, you can imagine this like a spring. A spring that is compressed would represent a short wavelength while a spring that is stretched out would represent a long wavelength. Frequency is how often a signal repeats within a second. A short wavelength correlates to a high frequency, a long wavelength correlates to a low frequency. This ties together with ocean rendering because we can use this wavelength to shape the waves of our ocean, how we do this will be discussed in this article. 

</details>

<details>
<summary>What are complex numbers?</summary>

A complex number is simply two numbers packed into one. It has a real part and an imaginary part. Its form is \(c = a + bi\)
You can think of it like a 2D coordinate. Instead of writing \(p = (3,4)\), you'd write \(p = 3 + 4i\). The \(i\) is the imaginary part of the number, which lives on the axis perpendicular to the real number line.

When any number is multiplied by the imaginary \(i\), it is essentially "rotated" by 90° counter clockwise. This rotation property is what lets Euler's formula describe circular motion. Interesting note, multiplying a number by \(i\) twice, brings it to -1, which leads to a whole other discussion on why \(i = \sqrt{-1}\). But that is out of scope for this blogpost.

</details>

<details>
<summary>  What is Euler's formula? </summary>

Euler's formula states that any point on a unit circle can be written as:

\[e^{i\theta} = \cos\theta + i\sin\theta\]

This tells us that if you take e to the power of an imaginary number, you would get a point on a circle. Here the \(cos\theta\) is the x coordinate, and the \(sin\theta\) is the y coordinate.

This is very useful for our ocean simulation since as theta increases over time, the point spins around the circle. This spinning around the circle causes the x and y values to oscillate up and down which drive the displacement of the ocean over time. Euler's formula is a compact way to represent the oscillation of the sin and cosine components packed into one expression. 

</details>

<details>
<summary>  How does a compute shader work? </summary>

A compute shader is a shader that runs directly on the GPU, outside of the normal rendering pipeline. Unlike vertex and pixel shaders, it has no fixed role. Instead, it runs a large grid of threads in parallel, allowing the GPU to do many calculations at the same time.

A CPU has a small number of powerful cores built for sequential logic. A GPU has thousands of smaller cores built to do the same operation on many pieces of data at once. This makes the GPU much better suited for tasks like the FFT, where the same calculation needs to happen on every point of a texture every frame.

The developer defines the size of the thread grid themselves. Each thread knows its own position in the grid via SV_DispatchThreadID, so it knows exactly which point on the ocean it is responsible for. This way every point on the ocean plane gets calculated in parallel.

<pre><code class="language-hlsl">
[numthreads(8, 8, 1)]
void CSMain(uint3 id : SV_DispatchThreadID)
{
    // id.xy is this thread's position in the grid
    // each thread computes the wave displacement for one point
    OutputTexture[id.xy] = ComputeWaveDisplacement(id.xy);
}
</code></pre>


</details>


## Chapter 1 Wave Simulation: JONSWAP & the FFT Pipeline


The ocean surface is made up of thousands of waves, all travelling in different directions with different sizes and speeds. To simulate this, we model the ocean as a sum of sine waves, each with their own frequency, direction and amplitude. The question then becomes: how do we decide how big each of those waves should be?

This is where oceanographers come in. Over decades, researchers measured real ocean surfaces using buoys, photographs and radar measurements to figure out exactly how wave energy is distributed across different frequencies in a fully developed ocean. A fully developed ocean simply means the ocean has had enough time and distance to reach an equilibrium with the wind blowing over it. The result of this research is a spectrum function, which tells us how much energy each wave frequency should have given a set of wind conditions.

Now, evaluating thousands of sine waves individually for every point on the ocean every frame would be far too slow even for a modern GPU. This is where the FFT comes in. Before we dive into how FFT works, we need to understand the two relevant domains. *The Spatial Domain and the Frequency Domain.*

The spatial domain is our usual graph that has a value Y on the vertical axis, and a constantly increasing value X usually representing time or position, on the horizontal axis. The frequency domain exposes frequency on the horizontal axis and amplitude on the vertical axis. This produces a graph that visualizes the link between frequencies and their amplitudes.

<div class="centered">
  <img src="/assets/img/posts/OceanRender/freqTimeDomain.webp" alt="Frequency and time domain">
  <p><em>Source: <a href="https://docs.keysight.com/kkbopen/why-measuring-in-the-time-domain-and-frequency-domain-is-the-same-but-not-603167255.html">Why Measuring in the Time Domain and Frequency Domain Is the Same, but Not</a></em></p>
</div>

FFT works in the frequency domain, where each point represents a wave frequency rather than a world position. The FFT algorithm then converts the entire frequency domain into real world displacements (which live in the spatial domain) in one efficient pass. The beautiful thing about this, is that it's a lossless operation. We can convert our data between domains without losing any information. This is neat since we can remove certain frequencies from the equation, convert the data back to the spatial domain and have the exact same wave minus the removed frequency. You can imagine this like having a musical chord, say *C Major 7*. This chord contains the notes *C, E, G and B.* Using the FFT, you would be able to see every note that this chord signal contains, remove the B for example and convert it back to the spatial domain. The result would be a simple C Major chord which has the notes *C, E and G.*  
With this understanding of the FFT, we can now look at how Tessendorf uses it to build the ocean spectrum.

In his paper, Jerry Tessendorf describes the Phillips Spectrum as the model for defining wave energy. After implementing it I found it too limiting since its only parameters were wind speed and direction. So I switched to the JONSWAP spectrum, a more widely adopted model that gives much more creative freedom.
With JONSWAP you can control things like how many waves follow the wind direction, the choppiness of the waves, the distance over which the wind affects the surface, and the sharpness of the spectrum peak. This lets you model anything from a calm open ocean to a stormy sea with large aggressive swells.


### 1.1 The Setup

The ocean simulation is driven by a statistical wave spectrum. Rather than simulating individual water particles, the sea surface is represented as a collection of many sinusoidal waves. 

To simulate the ocean, the general idea is that we want to start by generating the initial representation of the heightfield in 2D space. We do this by using the wave spectrum in combination with a gaussian pseudo random number generator.  The gaussian random number is used to ensure that each wave component starts at a different point in its cycle. This way two oceans with the same parameters will still look different from each other. This random number becomes the $\xi_r + i\xi_i$ term in the H₀ formula, which we will see in section 1.2.

Tessendorf expresses the ocean height field as a sum of complex wave contributions across all frequencies. 
We represent the ocean surface using the formula:

$$h(\mathbf{x}, t) = \sum_{\mathbf{k}} \tilde{h}(\mathbf{k}, t) \exp(i\mathbf{k} \cdot \mathbf{x})$$

<div class="centered">

Where:<br>

$t$ - time  <br>
$\mathbf{x}$ - horizontal position on the ocean surface  <br>
$\mathbf{k}$ - a 2D wave vector with components $\mathbf{k} = (k_x, k_z)$  <br>
$k_x = \frac{2\pi n}{L_x}$   <br>
$k_z = \frac{2\pi m}{L_z}$  <br>
$n, m$ - integers in the range [$-N/2 \leq n < N/2$] and [$-M/2 \leq m < M/2$].  <br>
$\tilde{h}(\mathbf{k}, t)$ - complex amplitude encoding the amplitude and **phase* of the wave at frequency $\mathbf{k}$ and time $t$  <br>
$N, M$ - the resolution of the FFT grid <br>

</div>

 

<details>
<summary>  What is the phase of a wave? </summary>

The phase is the position of a wave within its cycle at any point in time. It is measured in radians, a phase value of 0 means the wave is at its peak, while a phase value of $\frac{\pi}{2}$, means that the wave is halfway between the peak and zero.

</details>

This heightfield is the result of the FFT converting the initial spectrum from the frequency domain to the spatial domain. This will be discussed in section 1.5.
The complex amplitude $\tilde{h}(\mathbf{k}, t)$ is the heart of this formula. It is what we need to construct for every wave vector $\mathbf{k}$ on our grid. To do this we need two things: the JONSWAP spectrum, which tells us how much energy each wave frequency should carry, and the dispersion relation, which tells us how fast each wave travels. *Section 1.3*.

The dispersion relation allows us to propagate this heightfield forward in time, animating the waves. This will need to be recalculated every frame to update the heightfield accordingly. The dispersion relation defines the relationship between angular frequency $\omega$ and the wave number $k$.  
In deep water, its formula is defined like this: 

$$\omega = \sqrt{gk}$$

$\omega$ - Angular frequency. How fast the wave oscillates in time (radians/sec)  
$g$ - Gravitational acceleration (9.81 m/s²)  
$k$ - The Wavenumber. Waves per meter: $k = \frac{2\pi}{\lambda} $

<details>
<summary>  What is angular frequency? </summary>

Regular frequency describes how many full cycles happen in a second. For example: A wave that completes 3 cycles in a second has $f = 3$Hz.  
Angular frequency comes from thinking about this cycle rotating around a unit circle rather than oscillating up and down.  
A full rotation around a unit circle is $2\pi$. Angular frequency is simply the regular frequency multiplied by $2\pi$.

$$\omega = 2\pi f$$

</details>


For our implementation, we will be using the form that encodes a finite depth:

$$\omega = \sqrt{gk\tanh(kD)}$$

$D$ - Ocean Depth. Large values for D simplifies back to the base form while smaller values for D reduce the wave speed.

The dispersion relation formula is an approximation. There are many [different relationships](https://en.wikipedia.org/wiki/Dispersion_(water_waves)) you can choose to fit your ocean. 


With the general idea understood, we can now look at how the wave spectrum is constructed.


### 1.2 The Wave Spectrum

The wave spectrum is essentially a function that describes how the wave energy is distributed across combinations of angular frequencies $\omega$ and wind directions $\theta$.  


The JONSWAP spectrum formula looks like this: 

$$S_{\text{JONSWAP}}(\omega) = \text{scale} \cdot \phi_{TMA}(\omega) \cdot \frac{\alpha g^2}{\omega^5} \exp\left(-\frac{5}{4}\left(\frac{\omega_p}{\omega}\right)^4\right) \gamma^{\exp\left(-\frac{(\omega - \omega_p)^2}{2\sigma^2\omega_p^2}\right)}$$

<div class="centered">

Where:<br>

$\alpha$ - Energy scale, controls the overall wave height  <br>
$g$ - Gravitational acceleration (9.81 m/s²)  <br>
$\omega$ - Angular frequency of the wave being evaluated  <br>
$\omega_p$ - Peak frequency, the frequency with the most energy  <br>
$\gamma$ - Peak enhancement factor, controls the sharpness of the spectrum peak  <br>
$\sigma$ - Width parameter, 0.07 when $\omega \leq \omega_p$ and 0.09 when $\omega > \omega_p$  <br>
$\phi_{TMA}$ - TMA shallow water correction factor. Reduces the wave speed at shallow depths.   <br>

</div>

Before diving into each component of the JONSWAP, lets define a struct that will hold all the parameters that we will be populating.

```cpp
	struct JonswapParameters
	{
		float scale = 0.0f; // Used to scale the Spectrum [1.0f, 5.0f] 
		float spreadBlend = 0.0f; // Used to blend between agitated water motion, and windDirection [0.0f, 1.0f]
		float swell = 0.0f; // Influences wave choppiness, the bigger the swell, the longer the wave length [0.0f, 1.0f]
		float gamma = 0.0f; // Defines the Spectrum Peak [0.0f, 7.0f]
		float shortWavesFade = 0.0f; // [0.0f, 1.0f]

		float windDirection = 0.0f; // [0.0f, 360.0f]
		float fetch = 0.0f; // Distance over which Wind impacts Wave Formation [0.0f, 10000.0f]
		float windSpeed = 0.0f; // [0.0f, 100.0f]

        // These values get calculated using the metrics above.
		float angle = 0.0f;
		float alpha = 0.0f;
		float peakOmega = 0.0f;
	}m_jonswapParams;

```

In code, calculating the JONSWAP spectrum looks like this:

```cpp

float Ocean::JONSWAP(float omega)
{
    float sigma = (omega <= m_jonswapParams.peakOmega) ? 0.07f : 0.09f; // width parameter
    float r = exp(-(omega - m_jonswapParams.peakOmega) * (omega - m_jonswapParams.peakOmega) / 2.0f / sigma / sigma / m_jonswapParams.peakOmega / m_jonswapParams.peakOmega); // peak enhancement
    float g = 9.81f; // gravity

    float oneOverOmega = 1.0f / (omega + 1e-6f);
    float peakOmegaOverOmega = m_jonswapParams.peakOmega / omega;

    return m_jonswapParams.scale * TMACorrection(omega) * m_jonswapParams.alpha * g * g * oneOverOmega * oneOverOmega * oneOverOmega * oneOverOmega * oneOverOmega 
			* exp(-1.25f * peakOmegaOverOmega * peakOmegaOverOmega * peakOmegaOverOmega * peakOmegaOverOmega) * pow(abs(m_jonswapParams.gamma), r);
}

```

The TMA (Texel Marsen Arsloe) correction is used for the non directional component of the wave spectrum. This means that it does not care about the direction the waves are moving, instead the TMA functions on the depth of the ocean. In shallow waters, the seabed starts to intervene with the waves. The waves slow down, their shape changes and their energy distribution across waves get shifted. TMA accounts for this and adjusts the JONSWAP spectrum by multiplying the spectrum with a depth dependent factor.

```cpp

float TMACorrection(float w)
{
    float omegaH = omega * sqrt(OCEAN_DEPTH / 9.81f);
    if (omegaH <= 1.0f)
        return 0.5f * omegaH * omegaH;
    if (omegaH < 2.0f)
        return 1.0f - 0.5f * (2.0f - omegaH) * (2.0f - omegaH);

    return 1.0f;
}

```

Before we continue, lets populate our JonswapParameters. I recommend you play with the values to meet your desired artistic vision.  
We do need to calculate 3 of the variables: The `angle`, the `alpha` and the `peakOmega`.

```cpp

m_jonswapParams.angle = m_jonswapParams.windDirection / 180.0f * PI;
m_jonswapParams.alpha = JonswapAlpha(m_jonswapParams.fetch, m_jonswapParams.windSpeed);
m_jonswapParams.peakOmega = JonswapPeakFequency(m_jonswapParams.fetch, m_jonswapParams.windSpeed);

```

```cpp

float Ocean::JonswapAlpha(float fetch, float windSpeed)
{
    return 0.076f * pow(9.81f * fetch / windSpeed / windSpeed, - 0.22f);
}

float Ocean::JonswapPeakFequency(float fetch, float windSpeed)
{
    return 22.0f * pow(windSpeed * fetch / 9.81f / 9.81f, -0.33f);
}

```


Now that we have the wave spectrum, we can look at generating the initial heightfield.

### 1.3 Initial Spectrum Generation: H₀

We compute the initial spectrum once, my implementation does this on the CPU but its best done on the GPU since it can make great use of parallel computing.

The formula Tessendorf proposes in his paper is:

$$\tilde{h}_0(\mathbf{k}) = \frac{1}{\sqrt{2}}(\xi_r + i\xi_i)\sqrt{P_h(\mathbf{k})}$$

<div class="centered">

Where:<br>

$\tilde{h}_0(\mathbf{k})$ - The initial complex amplitude for wave vector $\mathbf{k}$. Encodes the amplitude and phase of one wave component.  <br>
$\mathbf{k}$ - A 2D wave vector representing the frequency and direction of a wave component.  <br>
$\xi_r$ - A Gaussian random number for the real part.  <br>
$\xi_i$ - A Gaussian random number for the imaginary part. <br> 
$P_h(\mathbf{k})$ - The wave spectrum energy at wave vector $\mathbf{k}$. In our implementation this is the JONSWAP spectrum.  <br>
$\frac{1}{\sqrt{2}}$ - A normalisation factor that ensures the correct distribution of wave amplitudes.<br>

</div>

This data lives in the frequency domain.  
We generate a complex number that encodes the amplitude and phase for every wave vector *k*. We store the resulting data in a R16G16B16A16_FLOAT texture.

Lets look at some code.

```cpp

void Ocean::GenerateH0(std::shared_ptr<CommandList> commandList, const UINT cascade) {

    float deltaK = 2.0f * PI / patchSize;
    float highestK = (OCEAN_SUBRES / 2.0f) * deltaK; // nyquist limit

    // stored in heap to avoid stack overflow
    std::vector<std::complex<float>> H0(OCEAN_SUBRES * OCEAN_SUBRES, { 0,0 });
    std::vector<std::complex<float>> H0Conj(OCEAN_SUBRES * OCEAN_SUBRES, { 0,0 });

    const float lowCutoff = cascade == 0 ? 0.001f : (OCEAN_SUBRES * PI / m_oceanPatchSizes[cascade - 1]); // nyquist limit of previous cascade;
    const float highCutoff = highestK;
    
    
    for (int m = 0; m < OCEAN_SUBRES; m++) {
        for (int n = 0; n < OCEAN_SUBRES; n++) {
            // Get wave vector for this frequency
            float kx = (n - OCEAN_SUBRES / 2.0f) * deltaK;
            float ky = (m - OCEAN_SUBRES / 2.0f) * deltaK;
            float k(sqrtf(kx * kx + ky * ky));

            if (k >= lowCutoff && k <= highCutoff)
            {
	            
            float kAngle = atan2(ky, kx);
            float omega = DispersionRelation(k);
            float dOmegadk = DispersionDerivative(k);

            float spectrum = JONSWAP(omega) * DirectionSpectrum(kAngle, omega) * ShortWavesFade(k);
            
            // Generate two independent gaussian random numbers
            float xiR = GaussianRandom();
            float xiI = GaussianRandom();

            float amplitude = sqrtf(2.0f * spectrum * fabsf(dOmegadk) / k * deltaK * deltaK);
            H0[m * OCEAN_SUBRES + n] = std::complex<float>(xiR * amplitude, xiI * amplitude);
            }
        }
    }

    // Needs its own loop since the conjugate needs all data of H0 to be valid
    for (int m = 0; m < OCEAN_SUBRES; m++) {
        for (int n = 0; n < OCEAN_SUBRES; n++) {
            int m_minus = (OCEAN_SUBRES - m) % OCEAN_SUBRES;
            int n_minus = (OCEAN_SUBRES - n) % OCEAN_SUBRES;
            H0Conj[m * OCEAN_SUBRES + n] = std::conj(H0[m_minus * OCEAN_SUBRES + n_minus]);
        }
    }

    std::vector<uint16_t> combinedData(OCEAN_SUBRES * OCEAN_SUBRES * 4);

    for (int m = 0; m < OCEAN_SUBRES; m++) {
        for (int n = 0; n < OCEAN_SUBRES; n++) {
            int index = (m * OCEAN_SUBRES + n) * 4;
            combinedData[index + 0] = FloatToHalf(H0[m * OCEAN_SUBRES + n].real());       // R: H0 real
            combinedData[index + 1] = FloatToHalf(H0[m * OCEAN_SUBRES + n].imag());       // G: H0 imaginary
            combinedData[index + 2] = FloatToHalf(H0Conj[m * OCEAN_SUBRES + n].real());   // B: H0_conj real
            combinedData[index + 3] = FloatToHalf(H0Conj[m * OCEAN_SUBRES + n].imag());   // A: H0_conj imaginary
        }
    }

    D3D12_SUBRESOURCE_DATA subData = {};
    subData.pData = combinedData.data();
    subData.RowPitch = OCEAN_SUBRES * 4 * sizeof(uint16_t); // 4 channels * 2 bytes
    subData.SlicePitch = subData.RowPitch * OCEAN_SUBRES;

    commandList->CopyTextureSubresource(m_oceanCascades[cascade].H0Texture, 0, 1, &subData);
}

```

Lets dissect this.  
`deltaK` is the spacing between frequency samples. Since our patch covers `patchSize` metres in the real world, dividing $2\pi$ by it gives us the step size in frequency space.  
`highestK` is the Nyquist limit, the highest frequency our grid can represent before aliasing occurs.  
`lowCutoff` and `highCutoff` can be ignored for now, these will be explained in Chapter 4.  

**The double for loop**  
For each grid position $(n, m)$ we compute the wave vector components `kx` and `ky`. Subtracting `OCEAN_SUBRES / 2.0f` centers the grid around zero so we cover both positive and negative frequencies, representing waves travelling in all directions.  
`k` is the magnitude of the wave vector, the wavenumber.  

**Computing the spectrum value**  
For each wave vector we compute three things.  
`kAngle` is the direction the wave is travelling.  
`omega` is the angular frequency from the dispersion relation.  
The full spectrum value is then the product of three functions. JONSWAP gives the total energy at this frequency.  
`DirectionSpectrum` distributes that energy across directions based on `kAngle`.  
`ShortWavesFade` damps out very high frequencies to prevent aliasing artifacts.  

<details>
<summary>How does directional spreading work?</summary>

The JONSWAP spectrum $S(\omega)$ only tells us how much energy a wave of a certain frequency should have. It says nothing about which direction that energy travels. The directional spreading function $D(\omega, \theta)$ solves this by distributing the energy across directions. Multiplying them together gives us the full directional spectrum:

$$S(\omega, \theta) = S(\omega) \cdot D(\omega, \theta)$$

The spreading function we use is based on the Longuet-Higgins form, which most empirical models share:

$$D(\omega, \theta) = Q(s) \cdot |\cos(\theta/2)|^{2s}$$

The parameter $s$ controls how concentrated the energy is around the wind direction. A large $s$ means waves are tightly focused along the wind. A small $s$ means energy spreads out in all directions. $Q(s)$ is a normalisation factor that ensures the total energy across all directions sums to 1.

In code, <code>Cosine2s</code> is this function and <code>NormalizationFactor</code> is $Q(s)$, computed using a polynomial approximation rather than the exact Euler gamma function for performance reasons.

<strong>Computing $s$: the Hasselmann model</strong>

We use the Hasselmann empirical model to compute $s$ based on how far the current frequency is from the peak frequency $\omega_p$:

<pre><code class="language-cpp">
float SpreadPower(float omega, float peakOmega)
{
    if (omega > peakOmega)
        return 9.77f * pow(abs(omega / peakOmega), -2.5f);
    else
        return 6.97f * pow(abs(omega / peakOmega), 5.0f);
}
</code></pre>

The constants <code>9.77</code> and <code>6.97</code> come directly from Horvath's paper. Frequencies near the peak get a high $s$ value, meaning they are focused along the wind. Frequencies far above the peak get a low $s$, spreading more freely in all directions.

<strong>The swell parameter</strong>

On top of the Hasselmann base value, we add a swell contribution:

$$s_\xi = 16 \tanh\left(\frac{\omega_p}{\omega}\right)\xi^2$$

Where $\xi$ is the <code>swell</code> parameter. Increasing swell adds to $s$, making waves more elongated and parallel, simulating waves that have travelled from a distant storm rather than being generated by local wind.

<strong>Blending with spreadBlend</strong>

The final spreading function blends between two models based on the <code>spreadBlend</code> parameter:

<pre><code class="language-cpp">
return lerp(
    2.0f / PI * cos(theta) * cos(theta),  // simple cosine squared, no directionality
    Cosine2s(theta - angle, s),            // full Hasselmann + swell spreading
    spreadBlend
);
</code></pre>

A <code>spreadBlend</code> of 0 gives a simple spreading where all wavelengths spread equally regardless of frequency. A <code>spreadBlend</code> of 1 gives the full empirical Hasselmann model with swell. Values in between blend the two, giving you creative control over how directional the ocean looks.

</details>

**Computing the amplitude and storing H₀**
Two independent Gaussian random numbers give each wave component a unique random phase. The amplitude formula converts the continuous spectrum density into a discrete amplitude value for this specific grid cell, accounting for the cell size `deltaK * deltaK`. Multiplying the random numbers by the amplitude gives us $\tilde{h}_0(\mathbf{k})$, stored as a unique complex number.

**The Conjugate**  
The conjugate is simply the sign mirror of a complex number. For example the conjugate of $z = a + bi$ is $z = a - bi$. This conjugate is needed since the FFT takes complex numbers as input and produces a complex number as an output too. Our heightfield needs to use real numbers, so using the conjugate we can cancel out the imaginary part of the FFT output, leaving us with only real values. for example:

$$ (a + bi) + (a - bi) = 2a $$

**Texture Packing**  
Both H0 and its conjugate are packed into a single RGBA texture. The real and imaginary parts of H0 go into the R and G channels, the conjugate goes into B and A. The values are converted to 16 bit half precision floats to save memory. This texture is then uploaded to the GPU where the compute shader will read it every frame to propagate the waves forward in time.


This function provides us with the initial spectrum texture. You can visualize this texture in your preferred graphics debugger, I'm using RenderDoc. *You will need to change the color range to a very small value to see the colors clearly*.

<div class="centered">

<div class="centered">
  <img src="/assets/img/posts/OceanRender/initialH0.webp" alt="Initial H0 spectrum texture">
  <p><em>Your version might look slightly less colorful, mine is using multiple frequency bands which will be covered in Chapter 4.</em></p>
</div>

Next we will look at how the FFT transforms this frequency domain data into real world wave displacements


### 1.4 Time Evolution: Animating the Waves

The next step now that we have the initial spectrum, is to bring our static data to life by animating it over time. Tessendorf provides us with the following formula:

$$\tilde{h}(\mathbf{k}, t) = \tilde{h}_0(\mathbf{k})\,e^{i\omega(k)t} + \tilde{h}_0^*(-\mathbf{k})\,e^{-i\omega(k)t}$$

Every frame, we take our initial spectrum $\tilde{h}_0(\mathbf{k})$ and multiply it by $e^{i\omega t}$. From Euler's formula we know that this advances the phase of each wave component forward in time at its own speed, determined by the dispersion relation. The second term $\tilde{h}_0^*(-\mathbf{k})\,e^{-i\omega(k)t}$ is the conjugate we discussed earlier, ensuring the output remains a real value.

One important detail is that we use a rounded version of $\omega$ when computing the time evolution. This ensures that every wave component completes full cycles within a fixed time period, so the ocean animation loops seamlessly without any visible discontinuity. 

{% comment %}

<!-- [ Explain how animate_waves.hlsl works — the dispersion relation ω = √(g·k), Euler's formula for complex exponentials, and why you accumulate total time rather than per-frame deltaTime. ] -->

### 1.5 The Butterfly FFT

A 2D IFFT converts the frequency-domain spectrum into a real-space displacement field each frame. The FFT is implemented as a GPU compute shader using the Cooley-Tukey butterfly algorithm.

<!-- [ Walk through the FFT pipeline — bit-reversal permutation, twiddle factor calculation, ping-pong buffers to avoid race conditions, row pass then column pass, and the final checkerboard permutation. ] -->

<!-- STRUGGLE TO MENTION:
- Checkerboard artifacts caused by a missing UAV barrier after the vertical FFT dispatch in DX12.
- Double-buffer race conditions requiring the ping-pong approach.
- Stack overflow from large stack-allocated complex arrays in GenerateH0 — fixed by moving to heap vectors.
- Incorrect normalization (dividing by N instead of N² for 2D IFFT) producing flat output. -->

---


## Chapter 2 Rendering & Shading

### 2.1 Physically-Based Shading (PBR)

The ocean surface is shaded using a full PBR BRDF:
- **GGX** normal distribution function
- **Smith** geometry function (shadowing-masking)  
- **Fresnel-Schlick** approximation

<!-- [ Briefly explain each term and why they suit water — GGX's long specular tail matches the sharp sun glints seen on a real ocean. Discuss your roughness and metallic values. ] -->

<!-- STRUGGLE TO MENTION: Early specular was broken because world-space normals were being dotted with view-space vectors — a coordinate-space mismatch producing dark spots across the surface. -->

### 2.2 Image-Based Lighting (IBL) — Split-Sum Approximation

To capture ambient environment lighting, the renderer uses precomputed IBL baked at startup via compute dispatches. The specular integral is approximated using the Epic Games split-sum method:

$$\int L(\omega_i)\,f(\omega_i,\omega_o)\cos\theta\,d\omega_i \approx L_{filtered}(r,roughness) \cdot (F_0 \cdot \text{BRDF}.x + \text{BRDF}.y)$$

Three assets are baked:
1. **Diffuse irradiance cubemap** — convolved environment for diffuse ambient
2. **Pre-filtered specular mip-chain** — blurred mips by roughness level
3. **BRDF LUT** — GGX response across all (NdotV, roughness) pairs

```hlsl
float3 specularColor = specularMap.SampleLevel(linearClampSampler, R, roughness * MAX_REFLECTION_LOD);
float2 envBRDF = brdfLUT.Sample(linearClampSampler, float2(NdotV, roughness)).rg;
float3 specular = specularColor * (fresnelIBL * envBRDF.x + envBRDF.y);
```

<!-- [ Explain in your own words why the integral can be split — and what each baked asset physically represents. ] -->

<!-- CHALLENGE: Indoor HDR environments made the IBL overwhelm the SSS and directional light contribution. Switching to an appropriate sky HDR fixed the balance. -->

### 2.3 Subsurface Scattering (SSS) at Wave Crests

Real ocean waves appear translucent and cyan-tinted when backlit. Light enters thin wave crests, scatters inside the water volume, and exits coloured by water's selective absorption of red wavelengths.

The approximation uses wave height **H** as a proxy for crest thinness:

```hlsl
float H = max(IN.WaveHeight, 0.0f) * heightModifier;
float k1 = peakScatterIntensity * H
         * pow(saturate(dot(dirLightDir, -viewDirWS)), 4.0f)
         * pow(0.5 - 0.5 * dot(dirLightDir, normal), 3.0f);

float3 sss = (1 - fresnel) * k1 * scatteredColor * DirectionalLights[0].Color;
```

<!-- [ Describe each term: the backscatter factor (dot(L,-V)^4), the surface orientation factor, and why the (1–fresnel) weighting maintains energy conservation. Reference the GDC 2019 paper / GarrettGunnell shader. ] -->

<!-- CHALLENGE: The vertex shader was initially passing incorrect height data to the pixel shader — WaveHeight was not being populated from the FFT displacement output. Also explored Beckmann vs GGX NDFs, ultimately kept GGX. -->

### 2.4 HDR Pipeline & Tonemapping

The scene renders into an `R16G16B16A16_FLOAT` HDR render target. A separate SDR fullscreen-quad pass applies tonemapping to produce the final swapchain image.

<!-- [ Describe your tonemapping operator and the two-pass pipeline structure — HDRPSO for the main scene, SDRPipelineState for tone mapping. Why does HDR matter for energy-conserving PBR math? ] -->

---

## Chapter 3 Foam

### 3.1 Jacobian-Based Foam Detection

Foam appears where waves are breaking — where horizontal displacement causes mesh triangles to fold over on themselves. The Jacobian determinant of the displacement field detects this directly: **J < 0 means triangle inversion**.

$$J = (1 + \lambda D_{xx})(1 + \lambda D_{zz}) - (\lambda D_{xz})^2$$

The four partial derivatives D_xx, D_zz, D_xz are computed in frequency space during the wave animation pass and carried through the FFT alongside displacement.

<!-- [ Explain the Jacobian matrix derivation and why the diagonal terms include a "+1" — because they are derivatives of total position (x + λ·Dx), not just displacement. ] -->

<!-- BUGS TO MENTION:
- Early foam was reading from an uninitialized component of the displacement texture (htildeDisplacement.a) instead of the dedicated foam texture — produced solid white foam or garbage flickering cubes.
- Foam texture must be zeroed at startup to prevent first-frame garbage data.
- The Jacobian cross-term was squaring one component instead of computing the proper mixed partial, giving incorrect foam coverage. -->

### 3.2 Persistent Foam Texture

Foam accumulates over time — once a wave breaks, foam persists and decays gradually. A dedicated `RWTexture2D<float>` stores foam state across frames and is never overwritten by the FFT passes.

<!-- [ Describe the persistent foam design — the permute shader reads the previous frame's foam value, applies decay, adds new foam where Jacobian threshold is crossed, and writes back to both the persistent texture and the displacement texture alpha channel for rendering. ] -->

<!-- STRUGGLE: The FFT pass was overwriting the displacement texture (including its alpha channel where foam was stored) each frame, destroying accumulated foam values before the permute shader could read them. This is why a separate persistent foam texture is necessary. -->

### 3.3 Per-Cascade Foam Tuning

Applying identical foam parameters to all four cascades produces under-foamed large waves and over-foamed small ripples. The NVIDIA paper recommends per-cascade bias values in the 0.3–0.5 range.

<!-- [ Describe the fix: 4 separate foamBias values, raising the bias from the initial conservative 0.096 toward the recommended range, and switching the pixel shader foam accumulation from max() to additive saturate() combining across cascades. ] -->

---


## Chapter 4 Wave Cascades: Multi Scale Detail

### 4.1 Why Multiple Cascades?

A single FFT patch can only represent a limited range of wave frequencies. Using one large patch loses fine ripple detail; one small patch loses large swells. Four cascades at different patch sizes solve this by each covering a unique, non-overlapping frequency band.

Each cascade covers the band $$[\omega_{low},\, \omega_{high}]$$ where the cutoff is computed from the Nyquist limit of adjacent cascades:

$$\omega_{cutoff} = \frac{N \cdot \pi}{L_i}$$

<!-- [ Describe the band-partitioning strategy and the four final patch sizes: 1500m, 250m, 17m, 5m. Explain why cascades must be ordered largest-to-smallest for the lowCutoff chaining logic to work correctly. ] -->

<!-- STRUGGLE TO MENTION: Originally started with 3 cascades at 250m / 17m / 5m — tiling was obviously visible at distance. Added the 1500m cascade to fill in the low-frequency swells. Tried reordering to smallest-to-largest which caused heavy tiling and a mirror-like ocean — the largest-to-smallest order is what the lowCutoff formula requires. -->

### 4.2 Adding the 4th Cascade

<!-- [ Tell the story of adding cascade 4 — the copy-paste bug in ocean_vertex.hlsl and ocean_pixel.hlsl that was sampling DisplacementTexture2/SlopeTexture2/FoamTexture2 for the new cascade instead of their cascade-3 equivalents. How did you find it? ] -->

<!-- BUG TO MENTION: m_foamParameters.resize() followed by push_back() doubled the vector to 8 elements instead of 4, causing a D3D12 root constants bounds error. Fixed by replacing both calls with a direct initializer list. -->

### 4.3 World-Space UV Sampling

In the vertex shader, each cascade is sampled using `worldPos.xz / patchSize[i]` as UV coordinates rather than object-space UVs. This ensures all cascades tile consistently across the same world-space ocean plane regardless of mesh position.

<!-- [ Describe the UV sampling strategy and the bug where &m_cascadeSizes was passed to the constant buffer instead of m_cascadeSizes.data(), producing garbage UV scaling for cascades 1 and 2. ] -->

<!-- BUG TO MENTION: A CLAMP sampler was being used at first — all vertices sampled the same displacement value. Fixed by adding a WRAP sampler. -->

---

## Chapter 5 Skybox & Environment

### 5.1 HDR Cubemap Pipeline

The scene uses an HDR equirectangular skybox texture converted to a cubemap at startup. The cubemap drives both the visible sky background and the IBL convolution passes described in Chapter 3.

<!-- [ Describe the cubemap pipeline — equirect-to-cubemap conversion, SkyboxPSO refactored out of the main EffectPSO using a BasePSO interface with four pure virtual methods. ] -->

<!-- STRUGGLE: Early skybox showed stripe artifacts from incorrect cubemap face dimensions (2:1 aspect ratio instead of square). DX12 PSO sample count mismatches and descriptor table sizing errors also caused crashes. Format mismatch between MSAA and non-MSAA targets (R16G16B16A16_FLOAT vs R8G8B8A8_UNORM) was a particularly subtle one. -->

### 5.2 IBL Bake Passes at Startup

All three IBL assets are computed as GPU compute dispatches during `Init()` before the first frame — diffuse irradiance convolution, specular pre-filter convolution, and BRDF LUT generation.

<!-- [ Briefly describe the three bake passes and the parameter choices — convolution plane size, sample count, and mip levels for the specular filter chain. ] -->

---

## Chapter 7 Major Struggles & Lessons Learned

### 7.1 DX12 Resource Barriers & Synchronisation

<!-- [ Reflect on how DX12's explicit synchronisation model was a recurring source of bugs throughout the project — UAV barriers, queue fences, resource state tracking between compute and graphics queues. What did you learn? ] -->

### 7.2 Debugging with RenderDoc

<!-- [ How did RenderDoc change your debugging workflow? Give one or two concrete examples of bugs you found with RenderDoc that you would not have found otherwise — for instance, confirming whether the foam texture had non-zero values in breaking areas, or inspecting intermediate FFT textures. ] -->

### 7.3 Theory Before Code

<!-- [ Reflect on your deliberate approach — understanding the Jacobian, dispersion relation, split-sum, and FFT butterfly algorithm before writing implementation. Was the time investment worth it? What would you do differently on the next project? ] -->

### 7.4 Scope Management

<!-- [ What did you decide not to implement, and why? (Clipmap LOD, foam seam fixes, refraction, caustics.) How do you think about scope on a time-boxed graphics project? ] -->

---

## Chapter 8 Results & Next Steps

### 8.1 Final Results

<!-- [ Add screenshots / video captures here. Describe the visual quality achieved — what looks good, what still has room for improvement. ] -->

| Metric | Value |
|--------|-------|
| Target framerate | 60+ fps @ 1920×1080 |
| GPU | [ Your GPU ] |
| Average frame time | [ X ms ] |
| Ocean patch size | 4096m × 4096m |
| FFT resolution | 512×512 per cascade |
| Cascade count | 4 (1500m / 250m / 17m / 5m) |

### 8.2 Known Issues

- **FFT tiling seam** — visible at distance on the large cascade, a fundamental FFT ocean artifact
- **Uniform foam parameters** — bias not yet tuned per-cascade
- **No clipmap LOD** — uniform mesh density across the whole ocean plane
- **No refraction or caustics**

### 8.3 What's Next

- **Geometry clipmap LOD** — concentric rings of geometry centred on the camera
- **Per-cascade foam bias** and additive blending in the pixel shader
- **Refraction** — depth-based water colour (light shallow, dark deep)
- **Caustics** — refracted light hitting a subsurface plane
- **Profiling** with Tracy Profiler and targeted optimisation

---

{% endcomment %}

## References

1. Tessendorf, J. (2001). *Simulating Ocean Water.* SIGGRAPH Course Notes.
2. NVIDIA. (2015). *Ocean Surface Simulation.* CGDC 2015.
3. FXGuide. (2012). *The Technology Behind Assassin's Creed III's Ocean.*
4. GarrettGunnell. [FFT Water (Unity)](https://github.com/GarrettGunnell/Water). GitHub.
5. gasgiant. [FFT-Ocean (Unity)](https://github.com/gasgiant/FFT-Ocean). GitHub.
6. Losasso, F. & Hoppe, H. (2004). *Geometry Clipmaps: Terrain Rendering Using Nested Regular Grids.* SIGGRAPH 2004.
7. Strugar, F. (2010). *Continuous Distance-Dependent Level of Detail for Rendering Heightmaps (CDLOD).*
8. Karis, B. (2013). *Real Shading in Unreal Engine 4.* SIGGRAPH 2013.
9. Bolba, G. Ocean rendering blog post.