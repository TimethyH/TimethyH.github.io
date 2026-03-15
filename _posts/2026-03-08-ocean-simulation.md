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
2. [Wave Cascades: Multi Scale Detail](#chapter-2-wave-cascades-multi-scale-detail)
3. [Rendering & Shading](#chapter-3-rendering--shading)
4. [Foam](#chapter-4-foam)
5. [Skybox & Environment](#chapter-5-skybox--environment)
7. [Major Struggles & Lessons Learned](#chapter-7-major-struggles--lessons-learned)
8. [Results & Next Steps](#chapter-8-results--next-steps)


## Understanding the basics


<details>
<summary>  How does a sine wave work?</summary>

The ocean wave implementation is heavily based on using multiple sine waves to get interesting displacements. 
Sine waves are oscillators, which means they generate a repetitive wave signal that stays within its amplitude. 3 important terms regarding a wave is its amplitude, its wavelength and its frequency.  
Amplitude is the peak of the wave, the highest value the that can be sampled. Wavelength is the distance between two of these peaks, you can imagine this like a spring. A spring that is compressed would represent a short wavelength while a spring that is stretched out would represent a long wavelength. To shape the wave using a desired wavelength, we can use certain formulas that will be discussed below.


</details>

<details>
<summary>What are complex numbers?</summary>

<p>
A complex number is simply two numbers packed into one. It has a real part and an imaginary part. Its form is \(c = a + bi\)
You can think of it like a 2D coordinate. Instead of writing \(p = (3,4)\), you'd write \(p = 3 + 4i\). The <em>i</em> is the imaginary part of the number, which lives on the axis perpendicular to the real number line.
When any number is multiplied by the imaginary <em>i</em>, it is essentially "rotated" by 90° counter clockwise. Interesting note, multiplying a number by <em>i</em> twice, brings it to -1, which leads to a whole other discussion on why \(i = \sqrt{-1}\). But that is out of the scope of this blogpost.
</p>

</details>

<details>
<summary>  What is Euler's formula? </summary>

</details>

<details>
<summary>  How does a compute shader work? </summary>

</details>


Simulating the ocean can seem daunting, but oceanographers across the world measured the frequencies found within waves.  

## Chapter 1 Wave Simulation: JONSWAP & the FFT Pipeline


### 1.1 The Wave Spectrum (JONSWAP + TMA)

The ocean simulation is driven by a statistical wave spectrum. Rather than simulating individual water particles, the sea surface is represented as a superposition of many sinusoidal waves — each with an amplitude drawn from an energy distribution that encodes wind conditions.

<!-- [ Describe the JONSWAP spectrum in your own words. What does each parameter control — windSpeed, fetch, gamma, swell, spreadBlend, shortWavesFade? Why did you choose JONSWAP+TMA over a simpler Phillips spectrum? ] -->

<!-- STRUGGLE TO MENTION: Getting swell and shortWavesFade tuned — initial waves looked like "boiling water" until parameters were dialled in. Low wind speed caused large slow swells from the 1500m cascade that looked like bouncing, but is physically correct behaviour. -->

### 1.2 Initial Spectrum Generation: H₀

$$\tilde{h}_0(\mathbf{k}) = \frac{1}{\sqrt{2}}(\xi_r + i\xi_i)\sqrt{P_h(\mathbf{k})}$$

H₀(**k**) is generated once on the CPU and uploaded to the GPU. Each texel stores a complex amplitude drawn from a Gaussian random distribution, scaled by the square root of the spectrum energy at that wavevector.

<!-- [ Describe the GenerateH0 function — how Gaussian noise is combined with the spectrum, and the critical conjugate symmetry requirement h₀(–k) = h₀*(k) that guarantees a real-valued displacement field after IFFT. ] -->

<!-- STRUGGLE TO MENTION: Early bug — the conjugate was being generated with new random numbers instead of the actual complex conjugate of h₀(k), breaking real-output symmetry entirely. -->

### 1.3 Time Evolution: Animating the Waves

$$\tilde{h}(\mathbf{k}, t) = \tilde{h}_0(\mathbf{k})\,e^{i\omega(k)t} + \tilde{h}_0^*(-\mathbf{k})\,e^{-i\omega(k)t}$$

Each frame, H₀ is evolved in frequency space using the dispersion relation, producing h̃(**k**, t). Quantised dispersion is used so that wave phases repeat exactly after a fixed period — giving seamless temporal looping with no discontinuity.

<!-- [ Explain how animate_waves.hlsl works — the dispersion relation ω = √(g·k), Euler's formula for complex exponentials, and why you accumulate total time rather than per-frame deltaTime. ] -->

### 1.4 The Butterfly FFT

A 2D IFFT converts the frequency-domain spectrum into a real-space displacement field each frame. The FFT is implemented as a GPU compute shader using the Cooley-Tukey butterfly algorithm.

<!-- [ Walk through the FFT pipeline — bit-reversal permutation, twiddle factor calculation, ping-pong buffers to avoid race conditions, row pass then column pass, and the final checkerboard permutation. ] -->

<!-- STRUGGLE TO MENTION:
- Checkerboard artifacts caused by a missing UAV barrier after the vertical FFT dispatch in DX12.
- Double-buffer race conditions requiring the ping-pong approach.
- Stack overflow from large stack-allocated complex arrays in GenerateH0 — fixed by moving to heap vectors.
- Incorrect normalization (dividing by N instead of N² for 2D IFFT) producing flat output. -->

---

## Chapter 2 Wave Cascades: Multi Scale Detail

### 2.1 Why Multiple Cascades?

A single FFT patch can only represent a limited range of wave frequencies. Using one large patch loses fine ripple detail; one small patch loses large swells. Four cascades at different patch sizes solve this by each covering a unique, non-overlapping frequency band.

Each cascade covers the band $$[\omega_{low},\, \omega_{high}]$$ where the cutoff is computed from the Nyquist limit of adjacent cascades:

$$\omega_{cutoff} = \frac{N \cdot \pi}{L_i}$$

<!-- [ Describe the band-partitioning strategy and the four final patch sizes: 1500m, 250m, 17m, 5m. Explain why cascades must be ordered largest-to-smallest for the lowCutoff chaining logic to work correctly. ] -->

<!-- STRUGGLE TO MENTION: Originally started with 3 cascades at 250m / 17m / 5m — tiling was obviously visible at distance. Added the 1500m cascade to fill in the low-frequency swells. Tried reordering to smallest-to-largest which caused heavy tiling and a mirror-like ocean — the largest-to-smallest order is what the lowCutoff formula requires. -->

### 2.2 Adding the 4th Cascade

<!-- [ Tell the story of adding cascade 4 — the copy-paste bug in ocean_vertex.hlsl and ocean_pixel.hlsl that was sampling DisplacementTexture2/SlopeTexture2/FoamTexture2 for the new cascade instead of their cascade-3 equivalents. How did you find it? ] -->

<!-- BUG TO MENTION: m_foamParameters.resize() followed by push_back() doubled the vector to 8 elements instead of 4, causing a D3D12 root constants bounds error. Fixed by replacing both calls with a direct initializer list. -->

### 2.3 World-Space UV Sampling

In the vertex shader, each cascade is sampled using `worldPos.xz / patchSize[i]` as UV coordinates rather than object-space UVs. This ensures all cascades tile consistently across the same world-space ocean plane regardless of mesh position.

<!-- [ Describe the UV sampling strategy and the bug where &m_cascadeSizes was passed to the constant buffer instead of m_cascadeSizes.data(), producing garbage UV scaling for cascades 1 and 2. ] -->

<!-- BUG TO MENTION: A CLAMP sampler was being used at first — all vertices sampled the same displacement value. Fixed by adding a WRAP sampler. -->

---

## Chapter 3 Rendering & Shading

### 3.1 Physically-Based Shading (PBR)

The ocean surface is shaded using a full PBR BRDF:
- **GGX** normal distribution function
- **Smith** geometry function (shadowing-masking)  
- **Fresnel-Schlick** approximation

<!-- [ Briefly explain each term and why they suit water — GGX's long specular tail matches the sharp sun glints seen on a real ocean. Discuss your roughness and metallic values. ] -->

<!-- STRUGGLE TO MENTION: Early specular was broken because world-space normals were being dotted with view-space vectors — a coordinate-space mismatch producing dark spots across the surface. -->

### 3.2 Image-Based Lighting (IBL) — Split-Sum Approximation

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

### 3.3 Subsurface Scattering (SSS) at Wave Crests

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

### 3.4 HDR Pipeline & Tonemapping

The scene renders into an `R16G16B16A16_FLOAT` HDR render target. A separate SDR fullscreen-quad pass applies tonemapping to produce the final swapchain image.

<!-- [ Describe your tonemapping operator and the two-pass pipeline structure — HDRPSO for the main scene, SDRPipelineState for tone mapping. Why does HDR matter for energy-conserving PBR math? ] -->

---

## Chapter 4 Foam

### 4.1 Jacobian-Based Foam Detection

Foam appears where waves are breaking — where horizontal displacement causes mesh triangles to fold over on themselves. The Jacobian determinant of the displacement field detects this directly: **J < 0 means triangle inversion**.

$$J = (1 + \lambda D_{xx})(1 + \lambda D_{zz}) - (\lambda D_{xz})^2$$

The four partial derivatives D_xx, D_zz, D_xz are computed in frequency space during the wave animation pass and carried through the FFT alongside displacement.

<!-- [ Explain the Jacobian matrix derivation and why the diagonal terms include a "+1" — because they are derivatives of total position (x + λ·Dx), not just displacement. ] -->

<!-- BUGS TO MENTION:
- Early foam was reading from an uninitialized component of the displacement texture (htildeDisplacement.a) instead of the dedicated foam texture — produced solid white foam or garbage flickering cubes.
- Foam texture must be zeroed at startup to prevent first-frame garbage data.
- The Jacobian cross-term was squaring one component instead of computing the proper mixed partial, giving incorrect foam coverage. -->

### 4.2 Persistent Foam Texture

Foam accumulates over time — once a wave breaks, foam persists and decays gradually. A dedicated `RWTexture2D<float>` stores foam state across frames and is never overwritten by the FFT passes.

<!-- [ Describe the persistent foam design — the permute shader reads the previous frame's foam value, applies decay, adds new foam where Jacobian threshold is crossed, and writes back to both the persistent texture and the displacement texture alpha channel for rendering. ] -->

<!-- STRUGGLE: The FFT pass was overwriting the displacement texture (including its alpha channel where foam was stored) each frame, destroying accumulated foam values before the permute shader could read them. This is why a separate persistent foam texture is necessary. -->

### 4.3 Per-Cascade Foam Tuning

Applying identical foam parameters to all four cascades produces under-foamed large waves and over-foamed small ripples. The NVIDIA paper recommends per-cascade bias values in the 0.3–0.5 range.

<!-- [ Describe the fix: 4 separate foamBias values, raising the bias from the initial conservative 0.096 toward the recommended range, and switching the pixel shader foam accumulation from max() to additive saturate() combining across cascades. ] -->

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