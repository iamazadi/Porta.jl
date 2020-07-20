p = ℝ³(rand(3))
q = ℍ(rand() * 2pi, normalize(ℝ³(rand(3))))
q₀ = ℍ(0, normalize(ℝ³(rand(3))))
orientation = ℍ(2pi * ℝ³(rand(3)))
orientation₀ = ℍ(0 * ℝ³(rand(3)))
points = [ℝ³(rand(3)) for i in 1:5]


@test typeof(rotate(p, q)) == typeof(p)
@test isapprox(rotate(p, q₀), p) # rotations with angle zero
@test isapprox(rotate(q, q₀), rotate(q₀, q)) # non-commutativity in multiplication
@test typeof(rotate(p, orientation)) == typeof(p) # rotations using Euler angles
@test isapprox(rotate(p, orientation₀), p) # rotations using Euler angles zero
@test typeof(rotate(points, q)) == typeof(points) # vector input
