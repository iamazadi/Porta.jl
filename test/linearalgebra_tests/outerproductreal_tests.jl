u, v = rand(d), rand(d)
a, b, c = rand(3), rand(3), rand(3)


@test size(outer(u, v)) == (length(u), length(v))
@test isapprox(norm(cross(a, b)),
               norm(a) * norm(b) * sin(acos(dot(normalize(a), normalize(b)))))
# triple product
@test isapprox(dot(a, cross(b, c)), dot(b, cross(c, a)))
@test isapprox(dot(b, cross(c, a)), dot(c, cross(a, b)))
@test isapprox(dot(a, cross(b, c)), dot(cross(a, b), c))
@test isapprox(dot(a, cross(b, c)), -dot(a, cross(c, b)))
@test isapprox(dot(a, cross(b, c)), -dot(b, cross(a, c)))
@test isapprox(dot(a, cross(b, c)), -dot(c, cross(b, a)))
