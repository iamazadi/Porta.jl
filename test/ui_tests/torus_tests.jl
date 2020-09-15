import Observables
import AbstractPlotting


q1 = Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
scene = AbstractPlotting.Scene()
r = 1 + rand()
R = 10 + rand()
segments = rand(5:10)
color = AbstractPlotting.RGBAf0(rand(4)...)
transparency = false
torus = Torus(q1,
              scene,
              r = r,
              R = R,
              segments = segments,
              color = color,
              transparency = transparency)
q2 = q1 * Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
value1 = getsurface(torus.observable, segments)
update(torus, q2)
value2 = getsurface(torus.observable, segments)

@test isapprox(torus.q, q2)
@test isapprox(value1, value2) == false
