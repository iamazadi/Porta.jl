η = [1.0 0.0 0.0 0.0;
     0.0 -1.0 0.0 0.0;
     0.0 0.0 -1.0 0.0;
     0.0 0.0 0.0 -1.0]
tetrad = Tetrad(η)
u = 𝕍(rand(4), tetrad = tetrad)
_u = 𝕍(-u.a.a, tetrad = tetrad)
v = 𝕍(rand(4))
w = 𝕍(ℝ⁴(rand(4)))
tetrad2 = Tetrad(ℝ⁴(-1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, 1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, 1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, 1.0))
x = 𝕍(u.a.a, tetrad = tetrad2)
zero = 𝕍(0.0, 0.0, 0.0, 0.0)
a = rand()
b = rand()

# test the inequality of the same vector with different bases
@test !isapprox(x, u)

@test isapprox(u + (v + w), (u + v) + w) # 1. associativity of addition
@test isapprox(u + v, v + u) # 2. commutativity of addition
@test isapprox(0 * u, 0 * v) # 3. the zero vector I
@test isapprox(0 * u, zero) # 3. the zero vector II
@test isapprox(-u, _u) # 4. the inverse element
@test isapprox(a * (u + v), a * u + a * v) # 5. distributivity Ι
@test isapprox((a + b) * u, a * u + b * u) # 6. distributivity ΙΙ
@test isapprox(a * (b * u), (a * b) * u) # 7. associativity of scalar multiplication
@test isapprox(1u, u) # 8. the unit scalar 1

## inner product tests
@test isapprox(dot(u, v), dot(v, u))
@test isapprox(dot(a * u, v), a * dot(u, v))
@test isapprox(dot(u + v, w), dot(u, w) + dot(v, w))

u⁰, u¹, u², u³ = vec(u)
v⁰, v¹, v², v³ = vec(v)
@test isapprox(u⁰ * v⁰ - u¹ * v¹ - u² * v² - u³ * v³, dot(u, v))

## Lorentz norm
@test isapprox(lorentznorm(u), u⁰^2 - u¹^2 - u²^2 - u³^2)
@test isapprox(0.5 * (lorentznorm(u + v) - lorentznorm(u) - lorentznorm(v)), dot(u, v))

u¹, u², u³ = rand(3)
u⁰ = 1.1 * √(u¹^2 + u²^2 + u³^2)
u = 𝕍(u⁰, u¹, u², u³)
@test istimelike(u)
@test iscausal(u)

u⁰ = 0.9 * √(u¹^2 + u²^2 + u³^2)
u = 𝕍(u⁰, u¹, u², u³)
@test isspacelike(u)
@test !iscausal(u)

u¹, u², u³ = rand(3)
u⁰ = √(u¹^2 + u²^2 + u³^2)
u = 𝕍(u⁰, u¹, u², u³)
@test isnull(u)

# u and v are orthogonal if both are null and proportional
u¹, u², u³ = rand(3)
u⁰ = √(u¹^2 + u²^2 + u³^2)
u = 𝕍(u⁰, u¹, u², u³)
v = rand() * u
@test isapprox(dot(u, v), 0.0, atol = TOLERANCE)
