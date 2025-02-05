using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig13stereographicprojection"
totalstages = 1
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π * 0.8
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
linewidth = 8.0
ratio = 0.05
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = ["Iran"]
boundary_nodes = Vector{Vector{ℝ³}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
        end
    end
end


makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

mask = load("data/basemap_mask.png")

lspaceθ = range(π / 2, stop = -π / 2, length = segments)
lspaceϕ = range(-π, stop = float(π), length = segments)
spherematrix = [convert_to_cartesian([1.0; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ]
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)
spherematrix = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspaceθ, ϕ in lspaceϕ]
updatesurface!(spherematrix, sphereobservable)

planematrix = [project(convert_to_cartesian([1.0; θ; ϕ])) for θ in lspaceθ, ϕ in lspaceϕ]
planeobservable = buildsurface(lscene, planematrix, mask, transparency = true)
planematrix = [project(convert_to_cartesian([1.0; θ; ϕ])) for θ in lspaceθ, ϕ in lspaceϕ]
updatesurface!(planematrix, planeobservable)

Ppoints = Observable(Point3f[])
Ppoints′ = Observable(Point3f[])
Pcolors = Observable(Int[])
Pcolors′ = Observable(Int[])
Plines = lines!(lscene, Ppoints, linewidth = 2linewidth, color = Pcolors, colormap = :rainbow, colorrange = (1, frames_number), transparency = false)
Plines′ = lines!(lscene, Ppoints′, linewidth = 2linewidth, color = Pcolors′, colormap = :rainbow, colorrange = (1, frames_number), transparency = false)

colorants = [:red, :green, :blue, :black, :orange, :gold]
Abase = Observable(Point3f(0.0, 0.0, 0.0))
Bbase = Observable(Point3f(0.0, 0.0, 0.0))
Cbase = Observable(Point3f(0.0, 0.0, 0.0))
Nbase = Observable(Point3f(0.0, 0.0, 1.0))
Pbase = Observable(Point3f(0.0, 0.0, 0.0))
Pbase′ = Observable(Point3f(0.0, 0.0, 0.0))
Aball = meshscatter!(lscene, Abase, markersize = 0.05, color = colorants[1])
Bball = meshscatter!(lscene, Bbase, markersize = 0.05, color = colorants[2])
Cball = meshscatter!(lscene, Cbase, markersize = 0.05, color = colorants[3])
Nball = meshscatter!(lscene, Nbase, markersize = 0.05, color = colorants[4])
Pball = meshscatter!(lscene, Pbase, markersize = 0.05, color = colorants[5])
Pball′ = meshscatter!(lscene, Pbase′, markersize = 0.05, color = colorants[6])

segmentNPP′ = @lift([$Nbase, $Pbase, $Pbase′])
segmentNPP′colors = Observable([1, 2, 3])
lines!(lscene, segmentNPP′, linewidth = 2linewidth, color = segmentNPP′, colormap = :plasma, colorrange = (1, 3), transparency = false)
segmentAP = @lift([$Abase, $Pbase])
segmentBP = @lift([$Bbase, $Pbase])
segmentCN = @lift([$Cbase, $Nbase])
segmentCP′ = @lift([$Cbase, $Pbase′])
segmentcolors = Observable([1, 2])
lines!(lscene, segmentAP, linewidth = 2linewidth, color = segmentcolors, colormap = :spring, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentBP, linewidth = 2linewidth, color = segmentcolors, colormap = :summer, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentCN, linewidth = 2linewidth, color = segmentcolors, colormap = :fall, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentCP′, linewidth = 2linewidth, color = segmentcolors, colormap = :winter, colorrange = (1, 2), transparency = false)


titles = ["A", "B", "C", "N", "P", "P′"]
rotation = gettextrotation(lscene)
textobservables = Observable(Point3f[])
textobservables[] = [Abase[], Bbase[], Cbase[], Nbase[], Pbase[], Pbase′[]]
text!(lscene,
    textobservables,
    text = titles,
    color = colorants,
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)


animate(frame::Int) = begin
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    nodes = boundary_nodes[stage]
    N = length(nodes)
    index = max(1, Int(floor(stageprogress * N)))
    P = nodes[index]
    P′ = project(P)
    Abase[] = Point3f([vec(P)[1:2]..., 0.0])
    Bbase[] = Point3f([0.0; 0.0; vec(P)[3]])
    Pbase[] = Point3f(P)
    Pbase′[] = Point3f(P′)
    push!(Ppoints[], Point3f(P))
    push!(Ppoints′[], Point3f(P′))
    push!(Pcolors[], index)
    push!(Pcolors′[], index)
    notify(Ppoints)
    notify(Pcolors)
    notify(Ppoints′)
    notify(Pcolors′)
    textobservables[] = [Abase[], Bbase[], Cbase[], Nbase[], Pbase[], Pbase′[]]

    if frame == 1
        ratio = 1.0
    else
        ratio = 0.05
    end
    global eyeposition = ratio * (P′ + ℝ³(Float64.(vec(Nbase[]))...) + normalize(cross(P, P′)) * Float64(π)) + (1.0 - ratio) * eyeposition
    θ = convert_to_geographic(P)[2]
    if θ > 0
        global lookat = ratio * (normalize(P′) + ℝ³(Float64.(vec(Cbase[]))...)) + (1.0 - ratio) * lookat
    else
        global lookat = ratio * (P′ + ℝ³(Float64.(vec(Cbase[]))...)) + (1.0 - ratio) * lookat
    end
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end