import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig113diracsscissors"

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
    _κlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _κlinecolors = GLMakie.Observable(Int[])
    for (j, scale2) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        κvector = LinearAlgebra.normalize(vec(scale1 * κv + scale2 * κ′v))
        κpoint = GLMakie.Point3f(projectnocompression(ℍ(κvector)))
        push!(_κlinepoints[], κpoint)
        push!(_κlinecolors[], i + j)
    end
    push!(κlinepoints, _κlinepoints)
    push!(κlinecolors, _κlinecolors)
    GLMakie.lines!(lscene, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
end

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
origin = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
northpole = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 1.0))
κobservable = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′observable = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″observable = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
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
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants[1], colorants[4], colorants[1], colorants[4], colorants[2], colorants[4], colorants[2], colorants[4], colorants[3], colorants[4], colorants[3], colorants[4]],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

rotation = gettextrotation(lscene)
titles = ["O", "N", "P", "P′", "P″", "P", "P′", "P″"]
GLMakie.text!(lscene,
    GLMakie.@lift(map(x -> GLMakie.Point3f(isnan(x) ? ẑ : x), [$origin, $northpole, $κobservable, $κ′observable, $κ″observable, $κprojectionobservable, $κ′projectionobservable, $κ″projectionobservable])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3], colorants[1], colorants[2], colorants[3]],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

κflagplanematrix = makeflagplane(κv, κ′v - κv, T, segments = segments)
κflagplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = true)

κsectional = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′sectional = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″sectional = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))

# balls
GLMakie.meshscatter!(lscene, northpole, markersize = 0.05, color = :black)
GLMakie.meshscatter!(lscene, origin, markersize = 0.05, color = :gold)
GLMakie.meshscatter!(lscene, κobservable, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene, κ′observable, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene, κ″observable, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene, κprojectionobservable, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene, κ′projectionobservable, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene, κ″projectionobservable, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene, κsectional, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene, κ′sectional, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene, κ″sectional, markersize = 0.05, color = colorants[3])

segmentP = GLMakie.@lift([$northpole, $κobservable, $κprojectionobservable])
segmentP′ = GLMakie.@lift([$northpole, $κ′observable, $κ′projectionobservable])
segmentP″ = GLMakie.@lift([$northpole, $κ″observable, $κ″projectionobservable])
segmentcolors = GLMakie.Observable(collect(1:segments))
linewidth = 8.0
GLMakie.lines!(lscene, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene, segmentP′, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene, segmentP″, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene, segmentP, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene, segmentP′, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene, segmentP″, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    θ = progress * 4π
    ϕ = 0.0
    ψ = 0.0
    spintransform = SpinTransformation(θ, ϕ, ψ)
    transform(κ, spintransform) = begin
        vector = mat(spintransform) * vec(κ)
        timesign = κ.timesign
        result = SpinVector(convert(Vector{Complex}, vector)..., timesign)
        if isapprox(result, -κ)
            timesign = -κ.timesign
            result = SpinVector(convert(Vector{Complex}, vector)..., timesign)
        end
        return result
    end
    κtransformed = 𝕍(transform(κ, spintransform))
    κ′transformed = 𝕍(transform(κ′, spintransform))
    κ″transformed = 𝕍(transform(κ″, spintransform))
    T = Float64(transform(κ, spintransform).timesign)
    println("T: $T")
    northpole[] = GLMakie.Point3f(ℝ³(0.0, 0.0, T))
    spherematrix = makesphere(spintransform, T, segments = segments)
    planematrix = makestereographicprojectionplane(spintransform, T = T, segments = segments)
    updatesurface!(planematrix, planeobservable)
    updatesurface!(spherematrix, sphereobservable)
    κflagplanematrix = makeflagplane(κtransformed, 𝕍(LinearAlgebra.normalize(vec(κ′transformed - κtransformed))), T, segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable)
    κflagplanecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([360.0 * progress; 1.0; 1.0])..., 0.8) for i in 1:segments, j in 1:segments]
    κobservable[] = GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κtransformed)))))
    κ′observable[] = GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ′transformed)))))
    κ″observable[] = GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ″transformed)))))
    κprojectionobservable[] = GLMakie.Point3f(projectontoplane(κtransformed))
    κ′projectionobservable[] = GLMakie.Point3f(projectontoplane(κ′transformed))
    κ″projectionobservable[] = GLMakie.Point3f(projectontoplane(κ″transformed))
    κsectional[] = (κobservable[] + κprojectionobservable[]) * 0.5
    κ′sectional[] = (κ′observable[] + κ′projectionobservable[]) * 0.5
    κ″sectional[] = (κ″observable[] + κ″projectionobservable[]) * 0.5
    for (i, scale1) in enumerate(collect(range(0.0, stop = T, length = segments)))
        _κlinepoints = GLMakie.Point3f[]
        _κlinecolors = Int[]
        for (j, scale2) in enumerate(collect(range(0.0, stop = T, length = segments)))
            κvector = normalize(ℍ(vec(scale1 * κtransformed + scale2 * 𝕍(LinearAlgebra.normalize(vec(κ′transformed - κtransformed))))))
            κpoint = GLMakie.Point3f(projectnocompression(κvector))
            push!(_κlinepoints, κpoint)
            push!(_κlinecolors, i + j)
        end
        κlinepoints[i][] = _κlinepoints
        κlinecolors[i][] = _κlinecolors
        GLMakie.notify(κlinepoints[i])
        GLMakie.notify(κlinecolors[i])
    end
    component = normalize(cross(ℝ³(κobservable[]), ℝ³(κprojectionobservable[])))
    global lookat = (1.0 / 3.0) * (ℝ³(κsectional[]) + ℝ³(κ′sectional[]) + ℝ³(κ″sectional[]) + component)
    # global eyeposition = normalize(ℝ³(northpole[]) + float(π) * component) * float(2π)
    global eyeposition = normalize((x̂ - ŷ + ẑ) * float(π)) * float(2π)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)