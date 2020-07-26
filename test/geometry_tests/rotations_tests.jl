p = ℝ³(rand(3))
q = Quaternion(rand() * 2pi, normalize(ℝ³(rand(3))))
q₀ = Quaternion(0, normalize(ℝ³(rand(3))))
points = [ℝ³(rand(3)) for i in 1:5]
i = ℝ³(1, 0, 0)
j = ℝ³(0, 1, 0)
k = ℝ³(0, 0, 1)
g = getrotation(i, j)


@test typeof(rotate(p, q)) == typeof(p)
@test isapprox(rotate(p, q₀), p) # rotations with angle zero
@test isapprox(rotate(q, q₀), rotate(q₀, q)) # non-commutativity in multiplication
@test typeof(rotate(points, q)) == typeof(points) # Array input
@test isapprox(g, Quaternion(pi/4, k))
