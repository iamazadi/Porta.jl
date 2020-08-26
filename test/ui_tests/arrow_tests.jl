import Observables
import AbstractPlotting


scene = AbstractPlotting.Scene()
len = 1 + rand()
width = 3
color = :gold
transparency = false
tail, head = ℝ³(rand(3)), ℝ³(rand(3))
arrow = Arrow(tail,
              head,
              scene,
              width = width,
              color = color)
tail1 = Observables.to_value(arrow.tail)[1]
head1 = Observables.to_value(arrow.head)[1]
tail, head = ℝ³(rand(3)), ℝ³(rand(3))
update(arrow, tail, head)
tail2 = Observables.to_value(arrow.tail)[1]
head2 = Observables.to_value(arrow.head)[1]

@test isapprox(tail1, tail2) == false
@test isapprox(head1, head2) == false
