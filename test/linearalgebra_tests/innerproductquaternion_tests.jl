u, v, v₁, v₂ = ℍ(rand(4)), ℍ(rand(4)), ℍ(rand(4)), ℍ(rand(4))
α, β = rand(2)
zero = ℍ(fill(0, 4))


@test isapprox(dot(u, v), conj(dot(v, u))) # conjugate symmetric
@test isapprox(dot(u, α * v₁ + β * v₂), α * dot(u, v₁) + β * dot(u, v₂)) # linear
@test abs(dot(u, u)) ≥ 0 && isapprox(abs(dot(u, zero)), 0) # positive semidefinite
