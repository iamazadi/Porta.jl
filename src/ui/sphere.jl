import Observables
import Makie


export Sphere
export update


"""
    Represents a sphere.

fields: q, radius, segments, color and observable.
"""
mutable struct Sphere <: Sprite
    q::Biquaternion
    radius::Float64
    segments::Int
    color::Observables.Observable{Array{Makie.ColorTypes.RGBA{Float32},2}}
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Sphere(q, scene)

Construct a sphere with the given configuration `q` and `scene`, and the optional arguments:
`radius`, `segments`, `color` and `transparency`.
"""
function Sphere(q::Biquaternion,
                scene::Makie.Scene;
                radius::Float64 = 1.0,
                segments::Int = 36,
                color::Makie.RGBAf = Makie.RGBAf(1.0,
                                                                         0.2705,
                                                                         0.0,
                                                                         0.5),
                transparency::Bool = false)
    sphere = constructsphere(q, radius, segments = segments)
    colorarray = Observables.Observable(fill(color, segments, segments))
    observable = buildsurface(scene, sphere, colorarray, transparency = transparency)
    Sphere(q, radius, segments, colorarray, observable)
end


"""
    update(sphere, q)

Update a Sphere by changing its observable with the given `sphere` and configuration `q`.
"""
function update(sphere::Sphere, q::Biquaternion)
    sphere.q = q
    value = constructsphere(sphere.q, sphere.radius, segments = sphere.segments)
    updatesurface(value, sphere.observable)
end


"""
    update(sphere, color)

Update a Sphere by changing its observable with the given `sphere` and `color`.
"""
function update(sphere::Sphere, color::Makie.RGBAf)
    sphere.color[] = fill(color, sphere.segments, sphere.segments)
end
