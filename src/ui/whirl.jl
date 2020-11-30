import Observables
import AbstractPlotting


export Whirl
export update


"""
    Represents a whirl.

fields: points, s2tos2map, s2tos3map, top, bottom, s3rotation, config, segments, color,
observable and scale.
"""
mutable struct Whirl <: Sprite
    points::Array{<:S²,1}
    s2tos3map::Any
    s2tos2map::Any
    top::S¹
    bottom::S¹
    s3rotation::S³
    config::Biquaternion
    segments::Int
    color::Observables.Observable{Array{AbstractPlotting.ColorTypes.RGBA{Float32},2}}
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
    scale::Real
end


"""
    Whirl(scene,
          points,
          s2tos3map,
          s2tos2map,
          [top, [bottom, [s3rotation, [config, [segments, [color, [transparency
           [,scale]]]]]]]])

Construct a whirl with the given `scene`, `points` in the base space, `s2tos3map`,
`s2tos2map`, `top`, `bottom`, S³ rotation `s3rotation`, configuration `config`, the number
of `segments`, `color`, `transparency` and `scale`.
"""
function Whirl(scene::AbstractPlotting.Scene,
               points::Array{<:S²,1},
               s2tos3map,
               s2tos2map;
               top::S¹ = U1(-pi),
               bottom::S¹ = U1(pi),
               s3rotation::S³ = Quaternion(1, 0, 0, 0),
               config::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
               segments::Int = 36,
               color::AbstractPlotting.RGBAf0 = AbstractPlotting.RGBAf0(1.0,
                                                                        0.2705,
                                                                        0.0,
                                                                        0.5),
               transparency::Bool = false,
               scale::Real = 1.0)
    whirl = constructwhirl(points,
                           s2tos3map,
                           s2tos2map,
                           top = top,
                           bottom = bottom,
                           s3rotation = s3rotation,
                           config = config,
                           segments = segments,
                           scale = scale)
    colorarray = Observables.Observable(fill(color, size(whirl)...))
    observable = buildsurface(scene, whirl, colorarray, transparency = transparency)
    Whirl(points, s2tos3map, s2tos2map, top, bottom, s3rotation, config, segments,
          colorarray, observable, scale)
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
                           whirl.s2tos3map,
                           whirl.s2tos2map,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments,
                           scale = whirl.scale)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, s2tos3map, s2tos2map)

Update a Whirl by changing its observable with the given `whirl` and map `s2tos3map` from
the base space into the total space, f: S² → S³, and also the map `s2tos2map` from the base
space into itself, f: S² → S².
"""
function update(whirl::Whirl, s2tos3map::Any, s2tos2map::Any)
    whirl.s2tos3map = s2tos3map
    whirl.s2tos2map = s2tos2map
    value = constructwhirl(whirl.points,
                           whirl.s2tos3map,
                           whirl.s2tos2map,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments,
                           scale = whirl.scale)
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
                           whirl.s2tos3map,
                           whirl.s2tos2map,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments,
                           scale = whirl.scale)
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
                           whirl.s2tos3map,
                           whirl.s2tos2map,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments,
                           scale = whirl.scale)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, config)

Update a Whirl by changing its observable with the given `whirl` and configuration `config`.
"""
function update(whirl::Whirl, config::Biquaternion)
    whirl.config = config
    value = constructwhirl(whirl.points,
                           whirl.s2tos3map,
                           whirl.s2tos2map,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments,
                           scale = whirl.scale)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, color)

Update a Whirl by changing its observable with the given `whirl` and `color`.
"""
function update(whirl::Whirl, color::AbstractPlotting.RGBAf0)
    whirl.color[] = fill(color, whirl.segments, length(whirl.points))
end


"""
    update(whirl, points, s3rotation, top, bottom)

Update a Whirl by constructing it from scratch with the given base space `points`, S³
rotation `s3rotation`, beginning U(1) action `top` and ending U(1) action `bottom`.
"""
function update(whirl::Whirl, points::Array{<:S²,1}, s3rotation::S³, top::S¹, bottom::S¹)
    @assert(length(points) == length(whirl.points),
            "The number of the given points must be equal to what it was before.")
    whirl.points = points
    whirl.s3rotation = s3rotation
    whirl.top = top
    whirl.bottom = bottom
    value = constructwhirl(whirl.points,
                           whirl.s2tos3map,
                           whirl.s2tos2map,
                           top = whirl.top,
                           bottom = whirl.bottom,
                           s3rotation = whirl.s3rotation,
                           config = whirl.config,
                           segments = whirl.segments,
                           scale = whirl.scale)
    updatesurface(value, whirl.observable)
end
