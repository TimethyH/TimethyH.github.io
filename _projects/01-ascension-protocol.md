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
<div class="project-text" markdown="1">

## Overview

Ascension Protocol is a VR game created in our custom engine in year 2 at Breda University. In this game, you are elevated through the clouds and met with hordes of robots. Your goal is to evade, deflect and shoot them while keeping your balance on the collapsing platform till you reach the mountain peak.

The team consisted of 8 developers. My role in the team was **Graphics Programmer** and **Optimization**.

### What did I do?

- I was in charge of the skybox and IBL reflections
- I created the volumetric fog used for the dust and clouds, as well as the depth fog
- I was in charge of the bloom postprocessing effect and HDR color support
- I was in charge of the **Optimizations** such as frustum culling, memory management and general profiling so the game stays within budget of 16.6 ms
- I made improvements to the shadows in the game

The game was made in 16 weeks: 8 for the VR/engine setup and 8 for the game itself.

</div>
<div class="project-media" markdown="1">

<video controls>
  <source src="/assets/img/gallery/y2vr/ThatsSoSick.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>
<p class="media-caption">Gameplay footage of Ascension Protocol</p>

</div>


<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Froxel Grid Implementation

The core of the volumetric fog system is built around a 3D froxel grid. Each froxel (frustum voxel) represents a volume of space in view space, allowing efficient sampling of lighting and fog density.

Key features:
- **160x90x64** froxel resolution for optimal performance
- Non-uniform depth distribution for better detail near camera
- View-space aligned to prevent swimming artifacts
- Compute shader-based volume generation

The froxel grid is regenerated each frame using a compute shader that calculates lighting contributions from all active light sources.

</div>
<div class="project-media" markdown="1">

![Froxel grid visualization](/assets/img/helmet.png)
<p class="media-caption">Visualization of the froxel grid structure in view space</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Another two-column section -->
<div class="project-section">
<div class="project-text" markdown="1">

## Volumetric Lighting

The volumetric lighting pass samples the froxel grid to compute in-scattering and light attenuation. This creates the characteristic god rays effect when light passes through fog.

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