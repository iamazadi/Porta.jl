using FileIO
using GLMakie
using LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig15stereographicprojection"

M = ℍ(1.0, 0.0, 0.0, 0.0)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 0.0)) * float(π)
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

rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)

timesign = 1
generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
κv = 𝕍(κ)
Nv = 𝕍(1.0, 0.0, 0.0, 1.0)
Ov = 𝕍(0.0, 0.0, 0.0, 0.0)

Pvobservable = Observable(κv)
Qvobservable = @lift(𝕍(vec($Pvobservable) .* (1.0 / (1.0 - vec($Pvobservable)[4]))))
X′ = @lift(vec($Pvobservable)[2] .* (1.0 / (1.0 - vec($Pvobservable)[4])))
Y′ = @lift(vec($Pvobservable)[3] .* (1.0 / (1.0 - vec($Pvobservable)[4])))
P′vobservable = @lift(𝕍(1.0, $X′, $Y′, 0.0))
Nvobservable = Observable(Nv)
Ovobservable = Observable(Ov)
Pprojection = @lift(Point3f(project(normalize(ℍ(vec($Pvobservable))))))
P′projection = @lift(Point3f(project(normalize(ℍ(vec($P′vobservable))))))
Qprojection = @lift(Point3f(project(ℍ(vec($Qvobservable)))))
Nprojection = @lift(Point3f(project(normalize(ℍ(vec($Nvobservable))))))
Oprojection = Observable(Point3f(0.0, 0.0, 0.0))

titles = ["O", "N", "P", "Q", "P′"]
colorants = [:gold, :black, :red, :green, :blue]
text!(lscene1,
    @lift(map(x -> Point3f((isnan(x) ? ẑ : x)), [$Oprojection, $Nprojection, $Pprojection, $Qprojection, $P′projection])),
    text = titles,
    color = colorants,
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)
text!(lscene2,
    @lift(map(x -> Point3f((isnan(x) ? ẑ : x)), [$Oprojection, $Nprojection, $Pprojection, $Qprojection, $P′projection])),
    text = titles,
    color = colorants,
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

Oball = meshscatter!(lscene1, Oprojection, markersize = 0.05, color = colorants[1])
Nball = meshscatter!(lscene1, Nprojection, markersize = 0.05, color = colorants[2])
Pball = meshscatter!(lscene1, Pprojection, markersize = 0.05, color = colorants[3])
Qball = meshscatter!(lscene1, Qprojection, markersize = 0.05, color = colorants[4])
P′ball = meshscatter!(lscene1, P′projection, markersize = 0.05, color = colorants[5])
Oball = meshscatter!(lscene2, Oprojection, markersize = 0.05, color = colorants[1])
Nball = meshscatter!(lscene2, Nprojection, markersize = 0.05, color = colorants[2])
Pball = meshscatter!(lscene2, Pprojection, markersize = 0.05, color = colorants[3])
Qball = meshscatter!(lscene2, Qprojection, markersize = 0.05, color = colorants[4])
P′ball = meshscatter!(lscene2, P′projection, markersize = 0.05, color = colorants[5])

θ = rand()
ϕ = rand()
ψ = rand()
transformation = SpinTransformation(θ, ϕ, ψ)
T = 1.0
planematrix = makesphere(transformation, T, segments = segments)
# planeobservable1 = buildsurface(lscene1, planematrix, mask, transparency = true)
planeobservable2 = buildsurface(lscene2, planematrix, mask, transparency = true)

plane2matrix = makespheretminusz(transformation, T = T, segments = segments)
plane2observable = buildsurface(lscene1, plane2matrix, mask, transparency = true)

plane3matrix = makestereographicprojectionplane(transformation, T = T, segments = segments)
plane3observable = buildsurface(lscene2, plane3matrix, mask, transparency = true)

segmentPN = @lift([Point3f(project(normalize(ℍ(vec($Pvobservable + α * 𝕍(normalize(vec($Nvobservable - $Pvobservable)))))))) for α in range(-float(2π), stop = float(2π), length = segments)])
segmentPO = @lift([Point3f(project(ℍ(vec($Pvobservable + α * 𝕍(normalize(vec($Pvobservable - $Ovobservable))))))) for α in range(-float(2π), stop = float(2π), length = segments)])
segmentQP′ = @lift([Point3f(project(ℍ(vec($Qvobservable + α * 𝕍(normalize(vec($P′vobservable - $Qvobservable))))))) for α in range(-float(2π), stop = float(2π), length = segments)])
segmentcolors = Observable(collect(1:segments))
linewidth = 8.0
lines!(lscene1, segmentPN, linewidth = 2linewidth, color = segmentcolors, colormap = :reds, colorrange = (1, segments), transparency = false)
lines!(lscene1, segmentPO, linewidth = 2linewidth, color = segmentcolors, colormap = :greens, colorrange = (1, segments), transparency = false)
lines!(lscene1, segmentQP′, linewidth = 2linewidth, color = segmentcolors, colormap = :blues, colorrange = (1, segments), transparency = false)
lines!(lscene2, segmentPN, linewidth = 2linewidth, color = segmentcolors, colormap = :reds, colorrange = (1, segments), transparency = false)
lines!(lscene2, segmentPO, linewidth = 2linewidth, color = segmentcolors, colormap = :greens, colorrange = (1, segments), transparency = false)
lines!(lscene2, segmentQP′, linewidth = 2linewidth, color = segmentcolors, colormap = :blues, colorrange = (1, segments), transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    θ = progress * 2π
    ϕ = cos(progress * 2π)
    ψ = sin(progress * 2π)
    spintransform = SpinTransformation(θ, ϕ, ψ)
    Pvobservable[] = 𝕍(spintransform * κ)
    planematrix = makesphere(spintransform, T, segments = segments)
    plane2matrix = makespheretminusz(spintransform, T = T, segments = segments)
    plane3matrix = makestereographicprojectionplane(spintransform, T = T, segments = segments)
    # updatesurface!(planematrix, planeobservable1)
    updatesurface!(planematrix, planeobservable2)
    updatesurface!(plane2matrix, plane2observable)
    updatesurface!(plane3matrix, plane3observable)
    global lookat = ℝ³(Float64.(vec(Pprojection[] + P′projection[]))...) * 0.5
    global eyeposition = normalize(ℝ³(1.0, 1.0, 0.1)) * float(π)
    updatecamera!(lscene1, eyeposition, lookat, up)
    global lookat = ℝ³(Float64.(vec(Pprojection[] + Qprojection[]))...) * 0.5
    global eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(2π)
    updatecamera!(lscene2, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end