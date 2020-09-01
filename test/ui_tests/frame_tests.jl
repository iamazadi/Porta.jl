import Observables
import AbstractPlotting
import FileIO


scene = AbstractPlotting.Scene()
circle = U1(rand() * 2pi - pi)
s3rotation = Quaternion(rand() * 2pi - pi, ℝ³(rand(3)))
config = Biquaternion(Quaternion(rand() * 2pi - pi, ℝ³(rand(3))), ℝ³(rand(3)))
segments = rand(5:10)
color = FileIO.load("data/basemap90grid.png")
transparency = rand(1:2) == 1 ? true : false
frame = Frame(scene,
              circle,
              color,
              s3rotation = s3rotation,
              config = config,
              segments = segments,
              transparency = transparency)


## update circle

circle2 = U1(rand() * 2pi - pi)
update(frame, circle2)

@test isapprox(frame.circle, circle2)


## update S³ rotation

s3rotation2 = Quaternion(rand() * 2pi - pi, ℝ³(rand(3)))
update(frame, s3rotation2)

@test isapprox(frame.s3rotation, s3rotation2)

## update configuration

config2 = config * Biquaternion(Quaternion(rand() * 2pi - pi, ℝ³(rand(3))), ℝ³(rand(3)))
value1 = getsurface(frame.observable, frame.segments)
update(frame, config2)
value2 = getsurface(frame.observable, frame.segments)

@test isapprox(frame.config, config2)
@test isapprox(value1, value2) == false
