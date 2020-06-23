a, b, c = ℝ³(rand(3)), ℝ³(rand(3)), ℝ³(rand(3))


@test size(outer(a, b)) == (length(vec(a)), length(vec(b)))
@test isapprox(norm(cross(a, b)),
               norm(a) * norm(b) * sin(acos(dot(a, b) / norm(a) / norm(b))))
@test isapprox(dot(a, cross(b, c)), dot(b, cross(c, a)))
@test isapprox(dot(b, cross(c, a)), dot(c, cross(a, b)))
@test isapprox(dot(a, cross(b, c)), dot(cross(a, b), c))
@test isapprox(dot(a, cross(b, c)), -dot(a, cross(c, b)))
@test isapprox(dot(a, cross(b, c)), -dot(b, cross(a, c)))
@test isapprox(dot(a, cross(b, c)), -dot(c, cross(b, a)))
