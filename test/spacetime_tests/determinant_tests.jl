# name test artifacts
d = rand(2:4)
A, B = rand(d, d), rand(d, d)
α = rand()

index1 = rand(1:size(A, 1))
index2 = rand(1:size(A, 2))
subresult = sub(A, index1, index2)
@test size(subresult) == (size(A, 1) - 1, size(A, 2) - 1)

@test isapprox(det(A * B), det(A) * det(B))
@test isapprox(det(A * B), det(B) * det(A))
@test isapprox(det(A * B), det(B * A))
@test isapprox(det(convert(Array{Float64}, transpose(A))), det(A))
@test isapprox(det(α .* A), α^d * det(A))

M = rand(d, d)
index1 = rand(1:d)
index2 = rand(1:d)
minorresult = minor(M, index1, index2)
@test typeof(minorresult) <: Float64

index1 = rand(1:d)
index2 = rand(1:d)
cofactorresult = cofactor(M, index1, index2)
@test typeof(cofactorresult) <: Float64