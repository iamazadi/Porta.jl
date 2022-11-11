import FixedPointNumbers
import ColorTypes
import Observables
import Makie


export Whirl
export update


"""
    Represents a whirl.

fields: points, gauge1, gauge2, configuration, segments, color, observable and scale.
"""
mutable struct Whirl <: Sprite
    points::Array{ComplexPlane,1}
    gauge1::Array{U1,1}
    gauge2::Array{U1,1}
    configuration::Biquaternion
    segments::Int
    color::Observables.Observable{Array{Makie.ColorTypes.RGBA{FixedPointNumbers.Normed{UInt8, 8}},2}}
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
    scale::Float64
end


"""
    Whirl(scene,
          points,
          [gauge1, [gauge2, [configuration, [segments, [color, [transparency, [scale]]]]]]])

Construct a whirl with the given `scene`, `points`, `gauge1`, `gauge2`,
`configuration`, `segments`, `color`, `transparency` and `scale`.
"""
function Whirl(scene::Makie.LScene,
               points::Array{ComplexPlane,1},
               gauge1::Array{U1,1},
               gauge2::Array{U1,1};
               configuration::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
               segments::Int = 36,
               color::Makie.RGBA{FixedPointNumbers.Normed{UInt8, 8}} = Makie.RGBA{FixedPointNumbers.Normed{UInt8, 8}}(1.0, 0.2705, 0.0, 0.5),
               transparency::Bool = false,
               scale::Float64 = 1.0)
    whirl = constructwhirl(points, gauge1, gauge2, configuration, segments, scale)
    colorarray = Observables.Observable(fill(color, size(whirl)...))
    observable = buildsurface(scene, whirl, colorarray, transparency = transparency)
    Whirl(points, gauge1, gauge2, configuration, segments, colorarray, observable, scale)
end


"""
    update(whirl, points)

Update a Whirl by changing its observable with the given `whirl` and `points`.
"""
function update(whirl::Whirl, points::Array{ComplexPlane,1})
    whirl.points = points
    value = constructwhirl(whirl.points,
                           whirl.gauge1,
                           whirl.gauge2,
                           whirl.configuration,
                           whirl.segments,
                           whild.scale)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, gauge1, gauge2)

Update a Whirl by changing its observable with the given `whirl`, `gauge1` and `gauge2`.
"""
function update(whirl::Whirl, gauge1::Array{U1,1}, gauge2::Array{U1,1})
    whirl.gauge1 = gauge1
    whirl.gauge2 = gauge2
    value = constructwhirl(whirl.points,
                           whirl.gauge1,
                           whirl.gauge2,
                           whirl.configuration,
                           whirl.segments,
                           whirl.scale)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, points, gauge1, gauge2)

Update a Whirl by changing its observable with the given `whirl`, `points`, `gauge1` and `gauge2`.
"""
function update(whirl::Whirl, points::Array{ComplexPlane,1}, gauge1::Array{U1,1}, gauge2::Array{U1,1})
    whirl.points = points
    whirl.gauge1 = gauge1
    whirl.gauge2 = gauge2
    value = constructwhirl(whirl.points,
                           whirl.gauge1,
                           whirl.gauge2,
                           whirl.configuration,
                           whirl.segments,
                           whirl.scale)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, points, gauge1, gauge2, configuration)

Update a Whirl by changing its observable with the given `whirl`, `points`, `gauge1`, `gauge2` and `configuration`.
"""
function update(whirl::Whirl, points::Array{ComplexPlane,1}, gauge1::Array{U1,1}, gauge2::Array{U1,1}, configuration::Biquaternion)
    whirl.points = points
    whirl.gauge1 = gauge1
    whirl.gauge2 = gauge2
    whirl.configuration = configuration
    value = constructwhirl(whirl.points,
                           whirl.gauge1,
                           whirl.gauge2,
                           whirl.configuration,
                           whirl.segments,
                           whirl.scale)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, configuration)

Update a Whirl by changing its observable with the given `whirl` and `configuration`.
"""
function update(whirl::Whirl, configuration::Biquaternion)
    whirl.configuration = configuration
    value = constructwhirl(whirl.points,
                           whirl.gauge1,
                           whirl.gauge2,
                           whirl.configuration,
                           whirl.segments,
                           whirl.scale)
    updatesurface(value, whirl.observable)
end


"""
    update(whirl, color)

Update a Whirl by changing its observable with the given `whirl` and `color`.
"""
function update(whirl::Whirl, color::Makie.RGBA{FixedPointNumbers.Normed{UInt8, 8}})
    whirl.color[] = fill(color, length(whirl.points), whirl.segments)
end
