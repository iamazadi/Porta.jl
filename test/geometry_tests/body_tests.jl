q = Biquaternion(Quaternion(0, ℝ³(0, 0, 1)), ℝ³(0, 0, 0))
triad = constructtriad(q, length = 1.0)
torus = constructtorus(q, 1, 10)
sphere = constructsphere(q, 1)
cylinder = constructcylinder(q, 1.0, 0.1)
scale = ℝ³(1, 1, 1)
box = constructbox(ℝ³(rand(3)), Quaternion(rand() * 2pi, ℝ³(rand(3))), scale)
plane = getplane([0.0; 5.0; 3.5], Quaternion(1, 0, 0, 0), [1.0; 13.0; 13.0])


@test typeof(triad) == Array{ℝ³,1}
@test size(triad) == (6,)
@test typeof(torus) == Array{ℝ³,2}
@test size(torus) == (36, 36)
@test typeof(sphere) == Array{ℝ³,2}
@test size(sphere) == (36, 36)
@test typeof(cylinder) == Array{ℝ³,2}
@test size(cylinder) == (36, 36)
@test typeof(box) == Array{ℝ³,2}
@test size(box) == (4, 4)
@test typeof(plane) == Array{Float64,3}
@test size(plane) == (2, 2, 3)
