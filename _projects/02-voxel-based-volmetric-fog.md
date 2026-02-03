---
layout: project
title: "Voxel based Volumetric Fog"
subtitle: "Timethy Hyman"
date: 2026-01-23
thumbnail: /assets/img/projects/Traverse/fogTree.webp
summary: "Real-time volumetric fog with god rays using froxel-based techniques"
tags:
  - Traverse Research
  - DX12
  - Custom Engine
  - Rendering
---
<!-- Two-column section: Overview text left, Video right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Overview

During my time at Traverse Research, I was tasked with implementing a production quality AAA volumetric fog system. The implementation is heavily inspiredby industry leading techniques presented by Naughty Dog's *The Last of Us Part II* and DICE's Frostbite engine, adapting their approaches in Traverse's rendering pipeline.

The system makes use of a froxel based (frustum aligned voxel) data structure to efficiently store and process volumetric lighting data. Shadow maps are leveraged during the raymarching pass to accelerate light occlusion calculations, enabling real time performance while maintaining visual fidelity.

### Key Contributions

- Designed and implemented a froxel data structure optimized for volumetric fog storage
- Developed GPU side froxel grid generation with exponential depth distribution
- Created debug visualization tools for froxel data inspection
- Implemented single light scattering integration
- Implemented a temporal integration system
- Implemented 3D reprojection technique to reuse existing froxel data across frames
- Created bidirectional mapping functions for froxel space and screen space coordinates

This project is currently in active development, with ongoing optimizations and feature additions.

</div>
<div class="project-media" markdown="1">

<a href="/assets/img/projects/Traverse/fogThumb.webp" class="image">
  ![Volumetric Fog Scene](/assets/img/projects/Traverse/fogThumb.webp)
</a>

<a href="/assets/img/projects/Traverse/fogTree.webp" class="image">
  ![God Rays Through Trees](/assets/img/projects/Traverse/fogTree.webp)
</a>
<p class="media-caption">Volumetric fog with god rays demonstrating single scattering and shadow occlusion</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section reverse">
<div class="project-media" markdown="1">

<a href="/assets/img/projects/Traverse/Froxels.webp" class="image">
  ![Froxel Grid Visualization](/assets/img/projects/Traverse/Froxels.webp)
</a>
<p class="media-caption">The froxel grid aligned to the camera frustum</p>

<video controls preload="metadata" src="/assets/img/projects/Traverse/GPUDepthFroxelDebug.webm" title="Froxel depth slices"></video>
<p class="media-caption">Debug visualization showing exponential depth distribution across froxel slices</p>

</div>
<div class="project-text" markdown="1">

## Froxel Grid Construction

A froxel (frustum aligned voxel) represents a volumetric element defined in camera view space.

The froxel grid construction begins by subdividing the screen into 8×8 pixel tiles in the XY plane. 
The depth dimension uses an exponential distribution based on Naughty Dog's formula, concentrating froxels near the camera where volumetric detail is more relevant. This distribution is computed as:

```hlsl
pow(2.0, (slice + q * c) / c) - pow(2.0, q);
```

This approach allocates more froxels to the near field while still covering the entire view range, maximizing detail where it matters most without excessive memory consumption. The entire grid is generated on the GPU each frame to account for dynamic camera movement.


</div>
</div>

<div class="section-divider"></div>

<!-- Another two-column section -->
<div class="project-section">
<div class="project-text" markdown="1">

## Scattering and Accumulation

The volumetric lighting calculation separates into two distinct phases: scattering computation and accumulation integration.

During the scattering phase, each froxel evaluates participating media properties. Specifically the extinction coefficient and scattering coefficient, to determine light interaction.  I raymarch from the froxel center toward the light, sampling shadow maps to determine occlusion. 

In scattered light is computed by integrating the phase function multiplied by light transmittance at each sample point. For the phase function, I'm using the Henyey Greenstein approximation.

The accumulation phase integrates all stored froxel data along the view rays through the froxel grid by combining transmittance and in scattered radiance into final textures. 

</div>
<div class="project-media" markdown="1">

<video controls preload="metadata" src="/assets/img/projects/Traverse/tempFog.webm" title="Temporal fog integration"></video>
<p class="media-caption">Real-time volumetric fog with temporal integration demonstrating god rays</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Dive Deeper

This is a very brief summary of what I’ve been working on at Traverse. It is still a work in progress with lots of improvements yet to be made. As the project develops, I'll write a detailed blogpost about it. Stay tuned!

</div>