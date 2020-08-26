import GeometryBasics
import Observables
import AbstractPlotting


export Arrow
export update


"""
    Represents an arrow.

fields: width, color, tail and head.
"""
mutable struct Arrow <: Sprite
    width::Int
    color::Symbol
    tail::Observables.Observable
    head::Observables.Observable
end


"""
    Arrow(tail, head, scene, [width, [color]])

Construct an Arrow with the given `tail`, `head`, `scene`, and the optional arguments:
`width` and `color`.
"""
function Arrow(tail::ℝ³,
               head::ℝ³,
               scene::AbstractPlotting.Scene;
               width::Int = 3,
               color::Symbol = :gold)
    tailobservable = Observables.Observable([GeometryBasics.Point3f0(vec(tail)...)])
    headobservable = Observables.Observable([GeometryBasics.Point3f0(vec(head)...)])
    AbstractPlotting.arrows!(scene,
                             tailobservable,
                             headobservable,
                             arrowsize = 0.1,
                             linecolor = color,
                             linewidth = width)
    Arrow(width, color, tailobservable, headobservable)
end


"""
    update(arrow, tail, head)

Update an Arrow by changing its observable with the given `arrow`, `tail` and `head`.
"""
function update(arrow::Arrow, tail::ℝ³, head::ℝ³)
    arrow.tail[] = [GeometryBasics.Point3f0(vec(tail)...)]
    arrow.head[] = [GeometryBasics.Point3f0(vec(head)...)];
end
