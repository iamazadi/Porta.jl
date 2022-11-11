import Observables
import Makie


export Frame
export update


"""
    Represents a frame.

fields: section, color, configuration, segments, observable and scale.
"""
mutable struct Frame <: Sprite
    section::Any
    color::Any
    configuration::Biquaternion
    segments::Int
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
    scale::Float64
end


"""
    Frame(scene, gauge, color, [configuration, [segments, [transparency, [scale]]]])

Construct a Frame with the given `scene`, `section`, `configuration`, `segments`, `color`, `transparency` and `scale`.
"""
function Frame(scene::Makie.LScene,
               section::Any,
               color::Any;
               configuration::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
               segments::Int = 36,
               transparency::Bool = false,
               scale::Float64 = 1.0)
    frame = constructframe(section, configuration, segments, scale)
    observable = buildsurface(scene, frame, color, transparency = transparency)
    Frame(section, color, configuration, segments, observable, scale)
end


"""
    update(frame, section)

Update a Frame by changing its observable with the given `frame` and `section`.
"""
function update(frame::Frame, section::Any)
    frame.section = section
    value = constructframe(frame.section, frame.configuration, frame.segments, frame.scale)
    updatesurface(value, frame.observable)
end


"""
    update(frame, configuration)

Update a Frame by changing its observable with the given `frame` and 1configuration`.
"""
function update(frame::Frame, configuration::Biquaternion)
    frame.configuration = configuration
    value = constructframe(frame.section, frame.configuration, frame.segments, frame.scale)
    updatesurface(value, frame.observable)
end


"""
    update(frame, section, configuration)

Update a Frame by changing its observable with the given `frame`, `section` and `configuration`.
"""
function update(frame::Frame, section::Any, configuration::Biquaternion)
    frame.section = section
    frame.configuration = configuration
    value = constructframe(frame.section, frame.configuration, frame.segments, frame.scale)
    updatesurface(value, frame.observable)
end
