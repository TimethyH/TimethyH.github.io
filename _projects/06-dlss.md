---
layout: project
title: "DLSS Integration"
subtitle: "Timethy Hyman"
date: 2025-07-23
thumbnail: /assets/img/projects/Traverse/dlss.jpg
summary: "Integrating DLSS into the Traverse framework"
tags:
  - Traverse Research
  - DX12
  - Vulkan
  - Custom Engine
  - Rendering
---

<!-- Two-column section: Overview text left, Video right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Overview

DLSS (Deep Learning Super Sampling) is NVIDIA's AI powered supersampling algorithm that uses deep learning to reconstruct high resolution images from low resolution inputs. Unlike traditional upscaling techniques, DLSS uses dedicated **Tensor Cores** on RTX GPUs to run a convolutional neural network trained on many high quality reference images.

The algorithm works by rendering the scene at a lower resolution and using temporal information and motion vectors to reconstruct a higher resolution output. This provides significant performance gains, while maintaining or even improving image quality compared to native resolution rendering.

During my Summer of Code internship at Traverse Research, I was asked to integrate this upscaler into their rendering framework, requiring careful abstraction across both DirectX 12 and Vulkan backends.

### Key Contributions

  - Created a module in **Rust** that abstracts the **DX12** and **Vulkan** functions, providing a unified interface for DLSS integration regardless of the underlying graphics API.
  - Generated Rust bindings using **bindgen** so the C and C++ NGX SDK functions can be called safely from Rust code with proper type checking.
  - Created a build system that detects whether the user is running **Vulkan** or **DX12** at compile time to generate the correct bindings, locate the corresponding API headers, and link the appropriate DLSS libraries.
  - Designed a high level module within Traverse that handles all DLSS setup and initialization with a single function call, abstracting away the complexity of feature creation, buffer binding, and execution.

</div>
<div class="project-media" markdown="1">

![alt text](/assets/img/projects/Traverse/dlssLogo.webp)

</div>
</div>

<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section">
<div class="project-text" markdown="1">

## How It Works

DLSS uses a **temporal convolutional neural network** that processes multiple frames over time to reconstruct high quality output. The network analyzes motion vectors to understand how pixels move between frames, allowing it to accumulate detail from previous frames and reject artifacts.

### Required Resources

The DLSS algorithm requires several input resources each frame:
  - **Input Color Buffer**: The rendered scene at lower resolution (e.g., 1080p for 4K output)
  - **Motion Vectors**: Per pixel velocity information showing how each pixel moved from the previous frame in normalized device coordinates
  - **Consistent Jitter Values**: Camera jitter offsets applied during rendering to gather sub pixel information across frames, essential for temporal anti aliasing
  - **Depth Buffer**: Scene depth information used to improve motion vector accuracy and handle occlusion
  - **History Buffer**: Internally managed buffer that DLSS uses to accumulate temporal information

Luckily, Traverse already had all of these inputs available for me. The challenge was understanding how DLSS expects these resources to be formatted and bound.

### Tensor Core Execution

DLSS runs on **Tensor Cores**, specialized hardware units on NVIDIA RTX GPUs designed for matrix operations. The network evaluates in approximately 1-2ms on modern RTX hardware, making it cheaper than rendering at native resolution.

### Quality Modes

DLSS offers several quality presets that trade output quality for performance:
- **Performance Mode**: Renders at 50% scale (0.5x in each dimension), providing maximum performance
- **Balanced Mode**: Renders at ~58% scale, balancing quality and performance
- **Quality Mode**: Renders at ~67% scale, prioritizing image quality
- **Ultra Performance**: Renders at 33% scale for extreme performance scenarios

Here DLSS reconstructs fine details that would alias or shimmer with traditional upscaling.

</div>
<div class="project-media" markdown="1">

![Froxel grid visualization](/assets/img/projects/Traverse/DLSS/dlssOFF.webp)
<p class="media-caption">DLSS Off</p>

![Froxel grid visualization](/assets/img/projects/Traverse/DLSS/dlssON.webp)
<p class="media-caption">DLSS On</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Another two-column section -->
<div class="project-section reverse">
<div class="project-text" markdown="1">

## Binding Generation

Generating Rust bindings for the NVIDIA NGX SDK was one of the most challenging aspects of this project. The NGX SDK provides both DirectX 12 and Vulkan interfaces, each with their own headers and dependencies.

### The Bindgen Challenge

At first glance, generating bindings appears straightforward:
```rust
bindgen::Builder::default()
    .header("nvsdk_ngx.h")
    .generate()?;
```

However, this naive approach generates bindings for **every** API, function, struct, and type definition across all recursively included files. Windows headers, DirectX headers, Vulkan headers, and more. The result is tens of thousands of lines of generated code, most of which is irrelevant.

### Filtering with Regex

To get only the NGX-specific bindings, we need to carefully filter what gets included using **allowlist** patterns with regex. For example:
```rust
bindgen::Builder::default()
    .header("nvsdk_ngx.h")
    // Allow all NVSDK_NGX types and functions
    .allowlist_type(r"NVSDK_NGX_\w+")
    .allowlist_function(r"NVSDK_NGX_\w+")
    // Include function pointers (PFN_ prefix)
    .allowlist_type(r"PFN_NVSDK_NGX_\w+")
    // Block Windows/DirectX types we don't need
    .blocklist_type(r"tagRECT")
    .blocklist_type(r"D3D12_.*(?<!RESOURCE|COMMAND_LIST)")
    .generate()?;
```

The real complexity comes from managing **conditional compilation** for the two graphics APIs. The build script must:
1. Detect which API is being targeted 
2. Include the correct API specific headers
3. Link against the appropriate libraries
4. Handle platform specific include paths and SDK locations

Learning regex patterns, managing conditional compilation, and correctly linking the platform specific SDK libraries across Windows development environments was the biggest bottleneck of this project.

</div>
<div class="project-media" markdown="1">

<video controls preload="metadata" src="/assets/img/projects/Traverse/DLSS/house.webm" title="Title"></video>
<p class="media-caption">Toggling DLSS On and Off</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

## Deep Dive

Because of NDA I cannot go into implementation detail.

NVIDIA provides useful [documentation](https://github.com/NVIDIA/DLSS/blob/982b0d19f9e35fef8e1b3109efa6b95470563866/doc/DLSS_Programming_Guide_Release.pdf) including integration guides, best practices, and troubleshooting tips.

</div>