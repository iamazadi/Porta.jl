using LinearAlgebra


x̂ = [1.0; 0.0; 0.0]
ŷ = [0.0; 1.0; 0.0]
ẑ = [0.0; 0.0; 1.0]

rotation_angle, rotation_axis = getrotation(x̂, ŷ)

@test isapprox(rotation_angle, π / 2)
@test isapprox(rotation_axis, ẑ)


rotation_angle, rotation_axis = getrotation(ŷ, x̂)

@test isapprox(rotation_angle, π / 2)
@test isapprox(rotation_axis, -ẑ)


rotation_angle, rotation_axis = getrotation(x̂, ẑ)

@test isapprox(rotation_angle, π / 2)
@test isapprox(rotation_axis, -ŷ)