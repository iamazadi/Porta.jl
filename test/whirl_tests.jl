import GLMakie
using LinearAlgebra


N = rand(5:10)
v = [normalize(Quaternion(rand(4)...)) for i in 1:N]
θ1 = rand(N)
θ2 = rand(N)
segments = rand(5:10)

@test norm(Porta.project(v[1])) ≤ 1

matrix = Porta.make(v, θ1, θ2, segments)
@test size(matrix) == (N, segments)
@test length(matrix[1,1]) == 3

fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])
color = GLMakie.RGBAf(rand(4)...)
whirl = Whirl(lscene, v, θ1, θ2, segments, color, transparency = false)

_v = [normalize(Quaternion(rand(4)...)) for i in 1:N]
_θ1 = rand(N)
_θ2 = rand(N)

update!(whirl, _v, _θ1, _θ2)

@test all([isapprox(whirl.v[i], _v[i]) for i in 1:N])
@test all([isapprox(whirl.θ1[i], _θ1[i]) for i in 1:N])
@test all([isapprox(whirl.θ2[i], _θ2[i]) for i in 1:N])

_color = GLMakie.RGBAf(rand(4)...)
update!(whirl, _color)

@test size(GLMakie.to_value(whirl.color)) == (N, segments)
@test isapprox(GLMakie.to_value(whirl.color)[1, 1], _color)


hsv = [rand(1:360); rand(); rand()]
rgb = convert_hsvtorgb(hsv)

@test 0 ≤ rgb[1] ≤ 1 && 0 ≤ rgb[2] ≤ 1 && 0 ≤ rgb[3] ≤ 1