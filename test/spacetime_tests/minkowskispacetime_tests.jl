tetrad = Tetrad(ℝ⁴(1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, -1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, -1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, -1.0))
zero = 𝕍(ℝ⁴(0.0, 0.0, 0.0, 0.0), tetrad = tetrad)
origin = 𝕍(ℝ⁴(rand(4)), tetrad = tetrad)
point1 = 𝕍(ℝ⁴(rand(4)), tetrad = tetrad)
point2 = 𝕍(ℝ⁴(rand(4)), tetrad = tetrad)
point3 = 𝕍(ℝ⁴(rand(4)), tetrad = tetrad)
p = 𝕄(origin, point1, tetrad)
q = 𝕄(origin, point2, tetrad)
r = 𝕄(origin, point3, tetrad)

@test isapprox(vec(p, q) + vec(q, r), vec(p, r))
@test isapprox(vec(p, p), zero)
@test isapprox(vec(p, q), -vec(q, p))

p⁰, p¹, p², p³ = vec(p)
q⁰, q¹, q², q³ = vec(q)
@test isapprox(Φ(p, q), (q⁰ - p⁰)^2 - (q¹ - p¹)^2 - (q² - p²)^2 - (q³ - p³)^2)


@test size(mat(p)) == (2, 2)


p = 𝕄(origin, [rand() * exp(rand() * im) rand() * exp(rand() * im); rand() * exp(rand() * im) rand() * exp(rand() * im)], tetrad)
@test typeof(p) <: 𝕄


atol = 1e-4
@test isapprox(p, p, atol = atol)
@test !isapprox(p, r, atol = atol)