import GLMakie
import FileIO


fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])

segments = rand(5:10)
color = FileIO.load("../data/basemap_color.png")
transparency = rand(1:2) == 1 ? true : false
q = SpinVector(normalize(ℝ³(rand(3))), rand([-1; 1]))
chart = (-π / 4, π / 4, -π / 4, π / 4)
basemap = Basemap(lscene, q, chart, segments, color, transparency = transparency)

matrix = getsurface(basemap.observable, segments, segments)
q = SpinVector(normalize(ℝ³(rand(3))), rand([-1; 1]))
update!(basemap, q)
_matrix = getsurface(basemap.observable, segments, segments)

@test all([!isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])

matrix = getsurface(basemap.observable, segments, segments)
chart = (rand() * -π / 4, rand() * π / 4, rand() * -π / 4, rand() * π / 4)
update!(basemap, chart)
_matrix = getsurface(basemap.observable, segments, segments)

@test all([!isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])