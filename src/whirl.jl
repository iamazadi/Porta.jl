import GLMakie


export Whirl
export update!
export project
export convert_hsvtorgb
export make


"""
    Represents a shape in a scene.
"""
abstract type Sprite end


"""
   hsvtorgb(color)

Convert a `color` from HSV space to RGB.
"""
convert_hsvtorgb(color) = begin
    H, S, V = color
    C = V * S
    X = C * (1 - Base.abs((H / 60) % 2 - 1))
    m = V - C
    if 0 ≤ H < 60
        R′, G′, B′ = C, X, 0
    elseif 60 ≤ H < 120
        R′, G′, B′ = X, C, 0
    elseif 120 ≤ H < 180
        R′, G′, B′ = 0, C, X
    elseif 180 ≤ H < 240
        R′, G′, B′ = 0, X, C
    elseif 240 ≤ H < 300
        R′, G′, B′ = X, 0, C
    elseif 300 ≤ H < 360
        R′, G′, B′ = C, 0, X
    else
        R′, G′, B′ = rand(3)
    end
    R, G, B = R′ + m, G′ + m, B′ + m
    [R; G; B]
end


"""
    project(q)

Take the given point `q` ∈ S³ ⊂ ℂ² into the Euclidean space ℝ³ using stereographic projection.
"""
function project(q::Quaternion)
    v = ℝ³(vec(q)[1], vec(q)[2], vec(q)[3]) * (1.0 / (1.0 - vec(q)[4]))
    normalize(v) * tanh(norm(v))
end


"""
    make(q, θ1, θ2, segments)

Make the vertical subspace of the boundary `q`, with the given heights `θ1` and `θ2`, and the number of `segments`.
"""
function make(q::Vector{Quaternion}, θ1::Float64, θ2::Float64, segments::Integer)
    matrix = Matrix{ℝ³}(undef, length(q), segments)
    lspaceθ = collect(range(θ1, stop = θ2, length = segments))
    for (j, p) in enumerate(q)
        for (i, θ) in enumerate(lspaceθ)
            matrix[j, i] = project(exp(K(3) * θ) * p)
        end
    end
    matrix
end


"""
    Represents a whirl.

fields: q, θ1, θ2, segments, color and observable.
"""
mutable struct Whirl <: Sprite
    q::Vector{Quaternion}
    θ1::Float64
    θ2::Float64
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Whirl(scene::GLMakie.LScene, q::Vector{Quaternion}, θ1::Float64, θ2::Float64, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(q, θ1, θ2, segments)
        color_matrix= GLMakie.Observable(fill(color, length(q), segments))
        observable = buildsurface(scene, matrix, color_matrix, transparency = transparency)
        new(q, θ1, θ2, segments, color_matrix, observable)
    end
end


"""
    update!(whirl, q, θ1, θ2)

Update the shape of a `whirl`.
"""
function update!(whirl::Whirl, q::Vector{Quaternion}, θ1::Float64, θ2::Float64)
    whirl.q = q
    whirl.θ1 = θ1
    whirl.θ2 = θ2
    matrix = make(q, θ1, θ2, whirl.segments)
    updatesurface!(matrix, whirl.observable)
end


"""
    update!(whirl, color)

Update the `color` of a `whirl`.
"""
function update!(whirl::Whirl, color::Any)
    whirl.color[] = fill(color, length(whirl.q), whirl.segments)
end
