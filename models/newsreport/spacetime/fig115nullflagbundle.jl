using FileIO
using GLMakie
using LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig115nullflagbundle"

M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
gauge1 = 0.0
gauge2 = float(π / 2)
gauge3 = float(2π)
chart = (-π / 2, π / 2, -π / 2, π / 2)
indices = Dict()
T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
u = 𝕍(T, X, Y, Z)
q = ℍ(T, X, Y, Z)
tolerance = 1e-3
@assert(isnull(u, atol = tolerance), "u in not a null vector, $u.")
@assert(isapprox(norm(q), 1, atol = tolerance), "q in not a unit quaternion, $(norm(q)).")
T = 1.0
ϵ = 0.1
transformation = SpinTransformation(rand() * ϵ, rand() * ϵ, rand() * ϵ)
reference = load("data/basemap_color.png")
mask = load("data/basemap_mask.png")

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), Int(T))
ζ = Complex(κ)
κ = SpinVector(ζ, Int(T))
ζ′ = ζ - (1.0 / √2) * ϵ * (1.0 / κ.a[2]^2)
κ′ = SpinVector(ζ′, Int(T))

ζ″ = ζ′ - (1.0 / √2) * ϵ * (1.0 / κ′.a[2]^2)
κ″ = transformation * SpinVector(ζ″, Int(T))
κv = 𝕍(κ)
κ′v = 𝕍(κ′)
κ″v = 𝕍(κ″)

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = Set()
while length(boundary_names) < 10
    push!(boundary_names, rand(countries["name"]))
end
boundary_nodes = Vector{Vector{ℝ³}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            println(name)
            indices[name] = length(boundary_nodes)
        end
    end
end

points = Vector{ℍ}[]
for i in eachindex(boundary_nodes)
    _points = ℍ[]
    for node in boundary_nodes[i]
        r, θ, ϕ = convert_to_geographic(node)
        push!(_points, q * ℍ(exp(ϕ / 2 * K(1) + θ * K(2))))
    end
    push!(points, _points)
end

basemap1 = Basemap(lscene, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene, q, gauge2, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.5)
    color2 = getcolor(boundary_nodes[i], reference, 0.25)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
end

linewidth = 20
κlinepoints = []
κlinecolors = []
for (i, scale1) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
    _κlinepoints = Observable(Point3f[])
    _κlinecolors = Observable(Int[])
    for (j, scale2) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        κvector = normalize(vec(scale1 * κv + scale2 * κ′v))
        κpoint = Point3f(projectnocompression(ℍ(κvector)))
        push!(_κlinepoints[], κpoint)
        push!(_κlinecolors[], i + j)
    end
    push!(κlinepoints, _κlinepoints)
    push!(κlinecolors, _κlinecolors)
    lines!(lscene, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
end

arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
origin = Observable(Point3f(0.0, 0.0, 0.0))
northpole = Observable(Point3f(0.0, 0.0, 1.0))
κobservable = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′observable = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″observable = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
ps = @lift([$origin, $κobservable,
            $origin, $κ′observable,
            $origin, $κ″observable])
ns = @lift([$κobservable, normalize($κ′observable - $κobservable),
            $κ′observable, normalize($κ″observable - $κ′observable),
            $κ″observable, normalize($κobservable - $κ″observable)])
colorants = [:red, :green, :blue, :black]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants[1], colorants[1], colorants[2], colorants[2], colorants[3], colorants[3]],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

rotation = gettextrotation(lscene)
titles = ["O", "N", "P", "P′", "P″"]
text!(lscene,
    @lift(map(x -> Point3f(isnan(x) ? ẑ : x), [$origin, $northpole, $κobservable, $κ′observable, $κ″observable])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3]],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

κflagplanematrix = makeflagplane(κv, κ′v - κv, T, compressedprojection = true, segments = segments)
κflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = true)

# balls
meshscatter!(lscene, northpole, markersize = 0.05, color = :black)
meshscatter!(lscene, origin, markersize = 0.05, color = :gold)
meshscatter!(lscene, κobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene, κ′observable, markersize = 0.05, color = colorants[2])
meshscatter!(lscene, κ″observable, markersize = 0.05, color = colorants[3])

segmentP = @lift([$northpole, $κobservable])
segmentP′ = @lift([$northpole, $κ′observable])
segmentP″ = @lift([$northpole, $κ″observable])
segmentcolors = collect(1:2)
linewidth = 8.0
lines!(lscene, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentP′, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 2), transparency = false)
lines!(lscene, segmentP″, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 2), transparency = false)

trajectorycolor = Observable(Int[])
κtrajectory = Observable(Point3f[])
κ′trajectory = Observable(Point3f[])
κ″trajectory = Observable(Point3f[])
lines!(lscene, κtrajectory, linewidth = linewidth, color = trajectorycolor, colormap = :darkrainbow, colorrange = (1, frames_number), transparency = true)
lines!(lscene, κ′trajectory, linewidth = linewidth, color = trajectorycolor, colormap = :darkrainbow, colorrange = (1, frames_number), transparency = true)
lines!(lscene, κ″trajectory, linewidth = linewidth, color = trajectorycolor, colormap = :darkrainbow, colorrange = (1, frames_number), transparency = true)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    global gauge2 = progress * 2π
    update!(basemap2, q, gauge2, M)
    for i in eachindex(whirls1)
        update!(whirls1[i], points[i], gauge1, gauge2, M)
        update!(whirls2[i], points[i], gauge2, gauge3, M)
    end
    r, θ, ϕ = convert_to_geographic(ℝ³(κ))
    κtransformed = 𝕍( vec(M * q * ℍ(exp(ϕ / 2 * K(1) + θ * K(2)) * exp(gauge2 * K(3)))))
    r, θ, ϕ = convert_to_geographic(ℝ³(κ′))
    κ′transformed = 𝕍( vec(M * q * ℍ(exp(ϕ / 2 * K(1) + θ * K(2)) * exp(gauge2 * K(3)))))
    r, θ, ϕ = convert_to_geographic(ℝ³(κ″))
    κ″transformed = 𝕍( vec(M * q * ℍ(exp(ϕ / 2 * K(1) + θ * K(2)) * exp(gauge2 * K(3)))))
    northpole[] = Point3f(project(M * q * ℍ(exp((float(0.0) / 2) * K(1) + float(π / 2) * K(2)) * exp(gauge2 * K(3)))))
    κflagplanematrix = makeflagplane(κtransformed, 𝕍( normalize(vec(κ′transformed - κtransformed))), T, compressedprojection = true, segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable)
    κflagplanecolor[] = [RGBAf(convert_hsvtorgb([359.0 * progress; 1.0; 1.0])..., 0.9) for i in 1:segments, j in 1:segments]
    κobservable[] = Point3f(project(normalize(ℍ(vec(κtransformed)))))
    κ′observable[] = Point3f(project(normalize(ℍ(vec(κ′transformed)))))
    κ″observable[] = Point3f(project(normalize(ℍ(vec(κ″transformed)))))
    push!(trajectorycolor[], frame)
    push!(κtrajectory[], κobservable[])
    push!(κ′trajectory[], κ′observable[])
    push!(κ″trajectory[], κ″observable[])
    notify(trajectorycolor)
    notify(κtrajectory)
    notify(κ′trajectory)
    notify(κ″trajectory)
    if (frame % 10) == 0
        arrows!(lscene,
                [κobservable[], κ′observable[], κ″observable[]],
                0.5 .* normalize.([κ′observable[] - κobservable[], κ″observable[] - κ′observable[], κobservable[] - κ″observable[]]),
                fxaa = true, # turn on anti-aliasing
                color = [colorants[1], colorants[2], colorants[3]],
                linewidth = arrowlinewidth * 0.5, arrowsize = arrowsize .* 0.5,
                align = :origin)
    end
    for (i, scale1) in enumerate(collect(range(0.0, stop = T, length = segments)))
        _κlinepoints = Point3f[]
        _κlinecolors = Int[]
        for (j, scale2) in enumerate(collect(range(0.0, stop = T, length = segments)))
            κvector = normalize(ℍ(vec(scale1 * κtransformed + scale2 * 𝕍( normalize(vec(κ′transformed - κtransformed))))))
            κpoint = Point3f(project(κvector))
            push!(_κlinepoints, κpoint)
            push!(_κlinecolors, i + j)
        end
        κlinepoints[i][] = _κlinepoints
        κlinecolors[i][] = _κlinecolors
        notify(κlinepoints[i])
        notify(κlinecolors[i])
    end
    global up = ℝ³(κobservable[] - κ″observable[])
    global lookat = (1.0 / 3.0) * ℝ³(κobservable[] + κ′observable[] + κ″observable[])
    global eyeposition = normalize(lookat + ℝ³(northpole[]) + cross(ℝ³(κobservable[]), ℝ³(κ″observable[]))) * float(π)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end