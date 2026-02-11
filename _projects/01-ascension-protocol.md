---
layout: project
title: "Ascension Protocol - VR"
subtitle: "Timethy Hyman"
date: 2025-06-27
thumbnail: /assets/img/projects/Y2VR/VR.webp
summary: "👥 9 developers | VR game fully made in our own custom engine."
tags:
  - Custom Engine
  - University Project
  - VR
  - Game
---

<!-- Two-column section: Overview text left, Video right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Overview

Ascension Protocol is a VR game developed using our custom engine during my second year at Breda University of Applied Sciences.

In this game, players ascend through the clouds while facing waves of hostile robots. The objective is to evade, deflect, and eliminate threats while maintaining balance on a collapsing platform until reaching the mountain peak.

The development team consisted of eight developers. My role focused on **Graphics Programming** and **Performance Optimization**.

### Key Contributions

- Implemented skybox rendering and Image-Based Lighting (IBL) reflections
- Developed volumetric fog system for atmospheric dust and clouds, including depth fog
- Created bloom post-processing effects with HDR color support
- Optimized rendering pipeline to maintain target performance of 16.6ms per frame
- Enhanced shadow rendering quality and performance

The project was completed over 16 weeks: 8 weeks for VR integration and engine development, followed by 8 weeks of game production.

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

<!-- Two-column section: Media left, Text right (REVERSED) -->
<div class="project-section reverse">
<div class="project-media" markdown="1">

<video controls preload="metadata" src="/assets/img/projects/Y2VR/fog.webm"></video>
<p class="media-caption">Volumetrics used as dust</p>

<video controls preload="metadata" src="/assets/img/projects/Y2VR/CloudUI.webm"></video>
<p class="media-caption">Real-time cloud parameter adjustment</p>

</div>
<div class="project-text" markdown="1">

## Volumetric Fog

The volumetric fog system is built upon a 3D noise texture and a two-pass rendering approach.

The shader responsible for 3D noise generation utilizes two key functions: **noise(vec3 p)**, which generates tileable 2D noise based on the ray's world position, and **fbm(vec3 p)** (Fractal Brownian Motion), which layers noise at multiple frequencies to create detailed, cloud-like structures.

The main function samples density values at world-space positions by generating a plane and multiplying its position with the fbm output, storing the result in a 2D texture. This process is repeated 256 times to generate a complete 256×256×256 3D texture.

The second pass raymarches through each slice of the noise texture, sampling cloud density at the ray's world position and calculating cloud color based on density values and sun parameters.

*A detailed technical breakdown of this implementation will be available in my upcoming blog post.*

</div>
</div>

<div class="section-divider"></div>

<!-- Another two-column section: Text left, Media right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Performance Optimization

Performance profiling revealed that the project was memory-bound, with significant time spent rendering off-screen objects. To address this, I implemented frustum culling, reducing the forward pass time from 2.30ms to 0.74ms.

Additionally, I optimized the rendering resolution for bloom and fog effects, decreasing the fog render pass from 3.32ms to 0.93ms while maintaining visual quality.

*Detailed optimization techniques and profiling methodologies will be covered in my upcoming blog post.*

</div>
<div class="project-media" markdown="1">

<video controls preload="metadata" src="/assets/img/projects/Y2VR/lowResFog.webm"></video>
<p class="media-caption">Fog quality at half resolution</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Example with code: Media left, Text right (REVERSED) -->
<div class="project-section reverse">
<div class="project-media" markdown="1">

<video controls preload="metadata" src="/assets/img/projects/Y2VR/bloomCrab.webm"></video>
<p class="media-caption">Bloom effect highlighting the crab enemy's eye</p>

<video controls preload="metadata" src="/assets/img/projects/Y2VR/FlyerParticles.webm"></video>
<p class="media-caption">Flying drone and particle systems with bloom</p>

</div>
<div class="project-text" markdown="1">

## Bloom and HDR

Bloom post-processing significantly enhances visual impact. Implementing bloom required ensuring render targets supported High Dynamic Range (HDR).

HDR is essential for bloom, as it enables values exceeding the 1.0 threshold, allowing accurate lighting calculations with bright colors before tone mapping back to the 0.0-1.0 range.

The bloom implementation consists of three stages: First, bright colors are separated into a dedicated buffer while preserving the original scene in another. Second, using dual Kawase blur, the bright buffer is downsampled by taking four samples per pixel and blurring them together across multiple mip levels (four in this case), each with progressively smaller render targets. Third, the final downsampled buffer is upsampled through each mip level, producing a bright, blurred texture at the original resolution.

In the final post-processing shader, fog, scene, and bright colors are combined. ACES filmic tone mapping and gamma correction convert the values to the sRGB color space (0-1).

</div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Further Reading

This article provides an overview of my contributions to the project during the 8 weeks of development. For in depth technical details on fog implementation, bloom effects, and optimization strategies, stay tuned for my upcoming blog post!

🎮 Check out the game on [Itch.io](https://buas.itch.io/ascension-protocol).

</div>