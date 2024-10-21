import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig14spherical"
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
stage = 1
Plines = GLMakie.lines!(lscene, Ppoints, linewidth = 2linewidth, color = Pcolors, colormap = :rainbow, colorrange = (1, length(boundary_nodes[stage])), transparency = false)
Plines′ = GLMakie.lines!(lscene, Ppoints′, linewidth = 2linewidth, color = Pcolors′, colormap = :rainbow, colorrange = (1, length(boundary_nodes[stage])), transparency = false)

colorants = [:gold, :purple, :navyblue, :black, :orange]
Sbase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, -1.0))
Cbase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
Nbase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 1.0))
Pbase = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
Pbase′ = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
Sball = GLMakie.meshscatter!(lscene, Sbase, markersize = 0.05, color = colorants[1])
Cball = GLMakie.meshscatter!(lscene, Cbase, markersize = 0.05, color = colorants[2])
Nball = GLMakie.meshscatter!(lscene, Nbase, markersize = 0.05, color = colorants[3])
Pball = GLMakie.meshscatter!(lscene, Pbase, markersize = 0.05, color = colorants[4])
Pball′ = GLMakie.meshscatter!(lscene, Pbase′, markersize = 0.05, color = colorants[5])

segmentNPP′ = GLMakie.@lift([$Nbase, $Pbase, $Pbase′])
segmentNPP′colors = GLMakie.Observable([1, 2, 3])
GLMakie.lines!(lscene, segmentNPP′, linewidth = 2linewidth, color = segmentNPP′, colormap = :plasma, colorrange = (1, 3), transparency = false)
segmentSP = GLMakie.@lift([$Sbase, $Pbase])
segmentSC = GLMakie.@lift([$Sbase, $Cbase])
segmentCN = GLMakie.@lift([$Cbase, $Nbase])
segmentCP = GLMakie.@lift([$Cbase, $Pbase])
segmentCP′ = GLMakie.@lift([$Cbase, $Pbase′])
segmentcolors = GLMakie.Observable([1, 2])
GLMakie.lines!(lscene, segmentSP, linewidth = 2linewidth, color = segmentcolors, colormap = :spring, colorrange = (1, 2), transparency = false)
GLMakie.lines!(lscene, segmentSC, linewidth = 2linewidth, color = segmentcolors, colormap = :summer, colorrange = (1, 2), transparency = false)
GLMakie.lines!(lscene, segmentCN, linewidth = 2linewidth, color = segmentcolors, colormap = :fall, colorrange = (1, 2), transparency = false)
GLMakie.lines!(lscene, segmentCP, linewidth = 2linewidth, color = segmentcolors, colormap = :winter, colorrange = (1, 2), transparency = false)
GLMakie.lines!(lscene, segmentCP′, linewidth = 2linewidth, color = segmentcolors, colormap = :winter, colorrange = (1, 2), transparency = false)

ϕarc1 = GLMakie.Observable(GLMakie.Point3f[])
ϕarc2 = GLMakie.Observable(GLMakie.Point3f[])
ϕarccolors = GLMakie.Observable(Int[])
GLMakie.lines!(lscene, ϕarc1, linewidth = 2linewidth, color = ϕarccolors, colormap = :blues, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene, ϕarc2, linewidth = 2linewidth, color = ϕarccolors, colormap = :blues, colorrange = (1, segments), transparency = false)

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
arrowscale = 1.2
tail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
xhead = GLMakie.Observable(GLMakie.Point3f(arrowscale * x̂))
yhead = GLMakie.Observable(GLMakie.Point3f(arrowscale * ŷ))
zhead = GLMakie.Observable(GLMakie.Point3f(arrowscale * ẑ))
ps = GLMakie.@lift([$tail, $tail, $tail])
ns = GLMakie.@lift([$xhead, $yhead, $zhead])
axiscolorants = [:red, :green, :blue]
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = axiscolorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation = GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle, $rotationaxis) * ℍ(getrotation(ẑ, $rotationaxis)...)))
textobservables = GLMakie.Observable(GLMakie.Point3f[])
titles = ["S", "C", "N", "P", "P′", "x", "y", "z"]
textobservables[] = [Sbase[], Cbase[], Nbase[], Pbase[], Pbase′[], xhead[], yhead[], zhead[]]
GLMakie.text!(lscene,
    textobservables,
    text = titles,
    color = [colorants; axiscolorants],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

θlinepoints1 = GLMakie.Observable(GLMakie.Point3f[])
θlinepoints2 = GLMakie.Observable(GLMakie.Point3f[])
θlinepoints3 = GLMakie.Observable(GLMakie.Point3f[])
ϕlinepoints1 = GLMakie.Observable(GLMakie.Point3f[])
ϕlinepoints2 = GLMakie.Observable(GLMakie.Point3f[])
linecolors = GLMakie.Observable(Int[])
GLMakie.lines!(lscene, θlinepoints1, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)
GLMakie.lines!(lscene, θlinepoints2, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)
GLMakie.lines!(lscene, θlinepoints3, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)
GLMakie.lines!(lscene, ϕlinepoints1, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)
GLMakie.lines!(lscene, ϕlinepoints2, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)


anglestitles = ["θ", "θ/2", "θ/2", "ϕ", "ϕ"]
anglestextobservables = GLMakie.Observable(GLMakie.Point3f[])
anglestextobservables[] = [GLMakie.Point3f(0.0, 0.0, 0.0) for _ in anglestitles]
GLMakie.text!(lscene,
    anglestextobservables,
    text = anglestitles,
    color = [:black for _ in anglestitles],
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
    number = length(nodes)
    index = max(1, Int(floor(stageprogress * number)))
    S = ℝ³(Float64.(vec(Sbase[]))...)
    C = ℝ³(Float64.(vec(Cbase[]))...)
    N = ℝ³(Float64.(vec(Nbase[]))...)
    P = nodes[index]
    P′ = project(P)
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
    textobservables[] = [Sbase[], Cbase[], Nbase[], Pbase[], Pbase′[], xhead[], yhead[], zhead[]]

    θlinepoints1[] = GLMakie.Point3f[]
    θlinepoints2[] = GLMakie.Point3f[]
    ϕlinepoints1[] = GLMakie.Point3f[]
    ϕlinepoints2[] = GLMakie.Point3f[]

    θlinepoints1[] = [GLMakie.Point3f(normalize(α * N + (1.0 - α) * P)) for α in range(0.0, stop = 1.0, length = segments)] .* 0.5
    θlinepoints2[] = [GLMakie.Point3f(S + 0.5 * normalize((α * N + (1.0 - α) * normalize(P - S)))) for α in range(0.0, stop = 1.0, length = segments)]
    θlinepoints3[] = [GLMakie.Point3f(P′ + 0.5 * normalize((α * normalize(N - P′) + (1.0 - α) * normalize(C - P′)))) for α in range(0.0, stop = 1.0, length = segments)]

    ϕlinepoints1[] = [GLMakie.Point3f(normalize(α * x̂ + (1.0 - α) * P′)) for α in range(0.0, stop = 1.0, length = segments)] .* 0.5
    ϕlinepoints2[] = map(x -> GLMakie.Point3f(ℝ³(Float64.(vec(x)[1:2])... , Float64(√(1.0 - (vec(x)[1]^2 + vec(x)[2]^2))))), ϕlinepoints1[])
    linecolors[] = collect(1:segments)
    GLMakie.notify(θlinepoints1)
    GLMakie.notify(θlinepoints2)
    GLMakie.notify(θlinepoints3)
    GLMakie.notify(ϕlinepoints1)
    GLMakie.notify(ϕlinepoints2)
    GLMakie.notify(linecolors)

    ϕarc1[] = [GLMakie.Point3f(normalize(α * N + (1.0 - α) * P′)) for α in range(0.0, stop = 1.0, length = segments)]
    ϕarc2[] = [GLMakie.Point3f(normalize(α * N + (1.0 - α) * x̂)) for α in range(0.0, stop = 1.0, length = segments)]
    ϕarccolors[] = collect(1:segments)

    θ1 = θlinepoints1[][1]
    θ2 = θlinepoints2[][1]
    θ3 = θlinepoints2[][1]
    ϕ1 = ϕlinepoints1[][1]
    ϕ2 = ϕlinepoints2[][1]
    for i in 2:segments
        θ1 += θlinepoints1[][i]
        θ2 += θlinepoints2[][i]
        θ3 += θlinepoints3[][i]
        ϕ1 += ϕlinepoints1[][i]
        ϕ2 += ϕlinepoints2[][i]
    end
    θ1 *= (1.0 / Float64(segments))
    θ2 *= (1.0 / Float64(segments))
    θ3 *= (1.0 / Float64(segments))
    ϕ1 *= (1.0 / Float64(segments))
    ϕ2 *= (1.0 / Float64(segments))
    anglestextobservables[] = [θ1, θ2, θ3, ϕ1, ϕ2]

    if frame == 1
        ratio = 1.0
    else
        ratio = 0.05
    end
    global eyeposition = ratio * (π / 2.0 * P′ + π / 2.0 * ℝ³(Float64.(vec(Nbase[]))...) + π / 2.0 * normalize(-cross(P, P′)) * Float64(π / 2.0)) + (1.0 - ratio) * eyeposition
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