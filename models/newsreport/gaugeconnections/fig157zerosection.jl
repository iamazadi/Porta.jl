using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 90
frames_number = 360
modelname = "fig157zerosection"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * 2float(π * π)
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
totalstages = 3

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = LScene(fig[1, 2], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

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

lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
section1 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
section2 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂) * ℍ(distance, ẑ)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
sectionobservable1 = buildsurface(lscene1, section1, mask, transparency = true)
sectionobservable2 = buildsurface(lscene2, section2, mask, transparency = true)

fibersobservable1 = Tuple{Observable{Matrix{Float64}}, Observable{Matrix{Float64}}, Observable{Matrix{Float64}}}[]
fibersobservable2 = Tuple{Observable{Matrix{Float64}}, Observable{Matrix{Float64}}, Observable{Matrix{Float64}}}[]

for index in 1:length(boundary_names)
    boundary = convert_to_geographic.(boundary_nodes[index])
    lspace = range(0.0, stop = distance, length = segments)
    fiber1 = [rotate(radius + rotate(ℝ³(vec(boundary[i])[2], vec(boundary[i])[3], 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
    fiber2 = [rotate(radius + rotate(ℝ³(vec(boundary[i])[2], vec(boundary[i])[3], 0.0), ℍ(π / 2, x̂) * ℍ(_distance, ẑ)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
    color = fill(getcolor(boundary_nodes[index], reference, 0.5), length(boundary), segments)
    push!(fibersobservable1, buildsurface(lscene1, fiber1, color, transparency = true))
    push!(fibersobservable2, buildsurface(lscene2, fiber2, color, transparency = true))
end

arcpoints1 = Observable(Point3f[])
arcpoints2 = Observable(Point3f[])
arcpoints3 = Observable(Point3f[])
arcpoints4 = Observable(Point3f[])
arccolors = Observable(Int[])
lines!(lscene1, arcpoints1, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism)
lines!(lscene2, arcpoints2, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism)
lines!(lscene1, arcpoints3, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :seaborn_bright)
lines!(lscene2, arcpoints4, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :seaborn_bright)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    lspace = range(0.0, stop = distance, length = segments)
    section1 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(stageprogress * distance, ẑ)) for θ in lspace2, ϕ in lspace1]
    section2 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂) * ℍ(stageprogress * distance, ẑ)), ℍ(stageprogress * distance, ẑ)) for θ in lspace2, ϕ in lspace1]
    updatesurface!(section1, sectionobservable1)
    updatesurface!(section2, sectionobservable2)
    arcpoints1[] = [Point3f(rotate(radius + rotate(ℝ³([0.0; 0.0; 0.0]), ℍ(π / 2, x̂)), ℍ(_distance, ẑ))) for _distance in lspace]
    arcpoints2[] = [Point3f(rotate(radius + rotate(ℝ³([0.0; 0.0; 0.0]), ℍ(π / 2, x̂) * ℍ(_distance, ẑ)), ℍ(_distance, ẑ))) for _distance in lspace]
    if stage == 1
        point = ℝ³([sin(π / 2 * stageprogress) * π / 2; 0.0; 0.0])
        arcpoints3[] = [Point3f(rotate(radius + rotate(point, ℍ(π / 2, x̂)), ℍ(_distance, ẑ))) for _distance in lspace]
        arcpoints4[] = [Point3f(rotate(radius + rotate(point, ℍ(π / 2, x̂) * ℍ(_distance, ẑ)), ℍ(_distance, ẑ))) for _distance in lspace]
    elseif stage == 2
        point = ℝ³([π / 2; sin(stageprogress * 2π) * π; 0.0])
        arcpoints3[] = [Point3f(rotate(radius + rotate(point, ℍ(π / 2, x̂)), ℍ(_distance, ẑ))) for _distance in lspace]
        arcpoints4[] = [Point3f(rotate(radius + rotate(point, ℍ(π / 2, x̂) * ℍ(_distance, ẑ)), ℍ(_distance, ẑ))) for _distance in lspace] 
    elseif stage == 3
        point = ℝ³([cos(π / 2 * stageprogress) * π / 2; sin(stageprogress * 2π) * π; 0.0])
        arcpoints3[] = [Point3f(rotate(radius + rotate(point, ℍ(π / 2, x̂)), ℍ(_distance, ẑ))) for _distance in lspace]
        arcpoints4[] = [Point3f(rotate(radius + rotate(point, ℍ(π / 2, x̂) * ℍ(_distance, ẑ)), ℍ(_distance, ẑ))) for _distance in lspace]
    end
    arccolors[] = collect(1:segments)
    updatecamera!(lscene1, eyeposition, sum(section1) * (1.0 / segments^2), up)
    updatecamera!(lscene2, eyeposition, sum(section2) * (1.0 / segments^2), up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end