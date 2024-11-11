using FileIO
using GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 60
frames_number = 360
modelname = "fig154twisting"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π * π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set{String}()
boundary_nodes = Vector{Vector{ℝ³}}()
indices = Dict{String,Int}()
reference = load("data/basemap_color.png")
mask = load("data/basemap_mask.png")

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = LScene(fig[1, 2], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

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

lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
plane = [ℝ³([θ; ϕ; 0.0]) for θ in lspace2, ϕ in lspace1]
sectionobservable1 = buildsurface(lscene1, plane, mask, transparency = true)
sectionobservable2 = buildsurface(lscene2, plane, mask, transparency = true)

fibersobservable1 = Tuple{Observable{Matrix{Float64}}, Observable{Matrix{Float64}}, Observable{Matrix{Float64}}}[]
fibersobservable2 = Tuple{Observable{Matrix{Float64}}, Observable{Matrix{Float64}}, Observable{Matrix{Float64}}}[]

for index in 1:length(boundary_names)
    boundary = convert_to_geographic.(boundary_nodes[index])
    lspace = range(0.0, stop = 1.0, length = segments)
    fiber = [ℝ³(vec(boundary[i])[2:3]..., height) for i in eachindex(boundary), height in lspace]
    color = fill(getcolor(boundary_nodes[index], reference, 0.5), length(boundary), segments)
    push!(fibersobservable1, buildsurface(lscene1, fiber, color, transparency = true))
    push!(fibersobservable2, buildsurface(lscene2, fiber, color, transparency = true))
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    height = progress * float(2π)
    lspace = range(0.0, stop = height, length = segments)
    z = float(π) * exp(-im * progress * 2π)
    x, y = real(z), imag(z)
    R = normalize(ℝ³(1.0, 1.0, 0.0)) * float(π)
    section1 = [rotate(R + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(height, ẑ)) for θ in lspace2, ϕ in lspace1]
    section2 = [rotate(R + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂) * ℍ(height, ẑ)), ℍ(height, ẑ)) for θ in lspace2, ϕ in lspace1]
    updatesurface!(section1, sectionobservable1)
    updatesurface!(section2, sectionobservable2)

    for index in 1:length(boundary_names)
        boundary = convert_to_geographic.(boundary_nodes[index])
        fiber1 = [rotate(R + rotate(ℝ³(vec(boundary[i])[2], vec(boundary[i])[3], 0.0), ℍ(π / 2, x̂)), ℍ(_height, ẑ)) for i in eachindex(boundary), _height in lspace]
        fiber2 = [rotate(R + rotate(ℝ³(vec(boundary[i])[2], vec(boundary[i])[3], 0.0), ℍ(π / 2, x̂) * ℍ(_height, ẑ)), ℍ(_height, ẑ)) for i in eachindex(boundary), _height in lspace]
        updatesurface!(fiber1, fibersobservable1[index])
        updatesurface!(fiber2, fibersobservable2[index])
    end

    if frame % 60 == 0
        buildsurface(lscene1, section1, mask, transparency = true)
        buildsurface(lscene2, section2, mask, transparency = true)
    end
    
    updatecamera!(lscene1, eyeposition, sum(section1) * (1.0 / segments^2), up)
    updatecamera!(lscene2, eyeposition, sum(section2) * (1.0 / segments^2), up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end