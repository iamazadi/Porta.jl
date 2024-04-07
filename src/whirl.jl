import GLMakie


export Whirl
export update!
export make


"""
    Represents a shape in a scene.
"""
abstract type Sprite end


"""
    make(q, θ1, θ2, f, segments)

Make the vertical subspace of the boundary `q`, with the given heights `θ1` and `θ2`, transform `f` and the number of `segments`.
"""
function make(q::Vector{Quaternion}, θ1::Float64, θ2::Float64, f::Matrix{Float64}, segments::Integer)
    lspaceθ = range(θ1, stop = θ2, length = segments)
    [project(normalize(f * (q[i] * Quaternion(exp(K(3) * θ))))) for i in 1:length(q), θ in lspaceθ]
end


"""
    Represents a whirl.

fields: q, θ1, θ2, f, segments, color and observable.
"""
mutable struct Whirl <: Sprite
    q::Vector{Quaternion}
    θ1::Float64
    θ2::Float64
    f::Matrix{Float64}
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Whirl(scene::GLMakie.LScene, q::Vector{Quaternion}, θ1::Float64, θ2::Float64, f::Matrix{Float64}, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(q, θ1, θ2, f, segments)
        color_matrix = GLMakie.Observable(fill(color, length(q), segments))
        observable = buildsurface(scene, matrix, color_matrix, transparency = transparency)
        new(q, θ1, θ2, f, segments, color_matrix, observable)
    end
end


"""
    update!(whirl, q, θ1, θ2, f)

Update the shape of a `whirl` with the given boundary points `q`, gauges `θ1` and `θ2`, and transformation `f`.
"""
function update!(whirl::Whirl, q::Vector{Quaternion}, θ1::Float64, θ2::Float64, f::Matrix{Float64})
    whirl.q = q
    whirl.θ1 = θ1
    whirl.θ2 = θ2
    whirl.f = f
    matrix = make(q, θ1, θ2, f, whirl.segments)
    updatesurface!(matrix, whirl.observable)
end


"""
    update!(whirl, color)

Update the `color` of a `whirl`.
"""
function update!(whirl::Whirl, color::Any)
    whirl.color[] = fill(color, length(whirl.q), whirl.segments)
end
