import Observables
import Makie


q1 = Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
scene = Makie.Scene()
height = rand()
radius = rand()
segments = rand(5:10)
color = Makie.RGBAf(rand(4)...)
transparency = false
cylinder = Cylinder(q1,
                    scene,
                    height = height,
                    radius = radius,
                    segments = segments,
                    color = color,
                    transparency = transparency)
q2 = q1 * Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
value1 = getsurface(cylinder.observable, segments)
update(cylinder, q2)
value2 = getsurface(cylinder.observable, segments)

@test isapprox(cylinder.q, q2)
@test isapprox(value1, value2) == false

color1 = Makie.RGBAf(rand(4)...)
update(cylinder, color1)
color2 = Observables.to_value(cylinder.color)[1] # Select element 1

@test isapprox(color1, color2)
