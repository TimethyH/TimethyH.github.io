---
layout: project
title: "Deferred Rendering on PS5"
subtitle: "Timethy Hyman"
date: 2024-09-23
thumbnail: /assets/img/helmet.webp
summary: "My first rendering project."
tags:
  - PS5
  - Custom Engine
  - Rendering
  - University Project
category: year2
---


<!-- Full-width introduction section -->
<div class="project-full-width" markdown="1">

## Overview

The PS5 renderer was my introduction to Rendering. This renderer was created in 16 weeks time. 8 weeks for the base render backend and 8 weeks for the deferred rendering aspect.

### Key Contributions

I built a render backend for the PS5 that has:
  - GLTF model loading
  - PBR
  - IBL
  - Skybox
  - Deferred Renderpasses
  - ECS Architechture
</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Deferred Rendering

Deferred Rendering is the act of separating the lighting calculation from the geometry. 
In a deferred renderer,we first draw all geometry into the render target. Then in the lighting pass, we only do lighting calculations for the visible pixels. This massively reduces the amount of costly light calculations done per frame. 

To keep track of all the geometry and their data, deferred rendering uses a G-Buffer. This contains data such as the normals, depth and albedo of the rendered geometry.

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Dive Deeper

Because of Playstation NDA I cannot go more into implementation details, but
if you'd like to read a detailed explanation of how deferred rendering works, check out the [blogpost](https://timethyh.github.io/blog/deferred-implementation/#/)!

</div>