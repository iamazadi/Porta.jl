import FileIO
import Observables
import Makie


## getsurface and buildsurface


scene = Makie.Scene()
transparency = false
segments = rand(5:10)
radius = 1 + rand()
value1 = constructsphere(q, radius, segments = segments)
color = fill(Makie.RGBAf(rand(4)...), segments, segments)
observable = buildsurface(scene, value1, color, transparency = transparency)
value2 = getsurface(observable, segments)

@test typeof(observable) == Tuple{Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}}}
@test typeof(value2) == Array{ℝ³,2}
@test isapprox(value1, value2, atol = TOLERANCE)


## getsurface with different segments in the coordinate chart axes


# Map from S² into its upper hemisphere
s2tos2map(b::S²) = begin
    p = Geographic(b)
    r = sqrt((1 - sin(p.θ)) / 2)
    Geographic(p.r, r * cos(p.ϕ), r * sin(p.ϕ))
end


number = rand(5:10)
points = [Geographic(rand(), rand() * 2pi - pi, rand() * pi - pi / 2) for i in 1:number]
top = U1(rand() * 2pi - pi)
bottom = U1(rand() * 2pi - pi)
s3rotation = Quaternion(rand() * 2pi - pi, ℝ³(rand(3)))
config = Biquaternion(Quaternion(rand() * 2pi - pi, ℝ³(rand(3))), ℝ³(rand(3)))
segments = rand(5:10)
s2tos3map = rand() > 0.5 ? σmap : τmap
value1 = constructwhirl(points,
                        s2tos3map,
                        s2tos2map,
                        top = top,
                        bottom = bottom,
                        s3rotation = s3rotation,
                        config = config,
                        segments = segments)

color = fill(Makie.RGBAf(rand(4)...), segments, number)
transparency = rand(1:2) == 1 ? true : false
observable = buildsurface(scene, value1, color, transparency = transparency)
value2 = getsurface(observable, segments, number)

@test typeof(observable) == Tuple{Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}}}
@test typeof(value2) == Array{ℝ³,2}
@test isapprox(value1, value2, atol = TOLERANCE)

## builsurface with "observable" color array argument


observablecolor = Observables.Observable(fill(Makie.RGBAf(rand(4)...),
                                              segments,
                                              segments))
segments = rand(5:10)
radius = 1 + rand()
value1 = constructsphere(q, radius, segments = segments)
observable = buildsurface(scene, value1, observablecolor, transparency = transparency)
value2 = getsurface(observable, segments)

@test typeof(observable) == Tuple{Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}},
                                  Observables.Observable{Array{Float64,2}}}
@test typeof(value2) == Array{ℝ³,2}
@test isapprox(value1, value2, atol = TOLERANCE)


## builsurface with image as color


color = FileIO.load("../data/basemap_color.png")
segments = rand(5:10)
radius = 1 + rand()
value1 = constructsphere(q, radius, segments = segments)
observable = buildsurface(scene, value1, color, transparency = transparency)
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
