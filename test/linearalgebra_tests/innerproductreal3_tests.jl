u, v, v₁, v₂ = ℝ³(rand(3)), ℝ³(rand(3)), ℝ³(rand(3)), ℝ³(rand(3))
α, β = rand(2)
zero = ℝ³([0.0; 0.0; 0.0])


@test isapprox(dot(u, v), dot(v, u)) # symmetric
@test isapprox(dot(u, α * v₁ + β * v₂), α * dot(u, v₁) + β * dot(u, v₂)) # linear
@test dot(u, u) ≥ 0 && isapprox(dot(u, zero), 0) # positive semidefinite
