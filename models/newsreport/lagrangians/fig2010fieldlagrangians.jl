using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 60
spacingsnumber = 12
frames_number = 360
modelname = "fig2010fieldlagrangians"
totalstages = 7
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
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

ϵ = 1e-3
gauges = collect(range(0.0, stop = 2π, length = spacingsnumber))
latitudescale = 0.5
longitudescale = 0.25
chart = (-π * latitudescale / 2, π * latitudescale / 2, -π * longitudescale, π * longitudescale)
M = Identity(4)

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
while length(boundary_names) < 10
    push!(boundary_names, rand(countries["name"]))
end
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

basemaps = []
whirls = []
for index in 1:spacingsnumber - 1
    basemap = Basemap(lscene, q, gauges[index], M, chart, segments, mask, transparency = true)
    push!(basemaps, basemap)
    _whirls = []
    for i in eachindex(boundary_nodes)
        color = getcolor(boundary_nodes[i], reference, float(index / spacingsnumber))
        whirl = Whirl(lscene, points[i], gauges[index], gauges[index + 1], M, segments, color, transparency = true)
        push!(_whirls, whirl)
    end
    push!(whirls, _whirls)
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    _, _θ, _ϕ = convert_to_geographic(boundary_nodes[findmax(length.(boundary_nodes))[2]][max(1, Int(floor(progress * findmax(length.(boundary_nodes))[1])))])

    _longitudescale = deepcopy(longitudescale)
    _latitudescale = deepcopy(latitudescale)
    _q = deepcopy(q)
    _gauges = deepcopy(gauges)
    if stage == 1
        _longitudescale = _longitudescale * cos(stageprogress * 2π)
    end
    if stage == 2
        _latitudescale = _latitudescale * cos(stageprogress * 2π)
    end
    if stage == 3
        _gauges = _gauges .+ sin(stageprogress * 2π)
    end
    if stage == 4
        _q = _q * ℍ(exp(sin(stageprogress * 2π) * K(1)))
    end
    if stage == 5
        _q = _q * ℍ(exp(sin(stageprogress * 2π) * K(2)))
    end
    if stage == 6
        _q = _q * ℍ(exp(sin(stageprogress * 2π) * K(3)))
    end
    if stage == 7
        ψ = stageprogress * float(π / 2)
        v = [ψ, cos(2ψ) * π / 2, sin(4ψ) * π]
        _q = _q * ℍ(exp(v[1] * K(1) + v[2] * K(2) + v[3] * K(3)))
    end

    _chart = (-π * _latitudescale / 2, π * _latitudescale / 2, -π * _longitudescale, π * _longitudescale)
    global points = Vector{Vector{ℍ}}()
    for i in eachindex(boundary_nodes)
        _points = Vector{ℍ}()
        for node in boundary_nodes[i]
            r, _θ, _ϕ = convert_to_geographic(node)
            push!(_points, _q * ℍ(exp(_ϕ * _longitudescale * K(1) + _θ * _latitudescale * K(2))))
        end
        push!(points, _points)
    end
    
    for index in 1:spacingsnumber - 1
        update!(basemaps[index], _q, _gauges[index], M, _chart)
        for i in eachindex(whirls[index])
            update!(whirls[index][i], points[i], _gauges[index], _gauges[index + 1], M)
        end
    end
    updatecamera!(lscene, rotate(eyeposition * (0.75 + sin(progress * 2π) * sin(progress * 2π) * 0.25), ℍ(progress * π, ẑ)), lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end