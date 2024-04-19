# the multiplication table
table = [elI eli elj elk;
         eli -elI elk -elj;
         elj -elk -elI eli;
         elk elj -eli -elI]
for i in 1:4
    for j in 1:4
        basis1 = table[1:2, 2i - 1:2i]
        basis2 = table[1:2, 2j - 1:2j]
        @test isapprox(basis1 * basis2, table[2i - 1:2i, 2j - 1:2j])
    end
end


## The space of abstract inner products

u = Quaternion(rand(4))
v = Quaternion(rand(4))
v₁ = Quaternion(rand(4))
v₂ = Quaternion(rand(4))
z = Quaternion(0.0, 0.0, 0.0, 0.0)
α, β = rand(2)
@test isapprox(dot(u, v), dot(v, u)) # Symmetric
@test isapprox(dot(u, α * v₁ + β * v₂), α * dot(u, v₁) + β * dot(u, v₂)) # Linear
@test dot(u, u) ≥ 0 # Positive semidefinite I
@test isapprox(dot(z, z), 0) # positive semidefinite II


q = Quaternion(rand(4))
@test isapprox(conj(conj(q)), q)
@test isapprox(mat(conj(q)), elI .* q.a - eli .* q.b - elj .* q.c - elk .* q.d)
@test isapprox(det(q), q.a^2 + q.b^2 + q.c^2 + q.d^2)
h = q * conj(q)
@test isapprox(mat(h), elI .* (q.a^2 + q.b^2 + q.c^2 + q.d^2))

q = Quaternion(normalize(ℝ⁴(rand(4))))
@test isapprox(norm(q), 1.0)
@test isapprox(norm(q), q.a^2 + q.b^2 + q.c^2 + q.d^2)


g = Quaternion(rand(4))
q = Quaternion(rand(4))
a = real(g)
v = imag(g)
a′ = real(q)
v′ = imag(q)
@test isapprox(g + q, Quaternion(a + a′, vec(v + v′)...))
@test isapprox(g * q, Quaternion(a * a′ - dot(v, v′), vec(a′ * v + a * v′ + cross(v, v′))...))


ψ = 2π
u = normalize(ℝ³(rand(3)))
g = Quaternion(0.0, u)
q = Quaternion(ψ, u)
@test isapprox(g, -q) # ψ ↦ ψ + 2π


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

conjugate = Quaternion(transpose(R) * mat4(q) * R)
@test isapprox(conj(q), conjugate)

# |q| = 1
@test isapprox(norm(q), 1)

# K₁ = RᵀJ₃R
@test isapprox(K(1), transpose(R) * J(3) * R, atol = TOLERANCE)
# K₂ = RᵀJ₁R
@test isapprox(K(2), transpose(R) * J(1) * R, atol = TOLERANCE)
# K₃ = RᵀJ₂R
@test isapprox(K(3), transpose(R) * J(2) * R, atol = TOLERANCE)

# Check to see if the following vectors form a basis for ℝ⁴
ξ = Quaternion(rand(4))

# <ξ, ξ> = 1
@test isapprox(norm(ξ)^2, abs(dot(ξ, ξ)), atol = TOLERANCE)
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


# vectorial quaternions
v = 𝕍(0.0, rand(3)...)
q = Quaternion(v)
M = mat(q)
T, X, Y, Z = vec(v)
N = [im * Z im * X - Y; im * X + Y -im * Z]
@test isapprox(M, N)


# spin-vectors to quaternions
timesign = rand([1, -1])
ζ = (2rand() - 1) * exp(im * rand() * 2π)
v = SpinVector(ζ, timesign)
q = Quaternion(v)
@test isapprox(ℝ³(v), imag(q))