import GLMakie
import FileIO


fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])

segments = rand(5:10)
color = FileIO.load("../data/basemap_color.png")
transparency = rand(1:2) == 1 ? true : false
q = Quaternion(1, 0, 0, 0)
basemap = Basemap(lscene, q, segments, color, transparency = transparency)

matrix = getsurface(basemap.observable, segments, segments)

q = Quaternion(rand(4))
update!(basemap, q)

_matrix = getsurface(basemap.observable, segments, segments)

@test all([!isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])
