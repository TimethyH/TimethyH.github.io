---
layout: project
title: "EV Engine"
subtitle: "Timethy Hyman"
date: 2025-11-23
thumbnail: /assets/img/projects/EV/cascadeThumb.webp
summary: "👥 1 developer | DirectX 12 Ocean Renderer"
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
The application's purpose is to help my dad's company simulate the carribean seas as a background of their architectural 
renders. On top of that, I hope it can play a small part in advancing the digital scene of my island.

The engine is still in early development. I started the engine in November 2024.

  </div>
  <div class="project-media" markdown="1">

  <video controls autoplay loop muted preload="metadata" src="/assets/img/projects/EV/sceneCompressed.mp4"></video>
  <p class="media-caption">Water Prototype!!</p>

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

This project is still a work in progress. Once it has more content the webpage will be updated!

<a href="https://github.com/TimethyH/EV" target="_blank" class="btn btn-dark btn-lg" style="text-decoration: none;">
  <i class="fab fa-github" style="margin-right: 8px;"></i> View on GitHub
</a>

</div>