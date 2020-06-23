r = ℝ³(rand(3))
h = ℍ(rand(4))


@test isapprox(norm(normalize(r)), 1)
@test isapprox(norm(normalize(h)), 1)
