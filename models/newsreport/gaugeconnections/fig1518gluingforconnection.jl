using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 100
frames_number = 360
modelname = "fig1518gluingforconnection"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(4π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
linewidth = 20
distance = float(2π)
radius = x̂ * float(π)
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set{String}()
boundary_nodes = Vector{Vector{ℝ³}}()
indices = Dict{String,Int}()
reference = load("data/basemap_color.png")
mask = load("data/basemap_mask.png")
markersize = 0.05
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
totalstages = 7

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
while length(boundary_names) < 30
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

origin1 = ℝ³(distance * 0.75, 0.0, 0.0)
origin2 = -origin1

lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
section1 = [origin1 + rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
section2 = [origin2 + rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
sectionobservable1 = buildsurface(lscene, section1, mask, transparency = true)
sectionobservable2 = buildsurface(lscene, section2, mask, transparency = true)

fibersobservables1 = []
fibersobservables2 = []
strain(θ::Float64, ϕ::Float64, strain::Float64) = strain / 2π .* [θ; ϕ]
lspace = range(0.0, stop = distance, length = segments)
for index in 1:length(boundary_names)
    boundary = convert_to_geographic.(boundary_nodes[index])
    fiber1 = [origin1 + rotate(radius + rotate(ℝ³(transform(vec(boundary[i])[2:3]..., _distance, 0.0)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
    fiber2 = [origin2 + rotate(radius + rotate(ℝ³(transform(vec(boundary[i])[2:3]..., _distance, 0.0)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
    color = fill(getcolor(boundary_nodes[index], reference, 0.5), length(boundary), segments)
    push!(fibersobservables1, buildsurface(lscene, fiber1, color, transparency = true))
    push!(fibersobservables2, buildsurface(lscene, fiber2, color, transparency = true))
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    if stage == 1
        section1 = [origin1 + rotate(radius + rotate(ℝ³([strain(-θ, ϕ, distance)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = [origin2 + rotate(radius + rotate(ℝ³([strain(-θ, ϕ, distance)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance, ẑ)) for θ in lspace2, ϕ in lspace1]
        updatesurface!(section1, sectionobservable1)
        updatesurface!(section2, sectionobservable2)
        for index in 1:length(boundary_names)
            boundary = convert_to_geographic.(boundary_nodes[index])
            fiber1 = [origin1 + rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., distance)..., 0.0), ℍ(π / 2, x̂)), ℍ(stageprogress * _distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = [origin2 + rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., distance)..., 0.0), ℍ(π / 2, x̂)), ℍ(stageprogress * _distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
            updatesurface!(fiber1, fibersobservables1[index])
            updatesurface!(fiber2, fibersobservables2[index])
        end
        eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(4π)
    end
    if stage == 2
        section1 = [origin1 + rotate(radius + rotate(ℝ³([strain(-θ, ϕ, distance)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = [origin2 + rotate(radius + rotate(ℝ³([strain(-θ, ϕ, stageprogress * (stageprogress * distance) + (1 - stageprogress) * distance)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance, ẑ)) for θ in lspace2, ϕ in lspace1]
        updatesurface!(section1, sectionobservable1)
        updatesurface!(section2, sectionobservable2)
        for index in 1:length(boundary_names)
            boundary = convert_to_geographic.(boundary_nodes[index])
            fiber1 = [origin1 + rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., distance)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = [origin2 + rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., stageprogress * _distance + (1 - stageprogress) * distance)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
            updatesurface!(fiber1, fibersobservables1[index])
            updatesurface!(fiber2, fibersobservables2[index])
        end
        eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(4π)
    end
    if stage == 3
        section1 = [origin1 + rotate(radius + rotate(ℝ³([strain(-θ, ϕ, distance)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = [origin2 + rotate(radius + rotate(ℝ³([strain(-θ, ϕ, stageprogress * distance - stageprogress * distance / 2)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        updatesurface!(section1, sectionobservable1)
        updatesurface!(section2, sectionobservable2)
        for index in 1:length(boundary_names)
            boundary = convert_to_geographic.(boundary_nodes[index])
            fiber1 = [origin1 + rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., distance)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance - stageprogress * _distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = [origin2 + rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., _distance - stageprogress * _distance / 2)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance - stageprogress * _distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            updatesurface!(fiber1, fibersobservables1[index])
            updatesurface!(fiber2, fibersobservables2[index])
        end
        eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(4π)
    end
    if stage == 4
        q = ℍ(stageprogress * π, ẑ)
        section1 = [origin1 + rotate(radius + rotate(ℝ³([strain(-θ, ϕ, distance)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = [rotate(radius + rotate(ℝ³([strain(-θ, ϕ, stageprogress * distance / 2)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = map(x -> origin2 + rotate(x, q), section2)
        updatesurface!(section1, sectionobservable1)
        updatesurface!(section2, sectionobservable2)
        for index in 1:length(boundary_names)
            boundary = convert_to_geographic.(boundary_nodes[index])
            fiber1 = [origin1 + rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., distance)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = [rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., _distance / 2)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = map(x -> origin2 + rotate(x, q), fiber2)
            updatesurface!(fiber1, fibersobservables1[index])
            updatesurface!(fiber2, fibersobservables2[index])
        end
        eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(4π)
    end
    if stage == 5
        q = ℍ(float(π), ẑ)
        section1 = [rotate(radius + rotate(ℝ³([strain(-θ, ϕ, distance)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = [rotate(radius + rotate(ℝ³([strain(-θ, ϕ, stageprogress * distance / 2)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section1 = map(x -> (1 - stageprogress) * origin1 + x, section1)
        section2 = map(x -> (1 - stageprogress) * origin2 + rotate(x, q), section2)
        updatesurface!(section1, sectionobservable1)
        updatesurface!(section2, sectionobservable2)
        for index in 1:length(boundary_names)
            boundary = convert_to_geographic.(boundary_nodes[index])
            fiber1 = [rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., distance)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = [rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., _distance / 2)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber1 = map(x -> (1 - stageprogress) * origin1 + x, fiber1)
            fiber2 = map(x -> (1 - stageprogress) * origin2 + rotate(x, q), fiber2)
            updatesurface!(fiber1, fibersobservables1[index])
            updatesurface!(fiber2, fibersobservables2[index])
        end
        eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(4π)
    end
    if stage == 6
        q = ℍ(float(π), ẑ)
        section1 = [rotate(radius + rotate(ℝ³([strain(-θ, ϕ, distance / 2 + 0.5 * ((1 - stageprogress) * distance + stageprogress * stageprogress * distance / 2))...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = [rotate(radius + rotate(ℝ³([strain(-θ, ϕ, stageprogress * distance / 2)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = map(x -> rotate(x, q), section2)
        updatesurface!(section1, sectionobservable1)
        updatesurface!(section2, sectionobservable2)
        for index in 1:length(boundary_names)
            boundary = convert_to_geographic.(boundary_nodes[index])
            fiber1 = [rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., distance / 2 + 0.5 * ((1 - stageprogress) * distance + stageprogress * _distance / 2))..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = [rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., _distance / 2)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = map(x -> rotate(x, q), fiber2)
            updatesurface!(fiber1, fibersobservables1[index])
            updatesurface!(fiber2, fibersobservables2[index])
        end
        eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(4π)
    end
    if stage == 7
        q = ℍ(float(π), ẑ)
        section1 = [rotate(radius + rotate(ℝ³([strain(-θ, ϕ, distance / 2 + 0.5 * (stageprogress * stageprogress * distance / 2))...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = [rotate(radius + rotate(ℝ³([strain(-θ, ϕ, stageprogress * distance / 2)...; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance / 2, ẑ)) for θ in lspace2, ϕ in lspace1]
        section2 = map(x -> rotate(x, q), section2)
        updatesurface!(section1, sectionobservable1)
        updatesurface!(section2, sectionobservable2)
        for index in 1:length(boundary_names)
            boundary = convert_to_geographic.(boundary_nodes[index])
            fiber1 = [rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., distance / 2 + 0.5 * (stageprogress * _distance / 2))..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = [rotate(radius + rotate(ℝ³(strain(vec(boundary[i])[2:3]..., _distance / 2)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance / 2, ẑ)) for i in eachindex(boundary), _distance in lspace]
            fiber2 = map(x -> rotate(x, q), fiber2)
            updatesurface!(fiber1, fibersobservables1[index])
            updatesurface!(fiber2, fibersobservables2[index])
        end
        eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(4π)
    end
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end