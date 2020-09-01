import Observables
import AbstractPlotting


export Whirl
export update


"""
    Represents a whirl.

fields: points, top, bottom, s3rotation, config, segments, color and observable.
"""
mutable struct Whirl <: Sprite
    points::Array{<:S²,1}
    top::S¹
    bottom::S¹
    s3rotation::S³
    config::Biquaternion
    segments::Int
    color::AbstractPlotting.RGBAf0
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Whirl(scene,
          points,
          [top, [bottom, [s3rotation, [config, [segments, [color, [transparency]]]]]]])

Construct a whirl with the given `scene`, `points` in the base space, `top`, `bottom`,
S³ rotation `s3rotation`, configuration `config`, the number of `segments`, `color` and
`transparency`.
"""
function Whirl(scene::AbstractPlotting.Scene,
               points::Array{<:S²,1};
               top::S¹ = U1(-pi),
               bottom::S¹ = U1(pi),
               s3rotation::S³ = Quaternion(1, 0, 0, 0),
               config::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
               segments::Int = 36,
               color::AbstractPlotting.RGBAf0 = AbstractPlotting.RGBAf0(1.0,
                                                                        0.2705,
                                                                        0.0,
                                                                        0.5),
               transparency::Bool = false)
    whirl = constructwhirl(points,
                           top = top,
                           bottom = bottom,
                           s3rotation = s3rotation,
                           config = config,
                           segments = segments)
    colorarray = fill(color, segments, segments)
    observable = buildsurface(scene, whirl, colorarray, transparency = transparency)
    Whirl(points, top, bottom, s3rotation, config, segments, color, observable)
end


"""
    update(whirl, points)

Update a Whirl by changing its observable with the given `whirl` and `points` in the base
space.
"""
function update(whirl::Whirl, points::Array{<:S²,1})
    @assert(length(points) == length(whirl.points),
            "The number of the given points must be equal to what it was before.")
    whirl.points = points
    value = constructwhirl(whirl.points,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, top, bottom)

Update a Whirl by changing its observable with the given `whirl`, `top` and `bottom`.
"""
function update(whirl::Whirl, top::S¹, bottom::S¹)
    whirl.top = top
    whirl.bottom = bottom
    value = constructwhirl(whirl.points,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, s3rotation)

Update a Whirl by changing its observable with the given `whirl` and S³ rotation
`s3rotation`.
"""
function update(whirl::Whirl, s3rotation::S³)
    whirl.s3rotation = s3rotation
    value = constructwhirl(whirl.points,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, config)

Update a Whirl by changing its observable with the given `whirl` and configuration `config`.
"""
function update(whirl::Whirl, config::Biquaternion)
    whirl.config = config
    value = constructwhirl(whirl.points,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments)
    updatesurface(value, whirl.observable)
end
