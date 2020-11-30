q = Quaternion(1, 0, 0, 0)
r = λmap(q)
p = compressedλmap(q)

@test isapprox(r, ℝ³(1, 0, 0))
@test isapprox(p, ℝ³(0.7615941559557649, 0, 0))
