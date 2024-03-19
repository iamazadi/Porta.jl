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