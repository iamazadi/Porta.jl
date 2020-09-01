import GeometryBasics
import Observables
import AbstractPlotting


export Sprite
export getsurface
export buildsurface
export updatesurface


"""
    Represents a shape in a scene.
"""
abstract type Sprite end


"""
    getsurface(observables, segments)

Get the array of points of a 2-surface with the given tuple of `observables` and the number
of `segments`.
"""
function getsurface(observable::Tuple{Observables.Observable{Array{Float64,2}},
                                      Observables.Observable{Array{Float64,2}},
                                      Observables.Observable{Array{Float64,2}}},
                    segments::Int)
    y₁, y₂, y₃ = map(x -> Observables.to_value(x), observable)
    value = Array{ℝ³,2}(undef, segments, segments)
    for i in 1:segments
        for j in 1:segments
            index = (j - 1) * segments + i
            value[i, j] = ℝ³(y₁[index], y₂[index], y₃[index])
        end
    end
    value
end


"""
    getsurface(observables, segments1, segments2)

Get the array of points of a 2-surface with the given tuple of `observables`, and the number
of `segments1` and `segments2`.
"""
function getsurface(observable::Tuple{Observables.Observable{Array{Float64,2}},
                                      Observables.Observable{Array{Float64,2}},
                                      Observables.Observable{Array{Float64,2}}},
                    segments1::Int,
                    segments2::Int)
    y₁, y₂, y₃ = map(x -> Observables.to_value(x), observable)
    value = Array{ℝ³,2}(undef, segments1, segments2)
    for i in 1:segments1
        for j in 1:segments2
            index = (j - 1) * segments1 + i
            value[i, j] = ℝ³(y₁[index], y₂[index], y₃[index])
        end
    end
    value
end


"""
    buildsurface(scene, value, color)

Build a surface with the given `scene`, `value` and `color`. An optional argument is
`transparency`.
"""
function buildsurface(scene::AbstractPlotting.Scene,
                      value::Array{ℝ³,2},
                      color::Array{AbstractPlotting.ColorTypes.RGBA{Float32},2};
                      transparency::Bool = false)
    x = Observables.Observable(map(x -> vec(x)[1] , value))
    y = Observables.Observable(map(x -> vec(x)[2] , value))
    z = Observables.Observable(map(x -> vec(x)[3] , value))
    AbstractPlotting.surface!(scene, x, y, z, color = color, transparency = transparency)
    x, y, z
end


"""
    buildsurface(scene, value, color)

Build a surface with the given `scene`, `value` and `color`. An optional argument is
`transparency`.
"""
function buildsurface(scene::AbstractPlotting.Scene,
                      value::Array{ℝ³,2},
                      color::Observables.Observable{Array{AbstractPlotting.ColorTypes.RGBA{
                                                          Float32},2}};
                      transparency::Bool = false)
    x = Observables.Observable(map(x -> vec(x)[1] , value))
    y = Observables.Observable(map(x -> vec(x)[2] , value))
    z = Observables.Observable(map(x -> vec(x)[3] , value))
    AbstractPlotting.surface!(scene, x, y, z, color = color, transparency = transparency)
    x, y, z
end


"""
    buildsurface(scene, value, color)

Build a surface with the given `scene`, `value` and `color`. An optional argument is
`transparency`.
"""
function buildsurface(scene::AbstractPlotting.Scene,
                      value::Array{ℝ³,2},
                      color::Any;
                      transparency::Bool = false)
    x = Observables.Observable(map(x -> vec(x)[1] , value))
    y = Observables.Observable(map(x -> vec(x)[2] , value))
    z = Observables.Observable(map(x -> vec(x)[3] , value))
    AbstractPlotting.surface!(scene, x, y, z, color = color, transparency = transparency)
    x, y, z
end


"""
    updatesurface(value, observable)

Update a surface with the given `value` and `observable`.
"""
function updatesurface(value::Array{ℝ³,2},
                       observable::Tuple{Observables.Observable{Array{Float64,2}},
                                         Observables.Observable{Array{Float64,2}},
                                         Observables.Observable{Array{Float64,2}}})
    x, y, z = observable
    x[] = map(x -> vec(x)[1], value)
    y[] = map(x -> vec(x)[2], value)
    z[] = map(x -> vec(x)[3], value)
end
