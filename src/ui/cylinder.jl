import Observables
import AbstractPlotting


export Cylinder
export update


"""
    Represents a cylinder.

fields: q, radius, height, segments, color and observable.
"""
mutable struct Cylinder
    q::Biquaternion
    height::Float64
    radius::Float64
    segments::Int
    color::Observables.Observable{Array{AbstractPlotting.ColorTypes.RGBA{Float32},2}}
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Cylinder(q, scene)

Construct a Cylinder with the given configuration `q` and `scene`, and the optional
arguments: `height`, `radius`, `segments`, `color` and `transparency`.
"""
function Cylinder(q::Biquaternion,
                  scene::AbstractPlotting.Scene;
                  height::Float64 = 1.0,
                  radius::Float64 = 0.1,
                  segments::Int = 36,
                  color::AbstractPlotting.RGBAf0 = AbstractPlotting.RGBAf0(0.7529,
                                                                           0.7529,
                                                                           0.7529,
                                                                           0.5),
                  transparency::Bool = false)
    cylinder = constructcylinder(q, height, radius, segments = segments)
    colorarray = Observables.Observable(fill(color, segments, segments))
    observable = buildsurface(scene, cylinder, colorarray, transparency = transparency)
    Cylinder(q, height, radius, segments, colorarray, observable)
end


"""
    update(cylinder, q)

Update a Cylinder by changing its observable with the given `cylinder` and configuration `q`
.
"""
function update(cylinder::Cylinder, q::Biquaternion)
    cylinder.q = q
    value = constructcylinder(cylinder.q,
                              cylinder.height,
                              cylinder.radius,
                              segments = cylinder.segments)
    updatesurface(value, cylinder.observable)
end


"""
    update(cylinder, color)

Update a Cylinder by changing its observable with the given `cylinder` and `color`.
"""
function update(cylinder::Cylinder, color::AbstractPlotting.RGBAf0)
    cylinder.color[] = fill(color, cylinder.segments, cylinder.segments)
end
