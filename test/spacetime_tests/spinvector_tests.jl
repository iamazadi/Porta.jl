u¹, u², u³ = rand(3)
u⁰ = √(u¹^2 + u²^2 + u³^2)
u = 𝕍(u⁰, u¹, u², u³)

v¹, v², v³ = [u¹; u²; u³] .* (rand() + 0.1)
v⁰ = √(v¹^2 + v²^2 + v³^2)
v = 𝕍(v⁰, v¹, v², v³)

vector1 = SpinVector(u)
vector2 = SpinVector(v)
@test isapprox(vector1, vector2)

timesign = rand([-1, 1])
t = float(timesign)
vector = SpinVector(normalize(t * ℝ³(rand(3))), timesign)
@test isnull(vector.nullvector)

timesign = rand([-1, 1])
θ = rand() * π
ϕ = rand() * 2π
vector = SpinVector(θ, ϕ, timesign)
@test isnull(vector.nullvector)

timesign = rand([-1, 1])
t = float(timesign)
v = 𝕍(ℝ⁴(t, t * vec(normalize(ℝ³(rand(3))))...))
vector = SpinVector(v)
@test isnull(vector.nullvector)

timesign = rand([-1, 1])
t = float(timesign)
ξ, η = Complex(t * rand() + im * t * rand()), Complex(t * rand() + im * t * rand())
vector = SpinVector(ξ, η, timesign)
@test isnull(vector.nullvector)

timesign = rand([-1, 1])
v = normalize(ℝ³(rand(3)))
vector = SpinVector(v, timesign)
@test isnull(vector.nullvector)

timesign = rand([-1, 1])
t = float(timesign)
ξ, η = Complex(t * rand() + im * t * rand()), Complex(t * rand() + im * t * rand())
ζ = ξ / η
@test isapprox(SpinVector(ξ, η, timesign), SpinVector(ζ, timesign))
z = exp(im * rand() * 2π)
r = rand()
@test isapprox(SpinVector(z * ξ, z * η, timesign), SpinVector(ξ, η, timesign)) # independence of phase rescaling
@test isapprox(SpinVector(r * ξ, r * η, timesign), SpinVector(ξ, η, timesign)) # independence of real scaling

timesign = rand([-1, 1])
t = float(timesign)
θ = 0.0
ϕ = 0.0
spherical = ℝ²(θ, ϕ)
ζ = Inf
vector = SpinVector(ζ, timesign)
@test isapprox(vector.spherical, spherical)


timesign = rand([-1, 1])
t = float(timesign)
ζ = Complex(t * rand() + im * t * rand())
vector = SpinVector(ζ, timesign)
_vector = antipodal(vector)
@test !isapprox(vector, _vector)
@test vector.timesign != _vector.timesign
@test isapprox(vector.nullvector, -_vector.nullvector)

vector = SpinVector(ℝ³(0.0, 0.0, 1.0), timesign) # The point at infinity
_vector = antipodal(vector)
@test !isapprox(vector, _vector)
@test vector.timesign != _vector.timesign
@test isapprox(vector.nullvector, -_vector.nullvector)


timesign = rand([-1, 1])
t = float(timesign)
ζ = Complex(t * rand() + im * t * rand())
vector = SpinVector(ζ, timesign)
@test isapprox(ζ, vector.ξ / vector.η)


@test all(isapprox.(mat(vector), [vector.ξ * conj(vector.ξ) vector.ξ * conj(vector.η); vector.η * conj(vector.ξ) vector.η * conj(vector.η)]))


## chacking the equivalence of initialization with the infinity point and the North Pole coordinate
r = ℝ³(0.0, 0.0, 1.0)
u = SpinVector(r, timesign)
ζ = Inf
v = SpinVector(ζ, timesign)
@test isapprox(u, v)