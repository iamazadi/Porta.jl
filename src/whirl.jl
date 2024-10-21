import GLMakie


export Whirl
export update!
export make


"""
    Represents a shape in a scene.
"""
abstract type Sprite end


"""
    make(x, gauge1, gauge2, M, segments)

Make the vertical subspace of the boundary `x`, with the given heights `gauge1` and `gauge2`, transform `M` and the number of `segments`.
"""
function make(x::Vector{ℍ}, gauge1::Float64, gauge2::Float64, M::Matrix{Float64}, segments::Integer)
    lspacegauge = range(gauge1, stop = gauge2, length = segments)
    [project(normalize(M * (x[i] * ℍ(exp(K(3) * gauge))))) for i in 1:length(x), gauge in lspacegauge]
end


"""
    Represents a whirl.

fields: x, gauge1, gauge2, M, segments, color and observable.
"""
mutable struct Whirl <: Sprite
    x::Vector{ℍ}
    gauge1::Float64
    gauge2::Float64
    M::Matrix{Float64}
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Whirl(scene::GLMakie.LScene, x::Vector{ℍ}, gauge1::Float64, gauge2::Float64, M::Matrix{Float64}, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(x, gauge1, gauge2, M, segments)
        color_matrix = GLMakie.Observable(fill(color, length(x), segments))
        observable = buildsurface(scene, matrix, color_matrix, transparency = transparency)
        new(x, gauge1, gauge2, M, segments, color_matrix, observable)
    end
end


"""
    update!(whirl, x, gauge1, gauge2, M)

Update the shape of a `whirl` with the given boundary points `x`, gauges `gauge1` and `gauge2`, and transformation `M`.
"""
function update!(whirl::Whirl, x::Vector{ℍ}, gauge1::Float64, gauge2::Float64, M::Matrix{Float64})
    whirl.x = x
    whirl.gauge1 = gauge1
    whirl.gauge2 = gauge2
    whirl.M = M
    matrix = make(x, gauge1, gauge2, M, whirl.segments)
    updatesurface!(matrix, whirl.observable)
end


"""
    update!(whirl, color)

Update the `color` of a `whirl`.
"""
function update!(whirl::Whirl, color::Any)
    whirl.color[] = fill(color, length(whirl.x), whirl.segments)
end
