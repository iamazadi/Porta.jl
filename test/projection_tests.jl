q = normalize(ℍ(rand(4)))
v = ℝ⁴(vec(q))
u = ℝ³(rand(3))

projection = project(q)
@test typeof(projection) <: ℝ³
@test norm(projection) ≤ 1.0

projection = project(v)
@test typeof(projection) <: ℝ³
@test norm(projection) ≤ 1.0

projection = projectnocompression(q)
@test typeof(projection) <: ℝ³

projection = projectnocompression(v)
@test typeof(projection) <: ℝ³

projection = project(u)
@test typeof(projection) <: ℝ³
@test isapprox(vec(projection)[3], 0.0)