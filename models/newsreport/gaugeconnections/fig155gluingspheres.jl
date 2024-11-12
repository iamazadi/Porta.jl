using FileIO
using GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
totalstages = 6
modelname = "fig155gluingspheres"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 0.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
sphereradius = 1.0
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
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

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
plane1 = [ℝ³([θ; ϕ; -1.0]) for θ in lspace2, ϕ in lspace1]
plane2 = [ℝ³([θ; ϕ; 1.0]) for θ in lspace2, ϕ in lspace1]
sectionobservable1 = buildsurface(lscene, plane1, mask, transparency = true)
sectionobservable2 = buildsurface(lscene, plane2, mask, transparency = true)

origin1 = ℝ³(0.0, 1.0, 0.0)
origin2 = ℝ³(0.0, -1.0, 0.0)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    if stage == 1
        sphere = [rotate(convert_to_cartesian([1.0; -θ; ϕ]), ℍ(stageprogress * 2π, ẑ)) for θ in lspace2, ϕ in lspace1]
        updatesurface!(map(x -> x + origin1, sphere), sectionobservable1)
        updatesurface!(map(x -> x + origin2, sphere), sectionobservable2)
    elseif stage == 2
        sphere = [convert_to_cartesian([1.0; -θ; ϕ]) for θ in lspace2, ϕ in lspace1]
        section = [ℝ³([-θ; ϕ; 0.0]) for θ in lspace2, ϕ in lspace1]
        matrix = stageprogress .* section + (1 - stageprogress) .* sphere
        updatesurface!(map(x -> x + origin1, matrix), sectionobservable1)
        updatesurface!(map(x -> x + origin2, matrix), sectionobservable2)
    elseif stage == 3
        disk = [ℝ³([-θ; ϕ; 0.0]) for θ in lspace2, ϕ in lspace1]
        projection = [√((1 - sin(-θ)) / 2) * ℝ³(cos(ϕ), sin(ϕ), 0.0) for θ in lspace2, ϕ in lspace1]
        matrix = stageprogress .* projection + (1 - stageprogress) .* disk
        updatesurface!(map(x -> x + origin1, matrix), sectionobservable1)
        updatesurface!(map(x -> x + origin2, matrix), sectionobservable2)
    elseif stage == 4
        projection1 = [origin1 + √((1 - sin(-θ)) / 2) * ℝ³(cos(ϕ), sin(ϕ), 0.0) for θ in lspace2, ϕ in lspace1]
        projection2 = [origin2 + √((1 - sin(-θ)) / 2) * ℝ³(cos(ϕ), sin(ϕ), 0.0) for θ in lspace2, ϕ in lspace1]
        disk1 = [ẑ + √((1 - sin(-θ)) / 2) * ℝ³(cos(ϕ), sin(ϕ), 0.0) for θ in lspace2, ϕ in lspace1]
        disk2 = [-ẑ + √((1 - sin(-θ)) / 2) * ℝ³(cos(ϕ), sin(ϕ), 0.0) for θ in lspace2, ϕ in lspace1]
        matrix1 = stageprogress .* disk1 + (1 - stageprogress) * projection1
        matrix2 = stageprogress .* disk2 + (1 - stageprogress) * projection2
        updatesurface!(matrix1, sectionobservable1)
        updatesurface!(matrix2, sectionobservable2)
    elseif stage == 5
        disk1 = [ẑ + √((1 - sin(-θ)) / 2) * ℝ³(cos(ϕ), sin(ϕ), 0.0) for θ in lspace2, ϕ in lspace1]
        disk2 = [-ẑ + √((1 - sin(-θ)) / 2) * ℝ³(cos(ϕ), sin(ϕ), 0.0) for θ in lspace2, ϕ in lspace1]
        hemisphere1 = [convert_to_cartesian([1.0; (-θ + π / 2) / 2; ϕ]) for θ in lspace2, ϕ in lspace1]
        hemisphere2 = [convert_to_cartesian([1.0; -(-θ + π / 2) / 2; ϕ]) for θ in lspace2, ϕ in lspace1]
        matrix1 = stageprogress .* hemisphere1 + (1 - stageprogress) .* disk1
        matrix2 = stageprogress .* hemisphere2 + (1 - stageprogress) .* disk2
        updatesurface!(matrix1, sectionobservable1)
        updatesurface!(matrix2, sectionobservable2)
    elseif stage == 6
        hemisphere1 = [rotate(convert_to_cartesian([1.0; (-θ + π / 2) / 2; ϕ]), ℍ(stageprogress * 2π, ẑ)) for θ in lspace2, ϕ in lspace1]
        hemisphere2 = [rotate(convert_to_cartesian([1.0; -(-θ + π / 2) / 2; ϕ]), ℍ(stageprogress * 2π, ẑ)) for θ in lspace2, ϕ in lspace1]
        updatesurface!(hemisphere1, sectionobservable1)
        updatesurface!(hemisphere2, sectionobservable2)
    end
    
    
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end