import FileIO
import GLMakie


## getsurface and buildsurface

fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])

segments = rand(5:10)

matrix = Matrix{ℝ³}(undef, segments, segments)
for i in 1:segments
    for j in 1:segments
        matrix[j, i] = ℝ³(rand(3))
    end
end

color = fill(GLMakie.RGBAf(rand(4)...), segments, segments)
observable = buildsurface(lscene, matrix, color, transparency = false)
_matrix = getsurface(observable, segments, segments)

@test all([isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])


## builsurface with "observable" color array argument

observablecolor = GLMakie.Observable(color)
observable = buildsurface(lscene, matrix, observablecolor, transparency = true)
_matrix = getsurface(observable, segments, segments)

@test all([isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])


## builsurface with image as color

color = FileIO.load("../data/basemap_color.png")
observable = buildsurface(lscene, matrix, color)
_matrix = getsurface(observable, segments, segments)

@test all([isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])


## updatesurfce

matrix = map(x -> 2 * x, matrix)
updatesurface!(matrix, observable)
_matrix = getsurface(observable, segments, segments)

@test all([isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])