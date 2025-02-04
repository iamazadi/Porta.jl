x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

rotation_angle, rotation_axis = getrotation(x̂, ŷ)

@test isapprox(rotation_angle, π / 2)
@test isapprox(rotation_axis, ẑ)


rotation_angle, rotation_axis = getrotation(ŷ, x̂)

@test isapprox(rotation_angle, π / 2)
@test isapprox(rotation_axis, -ẑ)


rotation_angle, rotation_axis = getrotation(x̂, ẑ)

@test isapprox(rotation_angle, π / 2)
@test isapprox(rotation_axis, -ŷ)


q = ℍ(1.0, 0.0, 0.0, 0.0)
@test typeof(rotate(elI, q)) <: typeof(q)

p = ℝ³(rand(3))
@test typeof(rotate(p, q)) <: typeof(p)

segments = rand(5:10)
lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
matrix = [ℝ³([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
rotatedmatrix = rotate(matrix, q)
@test typeof(rotatedmatrix) <: Matrix{ℝ³}
@test size(rotatedmatrix) == size(matrix)