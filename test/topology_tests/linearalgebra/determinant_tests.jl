d = rand(2:4)
A, B = rand(d, d), rand(d, d)
α = rand()


@test isapprox(det(A * B), det(A) * det(B))
@test isapprox(det(A * B), det(B) * det(A))
@test isapprox(det(A * B), det(B * A))
@test isapprox(det(convert(Array{Float64}, transpose(A))), det(A))
@test isapprox(det(α .* A), α^d * det(A))
