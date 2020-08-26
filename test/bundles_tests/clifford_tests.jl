plane = ComplexPlane(Quaternion(rand(), ℝ³(rand(3)))) # Construct a unit Quaternion
w, z = plane.z₁, plane.z₂
B = Complex(10rand(), 10rand())
clifford = Clifford(w, z, B)


@test typeof(clifford.total) <: S³
@test typeof(clifford.base) <: S²
@test isapprox(clifford.total, plane)
