import GLMakie
using LinearAlgebra


N = rand(5:10)
q = [normalize(Quaternion(rand(4)...)) for i in 1:N]
θ1 = rand()
θ2 = rand()
segments = rand(5:10)

@test norm(Porta.project(q[1])) ≤ 1

matrix = Porta.make(q, θ1, θ2, segments)
@test size(matrix) == (N, segments)
@test length(matrix[1,1]) == 3

fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])
color = GLMakie.RGBAf(rand(4)...)
whirl = Whirl(lscene, q, θ1, θ2, segments, color, transparency = false)

_q = [normalize(Quaternion(rand(4)...)) for i in 1:N]
_θ1 = rand()
_θ2 = rand()

update!(whirl, _q, _θ1, _θ2)

@test all([isapprox(whirl.q[i], _q[i]) for i in 1:N])
@test all([isapprox(whirl.θ1, _θ1) for i in 1:N])
@test all([isapprox(whirl.θ2, _θ2) for i in 1:N])

_color = GLMakie.RGBAf(rand(4)...)
update!(whirl, _color)

@test size(GLMakie.to_value(whirl.color)) == (N, segments)
@test isapprox(GLMakie.to_value(whirl.color)[1, 1], _color)


hsv = [rand(1:360); rand(); rand()]
rgb = convert_hsvtorgb(hsv)

@test 0 ≤ rgb[1] ≤ 1 && 0 ≤ rgb[2] ≤ 1 && 0 ≤ rgb[3] ≤ 1