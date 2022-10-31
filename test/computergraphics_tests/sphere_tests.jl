import Observables
import Makie


q1 = Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
scene = Makie.Scene()
radius = rand()
segments = rand(5:10)
color = Makie.RGBAf(rand(4)...)
transparency = false
sphere = Sphere(q1,
                scene,
                radius = radius,
                segments = segments,
                color = color,
                transparency = transparency)
q2 = q1 * Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
value1 = getsurface(sphere.observable, segments)
update(sphere, q2)
value2 = getsurface(sphere.observable, segments)

@test isapprox(sphere.q, q2)
@test isapprox(value1, value2) == false

color1 = Makie.RGBAf(rand(4)...)
update(sphere, color1)
color2 = Observables.to_value(sphere.color)[1] # Select element 1

@test isapprox(color1, color2)
