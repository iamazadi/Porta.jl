import Observables
import AbstractPlotting


q1 = Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
scene = AbstractPlotting.Scene()
radius = rand()
segments = rand(30:36)
color = AbstractPlotting.RGBAf0(rand(4)...)
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
