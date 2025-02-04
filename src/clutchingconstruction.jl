export showtori
export getpoint
export paralleltransport
export markframe
export updateui
export updatepoint
export labelpoint
export switchcharts
export rotatetorus
export showset1
export showset2


"""
    showtori(colorarray, toruscolor)

Make a set of tous of revolution visible by changing the alpha color channel for illustration.
"""
function showtori(colorarray::GLMakie.Observable{Matrix{GLMakie.RGBAf}}, toruscolor::GLMakie.RGBAf)
    color = GLMakie.to_value(colorarray)[1]
    segments = size(colorarray[])[1]
    if isapprox(color.alpha, 0)
        color = GLMakie.RGBAf(toruscolor.r, toruscolor.g, toruscolor.b, 0.5)
        colorarray[] = fill(color, segments, segments)
    end
    "Show the great circle that has four points."
end


"""
    getpoint(r₀, r₁, t)

Calculate a point along the connecting path from the starting point `r₀` to the destination `r₁` with the given time `t`.
"""
function getpoint(r₀::ℝ⁴, r₁::ℝ⁴, t::Float64)
    p = r₁ * t + (1 - t) * r₀
    if norm(p) > 1
        return normalize(p)
    else
        return p
    end
end


"""
    paralleltransport(source, sink, t, points, sliderx¹, sliderx², sliderx³, sliderx⁴)
    
Parallel transport the frame to `source` to `sink` with the given time `t` by setting the sliders to the correct values.
"""
function paralleltransport(source, sink, t::Float64, points::Dict{String, ℝ⁴}, sliderx¹::GLMakie.Slider, sliderx²::GLMakie.Slider, sliderx³::GLMakie.Slider, sliderx⁴::GLMakie.Slider)
    point1 = typeof(source) <: ℝ⁴ ? source : points[source]
    point2 = typeof(sink) <: ℝ⁴ ? sink : points[sink]
    point = getpoint(point1, point2, t)
    x¹, x², x³, x⁴ = vec(point)
    GLMakie.set_close_to!(sliderx¹, x¹)
    GLMakie.set_close_to!(sliderx², x²)
    GLMakie.set_close_to!(sliderx³, x³)
    GLMakie.set_close_to!(sliderx⁴, x⁴)
    GLMakie.notify(sliderx¹.value)
    GLMakie.notify(sliderx².value)
    GLMakie.notify(sliderx³.value)
    GLMakie.notify(sliderx⁴.value)
    # atol = 5e-1
    # if isapprox(point, points["o"])
    #     condition = isapprox(arrowx¹.head, x̂, atol = atol) && isapprox(arrowx².head, ŷ, atol = atol) && isapprox(arrowx³.head, ẑ, atol = atol)
    #     @assert(condition, "The frame is misaligned at the origin.")
    # end
    "parallel transport the frame from point `$source` to '$sink'"
end


"""
    paralleltransport(source, sink, points, sliderx¹, sliderx², sliderx³, sliderx⁴)

Parallel transport the frame to `source` to `sink` with the given sliders by calculating time steps and setting the sliders to the correct values.
"""
function paralleltransport(source, sink, points::Dict{String, ℝ⁴}, sliderx¹::GLMakie.Slider, sliderx²::GLMakie.Slider, sliderx³::GLMakie.Slider, sliderx⁴::GLMakie.Slider)
    for t in range(0, stop = 1, length = 30)
        paralleltransport(source, sink, t, points, sliderx¹, sliderx², sliderx³, sliderx⁴)
    end
    "parallel transport the frame from point `$source` to '$sink'"
end


"""
    markframe(name, label, islabeled, visible, tail, arrowx¹head, arrowx²head, arrowx³head, linewidth, arrowsize, fontsize,
    rotation, rotationn, rotations, lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)

Marks te current frame with the given `name` as a prefix.
"""
function markframe(name::String, label::String, islabeled::Dict{String, Bool},
    visible::GLMakie.Observable{Bool},
    tail::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx¹head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx²head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx³head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    linewidth::Float64,
    arrowsize::GLMakie.Vec{3, Float32},
    fontsize::Float64,
    rotation::GLMakie.Observable{GLMakie.Quaternion{Float64}},
    rotationn::GLMakie.Observable{GLMakie.Quaternion{Float64}},
    rotations::GLMakie.Observable{GLMakie.Quaternion{Float64}},
    lscene::GLMakie.LScene,
    lscenen::GLMakie.LScene,
    lscenes::GLMakie.LScene,
    eyeposition::ℝ³,
    eyepositionn::ℝ³,
    eyepositions::ℝ³,
    lookat::ℝ³,
    lookatn::ℝ³,
    lookats::ℝ³,
    up::ℝ³)
    index = name * label
    if get(islabeled, index, false)
        return "mark the frame using the identifier '$label'"
    end
    colors = [GLMakie.RGBAf(1.0, 0.0, 0.0, 0.5); GLMakie.RGBAf(0.0, 1.0, 0.0, 0.5); GLMakie.RGBAf(0.0, 0.0, 1.0, 0.5)]
    _ps = [tail[], tail[], tail[]]
    _ns = [arrowx¹head[], arrowx²head[], arrowx³head[]]
    GLMakie.arrows!(lscene,
        _ps, _ns, fxaa = true, # turn on anti-aliasing
        color = colors,
        linewidth = linewidth / 2.0, arrowsize = arrowsize,
        align = :origin,
        visible = visible
    )
    GLMakie.text!(lscene,
                  _ps .+ _ns,
                  text = ["$(label)₁", "$(label)₂", "$(label)₃"],
                  color = colors,
                  align = (:left, :baseline),
                  fontsize = fontsize / 2.0,
                  rotation = rotation,
                  markerspace = :data,
                  visible = visible)
    resetcamera(lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)
    islabeled[index] = true
    "mark the frame at poinr $name with identifier '$label'"
end


"""
    updateui(chart, q, tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)

Updates the User Interface (UI) such as camera, controls and scene objects.
"""
function updateui(chart::Bool, p₁::ℝ⁴,
    tangentvector::GLMakie.Observable{ℝ⁴},
    tail::GLMakie.Observable{GLMakie.Point{3, Float32}},
    tailn::GLMakie.Observable{GLMakie.Point{3, Float32}},
    tails::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx¹head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx²head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx³head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx¹headn::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx²headn::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx³headn::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx¹heads::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx²heads::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx³heads::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowcolorn::GLMakie.Observable{Vector{GLMakie.RGBAf}},
    arrowcolors::GLMakie.Observable{Vector{GLMakie.RGBAf}},
    arrowxcolorn::GLMakie.Observable{Vector{GLMakie.RGBAf}},
    arrowxcolors::GLMakie.Observable{Vector{GLMakie.RGBAf}},
    ps::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    ns::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    psn::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    nsn::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    pss::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    nss::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    ghostps::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    ghostns::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}})

    r = project(p₁)
    head = GLMakie.Point3f(r)

    # update the white arrow for pinpointing the position of the current point in the related chart
    ps[] = [GLMakie.Point3f(ℝ³(0.0, 0.0, 0.0))]
    ns[] = [head]
    
    transparentcolor = GLMakie.RGBAf(0.0, 0.0, 0.0, 0.0)
    clearwhite = GLMakie.RGBAf(1.0, 1.0, 1.0, 0.5)
    if chart
        pss[] = [tail[], tail[], tail[]]
        nss[] = [arrowx¹heads[], arrowx²heads[], arrowx³heads[]]
        arrowcolors[] = [clearwhite]
        arrowcolorn[] = [transparentcolor]
    else
        psn[] = [tail[], tail[], tail[]]
        nsn[] = [arrowx¹headn[], arrowx²headn[], arrowx³headn[]]
        arrowcolorn[] = [clearwhite]
        arrowcolors[] = [transparentcolor]
    end

    red = GLMakie.RGBAf(1.0, 0.0, 0.0, 1.0)
    green = GLMakie.RGBAf(0.0, 1.0, 0.0, 1.0)
    blue = GLMakie.RGBAf(0.0, 0.0, 1.0, 1.0)
    # update the frame in the related chart
    tail[] = head
    if chart
        tails[] = tail[]
        arrowxcolors[] = [red, green, blue]
        # hide the frame in the inactive chart
        arrowxcolorn[] = [transparentcolor, transparentcolor, transparentcolor]
    else
        tailn[] = tail[]
        arrowxcolorn[] = [red, green, blue]
        # hide the frame in the inactive chart
        arrowxcolors[] = [transparentcolor]
    end

    _v = GLMakie.to_value(tangentvector)
    # println("_v: ($_v), p₁: ($p₁).")
    if !isapprox(dot(_v, p₁), 0)
        perp = dot(_v, p₁) * p₁
        _v = normalize(_v - perp)
    end
    # @assert(isapprox(dot(_v, p₁), 0), "_v ($_v) is not perpendicular to p₁ ($p₁).")
    tangentvector[] = _v
    tail[] = GLMakie.Point3f(r)
    g = ℍ(tangentvector[])
    arrowx¹head[] = GLMakie.Point3f(rotate(ℝ³(1.0, 0.0, 0.0), g))
    arrowx²head[] = GLMakie.Point3f(rotate(ℝ³(0.0, 1.0, 0.0), g))
    arrowx³head[] = GLMakie.Point3f(rotate(ℝ³(0.0, 0.0, 1.0), g))
    ghostps[] = [tail[], tail[], tail[]]
    ghostns[] = [arrowx¹head[], arrowx²head[], arrowx³head[]]
end


"""
    updatepoint(p, p₀, p₁, chart, q, tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)

Updates the current point with the given coordinates `p`.
"""
function updatepoint(p::ℝ⁴, p₀::GLMakie.Observable{ℝ⁴}, p₁::GLMakie.Observable{ℝ⁴},
    chart::Bool, tangentvector::GLMakie.Observable{ℝ⁴},
    tail::GLMakie.Observable{GLMakie.Point{3, Float32}},
    tailn::GLMakie.Observable{GLMakie.Point{3, Float32}},
    tails::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx¹head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx²head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx³head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx¹headn::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx²headn::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx³headn::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx¹heads::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx²heads::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx³heads::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowcolorn::GLMakie.Observable{Vector{GLMakie.RGBAf}},
    arrowcolors::GLMakie.Observable{Vector{GLMakie.RGBAf}},
    arrowxcolorn::GLMakie.Observable{Vector{GLMakie.RGBAf}},
    arrowxcolors::GLMakie.Observable{Vector{GLMakie.RGBAf}},
    ps::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    ns::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    psn::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    nsn::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    pss::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    nss::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    ghostps::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    ghostns::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}})
    point₀ = GLMakie.to_value(p₁)
    # verify that the point in in a solid ball
    if norm(p) > 1
        point₁ = normalize(p)
    else
        point₁ = p
    end

    # prevent the update if the current point has not changed compare to the previous one
    threshold = 1e-8
    if isapprox(point₀, point₁, atol = threshold)
        return
    end

    # commit the changes
    p₀[] = point₀
    p₁[] = point₁

    # update the UI
    updateui(chart, p₁[], tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)
end


"""
    showset1(set1visible, set2visible)

Make a set of objects visible and make the other set invisible for illustration.
"""
showset1(set1visible::GLMakie.Observable{Bool}, set2visible::GLMakie.Observable{Bool}) = begin
    set1visible[] = true
    set2visible[] = false
    "Show the first set of points for comparing frames."
end


"""
    showset2(set1visible, set2visible)

Make a set of objects visible and make the other set invisible for illustration.
"""
showset2(set1visible::GLMakie.Observable{Bool}, set2visible::GLMakie.Observable{Bool}) = begin
    set1visible[] = false
    set2visible[] = true
    "Show the second set of points for comparing frames."
end


"""
    labelpoint(name, point, islabeled, set1, set1visible, set2visible,
        chart, markersize, lscene, lscenen, lscenes,
        rotation, rotationn, rotations, fontsize, eyeposition, eyepositionn, eyepositions,
        lookat, lookatn, lookats, up)

Label a point with the given `name`.
"""
function labelpoint(name::String, point::ℝ⁴, islabeled::Dict{String, Bool}, set1::Vector{String}, set1visible::GLMakie.Observable{Bool},
    set2visible::GLMakie.Observable{Bool}, charttoggle::GLMakie.Observable{Any}, markersize::Float64, lscene::GLMakie.LScene,
    lscenen::GLMakie.LScene, lscenes::GLMakie.LScene,
    rotation::GLMakie.Observable{GLMakie.Quaternion{Float64}},
    rotationn::GLMakie.Observable{GLMakie.Quaternion{Float64}},
    rotations::GLMakie.Observable{GLMakie.Quaternion{Float64}},
    fontsize::Float64, eyeposition::ℝ³, eyepositionn::ℝ³, eyepositions::ℝ³, lookat::ℝ³, lookatn::ℝ³, lookats::ℝ³, up::ℝ³)
    projectedpoint = GLMakie.Point3f(project(point))
    if !get(islabeled, name, false)
        visible = name ∈ set1 ? set1visible : set2visible
        visiblen = GLMakie.@lift($visible && !$(charttoggle))
        visibles = GLMakie.@lift($visible && $(charttoggle))
        GLMakie.meshscatter!(lscene, projectedpoint, markersize = markersize, color = :black, visible = visible)
        GLMakie.meshscatter!(lscenen, projectedpoint, markersize = markersize, color = :black, visible = visiblen)
        GLMakie.meshscatter!(lscenes, projectedpoint, markersize = markersize, color = :black, visible = visibles)
        GLMakie.text!(lscene.scene, projectedpoint, text = name, color = :black,
                      align = (:left, :baseline), rotation = rotation, fontsize = fontsize, markerspace = :data, visible = visible)
        GLMakie.text!(lscenen.scene, projectedpoint, text = name, color = :black,
                      align = (:left, :baseline), rotation = rotationn, fontsize = fontsize, markerspace = :data, visible = visiblen)
        GLMakie.text!(lscenes.scene, projectedpoint, text = name, color = :black,
                      align = (:left, :baseline), rotation = rotations, fontsize = fontsize, markerspace = :data, visible = visibles)
        resetcamera(lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)
        islabeled[name] = true
    end
    "Labeled point $name in $point"
end


"""
    switchcharts(chart, charttoggle)

Switch coordinate charts from one to the other.
"""
function switchcharts(chart::String, charttoggle::GLMakie.Observable{Any})
    if chart == "S"
        charttoggle[] = true
        return "Switched coordinate charts from N to S."
    end
    if chart == "N"
        charttoggle[] = false
        return "Switched coordinate charts from S to N."
    end
end


"""
    paralleltransport(path, t, points, chart, p₁, tail,
        arrowx¹head, arrowx²head, arrowx³head, ghostps, ghostns,
        sliderx¹, sliderx², sliderx³, sliderx⁴; tolerance)

Parallel transport a tangent vector along the given `path` and with the given time progress `t`.
"""
function paralleltransport(path::Vector{String}, t::Float64, points::Dict{String, ℝ⁴}, chart::Bool, p₁::ℝ⁴,
    tail::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx¹head::GLMakie.Observable{GLMakie.Point{3, Float32}}, arrowx²head::GLMakie.Observable{GLMakie.Point{3, Float32}},
    arrowx³head::GLMakie.Observable{GLMakie.Point{3, Float32}}, ghostps::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    ghostns::GLMakie.Observable{Vector{GLMakie.Point{3, Float32}}},
    sliderx¹::GLMakie.Slider, sliderx²::GLMakie.Slider, sliderx³::GLMakie.Slider, sliderx⁴::GLMakie.Slider; tolerance::Float64 = 1e-4)
    if isapprox(t, 1, atol = 1e-9)
        source = path[end-1]
        sink = path[end]
        return "Parallel transport the frame from $source to $sink"
    end
    N = length(path)
    τ = floor(t * N)
    sourceindex = Int(τ) + 1
    sinkindex = sourceindex == N ? 1 : sourceindex + 1
    source = path[sourceindex]
    sink = path[sinkindex]
    intervallength = 1 / N
    t₀ = (sourceindex - 1) * intervallength
    step = (t - t₀) * N

    # parallel transport the frame to the center of chart N and leave it there
    if !isapprox(p₁, points["o"])
        paralleltransport(p₁, "o", points, sliderx¹, sliderx², sliderx³, sliderx⁴)
    end
    if chart
        paralleltransport("o", "a", points, sliderx¹,  sliderx², sliderx³, sliderx⁴)
        switchcharts("N", toggle.active)
        paralleltransport("a", "o", points, sliderx¹, sliderx², sliderx³, sliderx⁴)
    end

    point = normalize(getpoint(points[source], points[sink], step))
    
    # Basis I
    v₁ = ℝ⁴(1.0, 0.0, 0.0, 0.0)
    ϵ = 1e-4
    chart = false # the N chart
    for i in range(ϵ, stop = 1.0, length = 30)
        q = i * point
        if !isapprox(dot(v₁, q), 0)
            perp = dot(v₁, q) * q
            v₁ = normalize(v₁ - perp)
        end
    end
    @assert(isapprox(dot(v₁, point), 0, atol = tolerance), "v₁ $v₁ is not perpendicular to point $point.")

    # Basis II
    v₂ = ℝ⁴(1.0, 0.0, 0.0, 0.0)
    chart = false
    for i in range(ϵ, stop = 1.0, length = 30)
        q = i * points["a"]
        if !isapprox(dot(v₂, q), 0)
            perp = dot(v₂, q) * q
            v₂ = normalize(v₂ - perp)
        end
    end
    @assert(isapprox(dot(v₂, points["a"]), 0, atol = tolerance), "v₂ $v₂ is not perpendicular to point $(points["a"]).")
    chart = true # the S chart
    for i in range(ϵ, stop = 1.0, length = 30)
        q = (1 - i) * points["a"]
        if !isapprox(dot(v₂, q), 0)
            perp = dot(v₂, q) * q
            v₂ = normalize(v₂ - perp)
        end
    end
    @assert(isapprox(dot(v₂, points["a"]), 0, atol = tolerance), "v₂ $v₂ is not perpendicular to point $(points["a"]).")
    for i in range(ϵ, stop = 1.0, length = 30)
        q = i * point
        if !isapprox(dot(v₂, q), 0)
            perp = dot(v₂, q) * q
            v₂ = normalize(v₂ - perp)
        end
    end
    @assert(isapprox(dot(v₂, point), 0, atol = tolerance), "v₂ $v₂ is not perpendicular to point $point.")
    
    tail[] = GLMakie.Point3f(project(point))
    g = ℍ(v₁)
    x̂ = ℝ³(1.0, 0.0, 0.0)
    ŷ = ℝ³(0.0, 1.0, 0.0)
    ẑ = ℝ³(0.0, 0.0, 1.0)
    arrowx¹head[] = GLMakie.Point3f(rotate(x̂, g))
    arrowx²head[] = GLMakie.Point3f(rotate(ŷ, g))
    arrowx³head[] = GLMakie.Point3f(rotate(ẑ, g))
    g = ℍ(v₂)
    _arrowx¹head = GLMakie.Point3f(rotate(x̂, g))
    _arrowx²head = GLMakie.Point3f(rotate(ŷ, g))
    _arrowx³head = GLMakie.Point3f(rotate(ẑ, g))
    ghostps[] = [tail[], tail[], tail[]]
    ghostns[] = [_arrowx¹head, _arrowx²head, _arrowx³head]
    "Parallel transport the frame from $source to $sink"
end


"""
    rotatetorus(q₁, q₂, t, segments, r, R, torus, torusn, toruss)

Rotate a torus of revolution from the given configuration `q₁` to `q₂` and interpolation time `t`.
"""
function rotatetorus(q₁::Dualquaternion, q₂::Dualquaternion, t::Float64, segments::Int, r::Float64, R::Float64,
    torus::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}},
    torusn::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}},
    toruss::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}})
    r₁, r₂ = getrotation(q₁), getrotation(q₂)
    q = t * r₂ + (1 - t) * r₁
    q = Dualquaternion(normalize(q))
    matrix = constructtorus(q, r, R, segments = segments)
    updatesurface!(matrix, torus)
    updatesurface!(matrix, torusn)
    updatesurface!(matrix, toruss)
    rotation = getrotation(q)
    "rotate the great circle with $rotation"
end
