using FileIO
using GLMakie
using LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig113diracsscissors"

M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
totalstages = 1
mask = load("data/basemap_mask.png")

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

T = 1.0
spherematrix = makesphere(M, T, compressedprojection = true, segments = segments)
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)
planematrix = makestereographicprojectionplane(M, T = T, segments = segments)
planeobservable = buildsurface(lscene, planematrix, mask, transparency = true)
ϵ = 0.1
transformation = SpinTransformation(rand() * ϵ, rand() * ϵ, rand() * ϵ)

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
linewidth = 0.04
origin = Observable(Point3f(0.0, 0.0, 0.0))
northpole = Observable(Point3f(0.0, 0.0, 1.0))
κobservable = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′observable = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″observable = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
κprojectionobservable = Observable(Point3f(projectontoplane(κv)))
κ′projectionobservable = Observable(Point3f(projectontoplane(κ′v)))
κ″projectionobservable = Observable(Point3f(projectontoplane(κ″v)))
ps = @lift([$origin, $κobservable, $origin, $κprojectionobservable,
                    $origin, $κ′observable, $origin, $κ′projectionobservable,
                    $origin, $κ″observable, $origin, $κ″projectionobservable])
ns = @lift([$κobservable, normalize($κ′observable - $κobservable), $κprojectionobservable, normalize($κ′projectionobservable - $κprojectionobservable),
                    $κ′observable, normalize($κ″observable - $κ′observable), $κ′projectionobservable, normalize($κ″projectionobservable - $κ′projectionobservable),
                    $κ″observable, normalize($κobservable - $κ″observable), $κ″projectionobservable, normalize($κprojectionobservable - $κ″projectionobservable)])
colorants = [:red, :green, :blue, :orange]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants[1], colorants[4], colorants[1], colorants[4], colorants[2], colorants[4], colorants[2], colorants[4], colorants[3], colorants[4], colorants[3], colorants[4]],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

rotation = gettextrotation(lscene)
titles = ["O", "N", "P", "P′", "P″", "P", "P′", "P″"]
text!(lscene,
    @lift(map(x -> Point3f(isnan(x) ? ẑ : x), [$origin, $northpole, $κobservable, $κ′observable, $κ″observable, $κprojectionobservable, $κ′projectionobservable, $κ″projectionobservable])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3], colorants[1], colorants[2], colorants[3]],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

κflagplanematrix = makeflagplane(κv, κ′v - κv, T, compressedprojection = true, segments = segments)
κflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = true)

κsectional = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′sectional = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″sectional = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))

# balls
meshscatter!(lscene, northpole, markersize = 0.05, color = :black)
meshscatter!(lscene, origin, markersize = 0.05, color = :gold)
meshscatter!(lscene, κobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene, κ′observable, markersize = 0.05, color = colorants[2])
meshscatter!(lscene, κ″observable, markersize = 0.05, color = colorants[3])
meshscatter!(lscene, κprojectionobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene, κ′projectionobservable, markersize = 0.05, color = colorants[2])
meshscatter!(lscene, κ″projectionobservable, markersize = 0.05, color = colorants[3])
meshscatter!(lscene, κsectional, markersize = 0.05, color = colorants[1])
meshscatter!(lscene, κ′sectional, markersize = 0.05, color = colorants[2])
meshscatter!(lscene, κ″sectional, markersize = 0.05, color = colorants[3])

segmentP = @lift([$northpole, $κobservable, $κprojectionobservable])
segmentP′ = @lift([$northpole, $κ′observable, $κ′projectionobservable])
segmentP″ = @lift([$northpole, $κ″observable, $κ″projectionobservable])
segmentcolors = Observable(collect(1:3))
linewidth = 8.0
lines!(lscene, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene, segmentP′, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene, segmentP″, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    θ = progress * 2π
    M = exp(K(3) * θ)
    κtransformed = 𝕍(vec(M * ℍ(vec(𝕍(κ)))))
    κ′transformed = 𝕍(vec(M * ℍ(vec(𝕍(κ′)))))
    κ″transformed = 𝕍(vec(M * ℍ(vec(𝕍(κ″)))))
    northpole[] = Point3f(project(M * normalize(ℍ(T, 0.0, 0.0, 1.0))))
    spherematrix = makesphere(M, T, compressedprojection = true, segments = segments)
    planematrix = makestereographicprojectionplane(M, T = T, segments = segments)
    updatesurface!(planematrix, planeobservable)
    updatesurface!(spherematrix, sphereobservable)
    κflagplanematrix = makeflagplane(κtransformed, 𝕍(normalize(vec(κ′transformed - κtransformed))), T, compressedprojection = true, segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable)
    κflagplanecolor[] = [RGBAf(convert_hsvtorgb([359.0 * progress; 1.0; 1.0])..., 0.8) for i in 1:segments, j in 1:segments]
    κobservable[] = Point3f(project(normalize(ℍ(vec(κtransformed)))))
    κ′observable[] = Point3f(project(normalize(ℍ(vec(κ′transformed)))))
    κ″observable[] = Point3f(project(normalize(ℍ(vec(κ″transformed)))))
    κprojectionobservable[] = Point3f(projectontoplane(κtransformed))
    κ′projectionobservable[] = Point3f(projectontoplane(κ′transformed))
    κ″projectionobservable[] = Point3f(projectontoplane(κ″transformed))
    κsectional[] = (κobservable[] + κprojectionobservable[]) * 0.5
    κ′sectional[] = (κ′observable[] + κ′projectionobservable[]) * 0.5
    κ″sectional[] = (κ″observable[] + κ″projectionobservable[]) * 0.5
    for (i, scale1) in enumerate(collect(range(0.0, stop = T, length = segments)))
        _κlinepoints = Point3f[]
        _κlinecolors = Int[]
        for (j, scale2) in enumerate(collect(range(0.0, stop = T, length = segments)))
            κvector = normalize(ℍ(vec(scale1 * κtransformed + scale2 * 𝕍(normalize(vec(κ′transformed - κtransformed))))))
            κpoint = Point3f(project(κvector))
            push!(_κlinepoints, κpoint)
            push!(_κlinecolors, i + j)
        end
        κlinepoints[i][] = _κlinepoints
        κlinecolors[i][] = _κlinecolors
        notify(κlinepoints[i])
        notify(κlinecolors[i])
    end
    global lookat = (1.0 / 3.0) * ℝ³(κobservable[] + κ′observable[] + κ″observable[])
    global eyeposition = normalize((x̂ - ŷ + ẑ) * float(π)) * float(2π)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end