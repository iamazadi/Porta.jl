timesign = rand([-1, 1])
t = float(timesign)
ζ = Complex(t * rand() + im * t * rand())
vector = SpinVector(ζ, timesign)
@test typeof(Quaternion(vector)) <: Quaternion
@test isnull(SpinVector(Quaternion(vector)).nullvector)
@test isapprox(norm(Quaternion(vector)), 1.0)