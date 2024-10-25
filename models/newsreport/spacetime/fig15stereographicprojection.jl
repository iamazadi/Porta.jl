import FileIO
import GLMakie
import LinearAlgebra
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
mask = FileIO.load("data/basemap_mask.png")

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene1 = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = GLMakie.LScene(fig[1, 2], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

eyeposition_observable1 = lscene1.scene.camera.eyeposition
eyeposition_observable2 = lscene2.scene.camera.eyeposition
lookat_observable1 = lscene1.scene.camera.lookat
lookat_observable2 = lscene2.scene.camera.lookat
rotationaxis1 = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable1)...] - [vec($lookat_observable1)...])...)))
rotationaxis2 = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable2)...] - [vec($lookat_observable2)...])...)))
rotationangle1 = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable1)[2], ($eyeposition_observable1)[1])))
rotationangle2 = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable2)[2], ($eyeposition_observable2)[1])))
rotation1 = GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle1, $rotationaxis1) * ℍ(getrotation(ẑ, $rotationaxis1)...)))
rotation2 = GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle2, $rotationaxis2) * ℍ(getrotation(ẑ, $rotationaxis2)...)))

timesign = 1
generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
κv = 𝕍(κ)
Nv = 𝕍(1.0, 0.0, 0.0, 1.0)
Ov = 𝕍(0.0, 0.0, 0.0, 0.0)

Pvobservable = GLMakie.Observable(κv)
Qvobservable = GLMakie.@lift(𝕍(vec($Pvobservable) .* (1.0 / (1.0 - vec($Pvobservable)[4]))))
X′ = GLMakie.@lift(vec($Pvobservable)[2] .* (1.0 / (1.0 - vec($Pvobservable)[4])))
Y′ = GLMakie.@lift(vec($Pvobservable)[3] .* (1.0 / (1.0 - vec($Pvobservable)[4])))
P′vobservable = GLMakie.@lift(𝕍(1.0, $X′, $Y′, 0.0))
Nvobservable = GLMakie.Observable(Nv)
Ovobservable = GLMakie.Observable(Ov)
Pprojection = GLMakie.@lift(GLMakie.Point3f(project(normalize(ℍ(vec($Pvobservable))))))
P′projection = GLMakie.@lift(GLMakie.Point3f(project(normalize(ℍ(vec($P′vobservable))))))
Qprojection = GLMakie.@lift(GLMakie.Point3f(project(ℍ(vec($Qvobservable)))))
Nprojection = GLMakie.@lift(GLMakie.Point3f(project(normalize(ℍ(vec($Nvobservable))))))
Oprojection = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))

titles = ["O", "N", "P", "Q", "P′"]
colorants = [:gold, :black, :red, :green, :blue]
GLMakie.text!(lscene1,
    GLMakie.@lift(map(x -> GLMakie.Point3f((isnan(x) ? ẑ : x)), [$Oprojection, $Nprojection, $Pprojection, $Qprojection, $P′projection])),
    text = titles,
    color = colorants,
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)
GLMakie.text!(lscene2,
    GLMakie.@lift(map(x -> GLMakie.Point3f((isnan(x) ? ẑ : x)), [$Oprojection, $Nprojection, $Pprojection, $Qprojection, $P′projection])),
    text = titles,
    color = colorants,
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

Oball = GLMakie.meshscatter!(lscene1, Oprojection, markersize = 0.05, color = colorants[1])
Nball = GLMakie.meshscatter!(lscene1, Nprojection, markersize = 0.05, color = colorants[2])
Pball = GLMakie.meshscatter!(lscene1, Pprojection, markersize = 0.05, color = colorants[3])
Qball = GLMakie.meshscatter!(lscene1, Qprojection, markersize = 0.05, color = colorants[4])
P′ball = GLMakie.meshscatter!(lscene1, P′projection, markersize = 0.05, color = colorants[5])
Oball = GLMakie.meshscatter!(lscene2, Oprojection, markersize = 0.05, color = colorants[1])
Nball = GLMakie.meshscatter!(lscene2, Nprojection, markersize = 0.05, color = colorants[2])
Pball = GLMakie.meshscatter!(lscene2, Pprojection, markersize = 0.05, color = colorants[3])
Qball = GLMakie.meshscatter!(lscene2, Qprojection, markersize = 0.05, color = colorants[4])
P′ball = GLMakie.meshscatter!(lscene2, P′projection, markersize = 0.05, color = colorants[5])

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

segmentPN = GLMakie.@lift([GLMakie.Point3f(project(normalize(ℍ(vec($Pvobservable + α * 𝕍(LinearAlgebra.normalize(vec($Nvobservable - $Pvobservable)))))))) for α in range(-float(2π), stop = float(2π), length = segments)])
segmentPO = GLMakie.@lift([GLMakie.Point3f(project(ℍ(vec($Pvobservable + α * 𝕍(LinearAlgebra.normalize(vec($Pvobservable - $Ovobservable))))))) for α in range(-float(2π), stop = float(2π), length = segments)])
segmentQP′ = GLMakie.@lift([GLMakie.Point3f(project(ℍ(vec($Qvobservable + α * 𝕍(LinearAlgebra.normalize(vec($P′vobservable - $Qvobservable))))))) for α in range(-float(2π), stop = float(2π), length = segments)])
segmentcolors = GLMakie.Observable(collect(1:segments))
linewidth = 8.0
GLMakie.lines!(lscene1, segmentPN, linewidth = 2linewidth, color = segmentcolors, colormap = :reds, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene1, segmentPO, linewidth = 2linewidth, color = segmentcolors, colormap = :greens, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene1, segmentQP′, linewidth = 2linewidth, color = segmentcolors, colormap = :blues, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentPN, linewidth = 2linewidth, color = segmentcolors, colormap = :reds, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentPO, linewidth = 2linewidth, color = segmentcolors, colormap = :greens, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentQP′, linewidth = 2linewidth, color = segmentcolors, colormap = :blues, colorrange = (1, segments), transparency = false)


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
    updatecamera(lscene1, eyeposition, lookat, up)
    global lookat = ℝ³(Float64.(vec(Pprojection[] + Qprojection[]))...) * 0.5
    global eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(2π)
    updatecamera(lscene2, eyeposition, lookat, up)
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)