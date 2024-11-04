import GLMakie


N = rand(5:10)
x = [ℍ(normalize(ℝ⁴(rand(4)))) for i in 1:N]
gauge1 = rand()
gauge2 = rand()
segments = rand(5:10)
M = Identity(4)
matrix = make(x, gauge1, gauge2, M, segments)
@test size(matrix) == (N, segments)
@test typeof(matrix[1, 1]) <: ℝ³

fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])
color = GLMakie.RGBAf(rand(4)...)
whirl = Whirl(lscene, x, gauge1, gauge2, M, segments, color, transparency = false)

_x = [ℍ(normalize(ℝ⁴(rand(4)))) for i in 1:N]
_gauge1 = rand()
_gauge2 = rand()

update!(whirl, _x, _gauge1, _gauge2, M)

@test all([isapprox(whirl.x[i], _x[i]) for i in 1:N])
@test all([isapprox(whirl.gauge1, _gauge1) for i in 1:N])
@test all([isapprox(whirl.gauge2, _gauge2) for i in 1:N])

_color = GLMakie.RGBAf(rand(4)...)
update!(whirl, _color)

@test size(GLMakie.to_value(whirl.color)) == (N, segments)
@test isapprox(GLMakie.to_value(whirl.color)[1, 1], _color)