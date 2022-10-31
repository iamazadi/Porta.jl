import Observables
import Makie


export Fiber
export update


"""
    Represents a Hopf fiber.

fields: point, s2tos2map, s2tos3map, radius, top, bottom, s3rotation, config, segments, color,
observable and scale.
"""
mutable struct Fiber <: Sprite
    point::S²
    s2tos3map::Any
    s2tos2map::Any
    radius::Float64
    top::S¹
    bottom::S¹
    s3rotation::S³
    config::Biquaternion
    segments::Int
    color::Observables.Observable{Array{Makie.ColorTypes.RGBA{Float32},2}}
    observable::Tuple{Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}},
                      Observables.Observable{Array{Float64,2}}}
    scale::Real
end


"""
    Fiber(scene,
          point,
          s2tos3map,
          s2tos2map,
          [radius, [top, [bottom, [s3rotation, [config, [segments, [color, [transparency
           [,scale]]]]]]]]])

Construct a Hopf fiber with the given `scene`, `points` in the base space, `s2tos3map`,
`s2tos2map`, `radius`, `top`, `bottom`, S³ rotation `s3rotation`, configuration `config`,
the number of `segments`, `color`, `transparency` and `scale`.
"""
function Fiber(scene::Makie.Scene,
               point::S²,
               s2tos3map,
               s2tos2map;
               radius::Float64 = 0.02,
               top::S¹ = U1(-pi),
               bottom::S¹ = U1(pi),
               s3rotation::S³ = Quaternion(1, 0, 0, 0),
               config::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
               segments::Int = 36,
               color::Makie.RGBAf = Makie.RGBAf(1.0, 0.2705, 0.0, 0.5),
               transparency::Bool = false,
               scale::Real = 1.0)
    fiber = constructfiber(point,
                           s2tos3map,
                           s2tos2map,
                           radius = radius,
                           top = top,
                           bottom = bottom,
                           s3rotation = s3rotation,
                           config = config,
                           segments = segments,
                           scale = scale)
    colorarray = Observables.Observable(fill(color, size(fiber)...))
    observable = buildsurface(scene, fiber, colorarray, transparency = transparency)
    Fiber(point, s2tos3map, s2tos2map, radius, top, bottom, s3rotation, config, segments,
          colorarray, observable, scale)
end


"""
    update(fiber, points)

Update a Fiber by changing its observable with the given `fiber` and `points` in the base
space.
"""
function update(fiber::Fiber, point::S²)
    fiber.point = point
    value = constructfiber(fiber.point,
                           fiber.s2tos3map,
                           fiber.s2tos2map,
                           radius = fiber.radius,
                           top = fiber.top,
                           bottom = fiber.bottom,
                           s3rotation = fiber.s3rotation,
                           config = fiber.config,
                           segments = fiber.segments,
                           scale = fiber.scale)
    updatesurface(value, fiber.observable)
end


"""
    update(fiber, s2tos3map, s2tos2map)

Update a Fiber by changing its observable with the given `fiber` and map `s2tos3map` from
the base space into the total space, f: S² → S³, and also the map `s2tos2map` from the base
space into itself, f: S² → S².
"""
function update(fiber::Fiber, s2tos3map::Any, s2tos2map::Any)
    fiber.s2tos3map = s2tos3map
    fiber.s2tos2map = s2tos2map
    value = constructfiber(fiber.point,
                           fiber.s2tos3map,
                           fiber.s2tos2map,
                           radius = fiber.radius,
                           top = fiber.top,
                           bottom = fiber.bottom,
                           s3rotation = fiber.s3rotation,
                           config = fiber.config,
                           segments = fiber.segments,
                           scale = fiber.scale)
    updatesurface(value, fiber.observable)
end


"""
    update(fiber, top, bottom)

Update a Fiber by changing its observable with the given `fiber`, `top` and `bottom`.
"""
function update(fiber::Fiber, top::S¹, bottom::S¹)
    fiber.top = top
    fiber.bottom = bottom
    value = constructfiber(fiber.point,
                           fiber.s2tos3map,
                           fiber.s2tos2map,
                           radius = fiber.radius,
                           top = fiber.top,
                           bottom = fiber.bottom,
                           s3rotation = fiber.s3rotation,
                           config = fiber.config,
                           segments = fiber.segments,
                           scale = fiber.scale)
    updatesurface(value, fiber.observable)
end


"""
    update(fiber, s3rotation)

Update a Fiber by changing its observable with the given `fiber` and S³ rotation
`s3rotation`.
"""
function update(fiber::Fiber, s3rotation::S³)
    fiber.s3rotation = s3rotation
    value = constructfiber(fiber.point,
                           fiber.s2tos3map,
                           fiber.s2tos2map,
                           radius = fiber.radius,
                           top = fiber.top,
                           bottom = fiber.bottom,
                           s3rotation = fiber.s3rotation,
                           config = fiber.config,
                           segments = fiber.segments,
                           scale = fiber.scale)
    updatesurface(value, fiber.observable)
end


"""
    update(fiber, config)

Update a Fiber by changing its observable with the given `fiber` and configuration `config`.
"""
function update(fiber::Fiber, config::Biquaternion)
    fiber.config = config
    value = constructfiber(fiber.point,
                           fiber.s2tos3map,
                           fiber.s2tos2map,
                           radius = fiber.radius,
                           top = fiber.top,
                           bottom = fiber.bottom,
                           s3rotation = fiber.s3rotation,
                           config = fiber.config,
                           segments = fiber.segments,
                           scale = fiber.scale)
    updatesurface(value, fiber.observable)
end


"""
    update(fiber, color)

Update a Fiber by changing its observable with the given `fiber` and `color`.
"""
function update(fiber::Fiber, color::Makie.RGBAf)
    fiber.color[] = fill(color, fiber.segments, 10)
end


"""
    update(fiber, point, s3rotation, radius, top, bottom)

Update a Fiber by constructing it from scratch with the given base space `point`, S³
rotation `s3rotation`, sectional `radius`, beginning U(1) action `top` and ending U(1) action `bottom`.
"""
function update(fiber::Fiber, point::S², s3rotation::S³, radius::Float64, top::S¹, bottom::S¹)
    fiber.point = point
    fiber.s3rotation = s3rotation
    fiber.radius = radius
    fiber.top = top
    fiber.bottom = bottom
    value = constructfiber(fiber.point,
                           fiber.s2tos3map,
                           fiber.s2tos2map,
                           radius = fiber.radius,
                           top = fiber.top,
                           bottom = fiber.bottom,
                           s3rotation = fiber.s3rotation,
                           config = fiber.config,
                           segments = fiber.segments,
                           scale = fiber.scale)
    updatesurface(value, fiber.observable)
end
