import FileIO
import GLMakie
import LinearAlgebra
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


makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

mask = FileIO.load("data/basemap_mask.png")

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

Ppoints = GLMakie.Observable(GLMakie.Point3f[])
Ppoints′ = GLMakie.Observable(GLMakie.Point3f[])
Pcolors = GLMakie.Observable(Int[])
Pcolors′ = GLMakie.Observable(Int[])
Plines = GLMakie.lines!(lscene, Ppoints, linewidth = 2linewidth, color = Pcolors, colormap = :rainbow, colorrange = (1, frames_number), transparency = false)
Plines′ = GLMakie.lines!(lscene, Ppoints′, linewidth = 2linewidth, color = Pcolors′, colormap = :rainbow, colorrange = (1, frames_number), transparency = false)

colorants = [:red, :green, :blue, :black, :orange, :gold]
Abase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
Bbase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
Cbase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
Nbase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 1.0))
Pbase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
Pbase′ = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
Aball = GLMakie.meshscatter!(lscene, Abase, markersize = 0.05, color = colorants[1])
Bball = GLMakie.meshscatter!(lscene, Bbase, markersize = 0.05, color = colorants[2])
Cball = GLMakie.meshscatter!(lscene, Cbase, markersize = 0.05, color = colorants[3])
Nball = GLMakie.meshscatter!(lscene, Nbase, markersize = 0.05, color = colorants[4])
Pball = GLMakie.meshscatter!(lscene, Pbase, markersize = 0.05, color = colorants[5])
Pball′ = GLMakie.meshscatter!(lscene, Pbase′, markersize = 0.05, color = colorants[6])

segmentNPP′ = GLMakie.@lift([$Nbase, $Pbase, $Pbase′])
segmentNPP′colors = GLMakie.Observable([1, 2, 3])
GLMakie.lines!(lscene, segmentNPP′, linewidth = 2linewidth, color = segmentNPP′, colormap = :plasma, colorrange = (1, 3), transparency = false)
segmentAP = GLMakie.@lift([$Abase, $Pbase])
segmentBP = GLMakie.@lift([$Bbase, $Pbase])
segmentCN = GLMakie.@lift([$Cbase, $Nbase])
segmentCP′ = GLMakie.@lift([$Cbase, $Pbase′])
segmentcolors = GLMakie.Observable([1, 2])
GLMakie.lines!(lscene, segmentAP, linewidth = 2linewidth, color = segmentcolors, colormap = :spring, colorrange = (1, 2), transparency = false)
GLMakie.lines!(lscene, segmentBP, linewidth = 2linewidth, color = segmentcolors, colormap = :summer, colorrange = (1, 2), transparency = false)
GLMakie.lines!(lscene, segmentCN, linewidth = 2linewidth, color = segmentcolors, colormap = :fall, colorrange = (1, 2), transparency = false)
GLMakie.lines!(lscene, segmentCP′, linewidth = 2linewidth, color = segmentcolors, colormap = :winter, colorrange = (1, 2), transparency = false)


titles = ["A", "B", "C", "N", "P", "P′"]
eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation = GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle, $rotationaxis) * ℍ(getrotation(ẑ, $rotationaxis)...)))
textobservables = GLMakie.Observable(GLMakie.Point3f[])
textobservables[] = [Abase[], Bbase[], Cbase[], Nbase[], Pbase[], Pbase′[]]
GLMakie.text!(lscene,
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
    Abase[] = GLMakie.Point3f([vec(P)[1:2]..., 0.0])
    Bbase[] = GLMakie.Point3f([0.0; 0.0; vec(P)[3]])
    Pbase[] = GLMakie.Point3f(P)
    Pbase′[] = GLMakie.Point3f(P′)
    push!(Ppoints[], GLMakie.Point3f(P))
    push!(Ppoints′[], GLMakie.Point3f(P′))
    push!(Pcolors[], index)
    push!(Pcolors′[], index)
    GLMakie.notify(Ppoints)
    GLMakie.notify(Pcolors)
    GLMakie.notify(Ppoints′)
    GLMakie.notify(Pcolors′)
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
    updatecamera(lscene, eyeposition, lookat, up)
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end