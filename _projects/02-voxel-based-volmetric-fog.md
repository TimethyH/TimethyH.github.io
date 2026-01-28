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

During my time at Traverse Research, I was asked to implement a AAA volumetric fog system. The system is largely based on how The Last of US 2 and Frostbite's implementation.

The implementation is voxel based and uses shadowmaps to speedup the raymarching pass. 

### What did I do?

- Created a voxel data structure to store fog data.
- Created a froxel grid with exponential depth on the GPU.
- Created debug tools for froxel visualization.
- Implemented single light scattering integration.
- Implemented temporal Integration.
- Implemented reprojection to reuse existing froxel data.
- Implemented functionality to map froxel space to screenspace and viceversa.

This project is still on going.
</div>
<div class="project-media" markdown="1">

![alt text](/assets/img/projects/Traverse/fogThumb.webp)

![alt text](/assets/img/projects/Traverse/fogTree.webp)
<p class="media-caption">Volumetric Fog and Godrays</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Froxel Grid

A froxel is a voxel defined in camera (view) space, aligned to the camera frustum.
The froxel grid is created by dividing the render resolution into 8x8pix froxels. The depth of the grid is calculated using the exponential depth function provided by Naughty Dog.

*I will go more into detail on how I achieved this in my blog. (linked once it's online)*

</div>
<div class="project-media" markdown="1">

![alt text](/assets/img/projects/Traverse/Froxels.webp)
<p class="media-caption">The froxel grid within the view frustum</p>

<video controls src="/assets/img/projects/Traverse/GPUDepthFroxelDebug.webm" title="Title"></video>
<p class="media-caption">Visualized depth slices</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Another two-column section -->
<div class="project-section">
<div class="project-text" markdown="1">

## Scattering and Accumulation

We calculate Transmittance and Scattered light and store the values for every froxel. Then in another pass we can accumulate this data and write it into their respective textures.

This is still a work in progress eventhough the result looks "okay" right now. Will update this sections as the project moves forward.

</div>
<div class="project-media" markdown="1">

<video controls src="/assets/img/projects/Traverse/tempFog.webm" title="Title"></video>

</div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Dive Deeper

This is a very brief summary of what I've been working on at Traverse. It is still a work in progress so stay tuned if the topic sparked your interest! 

</div>