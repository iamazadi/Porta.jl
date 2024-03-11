e = Quaternion(ℝ⁴(1.0, 0.0, 0.0, 0.0))
i = Quaternion(0.0, 1.0, 0.0, 0.0)
j = Quaternion(0.0, 0.0, 1.0, 0.0)
k = Quaternion(0.0, 0.0, 0.0, 1.0)

# i² = -1
@test isapprox(i * i, -e)
# j² = -1
@test isapprox(j * j, -e)
# k² = -1
@test isapprox(k * k, -e)
# ij = -ji
@test isapprox(i * j, -(j * i))
# (ij)² = -(ii)(jj)
@test isapprox((i * j) * (i * j), -((i * i) * (j * j)))

θ = rand() * 2π
u = normalize(ℝ³(rand(3)))
q = Quaternion(θ, u)

@test isapprox(conj(conj(q)), q)

# |q| = 1
@test isapprox(norm(q), 1)

# K₁ = RᵀJ₃R
@test isapprox(K(1), transpose(R) * J(3) * R, atol = TOLERANCE)
# K₂ = RᵀJ₁R
@test isapprox(K(2), transpose(R) * J(1) * R, atol = TOLERANCE)
# K₃ = RᵀJ₂R
@test isapprox(K(3), transpose(R) * J(2) * R, atol = TOLERANCE)

# Check to see if the following vectors form a basis for ℝ⁴
ξ = Quaternion(rand(4)...)

# <ξ, K₁ξ> = 0
@test isapprox(0, dot(ξ, K(1) * ξ), atol = TOLERANCE)
# <ξ, K₂ξ> = 0
@test isapprox(0, dot(ξ, K(2) * ξ), atol = TOLERANCE)
# <ξ, K₃ξ> = 0
@test isapprox(0, dot(ξ, K(3) * ξ), atol = TOLERANCE)

for i in 1:3
    for j = 1:3
        if i == j
            continue
        end
        # <Kᵢξ, Kⱼξ> = 0
        @test isapprox(0, dot(K(i) * ξ, K(j) * ξ), atol = TOLERANCE)
        # <ξ, KᵢᵀKⱼξ> = 0
        @test isapprox(0, dot(ξ, transpose(K(i)) * K(j) * ξ), atol = TOLERANCE)
        # <ξ, -KᵢKⱼξ> = 0
        @test isapprox(0, dot(ξ, -K(i) * K(j) * ξ), atol = TOLERANCE)
        for k in 1:3
            if k == i || k == j
                continue
            end
            # ϵᵢⱼₖ is 1 for even permutations, −1 for odd permutations and 0 otherwise.
            ϵ(i, j) = begin
                if i == 1
                    if j == 2
                        return 0
                    else
                        return -1
                    end
                end
                if i == 2
                    if j == 3
                        return -1
                    else
                        return 1
                    end
                end
                if i == 3
                    if j == 1
                        return -1
                    else
                        return 1
                    end
                end
            end
            # <ξ, ϵᵢⱼₖKₖξ> = 0
            @test isapprox(0, dot(ξ, ϵ(i, j) .* K(k) * ξ), atol = TOLERANCE)
        end
    end
end