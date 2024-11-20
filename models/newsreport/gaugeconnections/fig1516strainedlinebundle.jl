using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 180
frames_number = 360
modelname = "fig1516strainedlinebundle"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(2π)
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
totalstages = 1

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

lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
section1 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
section2 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
section3 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
section4 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
sectionobservable1 = buildsurface(lscene, section1, mask, transparency = true)
sectionobservable2 = buildsurface(lscene, section2, mask, transparency = true)
sectionobservable3 = buildsurface(lscene, section3, mask, transparency = true)
sectionobservable4 = buildsurface(lscene, section4, mask, transparency = true)

fibersobservable = Tuple{Observable{Matrix{Float64}}, Observable{Matrix{Float64}}, Observable{Matrix{Float64}}}[]
f(θ::Float64, ϕ::Float64, strain::Float64) = strain / 2π .* [θ; ϕ]
lspace = range(0.0, stop = distance, length = segments)
for index in 1:length(boundary_names)
    boundary = convert_to_geographic.(boundary_nodes[index])
    fiber = [rotate(radius + rotate(ℝ³(f(vec(boundary[i])[2:3]..., _distance)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
    # fiber = [rotate(radius + rotate(ℝ³(vec(boundary[i])[2], vec(boundary[i])[3], 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
    color = fill(getcolor(boundary_nodes[index], reference, 0.5), length(boundary), segments)
    push!(fibersobservable, buildsurface(lscene, fiber, color, transparency = true))
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    α₁ = ((stageprogress + 0.0) % 1.0) * distance
    α₂ = ((stageprogress + 0.5) % 1.0) * distance
    α₃ = (((1 - stageprogress) + 0.0) % 1.0) * distance
    α₄ = (((1 - stageprogress) + 0.5) % 1.0) * distance
    section1 = [rotate(radius + rotate(ℝ³([f(-θ, ϕ, α₁)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₁, ẑ)) for θ in lspace2, ϕ in lspace1]
    section2 = [rotate(radius + rotate(ℝ³([f(-θ, ϕ, α₂)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₂, ẑ)) for θ in lspace2, ϕ in lspace1]
    section3 = [rotate(radius + rotate(ℝ³([f(-θ, ϕ, α₃)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₃, ẑ)) for θ in lspace2, ϕ in lspace1]
    section4 = [rotate(radius + rotate(ℝ³([f(-θ, ϕ, α₄)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₄, ẑ)) for θ in lspace2, ϕ in lspace1]
    updatesurface!(section1, sectionobservable1)
    updatesurface!(section2, sectionobservable2)
    updatesurface!(section3, sectionobservable3)
    updatesurface!(section4, sectionobservable4)
    updatecamera!(lscene, eyeposition, sum(section1) * (1.0 / segments^2), up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end