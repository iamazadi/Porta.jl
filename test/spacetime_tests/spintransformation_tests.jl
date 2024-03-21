v = [Complex(rand() + im * rand()) for _ in 1:4]
α, β, γ, δ = v
α = (β * γ + 1.0) / δ
v[1] = α
m = [α β; γ δ]
a = SpinTransformation(α, β, γ, δ)
b = SpinTransformation(v)
c = SpinTransformation(m) # initialization with the spin matrix
@test isapprox(a, b)
@test isapprox(b, c)
@test !isapprox(0.0, det(a)) # non-singularity
@test isapprox(1.0, det(a)) # unitary
@test isapprox(1.0, det(inverse(a))) # unitary

transform = inverse(inverse(a))
@test isapprox(transform, a)

identity = SpinTransformation(Complex.([1.0 0.0; 0.0 1.0]))
@test isapprox(identity.α, Complex(1.0)) || isapprox(identity.α, -Complex(1.0)) # normalization
@test isapprox(identity.α, identity.δ) # identity matrix
@test isapprox(identity.β, identity.γ) # identity matrix
@test isapprox(identity.β, Complex(0.0)) # identity matrix

timesign = rand([-1, 1])
t = float(timesign)
ζ = Complex(t * rand() + im * t * rand())
vector = SpinVector(ζ, timesign)
@test typeof(Quaternion(vector)) <: Quaternion
@test isnull(SpinVector(Quaternion(vector)).nullvector)
@test isapprox(norm(Quaternion(vector)), 1.0)

timesign = rand([-1, 1])
t = float(timesign)
ζ = Complex(t * rand() + im * t * rand())
vector = SpinVector(ζ, timesign)
m = 𝕄(vector)
T, X, Y, Z = vec(m)
ζ1 = (X + im * Y) / (T - Z)
ζ2 = (T + Z) / (X - im * Y)

@test isapprox(ζ1, ζ2)
@test isapprox(ζ1, ζ)
@test all(isapprox.(mat(m), mat(vector)))


timesign = rand([-1, 1])
t = float(timesign)
ζ = Complex(t * rand() + im * t * rand())
vector = SpinVector(ζ, timesign)
spintransform = SpinTransformation(α, β, γ, δ)
@test isapprox(spintransform * vector, -spintransform * vector)


u¹, u², u³ = rand(3)
u⁰ = √(u¹^2 + u²^2 + u³^2)
u = [u⁰; u¹; u²; u³]
point = 𝕍(u)
spinvector = SpinVector(point)
tetrad = Tetrad(ℝ⁴(1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, -1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, -1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, -1.0))
origin = 𝕍(0.0, 0.0, 0.0, 0.0)
spacetimevector = 𝕄(origin, point, tetrad)
ψ = rand() * 2π
α, β, γ, δ = exp(im * ψ), Complex(0.0), Complex(0.0), exp(-im * ψ)
generictransform = SpinTransformation(α, β, γ, δ)
complexidentity = Complex.([1 0; 0 1])
identitytransform = SpinTransformation(complexidentity)
realidentity = [1.0 0.0 0.0 0.0;
                0.0 1.0 0.0 0.0;
                0.0 0.0 1.0 0.0;
                0.0 0.0 0.0 1.0]

@test isapprox(identitytransform * spacetimevector, spacetimevector)
@test isapprox(generictransform * spacetimevector, mat4(generictransform) * spacetimevector)
@test isapprox(norm(generictransform * spinvector), norm(spinvector)) # unitary
@test isapprox(mat(inverse(generictransform)), adjoint(mat(generictransform))) # unitary
@test isapprox(identitytransform * spinvector, spinvector)
@test isapprox(mat(identitytransform), complexidentity)
@test isapprox(0.5 * mat4(identitytransform), realidentity)


# construction with Euler angles
θ, ϕ, ψ = rand(3) .* 2π .- π
v = SpinTransformation(θ, ϕ, ψ)
@test isapprox(1.0, det(v))


timesign = rand([-1, 1])
r = 2rand() - 1.0
z = exp(im * rand() * 2π)
ξ = 2rand() - 1.0 + im * rand() * 2π
η = 2rand() - 1.0 + im * rand() * 2π
@test !isapprox(𝕄(r * ξ, r * η), 𝕄(ξ, η)) # real scaling dependence
@test isapprox(𝕄(z * ξ, z * η), 𝕄(ξ, η)) # phase rescaling independence


# apply a spin transform to two vectors: one with the point at infinity and the other in Agrand's complex plane
timesign = rand([-1, 1])
r = ℝ³(0.0, 0.0, 1.0)
u = SpinVector(r, timesign)
ζ = Inf
v = SpinVector(-1.0 + im * rand(), timesign)
transform = SpinTransformation((rand(3) .* 2π .- π)...)
@test !isapprox(transform * u, transform * v)