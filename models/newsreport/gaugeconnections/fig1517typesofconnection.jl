using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 90
frames_number = 360
modelname = "fig1517typesofconnection"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = ℝ³(-1.0, 1.0, 1.0) * float(2π)
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
base = [ℝ³([-θ; ϕ; -distance / 2]) for θ in lspace2, ϕ in lspace1]
section1 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
section2 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
section3 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
section4 = [rotate(radius + rotate(ℝ³([-θ; ϕ; 0.0]), ℍ(π / 2, x̂)), ℍ(distance, ẑ)) for θ in lspace2, ϕ in lspace1]
baseobservable = buildsurface(lscene, base, mask, transparency = true)
sectionobservable1 = buildsurface(lscene, section1, mask, transparency = true)
sectionobservable2 = buildsurface(lscene, section2, mask, transparency = true)
sectionobservable3 = buildsurface(lscene, section3, mask, transparency = true)
sectionobservable4 = buildsurface(lscene, section4, mask, transparency = true)

fibersobservables = []
strain(θ::Float64, ϕ::Float64, strain::Float64) = strain / 2π .* [θ; ϕ]
twist(θ::Float64, ϕ::Float64, degree::Float64) = vec(rotate(ℝ³(θ, ϕ, 0.0), ℍ(degree, ẑ)))[1:2]
transform(θ::Float64, ϕ::Float64, α::Float64, interpolation::Float64) = interpolation .* strain(θ, ϕ, α) + (1 - interpolation) .* twist(θ, ϕ, α)
lspace = range(0.0, stop = distance, length = segments)
for index in 1:length(boundary_names)
    boundary = convert_to_geographic.(boundary_nodes[index])
    fiber = [rotate(radius + rotate(ℝ³(transform(vec(boundary[i])[2:3]..., _distance, 0.0)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace]
    color = fill(getcolor(boundary_nodes[index], reference, 0.5), length(boundary), segments)
    push!(fibersobservables, buildsurface(lscene, fiber, color, transparency = true))
end

pointup1 = Observable(Point3f(ẑ))
pointup2 = Observable(Point3f(ẑ))
pointup3 = Observable(Point3f(ẑ))
pointup4 = Observable(Point3f(ẑ))
pointdown = Observable(Point3f(x̂))
colorants = [:red, :green, :blue, :orange]
meshscatter!(lscene, pointup1, markersize = markersize, color = colorants[1])
meshscatter!(lscene, pointup2, markersize = markersize, color = colorants[2])
meshscatter!(lscene, pointup3, markersize = markersize, color = colorants[3])
meshscatter!(lscene, pointup4, markersize = markersize, color = colorants[4])
meshscatter!(lscene, pointdown, markersize = markersize, color = colorants[1])

ray1 = @lift([$pointup1, $pointdown])
ray2 = @lift([$pointup2, $pointdown])
ray3 = @lift([$pointup3, $pointdown])
ray4 = @lift([$pointup4, $pointdown])
raycolors = collect(1:2)
lines!(lscene, ray1, color = raycolors, linewidth = linewidth, colorrange = (1, 2), colormap = :lightrainbow)
lines!(lscene, ray2, color = raycolors, linewidth = linewidth, colorrange = (1, 2), colormap = :lightrainbow)
lines!(lscene, ray3, color = raycolors, linewidth = linewidth, colorrange = (1, 2), colormap = :darkrainbow)
lines!(lscene, ray4, color = raycolors, linewidth = linewidth, colorrange = (1, 2), colormap = :darkrainbow)
path = Observable(Point3f[])
path1 = Observable(Point3f[])
path2 = Observable(Point3f[])
path3 = Observable(Point3f[])
path4 = Observable(Point3f[])
lines!(lscene, path, color = GLMakie.@lift(collect(1:length($path))), linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = :rainbow)
lines!(lscene, path1, color = GLMakie.@lift(collect(1:length($path1))), linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = :spring)
lines!(lscene, path2, color = GLMakie.@lift(collect(1:length($path2))), linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = :summer)
lines!(lscene, path3, color = GLMakie.@lift(collect(1:length($path3))), linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = :fall)
lines!(lscene, path4, color = GLMakie.@lift(collect(1:length($path4))), linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = :winter)

headx = Observable(Point3f(x̂))
heady = Observable(Point3f(ŷ))
headx1 = Observable(Point3f(x̂))
headx2 = Observable(Point3f(x̂))
headx3 = Observable(Point3f(x̂))
headx4 = Observable(Point3f(x̂))
heady1 = Observable(Point3f(ŷ))
heady2 = Observable(Point3f(ŷ))
heady3 = Observable(Point3f(ŷ))
heady4 = Observable(Point3f(ŷ))
headz1 = Observable(Point3f(ẑ))
headz2 = Observable(Point3f(ẑ))
headz3 = Observable(Point3f(ẑ))
headz4 = Observable(Point3f(ẑ))
ps = @lift([$pointup1, $pointup2, $pointup3, $pointup4, $pointup1, $pointup2, $pointup3, $pointup4, $pointup1, $pointup2, $pointup3, $pointup4, $pointdown, $pointdown])
ns = @lift([$headx1, $headx2, $headx3, $headx4, $heady1, $heady2, $heady3, $heady4, $headz1, $headz2, $headz3, $headz4, $headx, $heady])
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants..., colorants..., colorants..., colorants[1], colorants[1]],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin, transparency = false
)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    α₁ = ((stageprogress + 0.0) % 1.0) * distance
    α₂ = ((stageprogress + 0.5) % 1.0) * distance
    α₃ = (((1 - stageprogress) + 0.0) % 1.0) * distance
    α₄ = (((1 - stageprogress) + 0.5) % 1.0) * distance
    interpolation = abs(sin(stageprogress * π))
    section1 = [rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₁, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₁, ẑ)) for θ in lspace2, ϕ in lspace1]
    section2 = [rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₂, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₂, ẑ)) for θ in lspace2, ϕ in lspace1]
    section3 = [rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₃, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₃, ẑ)) for θ in lspace2, ϕ in lspace1]
    section4 = [rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₄, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₄, ẑ)) for θ in lspace2, ϕ in lspace1]
    updatesurface!(section1, sectionobservable1)
    updatesurface!(section2, sectionobservable2)
    updatesurface!(section3, sectionobservable3)
    updatesurface!(section4, sectionobservable4)
    ψ = stageprogress * π
    θ, ϕ = cos(2ψ) * π / 2, sin(4ψ) * π
    pointup1[] = Point3f(rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₁, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₁, ẑ)))
    pointup2[] = Point3f(rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₂, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₂, ẑ)))
    pointup3[] = Point3f(rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₃, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₃, ẑ)))
    pointup4[] = Point3f(rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₄, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₄, ẑ)))
    pointdown[] = Point3f(ℝ³([-θ; ϕ; -distance / 2]))
    ϵ = 1e-3
    headx[] = Point3f(normalize(ℝ³(pointdown[]) - ℝ³([-θ + ϵ * (-θ); ϕ; -distance / 2])))
    heady[] = Point3f(normalize(ℝ³(pointdown[]) - ℝ³([-θ; ϕ + ϵ * ϕ; -distance / 2])))
    headx1[] = Point3f(normalize(ℝ³(pointup1[]) - rotate(radius + rotate(ℝ³([transform(-θ + ϵ * (-θ), ϕ, α₁, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₁, ẑ))))
    headx2[] = Point3f(normalize(ℝ³(pointup2[]) - rotate(radius + rotate(ℝ³([transform(-θ + ϵ * (-θ), ϕ, α₂, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₂, ẑ))))
    headx3[] = Point3f(normalize(ℝ³(pointup3[]) - rotate(radius + rotate(ℝ³([transform(-θ + ϵ * (-θ), ϕ, α₃, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₃, ẑ))))
    headx4[] = Point3f(normalize(ℝ³(pointup4[]) - rotate(radius + rotate(ℝ³([transform(-θ + ϵ * (-θ), ϕ, α₄, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₄, ẑ))))
    heady1[] = Point3f(normalize(ℝ³(pointup1[]) - rotate(radius + rotate(ℝ³([transform(-θ, ϕ + ϵ * ϕ, α₁, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₁, ẑ))))
    heady2[] = Point3f(normalize(ℝ³(pointup2[]) - rotate(radius + rotate(ℝ³([transform(-θ, ϕ + ϵ * ϕ, α₂, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₂, ẑ))))
    heady3[] = Point3f(normalize(ℝ³(pointup3[]) - rotate(radius + rotate(ℝ³([transform(-θ, ϕ + ϵ * ϕ, α₃, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₃, ẑ))))
    heady4[] = Point3f(normalize(ℝ³(pointup4[]) - rotate(radius + rotate(ℝ³([transform(-θ, ϕ + ϵ * ϕ, α₄, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₄, ẑ))))
    α₁ = ((stageprogress + ϵ) % 1.0) * distance
    α₂ = ((stageprogress + ϵ + 0.5) % 1.0) * distance
    α₃ = (((1 - (stageprogress + ϵ))) % 1.0) * distance
    α₄ = (((1 - (stageprogress + ϵ)) + 0.5) % 1.0) * distance
    headz1[] = Point3f(normalize(rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₁, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₁, ẑ)) - ℝ³(pointup1[])))
    headz2[] = Point3f(normalize(rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₂, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₂, ẑ)) - ℝ³(pointup2[])))
    headz3[] = Point3f(normalize(rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₃, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₃, ẑ)) - ℝ³(pointup3[])))
    headz4[] = Point3f(normalize(rotate(radius + rotate(ℝ³([transform(-θ, ϕ, α₄, interpolation)...; 0.0]), ℍ(π / 2, x̂)), ℍ(α₄, ẑ)) - ℝ³(pointup4[])))
    push!(path[], pointdown[])
    push!(path1[], pointup1[])
    push!(path2[], pointup2[])
    push!(path3[], pointup3[])
    push!(path4[], pointup4[])
    notify(path)
    notify(path1)
    notify(path2)
    notify(path3)
    notify(path4)
    for index in 1:length(boundary_names)
        boundary = convert_to_geographic.(boundary_nodes[index])
        updatesurface!([rotate(radius + rotate(ℝ³(transform(vec(boundary[i])[2:3]..., _distance, interpolation)..., 0.0), ℍ(π / 2, x̂)), ℍ(_distance, ẑ)) for i in eachindex(boundary), _distance in lspace], fibersobservables[index])
    end
    global lookat = (ℝ³(pointdown[]) + sum(section1) * (1.0 / segments^2)) * 0.5
    updatecamera!(lscene, eyeposition, lookat, up)
end


# animate(1)
# path[] = Point3f[]
# path1[] = Point3f[]
# path2[] = Point3f[]
# path3[] = Point3f[]
# path4[] = Point3f[]
record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end