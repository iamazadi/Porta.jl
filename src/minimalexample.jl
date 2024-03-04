import FileIO
import DataFrames
import CSV
using LinearAlgebra
import GLMakie
using Porta


figuresize = (1920, 1080)
segments = 30
basemapsegments = 60
modelname = "minimalexample"
boundary_names = ["United States of America", "Mexico", "Canada", "Iran", "Turkey", "Pakistan"]
indices = Dict()
x̂ = [1.0; 0.0; 0.0]
ŷ = [0.0; 1.0; 0.0]
ẑ = [0.0; 0.0; 1.0]
α = 0.4
θ1 = float(π)


makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :black))

colorref = FileIO.load("data/basemap_color1.png")
basemap_color = FileIO.load("data/basemap_mask1.png")
## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_nodes = Vector{Vector{Vector{Float64}}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            indices[name] = length(boundary_nodes)
        end
    end
end

q = τmap(convert_to_geographic([1.0; -π; π / 2]))
basemap1 = Basemap(lscene, q, basemapsegments, basemap_color, transparency = true)
basemap2 = Basemap(lscene, q, basemapsegments, basemap_color, transparency = true)

whirls = []
_whirls = []
for i in eachindex(boundary_nodes)
    color = getcolor(boundary_nodes[i], colorref, 0.3)
    _color = getcolor(boundary_nodes[i], colorref, 0.2)
    w = [τmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])]
    whirl = Whirl(lscene, w, 0.0, θ1, segments, color, transparency = true, visible = true)
    _whirl = Whirl(lscene, w, θ1, 2π, segments, _color, transparency = true, visible = true)
    push!(whirls, whirl)
    push!(_whirls, _whirl)
end

function make(q::Quaternion, segments::Integer)
    matrix = Matrix{Vector{Float64}}(undef, segments, segments)
    lspaceϕ = collect(range(-π / 4, stop = π / 4, length = segments))
    lspaceθ = collect(range(-π / 4, stop = π / 4, length = segments))
    for (i, ϕ) in enumerate(lspaceϕ)
        for (j, θ) in enumerate(lspaceθ)
            matrix[i, j] = project(exp(θ * K(1) + -ϕ * K(2)) * q)
        end
    end
    matrix
end


q = τmap(convert_to_geographic([1.0; 0.0; 0.0]))
updatesurface!(make(q, basemap1.segments), basemap1.observable)
updatesurface!(make(G(float(π), q), basemap2.segments), basemap2.observable)

for i in eachindex(boundary_nodes)
    points = Quaternion[]
    for node in boundary_nodes[i]
        r, ϕ, θ = convert_to_geographic(node)
        push!(points, exp(ϕ / 4 * K(1) + θ / 2 * K(2)) * q)
    end
    update!(whirls[i], points, θ1, 2π)
    update!(_whirls[i], points, 0.0, θ1)
end
