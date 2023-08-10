import GLMakie


export Whirl
export update!
export project
export convert_hsvtorgb


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
    v = [q.a; q.b; q.c] ./ (1 - q.d)
    normalize(v) .* tanh(norm(v))
end


"""
    make(v, θ1, θ2, segments)

Make the shape of a whirl as a 2-surface in ℝ³.
"""
function make(v::Vector{Quaternion}, θ1::Vector{Float64}, θ2::Vector{Float64}, segments::Integer)
    matrix = Matrix{Vector{Float64}}(undef, length(v), segments)
    for (j, w) in enumerate(v)
        lspace = range(θ1[j], stop = θ2[j], length = segments)
        for (i, θ) in enumerate(lspace)
            matrix[j, i] = project(G(θ, w))
        end
    end
    matrix
end


"""
    Represents a whirl.

fields: v, θ1, θ2, segments, color and observable.
"""
mutable struct Whirl <: Sprite
    v::Vector{Quaternion}
    θ1::Vector{Float64}
    θ2::Vector{Float64}
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Whirl(scene::GLMakie.LScene, v::Vector{Quaternion}, θ1::Vector{Float64}, θ2::Vector{Float64}, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(v, θ1, θ2, segments)
        color_matrix= GLMakie.Observable(fill(color, length(v), segments))
        observable = buildsurface(scene, matrix, color_matrix, transparency = transparency)
        new(v, θ1, θ2, segments, color_matrix, observable)
    end
end


"""
    update!(whirl, v, θ1, θ2)

Update the shape of a `whirl`.
"""
function update!(whirl::Whirl, v::Vector{Quaternion}, θ1::Vector{Float64}, θ2::Vector{Float64})
    whirl.v = v
    whirl.θ1 = θ1
    whirl.θ2 = θ2
    matrix = make(v, θ1, θ2, whirl.segments)
    updatesurface!(matrix, whirl.observable)
end


"""
    update!(whirl, color)

Update the `color` of a `whirl`.
"""
function update!(whirl::Whirl, color::Any)
    whirl.color[] = fill(color, length(whirl.v), whirl.segments)
end
