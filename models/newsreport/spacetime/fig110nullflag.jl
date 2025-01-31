import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig110nullflag"

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
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

T = 1.0
spherematrix = makesphere(M, T, segments = segments)
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)
planematrix = makestereographicprojectionplane(M, T = T, segments = segments)
planeobservable = buildsurface(lscene, planematrix, mask, transparency = true)

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), Int(T))
ϵ = 0.1
ζ = Complex(κ)
ζ′ = ζ - (1.0 / √2) * ϵ * (1.0 / κ.a[2]^2)
κ = SpinVector(ζ, Int(T))
κ′ = SpinVector(ζ′, Int(T))
κv = 𝕍(κ)
κ′v = 𝕍(κ′)

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
origin = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
northpole = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 1.0))
κtail = GLMakie.Observable(GLMakie.Point3f(vec(project(normalize(ℍ(vec(κ′v)))))...))
κhead = GLMakie.Observable(GLMakie.Point3f(vec(project(normalize(ℍ(vec(κv)))))...))
κtail1 = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κ′v)))
κhead1 = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κv)))
ps = GLMakie.@lift([$origin, $κhead, $origin, $κhead1])
ns = GLMakie.@lift([$κhead, LinearAlgebra.normalize($κtail - $κhead), $κhead1, LinearAlgebra.normalize($κtail1 - $κhead1)])
colorants = [:red, :green]
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants..., colorants...],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

linewidth = 20
κlinepoints = []
κlines = []
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
    κline = GLMakie.lines!(lscene, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
    push!(κlines, κline)
end

eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation = GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle, $rotationaxis) * ℍ(getrotation(ẑ, $rotationaxis)...)))
titles = ["O", "N", "P", "P′", "P", "P′"]
GLMakie.text!(lscene,
    GLMakie.@lift(map(x -> GLMakie.Point3f(vec((isnan(x) ? ẑ : x))), [$origin, $northpole, $κhead, $κtail, $κhead1, $κtail1])),
    text = titles,
    color = [:gold, :black, colorants..., colorants...],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

θ = rand()
ϕ = rand()
ψ = rand()
transformation = SpinTransformation(θ, ϕ, ψ)
κflagplanematrix = makeflagplane(κv, κ′v - κv, T, segments = segments)
κflagplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = false)

# balls
GLMakie.meshscatter!(lscene, northpole, markersize = 0.05, color = :black)
GLMakie.meshscatter!(lscene, origin, markersize = 0.05, color = :gold)
GLMakie.meshscatter!(lscene, κhead, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene, κtail, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene, κhead1, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene, κtail1, markersize = 0.05, color = colorants[2])


segmentP = GLMakie.@lift([GLMakie.Point3f(0.0, 0.0, 1.0), $κhead, $κhead1])
segmentcolors = GLMakie.Observable(collect(1:segments))
linewidth = 8.0
GLMakie.lines!(lscene, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    θ = progress * 2π
    ϕ = cos(progress * 2π)
    ψ = sin(progress * 2π)
    spintransform = SpinTransformation(θ, ϕ, ψ)
    spherematrix = makesphere(spintransform, T, segments = segments)
    planematrix = makestereographicprojectionplane(spintransform, T = 1.0, segments = segments)
    updatesurface!(spherematrix, sphereobservable)
    updatesurface!(planematrix, planeobservable)
    κ_transformed = 𝕍(spintransform * κ)
    κ′_transformed = 𝕍(spintransform * κ′)
    κflagplanematrix = makeflagplane(κ_transformed, 𝕍(LinearAlgebra.normalize(vec(κ′_transformed - κ_transformed))), T, segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable)
    κflagplanecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([360.0 * progress; 1.0; 1.0])..., 1.0) for i in 1:segments, j in 1:segments]
    κhead[] = GLMakie.Point3f(project(ℍ(LinearAlgebra.normalize(vec(κ_transformed)))))
    κtail[] = GLMakie.Point3f(project(normalize(ℍ(vec(κ′_transformed)))))
    κtail1[] = GLMakie.Point3f(projectontoplane(κ′_transformed))
    κhead1[] = GLMakie.Point3f(projectontoplane(κ_transformed))
    for (i, scale1) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        _κlinepoints = GLMakie.Point3f[]
        _κlinecolors = Int[]
        for (j, scale2) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
            κvector = normalize(ℍ(vec(scale1 * κ_transformed + scale2 * 𝕍(LinearAlgebra.normalize(vec(κ′_transformed - κ_transformed))))))
            κpoint = GLMakie.Point3f(project(κvector))
            push!(_κlinepoints, κpoint)
            push!(_κlinecolors, i + j)
        end
        κlinepoints[i][] = _κlinepoints
        κlinecolors[i][] = _κlinecolors
        GLMakie.notify(κlinepoints[i])
        GLMakie.notify(κlinecolors[i])
    end
    global lookat = ℝ³(Float64.(vec(κhead[]))...)
    updatecamera(lscene, eyeposition, lookat, up)
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)