import Observables
import AbstractPlotting


export Frame
export update


"""
    Represents a frame.

fields: circle, s2tos3map, s2tos2map, color, s3rotation, config, segments and observable.
"""
mutable struct Frame <: Sprite
    circle::S¹
    s2tos3map::Any
    s2tos2map::Any
    color::Any
    s3rotation::S³
    config::Biquaternion
    segments::Int
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Frame(scene, circle, s2tos3map, s2tos2map, color,
          [s3rotation, [config, [segments, [transparency]]]])

Construct a Frame with the given `scene`, `circle` in the fiber space, function `f` that
takes the base space to itself, S³ rotation `s3rotation`, configuration `config`, the number
of `segments`, `color` and `transparency`.
"""
function Frame(scene::AbstractPlotting.Scene,
               circle::S¹,
               s2tos3map,
               s2tos2map,
               color::Any;
               s3rotation::S³ = Quaternion(1, 0, 0, 0),
               config::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
               segments::Int = 36,
               transparency::Bool = false)
    frame = constructframe(circle,
                           s2tos3map,
                           s2tos2map,
                           s3rotation = s3rotation,
                           config = config,
                           segments = segments)
    observable = buildsurface(scene, frame, color, transparency = transparency)
    Frame(circle, s2tos3map, s2tos2map, color, s3rotation, config, segments, observable)
end


"""
    update(frame, circle)

Update a Frame by changing its observable with the given `frame` and `circle` in the fiber
space.
"""
function update(frame::Frame, circle::S¹)
    frame.circle = circle
    value = constructframe(frame.circle,
                           frame.s2tos3map,
                           frame.s2tos2map,
                           s3rotation = frame.s3rotation,
                           config = frame.config,
                           segments = frame.segments)
    updatesurface(value, frame.observable)
end


"""
    update(frame, s2tos3map, s2tos2map)

Update a Frame by changing its observable with the given `frame` and map `s2tos3map` from
the base space into the total space, f: S² → S³, and also the map `s2tos2map` from the base
space into itself, f: S² → S².
"""
function update(frame::Frame, s2tos3map::Any, s2tos2map::Any)
    frame.s2tos3map = s2tos3map
    frame.s2tos2map = s2tos2map
    value = constructframe(frame.circle,
                           frame.s2tos3map,
                           frame.s2tos2map,
                           s3rotation = frame.s3rotation,
                           config = frame.config,
                           segments = frame.segments)
    updatesurface(value, frame.observable)
end


"""
    update(frame, s3rotation)

Update a Frame by changing its observable with the given `frame` and S³ rotation
`s3rotation`.
"""
function update(frame::Frame, s3rotation::S³)
    frame.s3rotation = s3rotation
    value = constructframe(frame.circle,
                           frame.s2tos3map,
                           frame.s2tos2map,
                           s3rotation = frame.s3rotation,
                           config = frame.config,
                           segments = frame.segments)
    updatesurface(value, frame.observable)
end


"""
    update(frame, config)

Update a Frame by changing its observable with the given `frame` and configuration `config`.
"""
function update(frame::Frame, config::Biquaternion)
    frame.config = config
    value = constructframe(frame.circle,
                           frame.s2tos3map,
                           frame.s2tos2map,
                           s3rotation = frame.s3rotation,
                           config = frame.config,
                           segments = frame.segments)
    updatesurface(value, frame.observable)
end
