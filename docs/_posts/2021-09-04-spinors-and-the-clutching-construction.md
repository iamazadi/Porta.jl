---
layout: post
title:  "Spinors and the Clutching Construction"
---

<script src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>

# What's the connection between spinors and the clutching construction?

This post serves as both the transcription of a [math video](https://youtu.be/5R1o2WE_iEQ) under the same title and also as an update to the [Graph-Wall-Tome](https://theportal.wiki/wiki/Graph,_Wall,_Tome) project. If you like this then you should know that about more than 6 times worth of content is available in [episode 20 of The Portal](https://youtu.be/mg93Dm-vYc8)!
[![cover](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/cover.JPG)](https://youtu.be/5R1o2WE_iEQ)

### Why should we care?
Today, we're going to talk about an important mathematical object: spinors. It determines the properties of atoms in the form of electron shells. It's responsible for the stability of matter. Without it, the periodic table wouldn't exist. And also quarks which make up protons and neutrons.

### Spinors in the pop culture
It's the idea behind Chrostopher Nolan's Tenet. Remember? Similar pairs of objects, one traveling forward through time, the other one going backwards! It's also closely related to the Mololith, in Sir Roger Penrose's favorite movie: A Space Odyssey: 2001. Spinors have been much like the Monolith for almost a century. When Paul Dirac put in order the discoveries of quantum physics, he discovered counterparts to electrons with negative energy. And in doing so, he opened a portal into a reality much larger than what we used to know at the time. So, spinors are really deep down in the reality and they're responsible for everything that we're seeing right now.

[![hopfflower](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/hopfflower.gif)](https://youtu.be/8oJ0ZqYRXEg)

### Graph
In order to see how and what we know about spinors we're going to turn to the Graph. (Edits are suggested by the other EW.)

Edward Witten*

If one wants to summarize our knowledge of physics in the briefest possible terms, there are three really fundamental observations: (i) Spacetime is a pseudo-Riemannina manifold M, endowed with a metric tensor and goverened by geometrical laws. (ii) Over M is a principal G-bundle with a non-abelian structure group G. (iii) Fermions are sections of $$ (\hat{S}_{+} \otimes V_R) \oplus (\hat{S}_{-} \otimes V_{\tilde{R}}) $$. $$ R $$ and $$ \tilde{R} $$ should be (complex) linear representations of G, and so they are not equivalent. The interaction between the Higgs field and the fermionic sections explains why the light fermions are light and presumably has its origins in a representation difference $$ \Delta $$ in some underlying theory. All of this, must be supplemented witht the understanding that the geometrical laws obeyed by the metric tensor, the Higgs field, the gauge fields, and the fermions are to be interpreted in quantum mechanical terms.

### Wall
We've taken the liberty to undertake the iconic Wall at the Stony Brook University, and do some graffiti. By adding the cosmological constant to the Einstein equation at the center of the Wall. And closely related to this topic is the Dirac equation which remains the same as before.

![wall](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/wall.JPG "wall")

### Tome
In this exposition, the main reference would be the Tome. The book by Sir Roger Penrose, called: The Roead to Reality. It has 34 chapters, but there are about a quarter of them most related to this. Including:
- chapter 10, Surfaces
- chapter 11, Hypercomplex numbers
- chapter 12, Manifolds of n dimensions
- chapter 13, Symmetry groups
- chapter 14, Calculus on manifolds
- chapter 15, Fiber bundles and gauge connections
- chapter 17, Spactime
- chapter 18, Minkowskian geometry
- chapter 27, section 11, Cosmology

![tome](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/tome.PNG "tome")

### Sir Roger Penrose
Sir Roger Penrose is the prominent figure at the nexus of physics and geometry. He was born in 1931. He did his undergraduate studies in University College London. Then, he went to Cambridge University to do his graduate studies. He got his P.h.D. in algebraic geometry. But a certain question in cosmology regarding the expnsion of the universe motivated him to work on physics problems.

![ucl](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/ucl.JPG "ucl")
![cambridge](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/cambridge.JPG "cambridge")

### Hopf fibration
In the standard cosmological models (FLRW,) the universe can be thought of as a 3-surface at each point of cosmological instant of time. Now, if we further assume that the curvature is positive, and we keep out the cosmological constant, then we're going to have a 3-surface as a 3-sphere at each point of time, by keeping time constant (see **a** in the picture below.) The way that we can visualize a 3-sphere using our visual cortex is to use the Hopf fibration. And also the stereographic projection to bring it down to the Euclidean 3-space that we're familiar with. The picture is inspired by Dror Bar-Natan from the University of Toronto. In the base space, in order to see where you are we've used the geographical map. And at each point of the base space there's a circle. And it's obvious that the circles are linked and this doesn't lead to a trivial bundle. As a 3-surface embedded in a 4-dimensional Euclidean space it has a hole with an interesting topology.

![flrw](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/flrw.GIF "flrw")
[![planethopf](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/planethopf.jpg)](https://youtu.be/IOF8QzMGhQE)

### Paul Dirac
Penrose attended one of Dirac's courses on spinors and quantum field theory. It was absolutely necessary for him to understand 2-component spinors. The way that Sir Roger Penrose explains spinors, it's a setting of a pole and a flag. And through 360 degrees of rotation of the pole the flag changes its sign.In order to get to the initial configuration the settings needs to be rotated 720 degrees. These are natural objects that can be found in real life.

![dirac](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/dirac.GIF "dirac")

### The belt trick
As an alternative way to visualize spinors would be to turn to the belt trick. Suppose we have two different frames. One of them is fixed and the other one is moving. At one point of a belt we have the fixed frame and at the other end we have the moving frame. Now, if we take the moving frame and rotate that one π, then another π, to make 2π, which amounts to 360 degrees of rotation, what we get as a result is a twist in the belt. That twist we can't get rid of. But, if we continue the rotation by two more πs, to get 4π, which in total makes 720 degrees, we still get the twist in the belt. But this time is diffeent. Because using parallel transport we can undo the twist. Parallel transport is a kind of transformation that doesn't allow reorientation of the moving frame. This gives us a way to shrink away the 4π loop and get no twist at all. And get back to the initial condition at the beginning, which is no twist at all. This is called the belt trick!

[![winedance](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/winedance.GIF)](https://youtu.be/mg93Dm-vYc8)
![belttrick1](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/belttrick1.GIF)
![belttrick2](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/belttrick2.GIF)
![belttrick3](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/belttrick3.GIF)

### Exterior derivative
The total space at each point of a manifold decomposes into two different bundles which can be summed up using the direct sum operator ($$ \oplus $$:) the normal bundle and the tangent bundle. The way that we get vectors in these bundles would be to use the exterior derivative. And at each point of a manifold we can have vectors in both bundles. Referring to the picture, the golden arrow is in the normal bundle, and x-constant and y-constant vectors are respectively the red arrow and the green arrrow, which are in the tangent bundle. This is a 2-manifold embedded in a 3-dimensional space.

![surfaces](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/surfaces.gif)

### Determine the clutching construction
There are vector bundles that are non-trivial. For example, on a sphere we can't have a trivial vector bundle (because we face the hairy ball paradox!) We use the clutching construction in order to get one. Suppose that we have two different disks identified with 4 points at the boundries, such that when we glue them together aligned with the corresponding points they make a sphere. So, we have the northern hemisphere and the southern hemisphere, and the equator where they meet. We take a frame on the northern hemisphere and parallel transport copies of it to the identified points. Then they twist as they go and pass over the boundry. Now, there's going to be a twist with respect to a fixed frame. We can determine the degree of the rotation, but for the sign, in order to see how they rotate we're going to need two other dummy points. This requires a little bit of intuition in order to see how how they twist as they pass the equator into the other hemisphere. Then, we're going to see that the twist sign in this case is negative, identified with the clockwise rotation. By symmetry we can conclude that the rotation along the equator is a continous one. And it seems to be two complete rounds of rotation along a great circle.

![clutchingfunction](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/clutchingfunction.GIF)

A sphere has at least one great circle, such as the equator. Then, passing from one hemisphere into the other a frame of reference necessarily has to twist. So, from a point to the antipodal on the other side we're going to have 360 degrees of rotation. But then in order to get back to the starting point the frame needs to be rotated another 360 degrees of rotation. And in total we're going to have 720 degrees. That's on the surface of a sphere.

### Tangent bundle
The vector bundle over a sphere is non-trivial, becuase passing through a great circle the frames are going to twist. We're going to see how this vector bundle which is non-trivial is properly defined. We follow expositions from section 4.6 The Clutching Construction, Mark J.D. Hamilton (2017.)

We take our 2-manifold, $$ S^2 \in \mathbb{R}^3 $$ given by $$ x^2 + y^2 + z^2 = 1 $$. Next, identify the poles and remove them. $$ N_{+} = (0, 0, 1) \in S^2 $$ and $$ N_{-} = (0, 0, -1) \in S^2 $$. Because we don't want x and y to be zro at the same time, otherwise we wouldn't have something to determine the orientation. So, we have $$ U_{+} = S^2\setminus\{N_{+}\} $$ and $$ U_{-} = S^2\setminus\{N_{-}\} $$ in $$ S^2 $$ excluding the poles. Next, define the clutching function at the equator as a great circle, which maps the circle into the general linear group of real dimension 2, our abstract space, where spinorial vectors transform. $$ f: S^1 \to GL(2,\mathbb{R}) $$. Then, we need a dummy function labeled as p in order to see how we can use any point on the sphere and map it onto the circle, the equator. $$ p: U_{+} \cap U_{-} \to S^1 $$ given by $$ (x, y, z) \mapsto \frac{(x, y)}{\sqrt{x^2+y^2}} $$. That's the magical square root! So, using the dummy function p now we can extend the clutching function as a composition. $$ \bar{f} = f \circ p: U_{+} \cap U_{-} \to GL(2,\mathbb{R}) $$. It takes points from the intersection of $$ U_{+} $$ and $$ U_{-} $$ and takes them to the general linear group of real dimension 2. There's going to be an equivalence class because the intersection is non-empty. And there, using the extended clutching function we can reorient vectors in the tangent space. And so the equivalence class of the vector bundle uses effectively the extended clutching function to resolve the conflict in orientation. $$ \tilde{E} = (U_{-} \times \mathbb{R}^2) \dot{\cup} (U_{+} \times \mathbb{R}^2) $$ by identifying $$ (x, y, z, v) \in (U_{-} \cap U_{+}) \times \mathbb{R}^2 $$ where $$ (U_{-} \cap U_{+}) \times \mathbb{R}^2 \subset U_{-} \times \mathbb{R}^2 $$ with $$ (x, y, z, \bar{f}(x, y, z) \bullet v) \in (U_{-} \cap U_{+}) \times \mathbb{R}^2 $$ where $$ (U_{-} \cap U_{+}) \times \mathbb{R}^2 \subset U_{+} \times \mathbb{R}^2 $$. Then, we have our projection map which essentially removes the extra piece of information, the one component that is the vector in the abstract vector space. It maps the vector bundle onto the sphere. $$ \pi: E_f \to S^2 $$, $$ [x, y, z, v] \mapsto [x, y, z] $$. That gives us an $$ \mathbb{R} $$-vector bundle of rank 2 over $$ S^2 $$. Each vector collapses onto a single point in the base space.

![diagram1](https://github.com/iamazadi/Porta.jl/raw/master/docs/_posts_images/diagram1.png)

### Summary
### Building an interstellar engine
