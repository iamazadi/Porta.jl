q = Quaternion(1, 0, 0, 0)
r = λmap(q)

@test isapprox(r, ℝ³(1, 0, 0))
