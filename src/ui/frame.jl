import Observables
import AbstractPlotting


export Frame
export update


"""
    Represents a frame.

fields: circle, color, s3rotation, config, segments and observable.
"""
mutable struct Frame <: Sprite
    circle::S¹
    color::Any
    s3rotation::S³
    config::Biquaternion
    segments::Int
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Frame(scene, circle, color, [s3rotation, [config, [segments, [transparency]]]])

Construct a Frame with the given `scene`, `circle` in the fiber space, S³ rotation
`s3rotation`, configuration `config`, the number of `segments`, `color` and `transparency`.
"""
function Frame(scene::AbstractPlotting.Scene,
               circle::S¹,
               color::Any;
               s3rotation::S³ = Quaternion(1, 0, 0, 0),
               config::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
               segments::Int = 36,
               transparency::Bool = false)
    frame = constructframe(circle,
                           s3rotation = s3rotation,
                           config = config,
                           segments = segments)
    observable = buildsurface(scene, frame, color, transparency = transparency)
    Frame(circle, color, s3rotation, config, segments, observable)
end


"""
    update(frame, circle)

Update a Frame by changing its observable with the given `frame` and `circle` in the fiber
space.
"""
function update(frame::Frame, circle::S¹)
    frame.circle = circle
    value = constructframe(frame.circle,
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
                           s3rotation = frame.s3rotation,
                           config = frame.config,
                           segments = frame.segments)
    updatesurface(value, frame.observable)
end
