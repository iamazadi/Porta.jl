# v ∈ S³
v = normalize(ℍ(rand(4)))
# constants c₁, c₂, c₃ ∈ ℝ
c₁, c₂, c₃ = rand(3)
# a ∈ TᵥS³ in terms of the basis {K₁v, K₂v, K₃v} for TᵥS³
a = c₁ * (K(1) * v) + c₂ * (K(2)* v) + c₃ * (K(3) * v)

zerovector = ℝ³(0.0, 0.0, 0.0)

# Check if some vector in the horizontal subspace is not in the kernel of the pushforward by π
@test !isapprox(zerovector, π✳(Dualquaternion(v, K(1) * v)))
@test !isapprox(zerovector, π✳(Dualquaternion(v, K(2) * v)))
# Check if some vector in the vertical subspace is in the kernel of the pushforward by π
@test isapprox(zerovector, π✳(Dualquaternion(v, K(3) * v)))
@test isapprox(π✳(Dualquaternion(v, c₁ * (K(1) * v) + c₂ * (K(2)* v))), π✳(Dualquaternion(v, a)))

θ = rand() * 2π
# verify that using different coordinates yields the same result
@test isapprox(Φ(θ, v), Φ(θ, ℝ⁴(vec(v))))
@test isapprox(G(θ, v), G(θ, ℝ⁴(vec(v))))
@test isapprox(G(θ, v), Φ(θ, v))
@test isapprox(hopfmap(v), hopfmap(ℝ⁴(vec(v))))


α = rand()
# Check if some vector in the vertical subspace is in the kernel of the pushforward by π
@test isapprox(zerovector, π✳(Dualquaternion(v, ver(v, α))), atol = TOLERANCE)

a, b, c, d = vec(v)
z₁ = a + im * c
z₂ = b + im * d
z = [z₁; z₂]
ϵ = 1e-8
_tolerance = 1e-4
# v = (x₁, x₂, y₁, y₂)
# z = (z₁, z₂) = (x₁, x₂) + 𝑖 (y₁, y₂)
# [d/dθ(ℯⁱᶿz)]_(θ=0) = iℯⁱᶿz|_(θ=0) = 𝑖z
# Check if some tangent vector to the curve of points generated by the action, at the identity of the action, is 𝑖z
@test isapprox(ℍ(im .* z), (Φ(ϵ, v) - Φ(0, v)) * (1 / ϵ), atol = _tolerance)
# Check if some tangent vector to the curve of points generated by the action, at the identity of the action, is in the vertical space
@test isapprox(zerovector, π✳(Dualquaternion(v, (Φ(ϵ, v) - Φ(0, v)) * (1 / ϵ))), atol = 10TOLERANCE)

# [d/dθ(G_θ(v))]_(θ=0) = [d/dθ(G_θ)]_(θ=0)(v) = (-y₁, -y₂, x₁, x₂)
# Check if some tangent vector to the curve of points generated by the action, at the identity of the action, is (-y₁, -y₂, x₁, x₂)
@test isapprox(ℍ(-vec(v)[3], -vec(v)[4], vec(v)[1], vec(v)[2]), (G(ϵ, v) - G(0, v)) * (1 / ϵ), atol = TOLERANCE)
# Check if some tangent vector to the curve of points generated by the action, at the identity of the action, is in the vertical space
@test isapprox(zerovector, π✳(Dualquaternion(v, (G(ϵ, v) - G(0, v)) * (1 / ϵ))), atol = 10TOLERANCE)

## Sections of the Hpf bundle

p = normalize(ℝ³(rand(3)))
q = σmap(p)
g = τmap(p)

@test isapprox(norm(q), 1)
@test isapprox(norm(g), 1)

## The Hopf map

q = normalize(ℍ(rand(4)))
p = πmap(q)

@test isapprox(norm(p), 1)


## Connection 1-forms
ϕ = rand()
θ = rand()
q = ℍ(exp(ϕ * K(1) + θ * K(2)))
ϵ = 1e-5
u, v, a = calculateconnection(q, ϵ = ϵ)

@test typeof(u) <: ℝ⁴
@test typeof(v) <: ℝ⁴
@test typeof(a) <: Complex
@test isapprox(real(a), 0.0)

ϕ = rand() * 2π
θ = rand() * 2π
α = rand() * 2π
γ = rand() * 2π
point =  ℍ(exp(ϕ * K(1) + θ * K(2)) * exp(α * K(3)))
X = ℍ(exp((ϕ + ϵ * sin(γ)) * K(1) + (θ + ϵ * cos(γ)) * K(2)) * exp(α * K(3))) - point
X = normalize(ℝ⁴(vec(X)))
v, a = calculateconnection(point, X, ϵ = ϵ)
@test typeof(v) <: ℝ⁴
@test typeof(a) <: Complex
@test isapprox(real(a), 0.0)