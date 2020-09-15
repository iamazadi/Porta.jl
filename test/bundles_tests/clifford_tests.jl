plane = ComplexPlane(Quaternion(rand(), ℝ³(rand(3)))) # Construct a unit Quaternion
w, z = plane.z₁, plane.z₂
B = Complex(10rand(), 10rand())
clifford = Clifford(w, z, B)


@test typeof(clifford.total) <: S³
@test typeof(clifford.base) <: S²
@test isapprox(clifford.total, plane)


cl = ComplexLine(100rand() + im * 100rand())
q = σmap(cl)
h = τmap(cl)

@test typeof(q) <: S³
@test typeof(q) <: S³


q = Quaternion(rand() * 2pi, normalize(ℝ³(rand(3))))
c = U1(rand() * 2pi - pi)
h = S¹action(q, c)

@test typeof(h) <: S³
@test isapprox(norm(q), norm(h))
