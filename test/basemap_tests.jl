import GLMakie
import FileIO


q = Quaternion(normalize(ℝ⁴(rand(4))))
gauge = rand() * 2π
f = I(4)
chart = (-π / 4, π / 4, -π / 4, π / 4)
matrix = make(q, gauge, f, segments, chart = chart)
@test size(matrix) == (segments, segments)
@test typeof(matrix[1, 1]) <: ℝ³


fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])

segments = rand(5:10)
color = FileIO.load("../data/basemap_color.png")
transparency = rand(1:2) == 1 ? true : false
basemap = Basemap(lscene, q, gauge, f, chart, segments, color, transparency = transparency)

matrix = getsurface(basemap.observable, segments, segments)
q = Quaternion(normalize(ℝ⁴(rand(4))))
update!(basemap, q, gauge, f)
_matrix = getsurface(basemap.observable, segments, segments)

@test all([!isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])

matrix = getsurface(basemap.observable, segments, segments)
chart = (rand() * -π / 4, rand() * π / 4, rand() * -π / 4, rand() * π / 4)
update!(basemap, chart)
_matrix = getsurface(basemap.observable, segments, segments)

@test all([!isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])