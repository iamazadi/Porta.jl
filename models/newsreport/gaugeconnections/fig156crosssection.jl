using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 90
frames_number = 360
modelname = "fig156crosssection"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
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

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 2], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

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
basemap1 = Basemap(lscene2, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene2, q, gauge2, M, chart, segments, mask, transparency = true)
basemap3 = Basemap(lscene2, q, gauge3, M, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene2, q, gauge4, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.2)
    color2 = getcolor(boundary_nodes[i], reference, 0.4)
    color3 = getcolor(boundary_nodes[i], reference, 0.6)
    color4 = getcolor(boundary_nodes[i], reference, 0.8)
    whirl1 = Whirl(lscene2, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene2, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene2, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene2, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end

lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
plane = [ℝ³([-θ; ϕ; 0.0]) * (1 / float(π)) for θ in lspace2, ϕ in lspace1]
sectionobservable = buildsurface(lscene1, plane, mask, transparency = true)
fibersobservable = Tuple{Observable{Matrix{Float64}}, Observable{Matrix{Float64}}, Observable{Matrix{Float64}}}[]
lspace = range(float(-π), stop = float(π), length = segments)
for index in 1:length(boundary_names)
    boundary = convert_to_geographic.(boundary_nodes[index])
    fiber = [ℝ³(vec(boundary[i])[2:3]..., height) * (1 / float(π)) for i in eachindex(boundary), height in lspace]
    color = fill(getcolor(boundary_nodes[index], reference, 0.8), length(boundary), segments)
    push!(fibersobservable, buildsurface(lscene1, fiber, color, transparency = true))
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    ψ = sin(progress * 2π) * π
    plane = [ℝ³([-θ; ϕ; ψ]) * (1 / float(π)) for θ in lspace2, ϕ in lspace1]
    updatesurface!(plane, sectionobservable)
    update!(basemap1, q, gauge1 + ψ, M)
    update!(basemap2, q, gauge2 + ψ, M)
    update!(basemap3, q, gauge3 + ψ, M)
    update!(basemap4, q, gauge4 + ψ, M)
    points = Vector{Vector{ℍ}}()
    for i in eachindex(boundary_nodes)
        _points = Vector{ℍ}()
        for node in boundary_nodes[i]
            r, θ, ϕ = convert_to_geographic(node)
            push!(_points, q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2))))
        end
        push!(points, _points)
    end
    for i in eachindex(whirls1)
        update!(whirls1[i], points[i], gauge1 + ψ, gauge2 + ψ, M)
        update!(whirls2[i], points[i], gauge2 + ψ, gauge3 + ψ, M)
        update!(whirls3[i], points[i], gauge3 + ψ, gauge4 + ψ, M)
        update!(whirls4[i], points[i], gauge4 + ψ, gauge5 + ψ, M)
    end
    
    updatecamera!(lscene1, eyeposition, sum(plane) * (1 / segments^2), up)
    updatecamera!(lscene2, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end