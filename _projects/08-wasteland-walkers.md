---
layout: project
title: "Wasteland Walkers"
subtitle: "Timethy Hyman"
date: 2024-06-23
thumbnail: /assets/img/projects/Y1D/thumb.webp
summary: "👥 12 developers | Maneuver through the desert wasteland in search of the Oasis"
tags:
  - Unreal Engine
  - Machine Learning
  - Game
  - University Project
category: year1
---
<!-- Two-column section: Overview text left, Video right -->
<div class="project-section">
<div class="project-text" markdown="1">

## Overview

Wasteland walkers is a local co-op game where you control Shelly the robot. Work as a team to maneuver Shelly through the desert, shoot down enemies and find your way to the Oasis.

The game was made in 8 weeks during my first year at Breda University.  The game was made using UnrealEngine 5 by a team of 12 developers.

### Key Contributions

  - Created a reinforcement learning system which controls all enemy behaviour.
  - I was in charge of all audio: Custom made music for the game, audio implementations and transitions.
  - Created the rotating start menu + widgets
  - Added bloom + day/night cycles.
</div>

<div class="project-media" markdown="1">

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
  <iframe 
    style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;" 
    src="https://www.youtube.com/embed/GzBfxlUhx4Q" 
    frameborder="0" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
    allowfullscreen>
  </iframe>
</div>
<p class="media-caption">Gameplay footage of Wasteland Walkers</p>

</div>
</div>


<div class="section-divider"></div>

<!-- Two-column section: Text left, Image right -->
<div class="project-section reverse">
<div class="project-text" markdown="1">

## Reinforcement Learning

Most of my time this project was spent on getting my little enemies to behave the way I wanted them to. It turns out that Reinforcement Learning is a huge rabbit hole. Luckily an extension that handled most of the setup already existed, I only needed to learn how Reinforcement learning works and implement the training system.

The key insights I learned regarding this topic, is that you can give an agent n anount of options, e.g. it can move forwards, backwards and rotate. Then you add or subtract points based off of the decisions the agent makes in accordance to what you want it to do. 

### A simple example from my implementation

Wasteland walkers has 4 enemy types:
  - The crawler
  - The spider
  - The scorpion
  - the beetle

The crawler's only objective is to crash into shelly. 
This meant that I would give it points for being close to the player, and points for looking in the direction of the player.

To iterate and train the agents, they get reset after a few conditions:
  - They got stuck in a state where no learning can be achieved
  - They accomplished their task
  - Their global timer ran out

After resetting an agent, the agents with relatively good scores get their data recorded, where as the agents that performed poorly get discarded. After this a new set of agents get spawned with the data of the well performing parents.

It's important to be very strict and careful with the rules you set and the way you award points. My first baby worms learned to drift to their target...
 

</div>
<div class="project-media" markdown="1">


<a href="/assets/img/projects/Y1D/enemy.webp" class="image">
  ![Volumetric Fog Scene](/assets/img/projects/Y1D/enemy.webp)
</a>

<video controls preload="metadata" src="/assets/img/projects/Y1D/enemy.webm" title="RL Enemies"></video>
<p class="media-caption">Early prototype of enemies spawn and behaviour</p>

</div>
</div>

<div class="section-divider"></div>

<!-- Final full-width section -->
<div class="project-full-width" markdown="1">

**Check it out on Itch!**: [Wasteland Walkers](https://buas.itch.io/team-mace)

</div>