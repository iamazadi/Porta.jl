# Geometrize the quantum!

![Gallery: Alternative view](https://github.com/iamazadi/Porta.jl/blob/master/docs/_posts_images/IMG_5621.gif)

This project helps with Eric Weinstein's the Graph-Wall-Tome (GWT) project. Watch visual
models on the YouTube [channel][1].

## Requirements
CSV v0.10.12
- DataFrames v1.6.1
- DifferentialEquations v7.12.0
- FileIO v1.16.2
- GLMakie v0.9.9
- Latexify v0.16.1
- ModelingToolkit v9.1.0


## Installation
You can install Porta by running this (in the REPL):

```julia-repl
]add Porta
```
or,
```julia-repl
Pkg.add("Porta")
```
or get the latest experimental code.
```julia-repl
]add https://github.com/iamazadi/Porta.jl.git
```

## Usage
For client-side code read the tests, and for examples on how to build please check out the
models directory. See [alternativeview.jl](../master/models/alternativeview.jl) as an example!

## Status
- Logic [Doing]
- Set Theory [TODO]
- Topology [TODO]
- Topological Manifolds [TODO]
- Differentiable Manifolds [TODO]
- Bundles [TODO]
- Geometry: Symplectic, Metric [TODO]
- Documentation [TODO]
- Geometric Unity [TODO]

## References
- Physics and Geometry, [Edward Witten][2] (1987)
- The iconic [wall][3] of Stony Brook University
- [The Road to Reality][4], Sir Roger Penrose (2004)
- A [Portal][5] Special Presentation- Geometric Unity: A First Look
- [Planet Hopf][6], Dror Bar-Natan (2010)
- Rupert Way, [Dynamics in the Hopf bundle][7], the geometric phase and implications for dynamical systems (2008)

[1]: https://www.youtube.com/channel/UCY8FW_kvEfGDj5i5j_rkaqA
[2]: https://cds.cern.ch/record/181783/files/cer-000093203.pdf
[3]: http://www.math.stonybrook.edu/~tony/scgp/wall-story/wall-story.html
[4]: https://www.amazon.com/Road-Reality-Complete-Guide-Universe/dp/0679776311
[5]: https://youtu.be/Z7rd04KzLcg
[6]: http://drorbn.net/AcademicPensieve/Projects/PlanetHopf/
[7]: https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwiCm-SnytGAAxUK2qQKHUB9CjoQFnoECBUQAQ&url=http%3A%2F%2Fpersonal.maths.surrey.ac.uk%2Fst%2FT.Bridges%2FGEOMETRIC-PHASE%2FRW_Finalformthesis.pdf&usg=AOvVaw2Fx2-wD95a3deuUiUaRef3&opi=89978449
