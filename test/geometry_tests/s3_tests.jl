q = Quaternion(rand() * 2pi, normalize(ℝ³(rand(3))))
cp = ComplexPlane(q)
s = SU2(cp)
θ = rand() * pi
u = normalize(ℝ³(rand(3)))
g = Quaternion(θ, u)

@test isapprox(cp, s)
@test isapprox(cp, q)
@test isapprox(g * q, g * Quaternion(s))
