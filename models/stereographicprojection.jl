import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 6 * 720
modelname = "stereographicprojection"
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π * 0.8
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
linewidth = 8.0
ratio = 0.05

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = ["United States of America", "Australia", "Antarctica", "Iran", "Canada", "Russia"]
totalstages = length(boundary_names)
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
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :black))

mask = FileIO.load("data/basemap_mask.png")

lspaceθ = range(π / 2, stop = -π / 2, length = segments)
lspaceϕ = range(-π, stop = float(π), length = segments)
spherematrix = [convert_to_cartesian([1.0; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ]
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)
spherematrix = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspaceθ, ϕ in lspaceϕ]
updatesurface!(spherematrix, sphereobservable)


project(p::ℝ³) = ℝ³(vec(p)[1], vec(p)[2], 0.0) * (1.0 / (1.0 - vec(p)[3]))

planematrix = [project(convert_to_cartesian([1.0; θ; ϕ])) for θ in lspaceθ, ϕ in lspaceϕ]
planeobservable = buildsurface(lscene, planematrix, mask, transparency = true)
planematrix = [project(convert_to_cartesian([1.0; θ; ϕ])) for θ in lspaceθ, ϕ in lspaceϕ]
updatesurface!(planematrix, planeobservable)

observablepoints = []
observablecolors = []
lines = []
for i in 1:totalstages
    _points = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
    _colors = GLMakie.Observable(Int[])
    _lines = GLMakie.lines!(lscene, _points, linewidth = 2linewidth, color = _colors, colormap = :rainbow, transparency = false)
    push!(observablepoints, _points)
    push!(observablecolors, _colors)
    push!(lines, _lines)
end

points1 = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors1 = GLMakie.Observable(Int[])
lines1 = GLMakie.lines!(lscene, points1, linewidth = 2linewidth, color = colors1, colormap = :rainbow, transparency = false)
points2 = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors2 = GLMakie.Observable(Int[])
lines2 = GLMakie.lines!(lscene, points2, linewidth = 2linewidth, color = colors2, colormap = :rainbow, transparency = false)


updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end

previousstage = 1


animate(frame::Int) = begin
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    # trigger stage change
    if stage != previousstage
        global previousstage = stage
        points1[] = GLMakie.Point3f[]
        colors1[] = Int[]
        points2[] = GLMakie.Point3f[]
        colors2[] = Int[]
    end

    for s in 1:totalstages
        observablepoints[s][] = GLMakie.Point3f[]
        observablecolors[s][] = Int[]
    end

    nodes = boundary_nodes[stage]
    N = length(nodes)
    index = max(1, Int(floor(stageprogress * N)))
    p = nodes[index]
    p₀ = project(p)
    _points = GLMakie.Point3f[]
    _colors = []
    northpole = ℝ³(0.0, 0.0, 1.0)
    push!(_points, GLMakie.Point3f(vec(northpole)...))
    push!(_points, GLMakie.Point3f(vec(p)...))
    push!(_points, GLMakie.Point3f(vec(p₀)...))
    push!(_colors, 1)
    push!(_colors, 2)
    push!(_colors, 3)
    observablepoints[stage][] = _points
    observablecolors[stage][] = _colors

    _points1 = points1[]
    push!(_points1, GLMakie.Point3f(vec(p)...))
    points1[] = _points1
    _colors1 = colors1[]
    push!(_colors1, index)
    colors1[] = _colors1

    _points2 = points2[]
    push!(_points2, GLMakie.Point3f(vec(p₀)...))
    points2[] = _points2
    _colors2 = colors2[]
    push!(_colors2, index)
    colors2[] = _colors2

    global eyeposition = ratio * (cross(p, p₀) + p * π) + (1.0 - ratio) * eyeposition
    θ = convert_to_geographic(p)[2]
    if θ > 0
        global lookat = ratio * (p + normalize(p₀)) + (1.0 - ratio) * lookat
    else
        global lookat = ratio * (p + p₀) + (1.0 - ratio) * lookat
    end
    updatecamera()
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end