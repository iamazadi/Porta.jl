```@meta
Description = "How the Hopf fibration works."
```

# The Hopf Fibration

The Hopf fibration is a fiber bundle with a two-dimensional sphere as the base space and circles as the fiber space. It is the geometrical shape that relates Einstein's spacetime to quantum fields. In this model, we visualize the Hopf fibration by first calculating its points via a bundle chart and then rendering the points in 3D space via stereographic projection. The projection step is necessary because the Hopf fibration is embedded in a four-space, yet it has only three degrees of freedom as a three-dimensional shape. The idea that makes this model more special and interesting than a typical visualization is the idea of [Planet Hopf](http://drorbn.net/AcademicPensieve/Projects/PlanetHopf/), due to Dror Bar-Natan (2010). So, if the base space is a two-dimensional sphere much like the skin of the globe then we can model the Earth as a sphere and skin the horizontal sections of the bundle. Into the bargain, the Earth rotates about its axis every 24 hours. That spinning transformation of the Earth, together with the non-trivial product space of the Hopf bundle, can be encoded naturally into the visualization. It makes a lot of sense no matter how ridiculous, especially when we try to visualize differential operators in the Minkowski space-time and investigate the properties of spin-transformations. The following explains how the source code for generating animations of the Hopf fibration works (alternative views of Planet Hopf).

## Import the Required Packages

Begin by importing a few software packages for doing algebraic operations, working with files and graphics processing units. Besides __Porta__, we need to use three packages: [FileIO](https://github.com/JuliaIO/FileIO.jl), [GLMakie](https://github.com/MakieOrg/Makie.jl) and [LinearAlgebra](https://github.com/JuliaLang/julia/blob/master/stdlib/LinearAlgebra/src/LinearAlgebra.jl). First, `FileIO` is the main package for IO and loading all different kind of files, including images. Second, interactive data visualizations and plotting in Julia are done with `GLMakie`. Finally, `LinearAlgebra`, as a module of the Julia programming language, provides array arithmetic, matrix factorizations and other linear algebra related functionality. However, through years of working with geometrical structures and shapes we have encapsulated mathematical computations and transformations into custom types and interfaces, which make up most of the functionalities of project Porta. In addition, we wrapped complicated computer graphics workflows inside custom types in order to increase the interoprability of our types with those of external packages such as GLMakie.

    import FileIO
    import GLMakie
    import LinearAlgebra
    using Porta

## Set Hyperparameters

There are essential Hyperparameters that determine the complexity of graphics rendering as well as the position and orientation of a camera, through which we render a scene. Since the output of the model is an animation video, we need to set the figure size to 1920 by 1080 to have a full high definition window, in which the scene is located. Most of the shapes and objects that we put inside of the scene are two-dimensional surfaces. Therefore, the segmentation of most shapes requires two integer values for determining how much compute power and resolution we are willing to spend on the animation. Furthermore, the shape of a circle is the most common in our scenes because of the magic of complex numbers. It is known that using 30 segments results in smooth low-polygon circles. So for a two-dimensional sphere a 30 by 30 segmented two-surface should look good. Therefore, we set the segments equal to 30 and less curvy shapes will look even better in consequence. But, an animation extends through time frame by frame and so we need to set the total number of frames. In this way, specifying the number of frames determines the length of the video. For example, 1440 frames make a one-minute video at 24 frames per second.

    figuresize = (1920, 1080)
    segments = 60
    basemapsegments = 60
    frames_number = 1440

A model means a complicated geometrical shape contained inside a graphical scene. Every model has a name to use as the file name of the output video. Here, we choose the name `planethopf` as we construct an alternative view of the [Planet Hopf](http://drorbn.net/AcademicPensieve/Projects/PlanetHopf/) by Dror Bar-Natan (2010). Heinz Hopf in 1931 discovered a way to join circles over the skin of the globe. The discovery defines a fiber bundle where the base space is the spherical Earth and the fibers are circles. But, the circles are all mutually parallel and linked. Moreover, the Earth goes through a full rotation about the axis that connect the poles every 24 hours. So it is not surprising that the picture of a non-trivial bundle and the spinning of the base space coordinates (longitudes) makes for a ridiculous geometric shape. But, the surprising fact is that all of it is visualizable as a 3D object. Then, we use a dictionary that maps indices to names in order to keep track of boundary data on the globe and the name of each boundary as a sovereign country.

    modelname = "planethopf"
    indices = Dict()

The camera is a viewport trough which we see the scene.  It is a three-dimensional camera and much like a drone it has six features to help it position and orient itself in the scene. Accordingly, a three-vector determins its position in the scene, another 3-vector specifies the point at which it looks at, and a third vector controls the up direction of the camera. The third 3-vector is needed because the camera can rotate through 360 degrees about the axis that connects its own position to the position of the subject. Using these three vectors we control how far away we are from the subject, and how upright the subject is. 

    eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
    lookat = ℝ³(0.0, 0.0, 0.0)
    up = normalize(ℝ³(1.0, 0.0, 0.0))

Each of the `eyeposition`, `lookat` and `up` vectors are in the three-real-dimensional vector space ℝ³. The structure of the abstract vector space of ℝ³ includes: associativity of addition, commutativity of addition, the zero vector, the inverse element, distributivity Ι, distributivity ΙΙ, associativity of scalar multiplication, and the unit scalar 1. Also, the product space associated with ℝ³ is symmetric, linear and positive semidefinite (see *real3_tests.jl*). The same goes for the structure of 4-vectors in ℝ⁴ as we are going to encounter in this model.

## Load the Natural Earth Data

Next, we need to load two image files: an image to be used as a color reference, and another one to be used as surface texture for sections of the Hopf bundle. This is the first example of using `FileIO` to load image files from hard drive memory. Both images are made with a software called [QGIS](https://www.qgis.org/en/site/), which is is a geographic information system software that is free and open-source. But, the data comes from [Natural Earth Data](https://www.naturalearthdata.com/). Natural Earth is a public domain map dataset available at 1:10m, 1:50m, and 1:110 million scales. Featuring tightly integrated vector and raster data, with Natural Earth you can make a variety of visually pleasing, well-crafted maps with cartography or GIS software. We downloaded the [Admin 0 - Countries](https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries.zip) data file from the 1:10m Cultural Vectors section of the Downloads page. It is a large-scale map that contains geometry nodes and attributes. As for the image files, we color the boundaries using the gemometry nodes, and add a grid to be able to visualize distortions of the Euclidean metric of the underlying surface. Therefore, the color reference is the clean image for picking colors from, whereas the base map image has a grid and transparency for visualization purposes.

    colorref = FileIO.load("data/basemap_color.png")
    basemap_color = FileIO.load("data/basemap_mask.png")

The geometry nodes of the data set consists of latitudes and longitudes of boundaries. But, geometry attributes features various geographical, cultural, economical and political values. Of these features we only need the names and geographic coordinates. To not limit the use cases of this model, the generic function `loadcountries` loads all of the data features by supplying it with the file paths of attributes and nodes. The attrubutes and nodes files are comma-separated values.

    attributespath = "data/naturalearth/geometry-attributes.csv"
    nodespath = "data/naturalearth/geometry-nodes.csv"
    countries = loadcountries(attributespath, nodespath)

At a high level of description, the process of loading boundary data is as follows. First, we use FileIO to open the attribute file. Second, we put the data in [`DataFrames`](https://github.com/JuliaData/DataFrames.jl) to have in-memory tabular data. Third, sort the data according to shape identification. Fourth, open the nodes file in a DataFrame. Fifth, group the attributes by the name of each sovereign country. Sixth, determine the number of attriibute groups by calling the generic function `length`. Seventh, define a constant `ϵ = 5e-3` to limit the distance between nodes so that the computational complexity becomes more reasonable. Eighth, define a dictionary that has the keys: shapeid, name, gdpmd, gdpyear, economy, partid, and nodes. Finally, for each group of the attributes we extract the data corresponding to the dictionary keys and push them into array values.

Part of the difficulty with the data loading process is that each sovereign country may have more than one connected component (closed boundary). That is why we store part identifications as one of the dictionary keys. In this process, the part with the greatest number of nodes is chosen as the main part and is pushed into the corresponding array value. All of the array values are ordered and have the same length so that indexing over the values of more than one key becomes easier. Once the part ID of each country name is determined, we make a subset of the data frame related to the part ID and then extract the geographic coordinates in terms of latitudes and longitudes. In fact, we make a histogram of each unique part ID and count the number of coordinates. The part ID with the greatest number of coordinates is selected for creaating the subset of the data frame. Next, the coordinates are converted into the cartesian coordinates system from the geographic one.

Finally, we `decimate` a curve containing a sequence of coordinates by removing points from the curve that are farther ferom each other than the given threshold `ϵ`. It is a step to make sure that the boundary data has superb quality while managing the size of data for computation. The generic function `decimate` implements the [Ramer–Douglas–Peucker](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm) algorithm. It is an iterative end-point fit algorithm suggested by Dror Bar-Natan (2010) for this model. Since a boundary is modelled as a curve of line segments, we set a segmentation limit. But, the decimation process finds a curve that is similar in shape, yet has fewer number of points with the given threshold `ϵ`. In short, `decimate` recursively simplifies the segmented curve of a closed boundary if the maximum distance between a pair of points is greater than `ϵ`.

    selectionindices = Int.(floor.(collect(range(1, stop = length(countries["name"]), length = 100))))
    boundary_names = countries["name"][selectionindices]
    if "Antarctica" ∉ boundary_names
        push!(boundary_names, "Antarctica")
    end

Now, as the boundary data is massive in number (248 countries) we need to select a subset for visualization. 100 countries selected from a linear space of alphabetically sroted names should be representative of the whole Earth. Also, Antarctica should be added due to its special coordinates at the south pole, to give the user a better sense of how bundle sections are expanded and distorted. As soon as we have the names of the selection, we can proceed with populating the dictionary of indices that relates the name of each country with the its index in boundary data. Using the dictionary we can read the attributes of countries by supplying just the name as argument.

    boundary_nodes = Vector{Vector{ℝ³}}()
    for i in eachindex(countries["name"])
        for name in boundary_names
            if countries["name"][i] == name
                push!(boundary_nodes, countries["nodes"][i])
                println(name)
                indices[name] = length(boundary_nodes)
            end
        end
    end


## Make a Computer Graphical Scene

Scenes are fundamental building blocks of `GLMakie` figures. In this model, the layout of the `Figure` (graphical window) is a single `Scene`, because we have been able to directly plot all of the information about the bundle geometry and topology inside the same scene. The figure is supplied with the hyperparameter `figuresize` that we define above. Then, we set a black theme to have black background around the margins. Next, we instantiate a gray point light and a lighter gray ambient light. The lights together with the figure are then passed to `LScene` to construct our scene. We pass the symbol `:white` as the argument to the `background` keyword as it makes for the most visible scene.

    makefigure() = GLMakie.Figure(size = figuresize)
    fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
    pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
    al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
    lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

## Construct Base Maps

The total space of the Hopf fibration is a non-trivial product of the base space and the fiber space. The Hopf map projects all of the points on a fiber to a point in the base space. Then, a section of the bundle is used to take us from a local region of a point in the base space to a local region of a point in the fiber space. The base map is a two-dimensional surface representing a section of the bundle, which could be horizontal or non-horizontal. A horizontal section is the one that assigns to each point of the region the same amount of fiber group action. Therefore, the tangent vectors at the points of a horizontal section, which is an open set, map to the same vector via the Hopf map. A section is the map that in composition with the Hopf map yield the identity.

    θ1 = float(π)
    q = Quaternion(ℝ⁴(0.0, 0.0, 1.0, 0.0))
    chart = (-π / 2, π / 2, -π / 2, π / 2)

We define the fiber gourp action (circle S¹) as a 64-bit floating point number, because a horizontal cross-section uses the same scalar number for all of its region. But, the region is parameterized by a two-dimensional chart. A chart can be thought of as a rectangle whose sides are at most π in length. However, the length of a great circle of the three-dimensional sphere is 2π and the maximum length of the chart sides is limited. In case we choose a bigger side length than π we run into the problem of wrapping around the same surface twice, which is visually confusing. The Hopf bundle doesn not admit a global section anyway and if we tried to use an oversized chart then the coordinates wrap around the same 2-surface, resulting in a confusingly textured surface.

    M = I(4)
    _f(x::Quaternion) = M * x

The Hopf bundle is embedded in ℝ⁴, the Euclidean four-dimensional space. The coordinates are defined as unit quaternions where the basis vectors are represented by the symmetry group of the rotations of an orthogonal tetrad, namely SO(4). when we talk about the fiber action and bundle charts we talk about values that are used in the Lie algebra of so(4), points in the tangent space of the bundle. Then, we use the exponential map for computing the Lie group values in SO(4), which are points in the bundle. A point in the Lie group is made by executing the statement `exp(θ * K(1) + -ϕ * K(2)) * q`, where `θ` and `ϕ` denote the latitude and longitude, respectively. `K(1)` and `K(2)` denote 4x4 matrices with real elements as a basis for so(4), the Lie algebra. The tangent space of the bundle at point `q` is expanded with the exponential map of a linear combination of basis vectors `K(1)` and `K(2)`. This way we get a strictly horizontal section of the bundle in terms of the elemnts of the Lie group SO(4).

Using eigendecomposition we can change the basis while keeping the coordinates the same. So the change of basis is the final step of the construction of the observables after defining the chart and coordinatization. [`Observables.jl`](https://github.com/JuliaGizmos/Observables.jl/tree/master) allows us to define the points that are to be rendered in the scene, in a way that they can listen to changes dynamically. Later, when we apply transformations to the bundle, including tha change of basis, the idea is to only change the top-level observables and avoid reconstructing the scene entirely. The change of basis is a linear transformation of the tetrad in ℝ⁴ as a matrix-vector product. Here we denote the transformation as the generic function `_f`, which takes a `Quaternion` number as input and spits out a new number of the same type. The input and output bases must be orthonormal as the numbers must remain unit quaternions throughout the transforation. Constructing a base map requires a few arguments: the scene object, the central point of the section, the change of basis transformation, the chart, the number of segments of the 2-surface of observables, the tuxture of the surface and the optional transparency setting. With that, we construct four base maps in order to visualize a more complete picture of the Hopf fibration using four different sections. But, the sections are going to be distinguished from one another and updated later when we animate the base maps.

    basemap1 = Basemap(lscene, q, _f, chart, basemapsegments, basemap_color, transparency = true)
    basemap2 = Basemap(lscene, q, _f, chart, basemapsegments, basemap_color, transparency = true)
    basemap3 = Basemap(lscene, q, _f, chart, basemapsegments, basemap_color, transparency = true)
    basemap4 = Basemap(lscene, q, _f, chart, basemapsegments, basemap_color, transparency = true)

## Construct Whirls

A `Whirl` is a structure of a closed boundary that is lifted up by a cross-section of the bundle. The lift is specified by two real values and is realized by executing the statement `exp(K(3) * θ) * p`, where `θ` denotes the fiber action value, and `K(3)` denotes the vertical direction of the tangent space at point `p` of the boundary. By varying `θ` in a linear space of floating point values a Whirl takes a three-dimensional volume. In the special case where `θ` ranges from zero to 2π, the Whirl makes a Hopf band. The coordinates of the bondary are lifted via a section `σmap` to make the points denoted by `p`. Then, multiplying `p` on the left by the exponentiation of `K(3) * θ` pushes `p` along the vertical subspace of the bundle.

There are two sets of whirls: `whirl` is more solid and `_whirl` is more transparent. This separation is done to highlight the antipodal points of the three-dimensional sphere. It also helps to visualize the direction of the null flag under transformations of the bundle. Since every pair of points that are infinitestimally close to each other in a cross-section, defines a differential operator. And fiber actions, as transformations from the bundle to itself change the direction of the operator. Therefore it can be visualized directly how the operator changes sign by comparing a closed boundary at antipodal points.

    whirls = []
    _whirls = []
    for i in eachindex(boundary_nodes)
        color = getcolor(boundary_nodes[i], colorref, 0.1)
        _color = getcolor(boundary_nodes[i], colorref, 0.05)
        w = [σmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])]
        whirl = Whirl(lscene, w, 0.0, θ1, _f, segments, color, transparency = true)
        _whirl = Whirl(lscene, w, θ1, 2π, _f, segments, _color, transparency = true)
        push!(whirls, whirl)
        push!(_whirls, _whirl)
    end

The color of a `Whirl` should match the color of the inside of its own boundary at every horizontal section, also known as a base map. The generic function `getcolor` finds the correct color to set for the `Whirl`. It takes as input a closed boundary, a color reference image and an alpha channel value to produce an RGBA color. `getcolor` finds a color according to the following steps. First, it determine the number of points in the given boundary. Second, gets the size of the reference color image as height and width in pixels. Third, converts all of the boundary points to geograpic coordinates. Fourth, finds the minimum and maximum values of the latitude and longitude of the boundary coordinates. Fifth, creates a two-dimensional linear space that ranges within the bounds of the latitudes and longitudes. Sixth, finds the cartesian two-dimensional coordinates of the points in the image space by normalizing the geographic coordinates and multiplying them by the image size. Seventh, picks the color of each grid point with the cartesian two-dimensional coordinates in the image space. Eighth, Makes a histogram of the colors by counting the number of each color. Finally, sorts the histogram and picks one color with the greatest number of occurance.

However, step seven makes sure that the coordinates in the linear space are inside the boundary, otherwise it skips the coordinates and continues with the next coordinate in the grid. In this way we don't pick colors from the boundaries of neighboring countries over the globe. The generic function `isinside` is used by `getcolor` to determine whether the given point is inside the boundary or not. But first, the boundary needs to become a polygon in the space of two-dimensional coordinates in terms of latitude and longitude. This is the same as geographic coordinates with the radius of Earth equal to 1 at all points, hence the spherical Earth model of the Greeks. After we make a polygon from the boundary, the generic function `rayintersectseg` determines whther a ray cast from a point of the linear grid intersects an edge with the given point `p` and `edge`. Here, `p` is a two-dimensional point and `edge` is a tuple of such points, representing a line segment. Eventhough this algorithm should work in theory, some boundaries are too small to yield a definite color via `getcolor` and so the default color may be white for a limited number of cases out of 248 countries. Once we have the color of the whirls, we can proceed with constructing the whirls by supplying the generic function `Whirl` with the following arguments: the scene object, the boundary points lifetd via an arbitrary section, the first fiber action value (gauge), the second action value, the change-of-basis transformation function as described above, the number of surface segments, the color and the optional transparency setting.

## Animate a Four-Screw

A four-screw is a kind of restricted Lorentz transformation where a z-boost and a proper rotation of the celestial sphere are applied. The transformation lives in a four-complex dimensional space and it has six degrees of freedom. By parameterizing a four-screw one can control how much boost and rotation a transformation shuld have. Here, `w` as a scalar controls the boost whereas `ψ` controls the rotation component of the transform. But, the parameterization accepts rapidity as input for the boost. So we take the natural logarithm of `w` in order to supply the transformer with the required arguments. First, we set `w` equal to one in order to preserve the scale of the Argand plane and animate the angle `ψ` through zero to 2π for rotation. The name `progress` denotes a normalized scalar for instantiating a different transformation at each frame of the animation.

    if status == 1 # roation
        w = 1.0
        ϕ = log(w) # rapidity
        ψ = progress * 2π
    end

In the second case, we fix the rotation angle `ψ` by setting it to zero and instead animate the rapidity by changing the value of `ϕ` at each time step.

    if status == 2 # boost
        w = max(1e-4, abs(cos(progress * 2π)))
        ϕ = log(w) # rapidity
        ψ = 0.0
    end

Third, in order to get a complete pucture of a four-screw we animate both rapidity `ϕ` and rotation `ψ`, at the same time.

    if status == 3 # four-screw
        w = max(1e-4, abs(cos(progress * 2π)))
        ϕ = log(w) # rapidity
        ψ = progress * 4π
    end

A four-dimensional vector in the Minkowski vector space is null if and only if its Lorentz norm is equal to zero. Since a Lorentz transformation of null vectors has the same effect on vectors that are not null, it make visualization easier to study the transformation on null vectors only. A null vector in the Minkowski vector space has length zero in tems of the Lorentz norm, but has Euclidean norm equal to one, and so it can be regarded as a unit `Quaternion`. Therefore, what we are animating here is the transformation of unit quaternions that represent null vectors. 

    X, Y, Z = vec(ℝ³(0.0, 1.0, 0.0))
    T = 1.0
    u = 𝕍(ℝ⁴(T, X, Y, Z))
    @assert(isnull(u), "u in not null, $u.")

The change-of-basis transformations that we used to instantiate `Whirl` and `Basemap` above can accomodate the effects of a Lorentz transformation. Then, by setting `ψ` and `ϕ` we can define a generic function `f` to take `Quaternion` numbers as input and to give us the transformed number as output. 

    q = normalize(Quaternion(T, X, Y, Z))
    f(x::Quaternion) = begin
        T, X, Y, Z = vec(x)
        X̃ = X * cos(ψ) - Y * sin(ψ)
        Ỹ = X * sin(ψ) + Y * cos(ψ)
        Z̃ = Z * cosh(ϕ) + T * sinh(ϕ)
        T̃ = Z * sinh(ϕ) + T * cosh(ϕ)
        Quaternion(T̃, X̃, Ỹ, Z̃)
    end

Every transformation in an abstract vector space such as Minkowski vector space `𝕍` has a matrix representation. For constructing the matrix of the transform we just need to compute it four times with basis vectors. The transformed set of the basis vectors of unit quaternions are denoted by `r₁`, `r₂`, `r₃` and `r₄`. The matrix `M` is a four by four matrix whose rows are `r₁` through `r₄`. `M` is the matrix representation of the transformation `f`.

    r₁ = f(Quaternion(1.0, 0.0, 0.0, 0.0))
    r₂ = f(Quaternion(0.0, 1.0, 0.0, 0.0))
    r₃ = f(Quaternion(0.0, 0.0, 1.0, 0.0))
    r₄ = f(Quaternion(0.0, 0.0, 0.0, 1.0))
    M = reshape([vec(r₁); vec(r₂); vec(r₃); vec(r₄)], (4, 4))

But, M doesn't necessarily take unit quaternions to unit quaternions. By decomposing `M` into eigenvalues and eigenvectors we can manipulate the transformation so that it takes unit quaternions to unit quaternions without modifying its effect on the geometrical structure of the Argand plane. Despite the fact that `M` is a matrix of real number, it has complex eigenvalues as it involves a rotation. By constructing a four-complex-dimensional vector off of the eigenvalues we can normalize `M` by normalizing the vector of eigenvalues, before reconstructing a unimodular, unitary transformation (a normal matrix). The reconstructed matrix is called `N` and now it can be used to define a generic function `f′` to replace `f`.


    F = LinearAlgebra.eigen(M)
    λ = LinearAlgebra.normalize(F.values) # normalize eigenvalues for a unimodular transformation
    Λ = [λ[1] 0.0 0.0 0.0; 0.0 λ[2] 0.0 0.0; 0.0 0.0 λ[3] 0.0; 0.0 0.0 0.0 λ[4]]
    M′ = F.vectors * Λ * LinearAlgebra.inv(F.vectors)
    N = real.(M′)
    f′(x::Quaternion) = normalize(N * x)

We can assert that the transformation `f′` takes null vectors to null vectors in Minkowski vector space `𝕍`. If that it the case, then the reconstructed transformation `f′` is a faithful representation and it only scales the extent of null vectors rather than null directions. The modification of `f`, namely `f′`,results in a faithful representation when for different numbers `g` and `q` in unit `Quaternion`s, the transformations `f′(g)` and `f′(q)` are equal if and only if `g = q`.

    s = SpinVector(u)
    T̃, X̃, Ỹ, Z̃ = vec(f′(Quaternion(u.a)))
    v = 𝕍(ℝ⁴(T̃, X̃, Ỹ, Z̃))
    @assert(isnull(v), "v in not null, $v.")

A spin-vector is based on the space of future or past null directions in Minkowski space-time. The field `ζ` of a `SpinVector` represents points in the Argand plane. Therefore, if `v` is obtained by the transformation of `u` by `f′`, then the corresponding spin-vectors `s` and `s′` should tell us how `f′` changes the Argand plane. We assert that the transformation by `f′` induced on the Argand plane is correct, because it extends the Argand plane by magnitude `w` and rotates it through angle `ψ`. So, we established the fact that normalizing the vector of eigenvalues of the transformation `f` and reconstructing it to get `f′` leaves the effect on the Argand plane invariant.

    s′ = SpinVector(v)
    ζ = w * exp(im * ψ) * s.ζ
    ζ′ = s′.ζ
    if (ζ′ == Inf)
        ζ = real(ζ)
    end
    @assert(isapprox(ζ, ζ′), "The transformation induced on the Argand plane is not correct, $ζ != $ζ′.")

Updating the base maps requires a point in the section denoted by `q` and the transformation `f′`. But, we use `x -> f′(exp(K(3) * π / 2) * x)` instead of `f′` to update base maps 2, 3 and 4 for the reason that we want to have different lifts of the horizontal sections by pushing the sections uniformly higher or lower in the fiber space. The generic function `update!` updates base maps by changing the embedded observables and consequently the graphical shapes take different forms.

    update!(basemap1, q, f′)
    update!(basemap2, q , x -> f′(exp(K(3) * π / 2) * x))
    update!(basemap3, q, x -> f′(exp(K(3) * π) * x))
    update!(basemap4, q, x -> f′(exp(K(3) * 3π / 2) * x))

Every time we update the observables of a `Whirl` under the transformation by `f′` we need to access the coordinates of the boundary data. But the coordinates are not changed and the change is taken care of by the map `f′`. The coordinate component `ϕ` is divided by a factor of two since in geographic coordinates longitudes range from -π to +π, whereas latitudes range from -π / 2 to +π / 2. This division rescales the longitude component of coordinates and allows us to have a square bundle chart. We finish the animation of one time-step after updating the last `Whirl`.

    for i in eachindex(boundary_nodes)
        points = Quaternion[]
        for node in boundary_nodes[i]
            r, θ, ϕ = convert_to_geographic(node)
            push!(points, exp(ϕ / 2 * K(1) + θ * K(2)) * q)
        end
        update!(whirls[i], points, θ1, 2π, f′)
        update!(_whirls[i], points, 0.0, θ1, f′)
    end



## Animate a Null Rotation

To understand a null rotation, imagine that you are an astronaut in empty space, far away from any celectial object. Looking at the space around you from every direction you can see your surrounding environment through a spherical field of view. This view is called the celestial sphere of past null directions, as the light from the stars reach your eyes from the past by the time they arrive. A null rotation translates the Argand plane such that one null direction is invariant. We control the animation of a null rotation by defining a real number `a` to be used a few paragraphs below. But, first we assert that the central point `u` of the bundle section represents a null vector in Minkowski vector spcae `𝕍`.

    a = sin(progress * 2π)
    X, Y, Z = vec(ℝ³(0.0, 1.0, 0.0))
    T = 1.0
    u = 𝕍(ℝ⁴(T, X, Y, Z))
    @assert(isnull(u), "u in not null, $u.")

Then, we use the coordinates of `u` to initialize the central point of the bundle section `q`. The transformation `f` defines a null rotation such that the invariant null vector is `t + z`, the north pole of the sphere of future pointing null directions, where `ζ` equals infinity. 

    q = normalize(Quaternion(T, X, Y, Z))
    f(x::Quaternion) = begin
        T, X, Y, Z = vec(x)
        X̃ = X 
        Ỹ = Y + a * (T - Z)
        Z̃ = Z + a * Y + 0.5 * a^2 * (T - Z)
        T̃ = T + a * Y + 0.5 * a^2 * (T - Z)
        normalize(Quaternion(T̃, X̃, Ỹ, Z̃))
    end

Now, by transforming `u` via `f` we assert that the result `v` is still a null vector. 

    s = SpinVector(u)
    T̃, X̃, Ỹ, Z̃ = vec(f(Quaternion(u.a)))
    v = 𝕍(ℝ⁴(T̃, X̃, Ỹ, Z̃))
    @assert(isnull(v), "v in not null, $v.")

Next, we instantiate another spin-vector using `f(u) = v` in order to examine the effect of transformation `f` on the Argand plane, specifically. Accordingly, the point `ζ` from the Argand plane of `u` transforms into `α * s.ζ + β` where `β` denotes the translation in the Argand plane. The scalar `a` controls the translation of the plane because `β` is defined as `β = Complex(im * a)`. We assert that the transformation induced on the Argand plane is correct by comparing the approximate equality of the Argand plane of `v` and the transformed Argand plane of `u`, which is `α * s.ζ + β`.

    s′ = SpinVector(v)
    β = Complex(im * a)
    α = 1.0
    ζ = α * s.ζ + β
    ζ′ = s′.ζ
    if (ζ′ == Inf)
        ζ = real(ζ)
    end
    @assert(isapprox(ζ, ζ′), "The transformation induced on the Argand plane is not correct, $ζ != $ζ′.")

Finally, we also assert that the null vector `z + t` is invariant under the transformation `f` because it is a null rotation with a fixed null direction at the north pole. The animation of a null rotation appears to be correct after all of the assertions evaluate true.

    vector = 𝕍(normalize(ℝ⁴(1.0, 0.0, 0.0, 1.0)))
    vector′ = 𝕍(vec(f(Quaternion(vec(vector)))))
    @assert(isnull(vector), "vector t + z in not null, $vector.")
    @assert(isapprox(vector, vector′), "The null vector t + z is not invariant under the null rotation, $vector != $vector′.")

## Update Camera Orientation and Position

The 3D camera of the scene requires the eye position, the look at vector and the up vector for positioning and orientation. The generic function `update_cam!` takes the scene object and the three required vectors as arguments and then updates the camera. But, our camera position and orientation vectors are of type ℝ³, and not `Vec3f`. To match the argument type we need to use the generic function `vec` and the `splat` operator in order to instantiate objects of type `Vec3f`, because `update_cam!` is going to match the type with its own signature.

    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))

## Record an Animation

The function `write` takes as input an integer called `frame` and then updates the observables according to the animation functions that we described above. First, it calculates the progress of the animation frames by dividing `frame` by `frames_number`. For different Lorentz transformations we have four stages, each stage having its own progress. The signature of the four-screw animator function reads: `animate_fourscrew(progress::Float64, status::Int)`. For example, stage one animates a pure boost by calling the generic function `animate_fourscrew` with `status` equal to 1. Stage 2 animates a proper rotation. Then, stage 3 animates a four-screw. Finally, stage 4 animates a null rotation by calling the function `animate_nullrotation`. After calling each stage function, we update the camera by calling `updatecamera`.

    write(frame::Int) = begin
        progress = frame / frames_number
        totalstages = 4
        stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
        stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
        println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
        if stage == 1
            animate_fourscrew(stageprogress, 1)
        elseif stage == 2
            animate_fourscrew(stageprogress, 2)
        elseif stage == 3
            animate_fourscrew(stageprogress, 3)
        elseif stage == 4
            animate_nullrotation(stageprogress)
        end
        updatecamera()
    end

To create an animation you need to use the `record` function. In summary, we instantiated a `Figure` and a `Scene`. Next, we created and animated observables in the scene, frame by frame. Now, we record the scene by passing the figure `fig`, the file path of a video, and the range of frame numbers to the `record` function. The frame is incremented by `record` and the frame number is passed to `write` in order to animate the observables. After the frame number reaches the total number of animation frames, the video file is saved on the hard drive at the supplied file path.

    GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
        write(frame)
    end