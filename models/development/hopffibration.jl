using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 60
frames_number = 360
modelname = "hopffibration"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(2π) * 0.4
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
sphereradius = 1.0
mask = load("data/basemap_mask.png")
reference = load("data/basemap_color.png")
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set()
boundary_nodes = Vector{Vector{ℝ³}}()
points = Vector{Vector{ℍ}}()
indices = Dict()
T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
u = 𝕍(T, X, Y, Z)
q = ℍ(T, X, Y, Z)
tolerance = 1e-3
@assert(isnull(u, atol = tolerance), "u in not a null vector, $u.")
@assert(isapprox(norm(q), 1, atol = tolerance), "q in not a unit quaternion, $(norm(q)).")
gauge1 = 0.0
gauge2 = π / 2
gauge3 = float(π)
gauge4 = 3π / 2
gauge5 = 2π
latitudescale = 1 / 2
longitudescale = 1 / 4
chart = (-π * latitudescale / 2, π * latitudescale / 2, -π * longitudescale, π * longitudescale)
M = Identity(4)
markersize = 0.05
linewidth = 3
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
fontsize = 0.25

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :black))

## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
boundary_names = ["Iran", "United States of America", "Antarctica"]
colormapslist = [:plasma, :ocean, :jet]
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            println(name)
            indices[name] = length(boundary_nodes)
        end
    end
end
for i in eachindex(boundary_nodes)
    _points = Vector{ℍ}()
    for node in boundary_nodes[i]
        r, θ, ϕ = convert_to_geographic(node)
        push!(_points, q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2))))
    end
    push!(points, _points)
end

linecolors = collect(1:segments)
fibers = Dict()
colormaps = Dict()
for (i, name) in enumerate(boundary_names)
    fibers[name] = []
    colormaps[name] = colormapslist[i]
end
for (name, nodes) in zip(boundary_names, points)
    for node in nodes
        fiber = Observable([Point3f(project(normalize(M * (node * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments)])
        lines!(lscene, fiber, linewidth = linewidth, color = linecolors, colorrange = (1, segments), colormap = colormaps[name])
        push!(fibers[name], fiber)
    end
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    ψ = progress * 2π
    # θ, ϕ = cos(ψ) * π / 2, sin(ψ) * π / 2
    # q = ℍ(exp(ϕ * K(1) + θ * K(2)))
    q = ℍ(exp(ψ * K(1)))
    for (name, nodes) in zip(boundary_names, points)
        for (i, node) in enumerate(nodes)
            fibers[name][i][] = [Point3f(project(normalize(q * (node * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments)]
        end
    end
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end