r = ℍ(rand() * 2π, normalize(ℝ³(rand(3))))
t = ℝ³(rand(3))
q = Dualquaternion(r, t)

@test isapprox(conj(conj(q)), q)

# Unit condition
g = ℍ(rand() * 2π, normalize(ℝ³(rand(3))))
q = ℍ(ℝ⁴(0.0, rand(3)...))
h = Dualquaternion(g, q)
ĥ = normalize(h)
p = 2Dualquaternion(h)

# unit quaternions representing points on a unit 3-sphere
@test isapprox(1.0, norm(ĥ)[1])
# vector imag(ĥ) in the tangent space of S³ at real(ĥ) is perpendicular to the normal real(ĥ)
@test isapprox(0.0, dot(real(ĥ), imag(ĥ)), atol = TOLERANCE)
@test !isapprox(h, p)

## constructors
rotation = ℍ(normalize(ℝ⁴(rand(4))))
translation = ℝ³(rand(3))
g = Dualquaternion(translation)
q = Dualquaternion(rotation)
p = Dualquaternion(rotation, translation)

@test isapprox(imag(p), 0.5 * (ℍ(ℝ⁴(0.0, vec(translation)...)) * real(p)))
@test isapprox(translation, gettranslation(g))
@test isapprox(rotation, getrotation(q))
@test isapprox(g * q, p)