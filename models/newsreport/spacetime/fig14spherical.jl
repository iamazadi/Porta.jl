using FileIO
using GLMakie
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
stage = 1
Plines = lines!(lscene, Ppoints, linewidth = 2linewidth, color = Pcolors, colormap = :rainbow, colorrange = (1, length(boundary_nodes[stage])), transparency = false)
Plines′ = lines!(lscene, Ppoints′, linewidth = 2linewidth, color = Pcolors′, colormap = :rainbow, colorrange = (1, length(boundary_nodes[stage])), transparency = false)

colorants = [:gold, :purple, :navyblue, :black, :orange]
Sbase = Observable(Point3f(0.0, 0.0, -1.0))
Cbase = Observable(Point3f(0.0, 0.0, 0.0))
Nbase = Observable(Point3f(0.0, 0.0, 1.0))
Pbase = Observable(Point3f(0.0, 0.0, 0.0))
Pbase′ = Observable(Point3f(0.0, 0.0, 0.0))
Sball = meshscatter!(lscene, Sbase, markersize = 0.05, color = colorants[1])
Cball = meshscatter!(lscene, Cbase, markersize = 0.05, color = colorants[2])
Nball = meshscatter!(lscene, Nbase, markersize = 0.05, color = colorants[3])
Pball = meshscatter!(lscene, Pbase, markersize = 0.05, color = colorants[4])
Pball′ = meshscatter!(lscene, Pbase′, markersize = 0.05, color = colorants[5])

segmentNPP′ = @lift([$Nbase, $Pbase, $Pbase′])
segmentNPP′colors = Observable([1, 2, 3])
lines!(lscene, segmentNPP′, linewidth = 2linewidth, color = segmentNPP′, colormap = :plasma, colorrange = (1, 3), transparency = false)
segmentSP = @lift([$Sbase, $Pbase])
segmentSC = @lift([$Sbase, $Cbase])
segmentCN = @lift([$Cbase, $Nbase])
segmentCP = @lift([$Cbase, $Pbase])
segmentCP′ = @lift([$Cbase, $Pbase′])
segmentcolors = Observable([1, 2])
lines!(lscene, segmentSP, linewidth = 2linewidth, color = segmentcolors, colormap = :spring, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentSC, linewidth = 2linewidth, color = segmentcolors, colormap = :summer, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentCN, linewidth = 2linewidth, color = segmentcolors, colormap = :fall, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentCP, linewidth = 2linewidth, color = segmentcolors, colormap = :winter, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentCP′, linewidth = 2linewidth, color = segmentcolors, colormap = :winter, colorrange = (1, 2), transparency = false)

ϕarc1 = Observable(Point3f[])
ϕarc2 = Observable(Point3f[])
ϕarccolors = Observable(Int[])
lines!(lscene, ϕarc1, linewidth = 2linewidth, color = ϕarccolors, colormap = :blues, colorrange = (1, segments), transparency = false)
lines!(lscene, ϕarc2, linewidth = 2linewidth, color = ϕarccolors, colormap = :blues, colorrange = (1, segments), transparency = false)

arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
arrowscale = 1.2
tail = Observable(Point3f(0.0, 0.0, 0.0))
xhead = Observable(Point3f(arrowscale * x̂))
yhead = Observable(Point3f(arrowscale * ŷ))
zhead = Observable(Point3f(arrowscale * ẑ))
ps = @lift([$tail, $tail, $tail])
ns = @lift([$xhead, $yhead, $zhead])
axiscolorants = [:red, :green, :blue]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = axiscolorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

rotation = gettextrotation(lscene)
textobservables = Observable(Point3f[])
titles = ["S", "C", "N", "P", "P′", "x", "y", "z"]
textobservables[] = [Sbase[], Cbase[], Nbase[], Pbase[], Pbase′[], xhead[], yhead[], zhead[]]
text!(lscene,
    textobservables,
    text = titles,
    color = [colorants; axiscolorants],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

θlinepoints1 = Observable(Point3f[])
θlinepoints2 = Observable(Point3f[])
θlinepoints3 = Observable(Point3f[])
ϕlinepoints1 = Observable(Point3f[])
ϕlinepoints2 = Observable(Point3f[])
linecolors = Observable(Int[])
lines!(lscene, θlinepoints1, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)
lines!(lscene, θlinepoints2, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)
lines!(lscene, θlinepoints3, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)
lines!(lscene, ϕlinepoints1, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)
lines!(lscene, ϕlinepoints2, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :grays)


anglestitles = ["θ", "θ/2", "θ/2", "ϕ", "ϕ"]
anglestextobservables = Observable(Point3f[])
anglestextobservables[] = [Point3f(0.0, 0.0, 0.0) for _ in anglestitles]
text!(lscene,
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
    textobservables[] = [Sbase[], Cbase[], Nbase[], Pbase[], Pbase′[], xhead[], yhead[], zhead[]]

    θlinepoints1[] = Point3f[]
    θlinepoints2[] = Point3f[]
    ϕlinepoints1[] = Point3f[]
    ϕlinepoints2[] = Point3f[]

    θlinepoints1[] = [Point3f(normalize(α * N + (1.0 - α) * P)) for α in range(0.0, stop = 1.0, length = segments)] .* 0.5
    θlinepoints2[] = [Point3f(S + 0.5 * normalize((α * N + (1.0 - α) * normalize(P - S)))) for α in range(0.0, stop = 1.0, length = segments)]
    θlinepoints3[] = [Point3f(P′ + 0.5 * normalize((α * normalize(N - P′) + (1.0 - α) * normalize(C - P′)))) for α in range(0.0, stop = 1.0, length = segments)]

    ϕlinepoints1[] = [Point3f(normalize(α * x̂ + (1.0 - α) * P′)) for α in range(0.0, stop = 1.0, length = segments)] .* 0.5
    ϕlinepoints2[] = map(x -> Point3f(ℝ³(Float64.(vec(x)[1:2])... , Float64(√(1.0 - (vec(x)[1]^2 + vec(x)[2]^2))))), ϕlinepoints1[])
    linecolors[] = collect(1:segments)
    notify(θlinepoints1)
    notify(θlinepoints2)
    notify(θlinepoints3)
    notify(ϕlinepoints1)
    notify(ϕlinepoints2)
    notify(linecolors)

    ϕarc1[] = [Point3f(normalize(α * N + (1.0 - α) * P′)) for α in range(0.0, stop = 1.0, length = segments)]
    ϕarc2[] = [Point3f(normalize(α * N + (1.0 - α) * x̂)) for α in range(0.0, stop = 1.0, length = segments)]
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
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end