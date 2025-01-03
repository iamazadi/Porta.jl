import LinearAlgebra
using FileIO
using GLMakie
using Porta
using OrdinaryDiffEq, ForwardDiff, NonlinearSolve


figuresize = (4096, 2160)
segments = 60
segments2 = 10
frames_number = 360
modelname = "fig205hamiltonianflow"
totalstages = 6
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
mask = load("data/basemap_mask.png")
radius = 1.0
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set()
boundary_nodes = Vector{Vector{ℝ³}}()
points = Vector{Vector{ℍ}}()
indices = Dict()
boundarylinewidth = 10
markersize = 0.02
number = 10
arrowlinewidth = 0.02
arrowsize = Vec3f(0.04, 0.04, 0.06)

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

sprite = Observable(LinearAlgebra.normalize(Point3f(rand(3))))
meshscatter!(lscene, sprite, markersize = markersize, color = :gold)

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

# Hamiltonian begin

const g = 9.8 * 1e-1 # m / s²
const m = 1.0

H(q, p) = m * LinearAlgebra.norm(p)^2 / 2 + m * g * LinearAlgebra.norm(q)
L(q, p) = m * LinearAlgebra.norm(p)^2 / 2 - m * g * LinearAlgebra.norm(q)

pdot(dp, p, q, params, t) = ForwardDiff.gradient!(dp, q -> -H(q, p), q)
qdot(dq, p, q, params, t) = ForwardDiff.gradient!(dq, p -> H(q, p), p)

initial_position = vec(convert_to_cartesian(center)) * 1.1
initial_velocity = [0.0, 0.0, 0.0]
initial_cond = (initial_position, initial_velocity)
initial_first_integrals = (H(initial_cond...), L(initial_cond...))
tspan = (0, 0.5)
prob = DynamicalODEProblem(pdot, qdot, initial_velocity, initial_position, tspan)
sol = solve(prob, KahanLi6(), dt = 1 // 100);
solutionnumber = length(sol.u)

# Hamiltonian end

visible = Observable(true)
lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(π / 2, stop = -π / 2, length = segments)
lspace11 = range(-π, stop = float(π), length = segments2)
lspace22 = range(π / 2, stop = -π / 2, length = segments2)
lspace = range(0.9, stop = 1.1, length = number)
sphere_observables = []
plane_observables = []
colors = []
for (index, spacing) in enumerate(lspace)
    sphere = [convert_to_cartesian([spacing * radius; -θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    observable = buildsurface(lscene, sphere, mask, visible, transparency = true)
    color = Observable(fill(GLMakie.RGBAf(convert_hsvtorgb([359.0 * float(index) / float(length(lspace)); 1.0; 1.0])..., 0.0), segments, segments))
    plane = [convert_to_cartesian([spacing * radius; -θ; ϕ]) for θ in lspace22, ϕ in lspace11]
    plane_observable = buildsurface(lscene, plane, color, @lift(!$visible), transparency = true)
    push!(sphere_observables, observable)
    push!(plane_observables, plane_observable)
    push!(colors, color)
end

boundarypoints_observables = []
point_observables = []
boundarycolors = collect(1:N)
for spacing in lspace
    boundarypoints = Observable([spacing * radius * Point3f(x) for x in nodes])
    push!(boundarypoints_observables, boundarypoints)
    lines!(lscene, boundarypoints, color = boundarycolors, linewidth = boundarylinewidth, colorrange = (1, N), colormap = :rainbow)
    point = Observable(spacing * radius * Point3f(normalize(sum(nodes) * (1.0 / N))))
    push!(point_observables, point)
    meshscatter!(lscene, point, markersize = markersize, color = :gold)
end

ps = @lift([$(point_observables[1]), $(point_observables[2]), $(point_observables[3]), $(point_observables[4]), $(point_observables[5]), $(point_observables[6]), $(point_observables[7]), $(point_observables[8]), $(point_observables[9]), $(point_observables[10])])
ns = Observable(Point3f[])
for point in point_observables
    push!(ns[], point[])
end
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue, :orange, :magenta, :pink, :purple, :cyan, :limegreen, :silver],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

# to show the sum of two vectors
v₁tail = Observable(Point3f(rand(3)))
v₂tail = Observable(Point3f(rand(3)))
v₁head = Observable(Point3f(rand(3)))
v₂head = Observable(Point3f(rand(3)))
arraysum_ps = @lift([$v₁tail, $v₂tail])
arraysum_ns = @lift([$v₁head, $v₂head])
arrows!(lscene,
    arraysum_ps, arraysum_ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :green],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

particle_ps = @lift([$sprite])
particle_ns = Observable([Point3f(ẑ)])
arrows!(lscene,
particle_ps, particle_ns, fxaa = true, # turn on anti-aliasing
    color = [:black],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    tailindex = max(1, Int(floor(progress * length(nodes))))

    if stage == 1
        visible[] = true
        for (index, spacing) in enumerate(lspace)
            sphere = [convert_to_cartesian([spacing * radius; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
            updatesurface!(sphere, sphere_observables[index])

            boundarypoints = [spacing * radius * Point3f(x) for x in nodes]
            boundarypoints_observables[index][] = boundarypoints
            notify(boundarypoints_observables[index])

            point = spacing * radius * Point3f(convert_to_cartesian(center))
            point_observables[index][] = point
            notify(point_observables[index])
        end
        spacing = 1.0
        p = spacing * radius * convert_to_cartesian(center)
        q = nodes[1]
        r = nodes[Int(N ÷ 2)]
        distance = float(π)
        global eyeposition = rotate(p * distance + normalize(r - q) * distance, ℍ(sin(stageprogress * 2π) * float(π), normalize(p)))
        global lookat = p
        solutionindex = max(1, Int(floor(stageprogress * float(solutionnumber))))
        sprite[] = Point3f(vec(sol.u[solutionindex])[4:6])
        particle_ns[] = [Point3f(vec(sol.u[solutionindex])[1:3])]
        v₁tail[] = Point3f(convert_to_cartesian(center))
        v₂tail[] = (boundarypoints_observables[10][])[tailindex]
        v₁head[] = v₂tail[] - v₁tail[] 
        v₂head[] = Point3f(convert_to_cartesian(sum([convert_to_geographic(ℝ³(vec(x)...)) for x in boundarypoints_observables[10][]]) * (1.0 / length(boundarypoints_observables[10][])))) - v₂tail[]
    end
    if stage == 2
        visible[] = true
        _spacing = 0.75 + 0.25 * sin(stageprogress * 2π)
        for (index, spacing) in enumerate(lspace)
            sphere = [convert_to_cartesian([_spacing * spacing * radius; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
            updatesurface!(sphere, sphere_observables[index])

            boundarypoints = [_spacing * spacing * radius * Point3f(x) for x in nodes]
            boundarypoints_observables[index][] = boundarypoints
            notify(boundarypoints_observables[index])

            point = _spacing * spacing * radius * Point3f(convert_to_cartesian(center))
            point_observables[index][] = point
            notify(point_observables[index])
        end
        p = _spacing * radius * convert_to_cartesian(center)
        q = nodes[1]
        r = nodes[Int(N ÷ 2)]
        distance = float(π) - stageprogress * (π - 1.0)
        global eyeposition = p * distance + normalize(r - q) * distance
        global lookat = p
        solutionindex = max(1, Int(floor(stageprogress * float(solutionnumber))))
        sprite[] = Point3f(vec(sol.u[solutionindex])[4:6])
        particle_ns[] = [Point3f(vec(sol.u[solutionindex])[1:3])]
        v₁tail[] = Point3f(convert_to_cartesian(center))
        v₂tail[] = (boundarypoints_observables[10][])[tailindex]
        v₁head[] = v₂tail[] - v₁tail[] 
        v₂head[] = Point3f(convert_to_cartesian(sum([convert_to_geographic(ℝ³(vec(x)...)) for x in boundarypoints_observables[10][]]) * (1.0 / length(boundarypoints_observables[10][])))) - v₂tail[]
    end
    if stage == 3
        visible[] = true
        for (index, spacing) in enumerate(lspace)
            sphere1 = [convert_to_cartesian([spacing * radius; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
            sphere2 = [ℝ³([θ; ϕ; spacing]) for θ in lspace2, ϕ in lspace1]
            matrix = stageprogress .* sphere2 + (1.0 - stageprogress) .* sphere1
            updatesurface!(matrix, sphere_observables[index])

            boundarypoints1 = [Point3f(convert_to_cartesian([spacing * radius; convert_to_geographic(x)[2]; convert_to_geographic(x)[3]])) for x in nodes]
            boundarypoints2 = [Point3f(ℝ³([convert_to_geographic(x)[2]; convert_to_geographic(x)[3]; spacing])) for x in nodes]
            boundarypoints_observables[index][] = stageprogress .* boundarypoints2 + (1.0 - stageprogress) .* boundarypoints1
            notify(boundarypoints_observables[index])

            point1 = spacing * radius * Point3f(convert_to_cartesian(center))
            point2 = Point3f(ℝ³(center[2], center[3], spacing))
            point_observables[index][] = stageprogress * point2 + (1.0 - stageprogress) * point1
        end
        spacing = 1.0
        p1 = spacing * radius * convert_to_cartesian(center)
        p2 = ℝ³(center[2], center[3], spacing * radius)
        p = stageprogress * p2 + (1.0 - stageprogress) * p1
        q1 = nodes[1]
        q2 = ℝ³(convert_to_geographic(q1)[2], convert_to_geographic(q1)[3], spacing)
        q = stageprogress * q2 + (1.0 - stageprogress) * q1
        r1 = nodes[Int(N ÷ 2)]
        r2 = ℝ³(convert_to_geographic(r1)[2], convert_to_geographic(r1)[3], spacing)
        r = stageprogress * r2 + (1.0 - stageprogress) * r1
        distance = 1.0
        global eyeposition = p * distance + normalize(r - q) * distance + stageprogress * ẑ
        global lookat = p
        solutionindex = max(1, Int(floor(stageprogress * float(solutionnumber))))
        solq = ℝ³(vec(sol.u[solutionindex])[4:6])
        geosolq = convert_to_geographic(solq)
        solp = ℝ³(vec(sol.u[solutionindex])[1:3])
        sprite1 = Point3f(vec(solq))
        sprite2 = Point3f(geosolq[2], geosolq[3], spacing * radius)
        sprite[] = stageprogress * sprite2 + (1.0 - stageprogress) * sprite1
        ns1 = [Point3f(vec(solp))]
        ns2 = [Point3f(vec(LinearAlgebra.normalize(Point3f(point_observables[end][] - point_observables[begin][]))))]
        particle_ns[] = stageprogress .* ns2 + (1.0 - stageprogress) .* ns1
        tail1 = Point3f(convert_to_cartesian(center))
        tail2 = Point3f(ℝ³(convert_to_geographic(ℝ³(tail1))[2], convert_to_geographic(ℝ³(tail1))[3], spacing))
        v₁tail[] = stageprogress * tail2 + stageprogress * tail1
        v₂tail[] = (boundarypoints_observables[10][])[tailindex]
        v₁head[] = v₂tail[] - v₁tail[] 
        v₂head[] = Point3f(convert_to_cartesian(sum([convert_to_geographic(ℝ³(vec(x)...)) for x in boundarypoints_observables[10][]]) * (1.0 / length(boundarypoints_observables[10][])))) - v₂tail[]
    end
    if stage == 4
        visible[] = true
        for (index, spacing) in enumerate(lspace)
            sphere = [ℝ³([θ; ϕ; spacing]) for θ in lspace2, ϕ in lspace1]
            updatesurface!(sphere, sphere_observables[index])

            boundarypoints = [Point3f(ℝ³([convert_to_geographic(x)[2]; convert_to_geographic(x)[3]; spacing])) for x in nodes]
            boundarypoints_observables[index][] = boundarypoints
            notify(boundarypoints_observables[index])

            point = Point3f(ℝ³(center[2], center[3], spacing))
            point_observables[index][] = point
        end
        spacing = 1.0
        p = ℝ³(center[2], center[3], spacing * radius)
        q1 = nodes[1]
        q = ℝ³(convert_to_geographic(q1)[2], convert_to_geographic(q1)[3], spacing)
        r1 = nodes[Int(N ÷ 2)]
        r = ℝ³(convert_to_geographic(r1)[2], convert_to_geographic(r1)[3], spacing)
        distance = 1.0
        global eyeposition = p * distance + normalize(r - q) * distance + ẑ
        global lookat = p
        solutionindex = max(1, Int(floor(stageprogress * float(solutionnumber))))
        solq = ℝ³(vec(sol.u[solutionindex])[4:6])
        geosolq = convert_to_geographic(solq)
        solp = ℝ³(vec(sol.u[solutionindex])[1:3])
        sprite[] = Point3f(geosolq[2], geosolq[3], spacing * radius)
        particle_ns[] = [Point3f(vec(LinearAlgebra.normalize(Point3f(point_observables[end][] - point_observables[begin][]))))]
        tail1 = Point3f(convert_to_cartesian(center))
        v₁tail[] = Point3f(ℝ³(convert_to_geographic(ℝ³(tail1))[2], convert_to_geographic(ℝ³(tail1))[3], spacing))
        v₂tail[] = (boundarypoints_observables[10][])[tailindex]
        v₁head[] = v₂tail[] - v₁tail[] 
        v₂head[] = Point3f(convert_to_cartesian(sum([convert_to_geographic(ℝ³(vec(x)...)) for x in boundarypoints_observables[10][]]) * (1.0 / length(boundarypoints_observables[10][])))) - v₂tail[]
    end
    if stage == 5
        visible[] = false
        for (index, spacing) in enumerate(lspace)
            sphere = [ℝ³([θ; ϕ; spacing]) for θ in lspace2, ϕ in lspace1]
            updatesurface!(sphere, sphere_observables[index])

            color = fill(GLMakie.RGBAf(convert_hsvtorgb([359.0 * float(index) / float(length(lspace)); 1.0; 1.0])..., stageprogress * 0.5), segments, segments)
            colors[index][] = color
            maxθ = max(map(x -> convert_to_geographic(x)[2], nodes)...)
            minθ = min(map(x -> convert_to_geographic(x)[2], nodes)...)
            maxϕ = max(map(x -> convert_to_geographic(x)[3], nodes)...)
            minϕ = min(map(x -> convert_to_geographic(x)[3], nodes)...)
            lspaceϕ = range(minϕ, stop = maxϕ, length = segments2)
            lspaceθ = range(maxθ, stop = minθ, length = segments2)
            bigplane = [ℝ³([θ; ϕ; spacing]) for θ in lspace22, ϕ in lspace11]
            fitplane = [ℝ³([θ; ϕ; spacing]) for θ in lspaceθ, ϕ in lspaceϕ]
            plane = stageprogress .* fitplane + (1.0 - stageprogress) .* bigplane
            updatesurface!(plane, plane_observables[index])

            boundarypoints = [Point3f(ℝ³([convert_to_geographic(x)[2]; convert_to_geographic(x)[3]; spacing])) for x in nodes]
            boundarypoints_observables[index][] = boundarypoints
            notify(boundarypoints_observables[index])

            point = Point3f(ℝ³(center[2], center[3], spacing))
            point_observables[index][] = point
        end
        spacing = 1.0
        p = ℝ³(center[2], center[3], spacing * radius)
        q1 = nodes[1]
        q = ℝ³(convert_to_geographic(q1)[2], convert_to_geographic(q1)[3], spacing)
        r1 = nodes[Int(N ÷ 2)]
        r = ℝ³(convert_to_geographic(r1)[2], convert_to_geographic(r1)[3], spacing)
        distance = 1.0
        global eyeposition = p * distance + normalize(r - q) * distance + ẑ
        global lookat = p
        solutionindex = max(1, Int(floor(stageprogress * float(solutionnumber))))
        solq = ℝ³(vec(sol.u[solutionindex])[4:6])
        geosolq = convert_to_geographic(solq)
        solp = ℝ³(vec(sol.u[solutionindex])[1:3])
        sprite[] = Point3f(geosolq[2], geosolq[3], norm(solq) * spacing * radius)
        particle_ns[] = [Point3f(vec(LinearAlgebra.normalize(Point3f(point_observables[end][] - point_observables[begin][]))))]
        tail1 = Point3f(convert_to_cartesian(center))
        v₁tail[] = Point3f(ℝ³(convert_to_geographic(ℝ³(tail1))[2], convert_to_geographic(ℝ³(tail1))[3], spacing))
        v₂tail[] = (boundarypoints_observables[10][])[tailindex]
        v₁head[] = v₂tail[] - v₁tail[] 
        v₂head[] = Point3f(convert_to_cartesian(sum([convert_to_geographic(ℝ³(vec(x)...)) for x in boundarypoints_observables[10][]]) * (1.0 / length(boundarypoints_observables[10][])))) - v₂tail[]
    end
    if stage == 6
        visible[] = false
        _spacing = 0.75 + 0.25 * sin(stageprogress * 2π)
        for (index, spacing) in enumerate(lspace)
            sphere = [ℝ³([θ; ϕ; _spacing * spacing]) for θ in lspace2, ϕ in lspace1]
            updatesurface!(sphere, sphere_observables[index])

            color = fill(GLMakie.RGBAf(convert_hsvtorgb([359.0 * float(index) / float(length(lspace)); 1.0; 1.0])..., 0.25), segments, segments)
            colors[index][] = color
            maxθ = max(map(x -> convert_to_geographic(x)[2], nodes)...)
            minθ = min(map(x -> convert_to_geographic(x)[2], nodes)...)
            maxϕ = max(map(x -> convert_to_geographic(x)[3], nodes)...)
            minϕ = min(map(x -> convert_to_geographic(x)[3], nodes)...)
            lspaceϕ = range(minϕ, stop = maxϕ, length = segments2)
            lspaceθ = range(maxθ, stop = minθ, length = segments2)
            plane = [ℝ³([θ; ϕ; _spacing * spacing]) for θ in lspaceθ, ϕ in lspaceϕ]
            updatesurface!(plane, plane_observables[index])

            boundarypoints = [Point3f(ℝ³([convert_to_geographic(x)[2]; convert_to_geographic(x)[3]; _spacing * spacing])) for x in nodes]
            boundarypoints_observables[index][] = boundarypoints
            notify(boundarypoints_observables[index])

            point = Point3f(ℝ³(center[2], center[3], _spacing * spacing))
            point_observables[index][] = point
        end
        spacing = _spacing * 1.0
        p = ℝ³(center[2], center[3], spacing * radius)
        q1 = nodes[1]
        q = ℝ³(convert_to_geographic(q1)[2], convert_to_geographic(q1)[3], spacing)
        r1 = nodes[Int(N ÷ 2)]
        r = ℝ³(convert_to_geographic(r1)[2], convert_to_geographic(r1)[3], spacing)
        distance = 1.0
        global eyeposition = rotate(p * distance + normalize(r - q) * distance + ẑ, ℍ(stageprogress * 2π, ẑ))
        global lookat = p
        solutionindex = max(1, Int(floor(stageprogress * float(solutionnumber))))
        solq = ℝ³(vec(sol.u[solutionindex])[4:6])
        geosolq = convert_to_geographic(solq)
        solp = ℝ³(vec(sol.u[solutionindex])[1:3])
        sprite[] = Point3f(geosolq[2], geosolq[3], norm(solq) * spacing * radius)
        particle_ns[] = [Point3f(vec(LinearAlgebra.normalize(Point3f(point_observables[end][] - point_observables[begin][]))))]
        tail1 = Point3f(convert_to_cartesian(center))
        v₁tail[] = Point3f(ℝ³(convert_to_geographic(ℝ³(tail1))[2], convert_to_geographic(ℝ³(tail1))[3], spacing))
        v₂tail[] = (boundarypoints_observables[10][])[tailindex]
        v₁head[] = v₂tail[] - v₁tail[] 
        v₂head[] = Point3f(convert_to_cartesian(sum([convert_to_geographic(ℝ³(vec(x)...)) for x in boundarypoints_observables[10][]]) * (1.0 / length(boundarypoints_observables[10][])))) - v₂tail[]
    end
    arrowheads = [LinearAlgebra.normalize(Point3f(point_observables[index][] - point_observables[max(index - 1, 1)][])) for index in eachindex(point_observables)]
    arrowheads[1] = LinearAlgebra.normalize(Point3f(point_observables[end][] - point_observables[begin][]))
    ns[] = arrowheads
    global up = ℝ³(arrowheads[1])
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end