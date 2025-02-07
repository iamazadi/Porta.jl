using LinearAlgebra
using FileIO
using GLMakie
using Porta
using OrdinaryDiffEq, ForwardDiff, NonlinearSolve


H(q, p) = m * norm(p)^2 / 2 + m * g * norm(q)
L(q, p) = m * norm(p)^2 / 2 - m * g * norm(q)

pdot(dp, p, q, params, t) = ForwardDiff.gradient!(dp, q -> -H(q, p), q)
qdot(dq, p, q, params, t) = ForwardDiff.gradient!(dq, p -> H(q, p), p)


figuresize = (4096, 2160)
segments = 360
segments2 = 5
frames_number = 360
modelname = "fig207liouvillestheorem"
totalstages = 4
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
mask = load("data/basemap_mask.png")
reference = load("data/basemap_color.png")
radius = 1.0
altitude = 1.0 # the initial altitude
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set()
boundary_nodes = Vector{Vector{ℝ³}}()
points = Vector{Vector{ℍ}}()
indices = Dict()
boundarylinewidth = 12
markersize = 0.01
arrowlinewidth = 0.01
arrowsize = Vec3f(0.02, 0.02, 0.04)
const g = 1.0 # m / s²
const m = 1.0 # unit mass in kilogram
const ϵ = 1e-1
tspan = (0, 1.5)

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

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

lengths = length.(boundary_nodes)
N, boundary_index = findmax(lengths)
nodes = boundary_nodes[boundary_index]
center = sum([convert_to_geographic(x) for x in nodes]) .* (1.0 / N)

maxθ = max(map(x -> convert_to_geographic(x)[2], nodes)...)
minθ = min(map(x -> convert_to_geographic(x)[2], nodes)...)
maxϕ = max(map(x -> convert_to_geographic(x)[3], nodes)...)
minϕ = min(map(x -> convert_to_geographic(x)[3], nodes)...)
patchlspaceϕ = range(minϕ, stop = maxϕ, length = segments2)
patchlspaceθ = range(maxθ, stop = minθ, length = segments2)

solutions = []
balls = []
colors = []
trajectories = []
trajectorycolors = collect(1:frames_number)
ps = Observable(Point3f[])
ns = Observable(Point3f[])

for (index, node) in enumerate(nodes)
    initial_position = vec(node * (radius + altitude))
    initial_velocity = rand(3) .* ϵ
    initial_cond = (initial_position, initial_velocity)
    initial_first_integrals = (H(initial_cond...), L(initial_cond...))
    prob = DynamicalODEProblem(pdot, qdot, initial_velocity, initial_position, tspan)
    sol = solve(prob, KahanLi6(), dt = 1 // 150);
    solutionnumber = length(sol.u)
    push!(solutions, sol)
    tail = ℝ³(vec(sol.u[1])[4:6]...)
    head = ℝ³(vec(sol.u[1])[1:3]...)
    ball_observable = Observable(Point3f(tail))
    push!(balls, ball_observable)
    color = GLMakie.RGBAf(convert_hsvtorgb([359.0 * float(index) / float(length(nodes)); 1.0; 1.0])..., 0.5)
    push!(colors, color)
    meshscatter!(lscene, ball_observable, markersize = markersize, color = color)
    push!(ps[], Point3f(tail))
    push!(ns[], Point3f(head))
    trajectorypoints = Observable(Point3f[])
    push!(trajectories, trajectorypoints)
    lines!(lscene, trajectorypoints, color = @lift(collect(1:length($trajectorypoints))), linewidth = boundarylinewidth / 10.0, colorrange = (1, frames_number), colormap = :plasma, transparency = true)
    println("Processed node $index out of $(length(nodes)) nodes in total.")
end

arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colors,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin,
    transparency = true)

lspaceϕ = range(-π, stop = float(π), length = segments)
lspaceθ = range(π / 2, stop = -π / 2, length = segments)
sphere = [convert_to_cartesian([radius; θ; ϕ]) for θ in lspaceθ, ϕ in lspaceϕ]
sphere_observable = buildsurface(lscene, sphere, mask, transparency = true)

sphere1 = [convert_to_cartesian([radius + altitude; θ; ϕ]) for θ in lspaceθ, ϕ in lspaceϕ]
boundarycolor = getcolor(nodes, reference, 0.25)
spherecolor = fill(boundarycolor, segments, segments)
sphere1_observable = buildsurface(lscene, sphere1, spherecolor, transparency = true)
patchcolor = fill(boundarycolor, segments2, segments2)
lines!(lscene, Point3f.(nodes), color = collect(1:length(nodes)), linewidth = boundarylinewidth, colorrange = (1, length(nodes)), colormap = :darkrainbow)
lines!(lscene, Point3f.(nodes) .* (radius + altitude), color = collect(1:length(nodes)), linewidth = boundarylinewidth, colorrange = (1, length(nodes)), colormap = :darkrainbow)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    _ps = Point3f[]
    _ns = Point3f[]

    for (index, node) in enumerate(nodes)
        solution = solutions[index]
        timeindex = max(1, Int(floor(progress * length(solution))))
        q = ℝ³(vec(solution[timeindex])[4:6]...)
        p = ℝ³(vec(solution[timeindex])[1:3]...)
        balls[index][] = Point3f(q)
        push!(_ps, Point3f(q))
        push!(_ns, Point3f(p))
        push!(trajectories[index][], Point3f(q))
        notify(trajectories[index])
    end

    ps[] = _ps
    ns[] = _ns
    notify(ps)
    notify(ns)

    _altitude = norm(ps[][1])
    sphere1 = [convert_to_cartesian([_altitude; θ; ϕ]) for θ in lspaceθ, ϕ in lspaceϕ]
    updatesurface!(sphere1, sphere1_observable)

    solution1 = solutions[1]
    solution2 = solutions[Int(length(solutions) ÷ 2)]
    timeindex1 = max(1, Int(floor(progress * length(solution1))))
    timeindex2 = max(1, Int(floor(progress * length(solution2))))
    q₁ = ℝ³(vec(solution1[timeindex1])[4:6]...)
    p₁ = ℝ³(vec(solution1[timeindex1])[1:3]...)
    q₂ = ℝ³(vec(solution2[timeindex2])[4:6]...)
    p₂ = ℝ³(vec(solution2[timeindex2])[1:3]...)
    H₁ = H(vec(q₁), vec(p₁))
    H₂ = H(vec(q₂), vec(p₂))
    if frame == 1
        println(" H₁ = $H₁, H₂ = $H₂ ")
    end
    if isapprox(frame % 30, 0)
        patch1 = [convert_to_cartesian([_altitude; θ; ϕ]) for θ in patchlspaceθ, ϕ in patchlspaceϕ]
        buildsurface(lscene, patch1, patchcolor, transparency = true)
        timeindex = max(1, Int(floor(progress * min(length.(solutions)...))))
        transformed_nodes = [ℝ³(vec(solutions[i][timeindex])[4:6]...) for i in eachindex(solutions)]
        lines!(lscene, Point3f.(transformed_nodes), color = collect(1:length(solutions)), linewidth = boundarylinewidth, colorrange = (1, length(solutions)), colormap = :darkrainbow)
    end

    if stage == 1
        global eyeposition = q₁ + cross(q₁, q₂)
        global up = q₁ + q₂
        global lookat = q₁
    end
    if stage == 2
        global eyeposition = q₁ * (1.0 + stageprogress) + cross(q₁, q₂) * (1.0 + stageprogress)
        global up = q₁ + q₂
        global lookat = q₁
    end
    if stage == 3
        global eyeposition = rotate(2q₁ + 2cross(q₁, q₂), ℍ(stageprogress * 2π, normalize(q₁ + q₂)))
        global up = q₁ + q₂
        global lookat = q₁
    end
    if stage == 4
        global eyeposition = stageprogress * (normalize(q₁) + 2normalize(cross(q₁, q₂))) + (1.0 - stageprogress) * (2q₁ + 2cross(q₁, q₂))
        global up = q₁ + q₂
        global lookat = q₁
    end
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end