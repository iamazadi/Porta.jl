import Observables
import AbstractPlotting


# Map from S² into its upper hemisphere
s2tos2map(b::S²) = begin
    p = Geographic(b)
    r = sqrt((1 - sin(p.θ)) / 2)
    Geographic(p.r, r * cos(p.ϕ), r * sin(p.ϕ))
end


scene = AbstractPlotting.Scene()
number = rand(5:10)
points = [Geographic(rand(), rand() * 2pi - pi, rand() * pi - pi / 2) for i in 1:number]
top = U1(rand() * 2pi - pi)
bottom = U1(rand() * 2pi - pi)
s3rotation = Quaternion(rand() * 2pi - pi, ℝ³(rand(3)))
config = Biquaternion(Quaternion(rand() * 2pi - pi, ℝ³(rand(3))), ℝ³(rand(3)))
segments = rand(5:10)
color = AbstractPlotting.RGBAf0(rand(4)...)
transparency = rand(1:2) == 1 ? true : false
s2tos3map = rand() > 0.5 ? σmap : τmap
whirl = Whirl(scene,
              points,
              s2tos3map,
              s2tos2map,
              top = top,
              bottom = bottom,
              s3rotation = s3rotation,
              config = config,
              segments = segments,
              color = color,
              transparency = transparency)


## update points

points2 = [Geographic(rand(), rand() * 2pi - pi, rand() * pi - pi / 2) for i in 1:number]
update(whirl, points2)

@test isapprox(whirl.points, points2)


# update maps f: S² → S³ and g: S² → S²


s2tos3map = rand() > 0.5 ? σmap : τmap
s2tos2map′(x) = Geographic(0.5 * x.r, 0.5 * x.ϕ, 0.5 * x.θ)
update(whirl, s2tos3map, s2tos2map′)
p = Geographic(rand(), rand() * 2pi - pi, rand() * pi - pi / 2)

@test isapprox(whirl.s2tos3map(p), s2tos3map(p))
@test isapprox(whirl.s2tos2map(p), s2tos2map′(p))


## update top and bottom

top2 = U1(rand() * 2pi - pi)
bottom2 = U1(rand() * 2pi - pi)
update(whirl, top2, bottom2)

@test isapprox(whirl.top, top2)
@test isapprox(whirl.bottom, bottom2)

## update S³ rotation

s3rotation2 = Quaternion(rand() * 2pi - pi, ℝ³(rand(3)))
update(whirl, s3rotation2)

@test isapprox(whirl.s3rotation, s3rotation2)

## update configuration

config2 = config * Biquaternion(Quaternion(rand() * 2pi - pi, ℝ³(rand(3))), ℝ³(rand(3)))
value1 = getsurface(whirl.observable, whirl.segments, length(whirl.points))
update(whirl, config2)
value2 = getsurface(whirl.observable, whirl.segments, length(whirl.points))

@test isapprox(whirl.config, config2)
@test isapprox(value1, value2) == false
