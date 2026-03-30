---
layout: project
title: "EV Engine"
subtitle: "Timethy Hyman"
date: 2025-11-23
thumbnail: /assets/img/projects/EV/cascadeThumb.webp
summary: "👥 1 developer | DirectX 12 Ocean Renderer"
blog_url: /blog/fft-ocean-rendering/
tags:
  - Personal Project
  - Custom Engine
  - DX12
category: year3
---

<!-- Two-column section: Overview text left, Image right -->
<div class="project-section">
  <div class="project-text" markdown="1">

## Overview

EV Engine is a DX12 renderer I started to improve my DX12 skills and rendering knowledge in general. It is based off of the work of one of my lecturers: Jeremiah van Oosten. You can see his work on [3dgep](https://www.3dgep.com/)! Following this tutorial I laid the foundation of the engine.

A wise man at [Nixxies](https://www.nixxes.com/) gave me the suggestion to build something I would be passionate about. Following his advice, I decided to build EV Engine, an Ocean Rendering application. 
The application's purpose is to help my dad's company simulate the carribean seas as a background for their architectural 
renders. On top of that, I hope it can play a small part in advancing the digital scene of my island.

I started the engine in November 2025.

Core engine implementation: 3 months.  
Ocean implementation: 1 month.


  </div>
  <div class="project-media" markdown="1">

  <video controls autoplay loop muted preload="metadata" src="/assets/img/projects/EV/sceneCompressed.mp4"></video>

  </div>
</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section reverse">
  <div class="project-text" markdown="1">

## What I did so far

All work so far is done by simply following along with Jeremiah's tutorial. The result of which gave me a good base of understanding the concepts that are required to build a DX12 renderer from scratch, such as:

**Engine Foundation**
  - DirectX 12 renderer from scratch: memory management, resource barriers, descriptor heaps, root signatures, and mip generation
  - HDR skybox pipeline with HDR to SDR tonemapping 

**Implemented real time FFT ocean simulation using the JONSWAP wave spectrum**
  - 4 wave cascades running simultaneously to cover large swells and fine surface detail at the same time
  - Per cascade frequency band cutoffs derived from Nyquist limits
  - Compute shaders that handle the butterfly FFT, outputting displacement and slope textures per cascade

**Water Shading**
  - PBR water shading with GGX specular, Fresnel Schlick, and split sum IBL reflections
  - Approximated subsurface scattering
  - Foam detection using the Jacobian determinant

  </div>
  <div class="project-media" markdown="1">

  <video controls autoplay loop muted preload="metadata" src="/assets/img/projects/EV/calmWavesCompressed.mp4"></video>
  <p class="media-caption">FFT Generated ocean with 4 frequency bands</p>

<a href="/assets/img/projects/EV/chess.webp" class="image">
  ![Chess IBL](/assets/img/projects/EV/chess.webp)
</a>
<p class="media-caption">IBL</p>

  </div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Up Next

The ocean currently has a LOD issue, vertices near the camera correctly display fine wave detail 
from all four cascades, but further vertices abruptly lose that detail as only the larger cascades 
contribute. I'm currently researching solutions, and it's looking like geometry tessellation shaders 
will be the right approach.

Beyond that, I plan to profile and optimize the simulation more thoroughly to further develop my profiling and optimization skills.

A full breakdown of the implementation is covered in the blog post!

<a href="https://github.com/TimethyH/EV" target="_blank" class="btn btn-dark btn-lg" style="text-decoration: none;">
  <i class="fab fa-github" style="margin-right: 8px;"></i> View on GitHub
</a>

<a href="/blog/fft-ocean-rendering/" target="_blank" class="btn btn-dark btn-lg" style="text-decoration: none;">
  <i class="fas fa-book-open" style="margin-right: 8px;"></i> Read Article
</a>

<a href="https://buas.artstation.com/YOUR_PROJECT_URL" target="_blank" class="btn btn-lg btn-artstation" style="text-decoration: none;">
  <i class="fa-brands fa-artstation" style="margin-right: 8px;"></i> Featured on BUas ArtStation
</a>
</div>