---
layout: project
title: "DLSS Integration"
subtitle: "Timethy Hyman"
date: 2025-07-23
thumbnail: /assets/img/projects/Traverse/dlss.jpg
summary: "Intergeating DLSS into the Traverse framework"
tags:
  - Traverse Research
  - DX12
  - Vulkan
  - Custom Engine
  - Rendering
---

<!-- Full-width introduction section -->
<div class="project-full-width" markdown="1">

## Overview

DLSS is NVIDIA's AI supersampling algorithm.

During my Summer of Code internship at Traverse Research, I was asked to integrate this upscaler into their framework.

### Key Contributions

  - Created a module in **Rust** that abstracts the **DX12** and **Vulkan** functions.
  - Generated Rust bindings so the C and C++ functions can be called externally.
  - Created a system that detects if the user is running **Vulkan** or **DX12** to then generate the correct bindings, find the corresponding API headers and link the libraries.
  - Created a module within Traverse that handles all setup initialization with a single function call.
</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section">
<div class="project-text" markdown="1">

## How It Works

The DLSS algorithm needs a few resources to function:
  - Input Color Buffer
  - Motion Vectors
  - Consisten Jitter Values
  - Depth Buffer
  - History Buffer

Luckily, Traverse already had all of these. The hard part was understanding how the system needs to be setup and generating the correct bindings.

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

## Binding Generation

Generating the rust bindings can be as simple as calling: 
```
Bindgen::builder::default();
```

The problem is that this generates bindings for every API, every function, struct, type, and this for every recursively included file.
To get only the bindings we're interested in, we need to filter what we allow into the generated file using **regex**. e.g.

```
allowlist_item(r"(PFN_)?NVSDK_NGX_\w+");
```

Learning how to work with **regex** and linking the correct libraries to eachother was the biggest bottleneck of this project.

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Deep Dive

Because of NDA I cannot go into implementation detail.

NVIDIA provides useful [documentation](https://github.com/NVIDIA/DLSS/blob/982b0d19f9e35fef8e1b3109efa6b95470563866/doc/DLSS_Programming_Guide_Release.pdf).
</div>