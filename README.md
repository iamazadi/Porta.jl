# Build Visual Models

![the Hopf fibration](londontsai.gif "The Hopf fibration inspired by one of the London Tsai's prints")
![the Hopf flower](flower.gif "The Hopf flower")
![the Hopf planet](planet.gif "The Hopf planet")
![24-cell](24-cell.gif "24-cell")
![600-cell](600-cell.gif "600-cell")

This project aims to help with Eric Weinstein's Graph, Wall, Tome (GWT) project.

## Requirements
- LinearAlgebra
- CSV
- DataFrames
- StatsBase
- Makie
- Combinatorics
- AbstractAlgebra

## Installation
You can install this using:

```julia-repl
julia> Pkg.update()
julia> Pkg.add("Porta")
```

## Usage
Please orient yourself through [The Unofficial Portal Wiki](https://theportal.wiki/wiki/Graph,_Wall,_Tome)! The ideal state would be a tool that you could use for visualizing and inspecting the equations on the famous wall, located at [Stony Brook University](http://www.math.stonybrook.edu/~tony/scgp/wall-story/wall-story.html). Also, join our unofficial community of The Portal podcast on Discord: [Invitation Link Here!](https://discord.gg/U8QQFc2)

## Status
- Complex numbers [Julia already supports complex numbers.]
- Spheres [we have stereographic projections.]
- Quaternions [3D rotations added.]
- The Hopf fibration [done.]
- Planet Hopf or something similar to let the viewer know where they are. [done.]
- Documentation [TODO]
- Maxwell's equations [TODO]
