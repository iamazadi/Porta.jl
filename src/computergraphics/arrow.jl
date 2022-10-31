import GeometryBasics
import Observables
import Makie


export Arrow
export update


"""
    Represents an arrow.

fields: width, color, tail, head, tailobservable and headobservable.
"""
mutable struct Arrow <: Sprite
    width::Float64
    color::Any
    tail::ℝ³
    head::ℝ³
    tailobservable::Observables.Observable
    headobservable::Observables.Observable
end


"""
    Arrow(tail, head, scene, [width, [color]])

Construct an Arrow with the given `tail`, `head`, `scene`, and the optional arguments:
`width` and `color`.
"""
function Arrow(tail::ℝ³,
               head::ℝ³,
               scene::Makie.Scene;
               width::Float64 = 0.05,
               color::Makie.RGBAf = Makie.RGBAf(1.0, 0.0, 0.0, 1.0),
               transparency::Bool = false)
    tailobservable = Observables.Observable([GeometryBasics.Point3f(vec(tail)...)])
    headobservable = Observables.Observable([GeometryBasics.Point3f(vec(head)...)])
    colorobservable = Observables.Observable(color)
    Makie.arrows!(scene,
                  tailobservable,
                  headobservable,
                  arrowsize = Makie.Vec3f(3width, 3width, 3width),
                  linecolor = colorobservable,
                  arrowcolor = colorobservable,
                  linewidth = width,
                  transparency = transparency)
    Arrow(width, colorobservable, tail, head, tailobservable, headobservable)
end


"""
    update(arrow, tail, head)

Update an Arrow by changing its observable with the given `arrow`, `tail` and `head`.
"""
function update(arrow::Arrow, tail::ℝ³, head::ℝ³)
    arrow.tail = tail
    arrow.head = head
    arrow.tailobservable[] = [GeometryBasics.Point3f(vec(tail)...)]
    arrow.headobservable[] = [GeometryBasics.Point3f(vec(head)...)];
end


"""
    update(arrow, color)

Update an Arrow by changing its observable with the given `color`.
"""
function update(arrow::Arrow, color::Makie.RGBAf)
    arrow.color[] = color
end