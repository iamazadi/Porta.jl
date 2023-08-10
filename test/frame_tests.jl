import GLMakie
import FileIO


σ(p::Vector{Float64}) = begin
    g = convert_to_geographic(p)
    r, ϕ, θ = g
    z₁ = ℯ^(im * 0) * √((1 + sin(θ)) / 2)
    z₂ = ℯ^(im * ϕ) * √((1 - sin(θ)) / 2)
    Quaternion([z₁; z₂])
end


fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])

segments = rand(5:10)
color = FileIO.load("../data/basemap_color.png")
transparency = rand(1:2) == 1 ? true : false

frame = Frame(lscene, σ, segments, color, transparency = transparency)

matrix = getsurface(frame.observable, segments, segments)

_σ(g) = G(rand() * 2π, σ(g))

update!(frame, _σ)

_matrix = getsurface(frame.observable, segments, segments)

@test all([!isapprox(matrix[i, j], _matrix[i, j]) for i in 1:segments for j in 1:segments])
