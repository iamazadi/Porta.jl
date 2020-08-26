import Observables
import AbstractPlotting


q1 = Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
scene = AbstractPlotting.Scene()
len = 1 + rand()
width = 5
color = [:red, :green, :blue]
transparency = false
triad = Triad(q1,
              scene,
              length = len,
              width = width,
              color = color)
q2 = q1 * Biquaternion(Quaternion(rand(4)), ℝ³(rand(3)))
value1 = Observables.to_value(triad.observable)
update(triad, q2)
value2 = Observables.to_value(triad.observable)

@test isapprox(triad.q, q2)
@test isapprox(value1, value2) == false
