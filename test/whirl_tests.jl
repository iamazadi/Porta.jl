import GLMakie


N = rand(5:10)
q = [Quaternion(normalize(ℝ⁴(rand(4)))) for i in 1:N]
θ1 = rand()
θ2 = rand()
segments = rand(5:10)
f = I(4)
matrix = make(q, θ1, θ2, f, segments)
@test size(matrix) == (N, segments)
@test typeof(matrix[1, 1]) <: ℝ³

fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])
color = GLMakie.RGBAf(rand(4)...)
whirl = Whirl(lscene, q, θ1, θ2, f, segments, color, transparency = false)

_q = [Quaternion(normalize(ℝ⁴(rand(4)))) for i in 1:N]
_θ1 = rand()
_θ2 = rand()

update!(whirl, _q, _θ1, _θ2, f)

@test all([isapprox(whirl.q[i], _q[i]) for i in 1:N])
@test all([isapprox(whirl.θ1, _θ1) for i in 1:N])
@test all([isapprox(whirl.θ2, _θ2) for i in 1:N])

_color = GLMakie.RGBAf(rand(4)...)
update!(whirl, _color)

@test size(GLMakie.to_value(whirl.color)) == (N, segments)
@test isapprox(GLMakie.to_value(whirl.color)[1, 1], _color)