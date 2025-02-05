using FileIO
using GLMakie
using LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig111crosssections"

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
lscene1 = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = LScene(fig[1, 2], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

T = 1.0
spherematrix = makesphere(M, T, segments = segments)
sphereobservable1 = buildsurface(lscene1, spherematrix, mask, transparency = true)
sphereobservable2 = buildsurface(lscene2, spherematrix, mask, transparency = true)
planematrix = makestereographicprojectionplane(M, T = T, segments = segments)
planeobservable1 = buildsurface(lscene1, planematrix, mask, transparency = true)
planeobservable2 = buildsurface(lscene2, planematrix, mask, transparency = true)
ϵ = 0.1
transformation = SpinTransformation(ϵ + rand() * 0.1, ϵ + rand() * 0.1, ϵ + rand() * 0.1)

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
        κpoint = Point3f(project(ℍ(κvector)))
        push!(_κlinepoints[], κpoint)
        push!(_κlinecolors[], i + j)
    end
    push!(κlinepoints, _κlinepoints)
    push!(κlinecolors, _κlinecolors)
    lines!(lscene1, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
    lines!(lscene2, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
end

arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
origin = Observable(Point3f(0.0, 0.0, 0.0))
northpole = Observable(Point3f(0.0, 0.0, 1.0))
κobservable = Observable(Point3f(project(normalize(ℍ(vec(κv))))))
κ′observable = Observable(Point3f(project(normalize(ℍ(vec(κ′v))))))
κ″observable = Observable(Point3f(project(normalize(ℍ(vec(κ″v))))))
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
arrows!(lscene1,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants[1], colorants[4], colorants[1], colorants[4], colorants[2], colorants[4], colorants[2], colorants[4], colorants[3], colorants[4], colorants[3], colorants[4]],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
arrows!(lscene2,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants..., colorants..., colorants...],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)
titles = ["O", "N", "P", "P′", "P″", "P", "P′", "P″"]
text!(lscene1,
    @lift(map(x -> Point3f(isnan(x) ? ẑ : x), [$origin, $northpole, $κobservable, $κ′observable, $κ″observable, $κprojectionobservable, $κ′projectionobservable, $κ″projectionobservable])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3], colorants[1], colorants[2], colorants[3]],
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)
text!(lscene2,
    @lift(map(x -> Point3f(isnan(x) ? ẑ : x), [$origin, $northpole, $κobservable, $κ′observable, $κ″observable, $κprojectionobservable, $κ′projectionobservable, $κ″projectionobservable])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3], colorants[1], colorants[2], colorants[3]],
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

κflagplanematrix = makeflagplane(κv, κ′v - κv, T, segments = segments)
κflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplaneobservable1 = buildsurface(lscene1, κflagplanematrix, κflagplanecolor, transparency = false)
κflagplaneobservable2 = buildsurface(lscene2, κflagplanematrix, κflagplanecolor, transparency = false)

κsectional = Observable(Point3f(project(normalize(ℍ(vec(κv))))))
κ′sectional = Observable(Point3f(project(normalize(ℍ(vec(κ′v))))))
κ″sectional = Observable(Point3f(project(normalize(ℍ(vec(κ″v))))))

# balls
meshscatter!(lscene1, northpole, markersize = 0.05, color = :black)
meshscatter!(lscene1, origin, markersize = 0.05, color = :gold)
meshscatter!(lscene1, κobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene1, κ′observable, markersize = 0.05, color = colorants[2])
meshscatter!(lscene1, κ″observable, markersize = 0.05, color = colorants[3])
meshscatter!(lscene1, κprojectionobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene1, κ′projectionobservable, markersize = 0.05, color = colorants[2])
meshscatter!(lscene1, κ″projectionobservable, markersize = 0.05, color = colorants[3])
meshscatter!(lscene2, northpole, markersize = 0.05, color = :black)
meshscatter!(lscene2, origin, markersize = 0.05, color = :gold)
meshscatter!(lscene2, κobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene2, κ′observable, markersize = 0.05, color = colorants[2])
meshscatter!(lscene2, κ″observable, markersize = 0.05, color = colorants[3])
meshscatter!(lscene2, κprojectionobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene2, κ′projectionobservable, markersize = 0.05, color = colorants[2])
meshscatter!(lscene2, κ″projectionobservable, markersize = 0.05, color = colorants[3])
meshscatter!(lscene2, κprojectionobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene2, κ′projectionobservable, markersize = 0.05, color = colorants[2])
meshscatter!(lscene2, κ″projectionobservable, markersize = 0.05, color = colorants[3])
meshscatter!(lscene1, κsectional, markersize = 0.05, color = colorants[1])
meshscatter!(lscene1, κ′sectional, markersize = 0.05, color = colorants[2])
meshscatter!(lscene1, κ″sectional, markersize = 0.05, color = colorants[3])
meshscatter!(lscene2, κsectional, markersize = 0.05, color = colorants[1])
meshscatter!(lscene2, κ′sectional, markersize = 0.05, color = colorants[2])
meshscatter!(lscene2, κ″sectional, markersize = 0.05, color = colorants[3])

segmentP = @lift([$northpole, $κobservable, $κprojectionobservable])
segmentP′ = @lift([$northpole, $κ′observable, $κ′projectionobservable])
segmentP″ = @lift([$northpole, $κ″observable, $κ″projectionobservable])
segmentcolors = collect(1:3)
linewidth = 8.0
lines!(lscene1, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene1, segmentP′, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene1, segmentP″, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene2, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene2, segmentP′, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene2, segmentP″, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    θ = progress * 2π
    ϕ = sin(progress * 2π)
    ψ = cos(progress * 2π)
    spintransform = SpinTransformation(θ, ϕ, ψ)
    spherematrix = makesphere(spintransform, T, segments = segments)
    planematrix = makestereographicprojectionplane(spintransform, T = 1.0, segments = segments)
    updatesurface!(planematrix, planeobservable1)
    updatesurface!(spherematrix, sphereobservable2)
    updatesurface!(planematrix, planeobservable2)
    κtransformed = 𝕍(spintransform * κ)
    κ′transformed = 𝕍(spintransform * κ′)
    κ″transformed = 𝕍(spintransform * κ″)
    κflagplanematrix = makeflagplane(κtransformed, 𝕍(normalize(vec(κ′transformed - κtransformed))), T, segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable1)
    updatesurface!(κflagplanematrix, κflagplaneobservable2)
    κflagplanecolor[] = [RGBAf(convert_hsvtorgb([359.0 * progress; 1.0; 1.0])..., 1.0) for i in 1:segments, j in 1:segments]
    κobservable[] = Point3f(project(normalize(ℍ(vec(κtransformed)))))
    κ′observable[] = Point3f(project(normalize(ℍ(vec(κ′transformed)))))
    κ″observable[] = Point3f(project(normalize(ℍ(vec(κ″transformed)))))
    κprojectionobservable[] = Point3f(projectontoplane(κtransformed))
    κ′projectionobservable[] = Point3f(projectontoplane(κ′transformed))
    κ″projectionobservable[] = Point3f(projectontoplane(κ″transformed))
    κsectional[] = (κobservable[] + κprojectionobservable[]) * 0.5
    κ′sectional[] = (κ′observable[] + κ′projectionobservable[]) * 0.5
    κ″sectional[] = (κ″observable[] + κ″projectionobservable[]) * 0.5
    for (i, scale1) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        _κlinepoints = Point3f[]
        _κlinecolors = Int[]
        for (j, scale2) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
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
    component = normalize(cross(ℝ³(κobservable[]), ℝ³(κprojectionobservable[])))
    global lookat = (1.0 / 3.0) * (ℝ³(κsectional[]) + ℝ³(κ′sectional[]) + ℝ³(κ″sectional[]) + component)
    global eyeposition = normalize(lookat) * float(π)
    updatecamera!(lscene1, eyeposition, lookat, up)
    global lookat = (1.0 / 3.0) * (ℝ³(κprojectionobservable[]) + ℝ³(κ′projectionobservable[]) + ℝ³(κ″projectionobservable[]))
    global eyeposition = normalize(ẑ) * float(π)
    updatecamera!(lscene2, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end