import Observables
import AbstractPlotting


scene = AbstractPlotting.Scene()
number = rand(5:10)
points = [Geographic(rand() * 2pi - pi, rand() * pi - pi / 2) for i in 1:number]
top = U1(rand() * 2pi - pi)
bottom = U1(rand() * 2pi - pi)
s3rotation = Quaternion(rand() * 2pi - pi, ℝ³(rand(3)))
config = Biquaternion(Quaternion(rand() * 2pi - pi, ℝ³(rand(3))), ℝ³(rand(3)))
segments = rand(5:10)
color = AbstractPlotting.RGBAf0(rand(4)...)
transparency = rand(1:2) == 1 ? true : false
whirl = Whirl(scene,
              points,
              top = top,
              bottom = bottom,
              s3rotation = s3rotation,
              config = config,
              segments = segments,
              color = color,
              transparency = transparency)


## update points

points2 = [Geographic(rand() * 2pi - pi, rand() * pi - pi / 2) for i in 1:number]
update(whirl, points2)

@test isapprox(whirl.points, points2)

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
