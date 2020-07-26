cl = ComplexLine(100rand() + im * 100rand())
s = Spherical(cl)
c = Cartesian(cl)
g = Geographic(cl)
r3 = ℝ³(1, 0, 0)


@test isapprox(cl, ComplexLine(s))
@test isapprox(cl, ComplexLine(c))
@test isapprox(cl, ComplexLine(g))
@test isapprox(s, Spherical(c))
@test isapprox(s, Spherical(g))
@test isapprox(c, Cartesian(s))
@test isapprox(c, Cartesian(g))
@test isapprox(g, Geographic(s))
@test isapprox(g, Geographic(c))

@test isapprox(ℝ³(cl), ℝ³(c))
@test isapprox(ComplexLine(r3), ComplexLine(Cartesian(r3)))
