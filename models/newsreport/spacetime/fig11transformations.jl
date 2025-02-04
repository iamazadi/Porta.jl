using GLMakie
using LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 60
frames_number = 360
modelname = "fig11transformations"
M = Identity(4)
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
v = 𝕍(normalize(rand(4)))

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
tail = Observable(Point3f(0.0, 0.0, 0.0))
thead = Observable(Point3f(project(ℍ(vec(t)))))
xhead = Observable(Point3f(project(ℍ(vec(x)))))
yhead = Observable(Point3f(project(ℍ(vec(y)))))
zhead = Observable(Point3f(project(ℍ(vec(z)))))
vhead = Observable(Point3f(project(ℍ(vec(v)))))
ps = @lift([$tail, $tail, $tail, $tail, $tail])
ns = @lift([$thead, $xhead, $yhead, $zhead, $vhead])
colorants = [:red, :blue, :green, :orange, :black]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

titles = ["O", "g₀", "g₁", "g₂", "g₃", "V"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f((isnan(x) ? ẑ : x)), [$tail, $thead, $xhead, $yhead, $zhead, $vhead])),
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
    thead[] = Point3f(project(t_transformed))
    xhead[] = Point3f(project(x_transformed))
    yhead[] = Point3f(project(y_transformed))
    zhead[] = Point3f(project(z_transformed))
    vhead[] = Point3f(project(v_transformed))

    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end