---
layout: project
title: "EV Engine"
subtitle: "Timethy Hyman"
date: 2025-11-23
thumbnail: /assets/img/projects/EV/SponzaPrototype.webp
summary: "DirectX 12 Renderer"
tags:
  - DX12
  - Custom Engine
  - Personal Project
category: year3
---

<!-- Two-column section: Overview text left, Image right -->
<div class="project-section">
  <div class="project-text" markdown="1">

## Overview

EV Engine is a DX12 renderer I started to improve my DX12 skills and rendering knowledge in general. It is based off of the work of one of my lecturers: Jeremiah van Oosten. You can see his work on [3dgep](https://www.3dgep.com/)!

The goal of this engine is to have basic functionality to **render full scenes** for example Sponza with **PBR**, **IBL** and a **skybox**. From there the goal is to implement the following ideas:

- Ocean rendering
- Volumetric clouds inspired by [Nubis](https://www.guerrilla-games.com/read/nubis-cubed)

By implementing these concepts, I hope to build a scene that reminds me of home.

The engine is still in early development. I started the engine in November 2024.

  </div>

  <div class="project-media">
    <a href="/assets/img/projects/EV/SponzaPrototype.webp" class="image">
      <img src="/assets/img/projects/EV/SponzaPrototype.webp" alt="Sponza Scene Prototype">
    </a>
  </div>
</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section reverse">
  <div class="project-text" markdown="1">

## What I did so far

All work so far is done by simply following along with Jeremiah's tutorial. The result of which gave me a good base of understanding the concepts that are required to build a DX12 renderer from scratch, such as:

- Memory management / allocation system
- Resource barriers and transitions
- Mip Generation
- Root signatures
- Descriptors

By applying what I learned, I managed to set the base for this project. An engine that loads any model and renders it with PBR.

This of course is still only the base of what I intend to achieve with this engine. With this done, I can focus on researching **Fast Fourier Transforms** for the **Ocean Rendering**!

  </div>
  
  <div class="project-media">
    <a href="/assets/img/projects/EV/ev-base.webp" class="image">
      <img src="/assets/img/projects/EV/ev-base.webp" alt="Chessboard with PBR">
    </a>
    <p class="media-caption">A chessboard within sponza with PBR.</p>
  </div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Up Next

This project is still a work in progress. Once it has more content the webpage will be updated!

The next step is to have a fully rendered scene.

</div>