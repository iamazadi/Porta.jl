generate() = 2rand() - 1 + im * (2rand() - 1)
timesign = rand([1; -1])
κ = SpinVector(generate(), generate(), timesign)
ω = SpinVector(generate(), generate(), timesign)
τ = SpinVector(generate(), generate(), timesign)
λ = generate()
μ = generate()
zero = SpinVector([Complex(0.0); Complex(0.0)], timesign)

@test typeof(vec(κ)) <: Vector{Complex}
@test typeof(mat(κ)) <: Matrix{<:Complex}

## The properties of basic operations on the spin-space G
@test(isapprox(λ * (μ * κ), (λ * μ) * κ))
@test(isapprox(1κ, κ))
@test(isapprox((0κ), zero))
@test(isapprox((-1) * κ, -κ))
@test(isapprox((λ + μ) * κ, (λ * κ) + (μ * κ)))
@test(isapprox(κ + ω, ω + κ))
@test(isapprox((κ + ω) + τ, κ + (ω + τ)))
@test(isapprox(λ * (κ + ω), (λ * κ) + (λ * ω)))
@test(isapprox(dot(κ, ω), -dot(ω, κ)))
@test(isapprox(λ * dot(κ, ω), dot(λ * κ, ω)))
@test(isapprox(dot(κ + ω, τ), dot(κ, τ) + dot(ω, τ)))
@test(isapprox((dot(κ, ω) * τ + dot(ω, τ) * κ + dot(τ, κ) * ω), zero))
@test(isapprox(dot(κ, κ), Complex(0)))
