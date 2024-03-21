v = [rand() + im * rand() for _ in 1:4]
α, β, γ, δ = v
α = (β * γ + 1.0) / δ
v[1] = α
m = [α β; γ δ]
a = SpinTransformation(α, β, γ, δ)
b = SpinTransformation(v)
c = SpinTransformation(m) # initialization with the spin-matrix
@test isapprox(a, b)
@test isapprox(b, c)
@test !isapprox(0.0, det(a)) # non-singularity
@test isapprox(1.0, det(a)) # special unitary
@test isapprox(1.0, det(inverse(a))) # special unitary


a = SpinTransformation(rand() * 2π, rand() * 2π, rand() * 2π) # with Euler angles
b = SpinTransformation(mat(a))
c = SpinTransformation(convert(Matrix{Complex}, adjoint(mat(a))))

@test isapprox(a, b) # different constructors
@test isapprox(inverse(inverse(a)), a) # the inverse of the inverse
@test isapprox(1.0, det(a)) # special unitary
@test isapprox(1.0, det(inverse(a))) # special unitary
@test isapprox(inverse(a), c) # unitary
@test isapprox(mat(a * c), [Complex(1) 0; 0 Complex(1)]) # identity
@test isapprox(mat(inverse(c)), adjoint(mat(c))) # unitary

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


## check the implication of constructing spacetime vectors with spin vectors
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
@test all(isapprox.(mat(m), √2 .* mat(vector)))


## determining a spin transformation by its effect on the Riemann sphere ζ, up to a sign
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
spacetimevector = 𝕄(spinvector.ξ, spinvector.η)
M = mat(spacetimevector)
ξ, η = spinvector.ξ, spinvector.η
ψ = rand() * 2π
α, β, γ, δ = exp(im * ψ), Complex(0.0), Complex(0.0), exp(-im * ψ)
generictransform = SpinTransformation(α, β, γ, δ)
complexidentity = Complex.([1 0; 0 1])
identitytransform = SpinTransformation(complexidentity)
realidentity = [1.0 0.0 0.0 0.0;
                0.0 1.0 0.0 0.0;
                0.0 0.0 1.0 0.0;
                0.0 0.0 0.0 1.0]

@test isapprox(mat(spacetimevector), √2 .* [ξ; η] * adjoint([ξ; η]))
@test isapprox(identitytransform * spacetimevector, spacetimevector)
@test isapprox(generictransform * spacetimevector, mat4(generictransform) * spacetimevector)
@test isapprox(norm(generictransform * spinvector), norm(spinvector)) # unitary
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


β, γ, δ = [rand() + im * rand() for _ in 1:3]
α = (β * γ + 1.0) / δ
_β, _γ, _δ = [rand() + im * rand() for _ in 1:3]
_α = (_β * _γ + 1.0) / _δ
a = SpinTransformation(α, β, γ, δ)
b = SpinTransformation(_α, _β, _γ, _δ)

@test typeof(a * b) <: SpinTransformation # matrix-matrix multiplication
@test isapprox(det(a * b), 1.0) # unitary


ζ = 2rand() - 1.0 + im * rand() * 2π
timesign = rand([-1, 1])
vector = SpinVector(ζ, timesign)
velocity = rand() # the velocity parameter
transform = zboost(velocity)
w = dopplerfactor(velocity) # the relativistic Doppler factor
@test isapprox(log(w), rapidity(velocity))
@test isapprox((transform * vector).ζ, w * ζ)
@test !isapprox(transform * vector, vector) # a pure z-boost
# a pure z-boost corresponds to a positive/negative-definite Hermitian spin-matrix
@test isapprox(mat(transform), convert(Matrix{Complex}, adjoint(mat(transform)))) # Hermiticity
@test !isapprox(det(transform), 0.0) # definiteness