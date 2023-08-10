r = Quaternion(rand() * 2π, LinearAlgebra.normalize(rand(3)))
t = rand(3)
q = Dualquaternion(r, t)

@test isapprox(conj(conj(q)), q)

# Unit condition
g = Quaternion(rand() * 2π, LinearAlgebra.normalize(rand(3)))
q = Quaternion(0, rand(3)...)
h = Dualquaternion(g, q)
ĥ = LinearAlgebra.normalize(h)
p = 2Dualquaternion(h)

# unit quaternions representing points on a unit 3-sphere
@test isapprox(1, LinearAlgebra.norm(ĥ)[1])
# vector imag(ĥ) in the tangent space of S³ at real(ĥ) is perpendicular to the normal real(ĥ)
@test isapprox(0, LinearAlgebra.dot(real(ĥ), imag(ĥ)), atol = TOLERANCE)
@test !isapprox(h, p)

## constructors
rotation = Quaternion(LinearAlgebra.normalize(rand(4))...)
translation = rand(3)
g = Dualquaternion(translation)
q = Dualquaternion(rotation)
p = Dualquaternion(rotation, translation)

@test isapprox(imag(p), 0.5 * (Quaternion(0, translation...) * real(p)))
@test isapprox(translation, gettranslation(g))
@test isapprox(rotation, getrotation(q))
@test isapprox(g * q, p)