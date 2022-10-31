import Observables
import Makie


export Frame
export update


"""
    Represents a frame.

fields: section, color, configuration, segments and observable.
"""
mutable struct Frame <: Sprite
    section::Any
    color::Any
    configuration::Biquaternion
    segments::Int
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Frame(scene, gauge, color, [configuration, [segments, [transparency]]])

Construct a Frame with the given `scene`, `section`, `configuration`, `segments`, `color` and `transparency`.
"""
function Frame(scene::Makie.Scene,
               section::Any,
               color::Any;
               configuration::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
               segments::Int = 36,
               transparency::Bool = false)
    frame = constructframe(section, configuration, segments)
    observable = buildsurface(scene, frame, color, transparency = transparency)
    Frame(section, color, configuration, segments, observable)
end


"""
    update(frame, section)

Update a Frame by changing its observable with the given `frame` and `section`.
"""
function update(frame::Frame, section::Any)
    frame.section = section
    value = constructframe(frame.section, frame.configuration, frame.segments)
    updatesurface(value, frame.observable)
end


"""
    update(frame, configuration)

Update a Frame by changing its observable with the given `frame` and 1configuration`.
"""
function update(frame::Frame, configuration::Biquaternion)
    frame.configuration = configuration
    value = constructframe(frame.section, frame.configuration, frame.segments)
    updatesurface(value, frame.observable)
end
