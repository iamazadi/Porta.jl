import GeometryBasics
import Observables
import Makie


export Triad
export update


"""
    Represents a triad.

fields: q, length, width, color and observable.
"""
mutable struct Triad <: Sprite
    q::Biquaternion
    length::Float64
    width::Int
    color::Array{Symbol}
    observable::Observables.Observable
end


"""
    Triad(q, scene)

Construct a Triad with the given configuration `q`, `scene`, and the optional arguments:
`length`, `width` and `color`.
"""
function Triad(q::Biquaternion,
               scene::Makie.LScene;
               length::Float64 = 1.0,
               width::Int = 5,
               color::Array{Symbol} = [:red, :green, :blue])
    triad = constructtriad(q, length = length)
    observable = Observables.Observable(triad)
    array = Makie.@lift begin
        s = map(x -> GeometryBasics.Point3f(vec(x)), $observable)
        [s[1] => s[2], s[3] => s[4], s[5] => s[6]]
    end
    Makie.linesegments!(scene,
                        array,
                        color = color,
                        linewidth = width)
    Triad(q, length, width, color, observable)
end


"""
    update(triad, q)

Update a Triad by changing its observable with the given `triad` and configuration `q`.
"""
function update(triad::Triad, q::Biquaternion)
    triad.q = q
    triad.observable[] = constructtriad(triad.q, length = triad.length)
end
