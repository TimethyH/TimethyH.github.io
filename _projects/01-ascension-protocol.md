---
layout: project
title: "Ascension Protocol - VR"
subtitle: "VR game fully made in a custom engine."
date: 2025-06-27
thumbnail: /assets/img/projects/Y2VR/Ascension.jpg
summary: "VR game fully made in our own custom engine."
tags:
  - Custom Engine
  - University Project
  - Rendering
  - VR
  - Game
---

<!-- Two-column section: Overview text left, Video right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Overview

Ascension Protocol is a VR game created in our custom engine in year 2 at Breda University. 

In this game, you are elevated through the clouds and met with hordes of robots. Your goal is to evade, deflect and shoot them while keeping your balance on the collapsing platform till you reach the mountain peak.

The team consisted of 8 developers. My role in the team was **Graphics Programmer** and **Optimization**.

### What did I do?

- I was in charge of the skybox and IBL reflections.
- Created the volumetric fog used for the dust and clouds, as well as the depth fog.
- Created the bloom postprocessing effect and HDR color support.
- I was in charge of the **Optimizations** so the game stays within budget of 16.6 ms
- I made improvements to the shadows in the game

The game was made in 16 weeks: 8 for the VR/engine setup and 8 for the game itself.

</div>
<div class="project-media" markdown="1">

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
  <iframe 
    style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;" 
    src="https://www.youtube.com/embed/r9AC-AtrcQo" 
    frameborder="0" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
    allowfullscreen>
  </iframe>
</div>
<p class="media-caption">Gameplay footage of Ascension Protocol</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Volumetric Fog

The core of the volumetric fog system is built around a 3D noise texture and 2 render passes.  
The shader that handles the 3D noise generation has 2 interesting functions: the **noise(vec3 p)** function which generates 2D tilable noise based on the world position of the ray, and the **fbm(vec3 p)** function which uses the generated noise to add layers of detail at multiple frequencies.  The result of which looks like puffy, layered clouds. 

The main function samples the density at a world position by generating a plane and multiplying the plane position with the fbm and stores this into the 2D texture. This is repeated 256 times to generate a 256x256x256 3D texture.

```hlsl
// Density function
float scene(vec3 p) 
{
    float f = fbm(p);

    // Height-based falloff
    float base = smoothstep(0.0, 1.0, p.y);
    return base * f;
}
```

The 2nd pass raymarches through every slice of the noise texture and samples the cloud density at the ray's world position. It then calculates the cloud color using the density and sun parameters.


</div>
<div class="project-media" markdown="1">

<video controls src="/assets/img/projects/Y2VR/fog.mp4" title="Title"></video>
<p class="media-caption">Volumetrics used as dust</p>

<video controls src="/assets/img/projects/Y2VR/CloudUI.mp4" title="Title"></video>

<p class="media-caption">The clouds with tweakable parameters</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Another two-column section -->
<div class="project-section">
<div class="project-text" markdown="1">

## Optimizations

After profiling I concluded that our project was memory bound and took a lot of time rendering objects that were not visible on screen. 

### Implementation Details

I used ray marching through the froxel grid with the following optimizations:

- **Temporal reprojection**: Reduces noise by blending current and previous frames
- **Exponential depth distribution**: More detail near camera, better performance overall  
- **Hardware interpolation**: Leveraging 3D texture sampling for smooth results
- **Adaptive step size**: Fewer samples in empty space

The shader performs 32 ray marching steps per pixel, with temporal accumulation bringing effective sample count much higher.

</div>
<div class="project-media" markdown="1">

![Volumetric lighting in forest scene](/assets/img/helmet.png)
<p class="media-caption">God rays streaming through trees in a forest environment</p>

![Debug view of light scattering](/assets/img/helmet.png)
<p class="media-caption">Debug visualization showing light scattering values</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Example with code -->
<div class="project-section">
<div class="project-text" markdown="1">

## Performance Optimizations

To achieve real-time performance, I implemented several key optimizations:

1. **Checkerboard rendering**: Only update half the pixels each frame
2. **Depth-aware upsampling**: Bilateral filter for artifact-free upscaling
3. **GPU-driven culling**: Lights outside frustum are culled on GPU
4. **Async compute**: Volume generation runs in parallel with geometry pass

Here's the core froxel indexing function:

```hlsl
uint3 GetFroxelCoord(float3 viewPos) {
    float depth = -viewPos.z;
    float linearDepth = saturate(depth / farPlane);
    float zSlice = log2(linearDepth * zParams.x + 1.0) * zParams.y;
    
    uint3 coord;
    coord.xy = uint2(screenPos.xy * froxelDimensions.xy);
    coord.z = uint(zSlice * froxelDimensions.z);
    return coord;
}
```

With these optimizations, the system runs at **~3.5ms** at 1080p on an RTX 3070.

</div>
<div class="project-media" markdown="1">

![Performance graph](/assets/img/helmet.png)
<p class="media-caption">Frame time breakdown showing volumetric pass cost</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Results & Reflections

This project taught me a lot about volumetric rendering techniques and GPU optimization. The biggest challenge was handling the noise inherent to ray marching - temporal reprojection helped significantly but required careful handling of disocclusion cases.

The system integrates seamlessly into my engine's deferred renderer and supports multiple dynamic lights. I'm particularly happy with how the exponential depth distribution allows good quality near the camera while still supporting large view distances.

### What I Learned

- Deep understanding of froxel-based volume rendering
- Temporal reprojection and history buffer management  
- Performance optimization for compute-heavy rendering techniques
- DirectX 12 compute shader programming and UAV barriers

**GitHub Repository**: [github.com/yourusername/volumetric-fog](https://github.com/yourusername/volumetric-fog)

</div>