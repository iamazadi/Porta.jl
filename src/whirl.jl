import GLMakie


export Whirl
export update!
export make


"""
    Represents a shape in a scene.
"""
abstract type Sprite end


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
