plane = getplane([0.0; 5.0; 3.5], Quaternion(1, 0, 0, 0), [1.0; 13.0; 13.0])
sprite = getsprite(ℝ³(0, 0, 0), Quaternion(0, ℝ³(1, 0, 0)))


p₁, p₂, p₃, p₄ = typeof(plane), typeof(sprite), size(sprite), size(plane)


@test p₁ == Array{Float64,3}
@test p₂ == Array{ℝ³,1}
@test p₃ == (6,)
@test p₄ == (2, 2, 3)
