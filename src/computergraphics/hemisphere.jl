import Observables
import Makie


export Hemisphere
export RGBHemisphere
export update


"""
    Represents a hemisphere.

fields: q, radius, segments, color and observable.
"""
mutable struct Hemisphere <: Sprite
    q::Biquaternion
    radius::Float64
    segments::Int
    color::Observables.Observable{Array{Makie.ColorTypes.RGBA{Float32},2}}
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


mutable struct RGBHemisphere <: Sprite
    q::Biquaternion
    radius::Float64
    segments::Int
    color::Any
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Hemisphere(q, scene)

Construct a hemisphere with the given configuration `q` and `scene`, and the optional arguments:
`radius`, `segments`, `color` and `transparency`.
"""
function Hemisphere(q::Biquaternion,
                scene::Makie.LScene;
                radius::Float64 = 1.0,
                segments::Int = 36,
                color::Makie.RGBAf = Makie.RGBAf(1.0, 0.2705, 0.0, 0.5),
                transparency::Bool = false)
    hemisphere = constructhemisphere(q, radius, segments = segments)
    colorarray = Observables.Observable(fill(color, segments, segments))
    observable = buildsurface(scene, hemisphere, colorarray, transparency = transparency)
    Hemisphere(q, radius, segments, colorarray, observable)
end


function RGBHemisphere(q::Biquaternion,
                scene::Makie.LScene,
                color::Any;
                radius::Float64 = 1.0,
                segments::Int = 36,
                transparency::Bool = false)
    hemisphere = constructhemisphere(q, radius, segments = segments)
    observable = buildsurface(scene, hemisphere, color, transparency = transparency)
    RGBHemisphere(q, radius, segments, color, observable)
end


"""
    update(hemisphere, q)

Update a Hemisphere by changing its observable with the given `hemisphere` and configuration `q`.
"""
function update(hemisphere::Hemisphere, q::Biquaternion)
    hemisphere.q = q
    value = constructhemisphere(hemisphere.q, hemisphere.radius, segments = hemisphere.segments)
    updatesurface(value, hemisphere.observable)
end

"""
    update(hemisphere, q)

Update a Hemisphere by changing its observable with the given `hemisphere` and configuration `q`.
"""
function update(hemisphere::RGBHemisphere, q::Biquaternion)
    hemisphere.q = q
    value = constructhemisphere(hemisphere.q, hemisphere.radius, segments = hemisphere.segments)
    updatesurface(value, hemisphere.observable)
end


"""
    update(hemisphere, color)

Update a Hemisphere by changing its observable with the given `hemisphere` and `color`.
"""
function update(hemisphere::Hemisphere, color::Makie.RGBAf)
    hemisphere.color[] = fill(color, hemisphere.segments, hemisphere.segments)
end
