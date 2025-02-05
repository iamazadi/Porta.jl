using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 60
frames_number = 360
modelname = "fig12ynegative"

M = ℍ(1.0, 0.0, 0.0, 0.0)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, -2.0, 0.0)) * float(π)
lookat = ℝ³(1.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
totalstages = 1

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

timesign = -1
generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
ω = SpinVector(generate(), generate(), timesign)
κv = 𝕍(κ)
ωv = 𝕍(ω)

arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
tail = Observable(Point3f(0.0, 0.0, 0.0))
κhead = Observable(Point3f(project(ℍ(vec(κv)))))
ωhead = Observable(Point3f(project(ℍ(vec(ωv)))))
ps = @lift([$tail, $tail])
ns = @lift([$κhead, $ωhead])
colorants = [:red, :blue]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

origin = ℝ³(2.0, 0.0, 0.0)
κbase = Observable(Point3f(origin + ℝ³(hopfmap(ℍ(vec(κv))))))
ωbase = Observable(Point3f(origin + ℝ³(hopfmap(ℍ(vec(ωv))))))
κball = meshscatter!(lscene, κbase, markersize = 0.05, color = colorants[1])
ωball = meshscatter!(lscene, ωbase, markersize = 0.05, color = colorants[2])

titles = ["O", "κ", "ω", "κ", "ω"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f((isnan(x) ? ẑ : x)), [$tail, $κhead, $ωhead, $κbase, $ωbase])),
    text = titles,
    color = [:gold, colorants..., colorants...],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

T = -1.0
spherematrix1 = makesphere(M, T)
T = 0.0
spherematrix2 = makesphere(M, T)
T = 1.0
spherematrix3 = makesphere(M, T)
mask = load("data/basemap_mask.png")
sphereobservable1 = buildsurface(lscene, spherematrix1, mask, transparency = true)
sphereobservable2 = buildsurface(lscene, spherematrix2, mask, transparency = true)
sphereobservable3 = buildsurface(lscene, spherematrix3, mask, transparency = true)

twospherematrix = maketwosphere(origin)
twospherecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
twosphereobservable = buildsurface(lscene, twospherematrix, twospherecolor, transparency = true)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    M = ℍ(progress * 4π, ẑ)
    hue = Float64(frame) / Float64(frames_number) * 359.0
    twospherecolor[] = [RGBAf(convert_hsvtorgb([hue; 1.0; 1.0])..., 0.5) for i in 1:segments, j in 1:segments]
    κbase[] = Point3f(origin + ℝ³(hopfmap(normalize(M * ℍ(vec(κv))))))
    ωbase[] = Point3f(origin + ℝ³(hopfmap(normalize(M * ℍ(vec(ωv))))))
    κhead[] = Point3f(project(M * ℍ(vec(κv))))
    ωhead[] = Point3f(project(M * ℍ(vec(ωv))))
    
    spherematrix1 = makesphere(M, -1.0)
    spherematrix2 = makesphere(M, 0.0)
    spherematrix3 = makesphere(M, 1.0)
    updatesurface!(spherematrix1, sphereobservable1)
    updatesurface!(spherematrix2, sphereobservable2)
    updatesurface!(spherematrix3, sphereobservable3)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end