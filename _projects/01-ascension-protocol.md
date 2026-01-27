---
layout: project
title: "Ascension Protocol - VR"
subtitle: "Timethy Hyman"
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

The main function samples the density at a world position by generating a plane, multiplying the plane position with the fbm and stores this value into the 2D texture. This is repeated 256 times to generate a 256x256x256 3D texture.

The 2nd pass raymarches through every slice of the noise texture and samples the cloud density at the ray's world position. It then calculates the cloud color using the density and sun parameters.

*I will go more into detail on how I achieved this in my blog. (linked once it's online)*

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

After profiling I concluded that our project was memory bound and took a lot of time rendering objects that were not visible on screen. To solve this I added frustum culling which allowed the forward pass to go from 2.30ms to 0.74ms. I also reduced the resolutions used for bloom and fog which led the fog renderpass go from 3.32ms to 0.93ms.

*I will go more into detail on how I achieved this in my blog. (linked once it's online)*

</div>
<div class="project-media" markdown="1">


<video controls src="/assets/img/projects/Y2VR/lowResFog.mp4" title="Title"></video>
<p class="media-caption">Fog quality at half resolution</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Example with code -->
<div class="project-section">
<div class="project-text" markdown="1">

## Bloom and HDR

Bloom makes the game feel more alive. To get bloom working I first needed to make sure the render targets support HDR.

HDR is needed since bloom requires values to be above the 1.0 threshold. This allows us to do lighting calculations with bright colors and tonemap them back to the 0.0 - 1.0 threshold.

The bloom is seperated into 3 parts, first I separate the brighter colors into a separate color buffer and keep the original scene colors separate in another color buffer.  
Then using dual kawase blur, I down sample the bright color buffer. To do this, I take 4 samples per pixel and blur them together. I do this for n amount of mips, in my case 4. Each time with a smaller render target.  
Then I upsample the final downsampled buffer in a forloop aswel for every mip, which results in a bright blurred texture of our original resulution.

Finally in the postprocessing shader, I add the fog, the scene and the brightcolors together. Using ACESFILM tonemapping and gamma correction to bring the values to sRGB space (0-1).

</div>
<div class="project-media" markdown="1">

<video controls src="/assets/img/projects/Y2VR/bloomCrab.mp4" title="Title"></video>
<p class="media-caption">The crab enemy has bloom on its eye</p>

<video controls src="/assets/img/projects/Y2VR/FlyerParticles.mp4" title="Title"></video>
<p class="media-caption">The flying drone and particles using bloom</p>
</div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Dive Deeper

This is a summary of what I did on for the project during the 8 weeks I had. If you'd like to know more on how I implemented the fog, bloom or optimization steps, take a look at the full article: [not online yet](https://timethyh.github.io/blog/#/)

**GitHub Repository**: [github.com/yourusername/volumetric-fog](https://github.com/yourusername/volumetric-fog)

</div>