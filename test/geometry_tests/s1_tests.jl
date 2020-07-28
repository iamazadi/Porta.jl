α₁ = rand() * 2pi - pi
α₂ = rand() * 2pi - pi
u = U1(α₁)
v = U1(α₂)


@test isapprox(angle(u), α₁)
@test isapprox(u * v, v * u)
