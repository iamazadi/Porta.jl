import Observables
import AbstractPlotting


## getsurface and buildsurface


scene = AbstractPlotting.Scene()
transparency = false
segments = 36
radius = 1 + rand()
value1 = constructsphere(q, radius, segments = segments)
color = fill(AbstractPlotting.RGBAf0(rand(4)...), segments, segments)
observable = buildsurface(scene, value1, color, transparency = transparency)
value2 = getsurface(observable, segments)

@test typeof(observable) == Tuple{Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}}}
@test typeof(value2) == Array{ℝ³,2}
@test isapprox(value1, value2, atol = TOLERANCE)


## builsurface with "observable" color array argument


observablecolor = Observables.Observable(fill(AbstractPlotting.RGBAf0(rand(4)...),
                                              segments,
                                              segments))
observable = buildsurface(scene, value1, observablecolor, transparency = transparency)
value2 = getsurface(observable, segments)

@test typeof(observable) == Tuple{Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}}}
@test typeof(value2) == Array{ℝ³,2}
@test isapprox(value1, value2, atol = TOLERANCE)


## updatesurfce


value2 = map(x -> 2x, value1)
updatesurface(value2, observable)
value3 = getsurface(observable, segments)

@test isapprox(value1, value2, atol = TOLERANCE) == false
@test isapprox(value2, value3, atol = TOLERANCE)
