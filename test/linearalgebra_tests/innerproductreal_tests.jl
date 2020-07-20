d = rand(1:4)
u, v, v₁, v₂ = rand(d), rand(d), rand(d), rand(d)
α, β = rand(2)
zero = fill(0.0, d)

@test isapprox(dot(u, v), dot(v, u)) # symmetric
@test isapprox(dot(u, α * v₁ + β * v₂), α * dot(u, v₁) + β * dot(u, v₂)) # linear
@test dot(u, u) ≥ 0 && isapprox(dot(u, zero), 0) # positive semidefinite
