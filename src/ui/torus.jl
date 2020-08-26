import Observables
import AbstractPlotting


export Torus
export update


"""
    Represents a torus of revolution.

fields: q, r, R, segments, color and observables.
"""
mutable struct Torus <: Sprite
    q::Biquaternion
    r::Float64
    R::Float64
    segments::Int
    color::AbstractPlotting.RGBAf0
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Torus(joint, scene)

Construct a torus of revolution with the given configuration `q` and `scene`, and the
optional arguments: smaller radius `r`, bigger radius `R`, `segments`, `color` and
`transparency`.
"""
function Torus(q::Biquaternion,
               scene::AbstractPlotting.Scene;
               r::Float64 = 0.025,
               R::Float64 = 1.0,
               segments::Int = 36,
               color::AbstractPlotting.RGBAf0 = AbstractPlotting.RGBAf0(0.1, 0.1, 0.1, 0.9),
               transparency::Bool = false)
    torus = constructtorus(q, r, R, segments = segments)
    colorarray = fill(color, segments, segments)
    observable = buildsurface(scene, torus, colorarray, transparency = transparency)
    Torus(q, r, R, segments, color, observable)
end


"""
    update(torus, q)

Update a Torus by changing its observable with the given `torus` and configuration `q`.
"""
function update(torus::Torus, q::Biquaternion)
    torus.q = q
    value = constructtorus(torus.q, torus.r, torus.R, segments = torus.segments)
    updatesurface(value, torus.observable)
end
