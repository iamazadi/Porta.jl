import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 60
frames_number = 360
modelname = "fig11transformations"
M = I(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
totalstages = 1

t = 𝕍(1.0, 0.0, 0.0, 0.0)
x = 𝕍(0.0, 1.0, 0.0, 0.0)
y = 𝕍(0.0, 0.0, 1.0, 0.0)
z = 𝕍(0.0, 0.0, 0.0, 1.0)
v = 𝕍(LinearAlgebra.normalize(rand(4)))

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
tail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
thead = GLMakie.Observable(GLMakie.Point3f(project(ℍ(vec(t)))))
xhead = GLMakie.Observable(GLMakie.Point3f(project(ℍ(vec(x)))))
yhead = GLMakie.Observable(GLMakie.Point3f(project(ℍ(vec(y)))))
zhead = GLMakie.Observable(GLMakie.Point3f(project(ℍ(vec(z)))))
vhead = GLMakie.Observable(GLMakie.Point3f(project(ℍ(vec(v)))))
ps = GLMakie.@lift([$tail, $tail, $tail, $tail, $tail])
ns = GLMakie.@lift([$thead, $xhead, $yhead, $zhead, $vhead])
colorants = [:red, :blue, :green, :orange, :black]
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

titles = ["O", "g₀", "g₁", "g₂", "g₃", "V"]
eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation = GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle, $rotationaxis) * ℍ(getrotation(ẑ, $rotationaxis)...)))
GLMakie.text!(lscene,
    GLMakie.@lift(map(x -> GLMakie.Point3f((isnan(x) ? ẑ : x)), [$tail, $thead, $xhead, $yhead, $zhead, $vhead])),
    text = titles,
    color = [:gold, colorants...],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    status = 3
    M1 = compute_fourscrew(progress, status)
    M2 = compute_nullrotation(progress)
    M = M1 * M2
    t_transformed = M * ℍ(vec(t))
    x_transformed = M * ℍ(vec(x))
    y_transformed = M * ℍ(vec(y))
    z_transformed = M * ℍ(vec(z))
    v_transformed = M * ℍ(vec(v))
    thead[] = GLMakie.Point3f(project(t_transformed))
    xhead[] = GLMakie.Point3f(project(x_transformed))
    yhead[] = GLMakie.Point3f(project(y_transformed))
    zhead[] = GLMakie.Point3f(project(z_transformed))
    vhead[] = GLMakie.Point3f(project(v_transformed))

    updatecamera(lscene, eyeposition, lookat, up)
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)