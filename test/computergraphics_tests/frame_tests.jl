import Observables
import Makie
import FileIO


# Map from S² into its upper hemisphere
s2tos2map(b::S²) = begin
    p = Geographic(b)
    r = sqrt((1 - sin(p.θ)) / 2)
    Geographic(p.r, r * cos(p.ϕ), r * sin(p.ϕ))
end


scene = Makie.Scene()
circle = U1(rand() * 2pi - pi)
s3rotation = Quaternion(rand() * 2pi - pi, ℝ³(rand(3)))
config = Biquaternion(Quaternion(rand() * 2pi - pi, ℝ³(rand(3))), ℝ³(rand(3)))
segments = rand(5:10)
color = FileIO.load("../data/basemap_color.png")
transparency = rand(1:2) == 1 ? true : false
s2tos3map = rand() > 0.5 ? σmap : τmap
frame = Frame(scene,
              circle,
              s2tos3map,
              s2tos2map,
              color,
              s3rotation = s3rotation,
              config = config,
              segments = segments,
              transparency = transparency)


## update circle

circle2 = U1(rand() * 2pi - pi)
update(frame, circle2)

@test isapprox(frame.circle, circle2)


## update maps f: S² → S³ and g: S² → S²


s2tos3map = rand() > 0.5 ? σmap : τmap
s2tos2map′(x) = Geographic(0.5 * x.r, 0.5 * x.ϕ, 0.5 * x.θ)
update(frame, s2tos3map, s2tos2map′)
p = Geographic(rand(), rand() * 2pi - pi, rand() * pi - pi / 2)

@test isapprox(frame.s2tos3map(p), s2tos3map(p))
@test isapprox(frame.s2tos2map(p), s2tos2map′(p))


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
