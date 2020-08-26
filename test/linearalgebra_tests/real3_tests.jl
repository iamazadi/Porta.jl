u, v, w = ℝ³(rand(3)), ℝ³(rand(3)), ℝ³(rand(3))
a, b = ℝ³(rand(3)), ℝ³(rand(3))
zero = ℝ³([0.0; 0.0; 0.0])
α, β = rand(2)

## Abstract Vector Space Tests ##

@test isapprox(u + (v + w), (u + v) + w) # 1. associativity of addition
@test isapprox(u + v, v + u) # 2. commutativity of addition
@test isapprox(u + zero, u) # 3. the zero vector
@test isapprox(u - u, zero) # 4. the inverse element
@test isapprox(α * (u + v), α * u + α * v) # 5. distributivity Ι
@test isapprox((α + β) * u, α * u + β * u) # 6. distributivity ΙΙ
@test isapprox(α * (β * u), (α * β) * u) # 7. associativity of scalar multiplication
@test isapprox(1u, u) # 8. the unit scalar 1

## Product Space Tests ##

@test isapprox(dot(u, v), dot(v, u)) # symmetric
@test isapprox(dot(u, α * a + β * b), α * dot(u, a) + β * dot(u, b)) # linear
@test dot(u, u) ≥ 0 && isapprox(dot(u, zero), 0) # positive semidefinite
@test size(outer(u, v)) == (length(u), length(v))


## isapprox

segments = 5
array1 = Array{ℝ³,2}(undef, segments, segments)
for i in 1:segments
    for j in 1:segments
        array1[i, j] = ℝ³(rand(3))
    end
end

array2 = map(x -> 2x, array1)

@test isapprox(array1, array1, atol = TOLERANCE)
@test isapprox(array1, array2, atol = TOLERANCE) == false
