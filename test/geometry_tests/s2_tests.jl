cl = ComplexLine(100rand() + im * 100rand())
s = Spherical(cl)
c = Cartesian(cl)
g = Geographic(cl)
r3 = normalize(ℝ³(rand(3)))


@test isapprox(cl, ComplexLine(s))
@test isapprox(cl, ComplexLine(c))
@test isapprox(cl, ComplexLine(g))
@test isapprox(s, Spherical(c))
@test isapprox(s, Spherical(g))
@test isapprox(c, Cartesian(s))
@test isapprox(c, Cartesian(g))
@test isapprox(g, Geographic(s))
@test isapprox(g, Geographic(c))
@test isapprox(g, Geographic(Cartesian(ℝ³(Cartesian(g)))))

@test isapprox(ℝ³(cl), ℝ³(c))
@test isapprox(ComplexLine(r3), ComplexLine(Cartesian(r3)))

number = rand(5:10)
a = [Geographic(rand(), rand() * 2pi - pi, rand() * pi - pi / 2,) for i in 1:number]
b = [Geographic(rand(), rand() * 2pi - pi, rand() * pi - pi / 2) for i in 1:number]

@test isapprox(a, a, atol = TOLERANCE)
@test isapprox(a, b, atol = TOLERANCE) == false
