import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig1678fourscrew"

M = I(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
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

T = 1.0
spherematrix = makesphere(M, T, segments = segments)
sphereobservable1 = buildsurface(lscene1, spherematrix, mask, transparency = true)
sphereobservable2 = buildsurface(lscene2, spherematrix, mask, transparency = true)
planematrix = makestereographicprojectionplane(M, T = T, segments = segments)
planeobservable1 = buildsurface(lscene1, planematrix, mask, transparency = true)
planeobservable2 = buildsurface(lscene2, planematrix, mask, transparency = true)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    rotation = compute_fourscrew(progress, 1)
    boost = compute_fourscrew(progress, 2)
    spherematrix1 = makesphere(rotation, T, segments = segments)
    spherematrix2 = makesphere(boost, T, segments = segments)
    planematrix1 = makestereographicprojectionplane(rotation, T = 1.0, segments = segments)
    planematrix2 = makestereographicprojectionplane(boost, T = 1.0, segments = segments)
    updatesurface!(spherematrix1, sphereobservable1)
    updatesurface!(spherematrix2, sphereobservable2)
    updatesurface!(planematrix1, planeobservable1)
    updatesurface!(planematrix2, planeobservable2)

    updatecamera(lscene1, eyeposition, lookat, up)
    updatecamera(lscene2, eyeposition, lookat, up)
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)