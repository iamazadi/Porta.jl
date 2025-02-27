using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 360
modelname = "fig118spinvectorssplus"
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
frames_number = length(boundary_names) * 360
totalstages = length(boundary_names)
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

Ppoints_observable = []
Ppoints_observable′ = []
Qpoints_observable = []
Qpoints_observable′ = []
Pcolors_observable = []
Qcolors_observable = []
Plines = []
Qlines = []
for i in 1:totalstages
    Ppoints = Observable(Point3f[])
    Ppoints′ = Observable(Point3f[])
    Pcolors = Observable(Int[])
    Qpoints = Observable(Point3f[])
    Qpoints′ = Observable(Point3f[])
    Qcolors = Observable(Int[])
    push!(Ppoints_observable, Ppoints)
    push!(Ppoints_observable′, Ppoints′)
    push!(Pcolors_observable, Pcolors)
    push!(Plines, lines!(lscene, Ppoints, linewidth = 2linewidth, color = Pcolors, colormap = :plasma, transparency = false))
    push!(Qpoints_observable, Qpoints)
    push!(Qpoints_observable′, Qpoints′)
    push!(Qcolors_observable, Qcolors)
    push!(Qlines, lines!(lscene, Qpoints, linewidth = 2linewidth, color = Qcolors, colormap = :plasma, transparency = false))
end

Praypoints1 = Observable(Point3f[])
Praycolors1 = Observable(Int[])
Praylines1 = lines!(lscene, Praypoints1, linewidth = 2linewidth, color = Praycolors1, colormap = :plasma, transparency = false)
Praypoints2 = Observable(Point3f[])
Praycolors2 = Observable(Int[])
Praylines2 = lines!(lscene, Praypoints2, linewidth = 2linewidth, color = Praycolors2, colormap = :plasma, transparency = false)

Qraypoints1 = Observable(Point3f[])
Qraycolors1 = Observable(Int[])
Qraylines1 = lines!(lscene, Qraypoints1, linewidth = 2linewidth, color = Qraycolors1, colormap = :plasma, transparency = false)
Qraypoints2 = Observable(Point3f[])
Qraycolors2 = Observable(Int[])
Qraylines2 = lines!(lscene, Qraypoints2, linewidth = 2linewidth, color = Qraycolors2, colormap = :plasma, transparency = false)

previousstage = 1

timesign = -1
ο = SpinVector([Complex(1.0); Complex(0.0)], timesign)
ι = SpinVector([Complex(0.0); Complex(1.0)], timesign)
@assert(isapprox(dot(ο, ι), 1.0), "The inner product of spin vectors $ι and $ο is not unity.")
@assert(isapprox(dot(ι, ο), -1.0), "The inner product of spin vectors $ι and $ο is not unity.")

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
ω = SpinVector(generate(), generate(), timesign)
@assert(isapprox(dot(κ, ι), vec(κ)[1]), "The first component of the spin vector $κ is not equal to the inner product of $κ and $ι.")
@assert(isapprox(dot(κ, ο), -vec(κ)[2]), "The second component of the spin vector $κ is not equal to minus the inner product of $κ and $ο.")
@assert(isapprox(dot(ω, ι), vec(ω)[1]), "The first component of the spin vector $ω is not equal to the inner product of $ω and $ι.")
@assert(isapprox(dot(ω, ο), -vec(ω)[2]), "The second component of the spin vector $ω is not equal to minus the inner product of $ω and $ο.")

Ptail = Observable(Point3f(0.0, 0.0, 0.0))
Ptail₀ = Observable(Point3f(0.0, 0.0, 0.0))
Phead = Observable(Point3f(vec(project(ℍ(vec(κ))))...))
Phead₀ = Observable(Point3f(vec(project(ℍ(vec(κ))))...))
Qtail = Observable(Point3f(0.0, 0.0, 0.0))
Qtail₀ = Observable(Point3f(0.0, 0.0, 0.0))
Qhead = Observable(Point3f(vec(project(ℍ(vec(ω))))...))
Qhead₀ = Observable(Point3f(vec(project(ℍ(vec(ω))))...))
colorants = [:red, :blue, :green, :orange]
northpole = Observable(Point3f(vec(ẑ)))
meshscatter!(lscene, northpole, markersize = 0.05, color = :black)
meshscatter!(lscene, Ptail, markersize = 0.05, color = colorants[1])
meshscatter!(lscene, Ptail₀, markersize = 0.05, color = colorants[2])
meshscatter!(lscene, Qtail, markersize = 0.05, color = colorants[3])
meshscatter!(lscene, Qtail₀, markersize = 0.05, color = colorants[4])

ps = @lift([$Ptail, $Ptail₀, $Qtail, $Qtail₀])
ns = @lift([$Phead, $Phead₀, $Qhead, $Qhead₀])

arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

titles = ["P", "P′", "P₀", "P′₀", "Q", "Q′", "Q₀", "Q′₀", "N"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f(vec(x)), [$Ptail, $Ptail + $Phead, $Ptail₀, $Ptail₀ + $Phead₀, $Qtail, $Qtail + $Qhead, $Qtail₀, $Qtail₀ + $Qhead₀, $northpole])),
    text = titles,
    color = [:red, :red, :blue, :blue, :green, :green, :orange, :orange, :black],
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

    # trigger stage change
    if stage != previousstage
        global previousstage = stage
        Praypoints1[] = Point3f[]
        Praycolors1[] = Int[]
        Praypoints2[] = Point3f[]
        Praycolors2[] = Int[]
        Qraypoints1[] = Point3f[]
        Qraycolors1[] = Int[]
        Qraypoints2[] = Point3f[]
        Qraycolors2[] = Int[]
    end

    for s in 1:totalstages
        Ppoints_observable[s][] = Point3f[]
        Ppoints_observable′[s][] = Point3f[]
        Pcolors_observable[s][] = Int[]
        Qpoints_observable[s][] = Point3f[]
        Qpoints_observable′[s][] = Point3f[]
        Qcolors_observable[s][] = Int[]
    end

    nodes = boundary_nodes[stage]
    N = length(nodes)
    Pindex = max(1, Int(floor(stageprogress * N)))
    Pindex′ = max(1, (Pindex + 1) % N)
    Qindex = max(1, Int(floor((1.0 - stageprogress) * N)))
    Qindex′ = max(1, (Qindex + 1) % N)
    P = nodes[Pindex]
    P′ = nodes[Pindex′]
    Q = nodes[Qindex]
    Q′ = nodes[Qindex′]
    P₀ = project(P)
    P′₀ = project(P′)
    Q₀ = project(Q)
    Q′₀ = project(Q′)
    _Ppoints = Point3f[]
    _Ppoints′ = Point3f[]
    _Pcolors = []
    _Qpoints = Point3f[]
    _Qpoints′ = Point3f[]
    _Qcolors = []
    northpole[] = Point3f(vec(ℝ³(0.0, 0.0, 1.0)))
    push!(_Ppoints, northpole[])
    push!(_Ppoints, Point3f(vec(P)...))
    push!(_Ppoints, Point3f(vec(P′₀)...))
    push!(_Ppoints′, northpole[])
    push!(_Ppoints′, Point3f(vec(P)...))
    push!(_Ppoints′, Point3f(vec(P′₀)...))
    push!(_Pcolors, 1)
    push!(_Pcolors, 2)
    push!(_Pcolors, 3)
    push!(_Qpoints, northpole[])
    push!(_Qpoints, Point3f(vec(Q)...))
    push!(_Qpoints, Point3f(vec(Q′₀)...))
    push!(_Qpoints′, northpole[])
    push!(_Qpoints′, Point3f(vec(Q)...))
    push!(_Qpoints′, Point3f(vec(Q′₀)...))
    push!(_Qcolors, 1)
    push!(_Qcolors, 2)
    push!(_Qcolors, 3)
    Ppoints_observable[stage][] = _Ppoints
    Ppoints_observable′[stage][] = _Ppoints′
    Pcolors_observable[stage][] = _Pcolors
    Qpoints_observable[stage][] = _Qpoints
    Qpoints_observable′[stage][] = _Qpoints′
    Qcolors_observable[stage][] = _Qcolors

    _Praypoints1 = Praypoints1[]
    push!(_Praypoints1, Point3f(vec(P)...))
    Praypoints1[] = _Praypoints1
    _Praycolors1 = Praycolors1[]
    push!(_Praycolors1, Pindex)
    Praycolors1[] = _Praycolors1

    _Praypoints2 = Praypoints2[]
    push!(_Praypoints2, Point3f(vec(P₀)...))
    Praypoints2[] = _Praypoints2
    _Praycolors2 = Praycolors2[]
    push!(_Praycolors2, Pindex)
    Praycolors2[] = _Praycolors2

    _Qraypoints1 = Qraypoints1[]
    push!(_Qraypoints1, Point3f(vec(Q)...))
    Qraypoints1[] = _Qraypoints1
    _Qraycolors1 = Qraycolors1[]
    push!(_Qraycolors1, Qindex)
    Qraycolors1[] = _Qraycolors1

    _Qraypoints2 = Qraypoints2[]
    push!(_Qraypoints2, Point3f(vec(Q₀)...))
    Qraypoints2[] = _Qraypoints2
    _Qraycolors2 = Qraycolors2[]
    push!(_Qraycolors2, Qindex)
    Qraycolors2[] = _Qraycolors2

    vectorlength = 0.5

    Ptail[] = Point3f(vec(P))
    Phead[] = Point3f(vec(vectorlength * normalize(P′ - P))...)
    Ptail₀[] = Point3f(vec(P₀))
    Phead₀[] = Point3f(vec(vectorlength * normalize(P′₀ - P₀))...)

    Qtail[] = Point3f(vec(Q))
    Qhead[] = Point3f(vec(vectorlength * normalize(Q′ - Q))...)
    Qtail₀[] = Point3f(vec(Q₀))
    Qhead₀[] = Point3f(vec(vectorlength * normalize(Q′₀ - Q₀))...)

    ratio = frame == 1 ? 1.0 : 0.05

    global eyeposition = ratio * (cross(P, P₀) + P * π) + (1.0 - ratio) * eyeposition
    θ = convert_to_geographic(P)[2]
    if θ > 0
        global lookat = ratio * (P + normalize(P₀)) + (1.0 - ratio) * lookat
    else
        global lookat = ratio * (P + P₀) + (1.0 - ratio) * lookat
    end
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end