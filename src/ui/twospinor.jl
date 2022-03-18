import Observables
import Makie


export Twospinor
export update


"""
    Represents a two-component spinor.

fields: point, gauge1, gauge2, configuration, radius, segments1, segments2, color and observable.
"""
mutable struct Twospinor <: Sprite
    point::ComplexPlane
    gauge1::U1
    gauge2::U1
    configuration::Biquaternion
    radius::Float64
    segments1::Int
    segments2::Int
    color::Observables.Observable{Array{Makie.ColorTypes.RGBA{Float32},2}}
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
end


"""
    Twospinor(scene, point; [rotation, [gauge1, [gauge2, [configuration, [radius, [segments1, [segments2, [color, [transparency]]]]]]]]])

Construct a 2-spinor with the given `scene`, `point` in the principal bundle,
`gauge1`, `gauge2`, `configuration`, `radius`, `segments1`, `segments2`, `color` and `transparency`.
"""
function Twospinor(scene::Makie.Scene,
                   point::ComplexPlane;
                   gauge1::U1 = U1(0),
                   gauge2::U1 = U1(2π),
                   configuration::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
                   radius::Float64 = 0.005,
                   segments1::Int = 36,
                   segments2::Int = 12,
                   color::Makie.RGBAf = Makie.RGBAf(1.0, 0.2705, 0.0, 0.5),
                   transparency::Bool = false)
    spinor = constructtwospinor(point, gauge1, gauge2, configuration, radius, segments1, segments2)
    colorarray = Observables.Observable(fill(color, size(spinor)...))
    observable = buildsurface(scene, spinor, colorarray, transparency = transparency)
    Twospinor(point, gauge1, gauge2, configuration, radius, segments1, segments2, colorarray, observable)
end


"""
    update(spinor, point)

Update a Twospinor by changing its observable with the given `spinor` and `point` in the principal bundle.
"""
function update(spinor::Twospinor, point::ComplexPlane)
    spinor.point = point
    value = constructtwospinor(spinor.point,
                               spinor.gauge1,
                               spinor.gauge2,
                               spinor.configuration,
                               spinor.radius,
                               spinor.segments1,
                               spinor.segments2)
    updatesurface(value, spinor.observable)
end


"""
    update(spinor, gauge1, gauge2)

Update a Twospinor by changing its observable with the given `spinor`, `gauge1` and `gauge2`.
"""
function update(spinor::Twospinor, gauge1::U1, gauge2::U1)
    spinor.gauge1 = gauge1
    spinor.gauge2 = gauge2
    value = constructtwospinor(spinor.point,
                               spinor.gauge1,
                               spinor.gauge2,
                               spinor.configuration,
                               spinor.radius,
                               spinor.segments1,
                               spinor.segments2)
    updatesurface(value, spinor.observable)
end


"""
    update(spinor, configuration)

Update a Twospinor by changing its observable with the given `spinor` and `configuration`.
"""
function update(spinor::Twospinor, configuration::Biquaternion)
    spinor.configuration = configuration
    value = constructtwospinor(spinor.point,
                               spinor.gauge1,
                               spinor.gauge2,
                               spinor.configuration,
                               spinor.radius,
                               spinor.segments1,
                               spinor.segments2)
    updatesurface(value, spinor.observable)
end


"""
    update(spinor, color)

Update a Twospinor by changing its observable with the given `spinor` and `color`.
"""
function update(spinor::Twospinor, color::Makie.RGBAf)
    spinor.color[] = fill(color, spinor.segments1, spinor.segments2)
end


"""
    update(spinor, point, gauge1, gauge2)

Update a Twospinor by constructing it from scratch with the given
`point` in the principal bundle, `gauge1` and `gauge2`.
"""
function update(spinor::Twospinor, point::ComplexPlane, gauge1::U1, gauge2::U1)
    spinor.point = point
    spinor.gauge1 = gauge1
    spinor.gauge2 = gauge2
    value = constructtwospinor(spinor.point,
                               spinor.gauge1,
                               spinor.gauge2,
                               spinor.configuration,
                               spinor.radius,
                               spinor.segments1,
                               spinor.segments2)
    updatesurface(value, spinor.observable)
end
