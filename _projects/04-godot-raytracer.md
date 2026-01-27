---
layout: project
title: "Raytracing in Godot"
subtitle: "Timethy Hyman"
date: 2025-09-23
thumbnail: /assets/img/projects/Y3A/materials.png
summary: "Real-time volumetric fog with god rays using froxel-based techniques"
tags:
  - Vulkan
  - Rendering
  - University Project
category: year3
---


<!-- Full-width introduction section -->
<div class="project-full-width" markdown="1">

## Overview

During my self study block in Year 3,  I worked together with 2 other programmers to create a **raytracing extension** for **Godot**.

**What did I do**
  - Setup the raytracing pipeline.
  - Added functionality to create BLAS and TLAS acceleration structures.
  - Created the Raygen, Hit and Miss shaders.
  - Improved the Shader Binding Table.
  - Added Bindless Rendering support.
  - Added Material Rendering support.


</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Pipeline Overview

TODO

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

## Bindless

Godot does not inheritly support bindless. The only way the engine supports multiple textures is if a static array of textures is defined in the shader. 
The extra limitation of this is that every texture in this array has to share the same resolution.

I deemed it important for the raytracer to be able to render any amount of textures,
without the user needing to worry about their resolutions, or over-allocating texture slots.

implementation details can be found on my [blog](https://timethyh.github.io/blog/#/) (*once its online...*)


</div>
<div class="project-media" markdown="1">

![Volumetric lighting in forest scene](/assets/img/helmet.png)
<p class="media-caption">God rays streaming through trees in a forest environment</p>

![Debug view of light scattering](/assets/img/helmet.png)
<p class="media-caption">Debug visualization showing light scattering values</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Results & Reflections

This was the most challenging project so far.  
In the end we're proud we achieved to build a working raytracer in 8 weeks. The raytracer is still very bare bones and does not have lighting support, or transparant object support, but we wish to continue polishing the extension over the coming months.

**GitHub Repository**: [Godot Raytracer](https://github.com/TimethyH/godot-raytrace)

</div>