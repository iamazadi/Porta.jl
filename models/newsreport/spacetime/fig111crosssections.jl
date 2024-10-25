import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig111crosssections"

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
# transformingplaneobservable1 = buildsurface(lscene1, planematrix, mask, transparency = true)
# transformingplaneobservable2 = buildsurface(lscene2, planematrix, mask, transparency = true)

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), Int(T))
ϵ = 0.1
ζ = Complex(κ)
κ = SpinVector(ζ, Int(T))
ζ′ = ζ - (1.0 / √2) * ϵ * (1.0 / κ.a[2]^2)
κ′ = SpinVector(ζ′, Int(T))

ζ″ = ζ′ - (1.0 / √2) * ϵ * (1.0 / κ′.a[2]^2)
κ″ = SpinVector(ζ″, Int(T))
κv = 𝕍(κ)
κ′v = 𝕍(κ′)
κ″v = 𝕍(κ″)

linewidth = 20
κlinepoints = []
κlinecolors = []
for (i, scale1) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
    _κlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _κlinecolors = GLMakie.Observable(Int[])
    for (j, scale2) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        κvector = LinearAlgebra.normalize(vec(scale1 * κv + scale2 * κ′v))
        κpoint = GLMakie.Point3f(project(ℍ(κvector)))
        push!(_κlinepoints[], κpoint)
        push!(_κlinecolors[], i + j)
    end
    push!(κlinepoints, _κlinepoints)
    push!(κlinecolors, _κlinecolors)
    GLMakie.lines!(lscene1, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
    GLMakie.lines!(lscene2, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
end

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
origin = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
northpole = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 1.0))
κobservable = GLMakie.Observable(GLMakie.Point3f(project(normalize(ℍ(vec(κv))))))
κ′observable = GLMakie.Observable(GLMakie.Point3f(project(normalize(ℍ(vec(κ′v))))))
κ″observable = GLMakie.Observable(GLMakie.Point3f(project(normalize(ℍ(vec(κ″v))))))
κprojectionobservable = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κv)))
κ′projectionobservable = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κ′v)))
κ″projectionobservable = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κ″v)))
ps = GLMakie.@lift([$origin, $κobservable, $origin, $κprojectionobservable,
                    $origin, $κ′observable, $origin, $κ′projectionobservable,
                    $origin, $κ″observable, $origin, $κ″projectionobservable])
ns = GLMakie.@lift([$κobservable, LinearAlgebra.normalize($κ′observable - $κobservable), $κprojectionobservable, LinearAlgebra.normalize($κ′projectionobservable - $κprojectionobservable),
                    $κ′observable, LinearAlgebra.normalize($κ″observable - $κ′observable), $κ′projectionobservable, LinearAlgebra.normalize($κ″projectionobservable - $κ′projectionobservable),
                    $κ″observable, LinearAlgebra.normalize($κobservable - $κ″observable), $κ″projectionobservable, LinearAlgebra.normalize($κprojectionobservable - $κ″projectionobservable)])
colorants = [:red, :green, :blue, :orange]
GLMakie.arrows!(lscene1,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants..., colorants..., colorants...],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
GLMakie.arrows!(lscene2,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants..., colorants..., colorants...],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

eyeposition_observable1 = lscene1.scene.camera.eyeposition
lookat_observable1 = lscene1.scene.camera.lookat
rotationaxis1 = GLMakie.@lift(normalize(ℝ³(Float64.(vec($eyeposition_observable1 - $lookat_observable1))...)))
rotationangle1 = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable1)[2], ($eyeposition_observable1)[1])))
rotation1 = GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle1, $rotationaxis1) * ℍ(getrotation(ẑ, $rotationaxis1)...)))
eyeposition_observable2 = lscene2.scene.camera.eyeposition
lookat_observable2 = lscene2.scene.camera.lookat
rotationaxis2 = GLMakie.@lift(normalize(ℝ³(Float64.(vec($eyeposition_observable2 - $lookat_observable2))...)))
rotationangle2 = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable2)[2], ($eyeposition_observable2)[1])))
rotation2 = GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle2, $rotationaxis2) * ℍ(getrotation(ẑ, $rotationaxis2)...)))
titles = ["O", "N", "P", "P′", "P″", "P", "P′", "P″"]
GLMakie.text!(lscene1,
    GLMakie.@lift(map(x -> GLMakie.Point3f(isnan(x) ? ẑ : x), [$origin, $northpole, $κobservable, $κ′observable, $κ″observable, $κprojectionobservable, $κ′projectionobservable, $κ″projectionobservable])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[1], colorants[1], colorants[3], colorants[3], colorants[3]],
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)
GLMakie.text!(lscene2,
    GLMakie.@lift(map(x -> GLMakie.Point3f(isnan(x) ? ẑ : x), [$origin, $northpole, $κobservable, $κ′observable, $κ″observable, $κprojectionobservable, $κ′projectionobservable, $κ″projectionobservable])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[1], colorants[1], colorants[3], colorants[3], colorants[3]],
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

θ = rand()
ϕ = rand()
ψ = rand()
transformation = SpinTransformation(θ, ϕ, ψ)
κflagplanematrix = makeflagplane(κv, κ′v - κv, segments = segments)
κflagplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplaneobservable1 = buildsurface(lscene1, κflagplanematrix, κflagplanecolor, transparency = false)
κflagplaneobservable2 = buildsurface(lscene2, κflagplanematrix, κflagplanecolor, transparency = false)

κsectional = GLMakie.Observable(GLMakie.Point3f(project(normalize(ℍ(vec(κv))))))
κ′sectional = GLMakie.Observable(GLMakie.Point3f(project(normalize(ℍ(vec(κ′v))))))
κ″sectional = GLMakie.Observable(GLMakie.Point3f(project(normalize(ℍ(vec(κ″v))))))

# balls
GLMakie.meshscatter!(lscene1, northpole, markersize = 0.05, color = :black)
GLMakie.meshscatter!(lscene1, origin, markersize = 0.05, color = :gold)
GLMakie.meshscatter!(lscene1, κobservable, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene1, κ′observable, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene1, κ″observable, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene1, κprojectionobservable, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene1, κ′projectionobservable, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene1, κ″projectionobservable, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene2, northpole, markersize = 0.05, color = :black)
GLMakie.meshscatter!(lscene2, origin, markersize = 0.05, color = :gold)
GLMakie.meshscatter!(lscene2, κobservable, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene2, κ′observable, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene2, κ″observable, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene2, κprojectionobservable, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene2, κ′projectionobservable, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene2, κ″projectionobservable, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene2, κprojectionobservable, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene2, κ′projectionobservable, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene2, κ″projectionobservable, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene2, κsectional, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene2, κ′sectional, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene2, κ″sectional, markersize = 0.05, color = colorants[3])

segmentP = GLMakie.@lift([$northpole, $κobservable, $κprojectionobservable])
segmentP′ = GLMakie.@lift([$northpole, $κ′observable, $κ′projectionobservable])
segmentP″ = GLMakie.@lift([$northpole, $κ″observable, $κ″projectionobservable])
segmentcolors = GLMakie.Observable(collect(1:segments))
linewidth = 8.0
GLMakie.lines!(lscene1, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene1, segmentP′, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene1, segmentP″, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentP′, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentP″, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    θ = sin(progress * 2π)
    ϕ = progress * 2π
    ψ = cos(progress * 2π)
    spintransform = SpinTransformation(θ, ϕ, ψ)
    spherematrix = makesphere(spintransform, T, segments = segments)
    planematrix = makestereographicprojectionplane(spintransform, T = 1.0, segments = segments)
    updatesurface!(spherematrix, sphereobservable1)
    updatesurface!(planematrix, planeobservable1)
    updatesurface!(spherematrix, sphereobservable2)
    updatesurface!(planematrix, planeobservable2)
    κtransformed = 𝕍(spintransform * κ)
    κ′transformed = 𝕍(spintransform * κ′)
    κ″transformed = 𝕍(spintransform * κ″)
    κflagplanematrix = makeflagplane(κtransformed, 𝕍(LinearAlgebra.normalize(vec(κ′transformed - κtransformed))), segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable1)
    updatesurface!(κflagplanematrix, κflagplaneobservable2)
    κflagplanecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([360.0 * progress; 1.0; 1.0])..., 1.0) for i in 1:segments, j in 1:segments]
    κobservable[] = GLMakie.Point3f(project(normalize(ℍ(vec(κtransformed)))))
    κ′observable[] = GLMakie.Point3f(project(normalize(ℍ(vec(κ′transformed)))))
    κ″observable[] = GLMakie.Point3f(project(normalize(ℍ(vec(κ″transformed)))))
    κprojectionobservable[] = GLMakie.Point3f(projectontoplane(κtransformed))
    κ′projectionobservable[] = GLMakie.Point3f(projectontoplane(κ′transformed))
    κ″projectionobservable[] = GLMakie.Point3f(projectontoplane(κ″transformed))
    κsectional[] = (κobservable[] + κprojectionobservable[]) * 0.5
    κ′sectional[] = (κ′observable[] + κ′projectionobservable[]) * 0.5
    κ″sectional[] = (κ″observable[] + κ″projectionobservable[]) * 0.5
    for (i, scale1) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        _κlinepoints = GLMakie.Point3f[]
        _κlinecolors = Int[]
        for (j, scale2) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
            κvector = normalize(ℍ(vec(scale1 * κtransformed + scale2 * 𝕍(LinearAlgebra.normalize(vec(κ′transformed - κtransformed))))))
            κpoint = GLMakie.Point3f(project(κvector))
            push!(_κlinepoints, κpoint)
            push!(_κlinecolors, i + j)
        end
        κlinepoints[i][] = _κlinepoints
        κlinecolors[i][] = _κlinecolors
        GLMakie.notify(κlinepoints[i])
        GLMakie.notify(κlinecolors[i])
    end
    global lookat = (1.0 / 3.0) * (ℝ³(κobservable[]) + ℝ³(κ′observable[]) + ℝ³(κ″observable[]))
    global eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
    updatecamera(lscene1, eyeposition, lookat, up)
    global lookat = (1.0 / 3.0) * (ℝ³(κprojectionobservable[]) + ℝ³(κ′projectionobservable[]) + ℝ³(κ″projectionobservable[]))
    global eyeposition = normalize(ℝ³(0.0, 0.0, 1.0)) * float(π)
    updatecamera(lscene2, eyeposition, lookat, up)
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)