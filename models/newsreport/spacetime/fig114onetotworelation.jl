import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig114onetotworelation"

M = I(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition1 = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
eyeposition2 = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat1 = ℝ³(0.0, 0.0, 0.0)
lookat2 = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
totalstages = 1
mask = FileIO.load("data/basemap_mask.png")

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene1 = GLMakie.LScene(fig[1, 2], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

T = 1.0
spherematrix1 = makesphere(M, T, compressedprojection = true, segments = segments)
spherematrix2 = makesphere(M, T, compressedprojection = true, segments = segments)
planematrix1 = makestereographicprojectionplane(M, T = T, segments = segments)
planematrix2 = makestereographicprojectionplane(M, T = T, segments = segments)
sphereobservable1 = buildsurface(lscene1, spherematrix1, mask, transparency = true)
sphereobservable2 = buildsurface(lscene2, spherematrix2, mask, transparency = true)
planeobservable1 = buildsurface(lscene1, planematrix1, mask, transparency = true)
planeobservable2 = buildsurface(lscene2, planematrix2, mask, transparency = true)
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
κlinepoints1 = []
κlinepoints2 = []
κlinecolors = []
for (i, scale1) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
    _κlinepoints1 = GLMakie.Observable(GLMakie.Point3f[])
    _κlinepoints2 = GLMakie.Observable(GLMakie.Point3f[])
    _κlinecolors = GLMakie.Observable(Int[])
    for (j, scale2) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        κvector = LinearAlgebra.normalize(vec(scale1 * κv + scale2 * κ′v))
        κpoint = GLMakie.Point3f(projectnocompression(ℍ(κvector)))
        push!(_κlinepoints1[], κpoint)
        push!(_κlinecolors[], i + j)
        κvector = LinearAlgebra.normalize(vec(scale1 * κv + scale2 * κ′v))
        κpoint = GLMakie.Point3f(projectnocompression(ℍ(κvector)))
        push!(_κlinepoints2[], κpoint)
    end
    push!(κlinepoints1, _κlinepoints1)
    push!(κlinecolors, _κlinecolors)
    push!(κlinepoints2, _κlinepoints2)
    GLMakie.lines!(lscene1, κlinepoints1[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
    GLMakie.lines!(lscene2, κlinepoints2[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
end

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
colorants = [:red, :green, :blue, :black]
origin = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
northpole1 = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 1.0))
κobservable1 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′observable1 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″observable1 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
κprojectionobservable1 = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κv)))
κ′projectionobservable1 = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κ′v)))
κ″projectionobservable1 = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κ″v)))
northpole2 = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 1.0))
κobservable2 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′observable2 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″observable2 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
κprojectionobservable2 = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κv)))
κ′projectionobservable2 = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κ′v)))
κ″projectionobservable2 = GLMakie.Observable(GLMakie.Point3f(projectontoplane(κ″v)))
ps1 = GLMakie.@lift([$origin, $κobservable1, $origin, $κprojectionobservable1,
                    $origin, $κ′observable1, $origin, $κ′projectionobservable1,
                    $origin, $κ″observable1, $origin, $κ″projectionobservable1])
ns1 = GLMakie.@lift([$κobservable1, LinearAlgebra.normalize($κ′observable1 - $κobservable1), $κprojectionobservable1, LinearAlgebra.normalize($κ′projectionobservable1 - $κprojectionobservable1),
                    $κ′observable1, LinearAlgebra.normalize($κ″observable1 - $κ′observable1), $κ′projectionobservable1, LinearAlgebra.normalize($κ″projectionobservable1 - $κ′projectionobservable1),
                    $κ″observable1, LinearAlgebra.normalize($κobservable1 - $κ″observable1), $κ″projectionobservable1, LinearAlgebra.normalize($κprojectionobservable1 - $κ″projectionobservable1)])
ps2 = GLMakie.@lift([$origin, $κobservable2, $origin, $κprojectionobservable2,
                    $origin, $κ′observable2, $origin, $κ′projectionobservable2,
                    $origin, $κ″observable2, $origin, $κ″projectionobservable2])
ns2 = GLMakie.@lift([$κobservable2, LinearAlgebra.normalize($κ′observable2 - $κobservable2), $κprojectionobservable2, LinearAlgebra.normalize($κ′projectionobservable2 - $κprojectionobservable2),
                    $κ′observable2, LinearAlgebra.normalize($κ″observable2 - $κ′observable2), $κ′projectionobservable2, LinearAlgebra.normalize($κ″projectionobservable2 - $κ′projectionobservable2),
                    $κ″observable2, LinearAlgebra.normalize($κobservable2 - $κ″observable2), $κ″projectionobservable2, LinearAlgebra.normalize($κprojectionobservable2 - $κ″projectionobservable2)])
GLMakie.arrows!(lscene1,
    ps1, ns1, fxaa = true, # turn on anti-aliasing
    color = [colorants[1], colorants[4], colorants[1], colorants[4], colorants[2], colorants[4], colorants[2], colorants[4], colorants[3], colorants[4], colorants[3], colorants[4]],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
GLMakie.arrows!(lscene2,
    ps2, ns2, fxaa = true, # turn on anti-aliasing
    color = [colorants[1], colorants[4], colorants[1], colorants[4], colorants[2], colorants[4], colorants[2], colorants[4], colorants[3], colorants[4], colorants[3], colorants[4]],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)
titles = ["O", "N", "P", "P′", "P″", "P", "P′", "P″"]
GLMakie.text!(lscene1,
    GLMakie.@lift(map(x -> GLMakie.Point3f(isnan(x) ? ẑ : x), [$origin, $northpole1, $κobservable1, $κ′observable1, $κ″observable1, $κprojectionobservable1, $κ′projectionobservable1, $κ″projectionobservable1])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3], colorants[1], colorants[2], colorants[3]],
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)
GLMakie.text!(lscene2,
    GLMakie.@lift(map(x -> GLMakie.Point3f(isnan(x) ? ẑ : x), [$origin, $northpole2, $κobservable2, $κ′observable2, $κ″observable2, $κprojectionobservable2, $κ′projectionobservable2, $κ″projectionobservable2])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3], colorants[1], colorants[2], colorants[3]],
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

κflagplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplanematrix1 = makeflagplane(κv, κ′v - κv, T, compressedprojection = true, segments = segments)
κflagplanematrix2 = makeflagplane(κv, κ′v - κv, T, compressedprojection = true, segments = segments)
κflagplaneobservable1 = buildsurface(lscene1, κflagplanematrix1, κflagplanecolor, transparency = true)
κflagplaneobservable2 = buildsurface(lscene2, κflagplanematrix2, κflagplanecolor, transparency = true)

κsectional1 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′sectional1 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″sectional1 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
κsectional2 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′sectional2 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″sectional2 = GLMakie.Observable(GLMakie.Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))

# balls
GLMakie.meshscatter!(lscene1, northpole1, markersize = 0.05, color = :black)
GLMakie.meshscatter!(lscene1, origin, markersize = 0.05, color = :gold)
GLMakie.meshscatter!(lscene1, κobservable1, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene1, κ′observable1, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene1, κ″observable1, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene1, κprojectionobservable1, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene1, κ′projectionobservable1, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene1, κ″projectionobservable1, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene1, κsectional1, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene1, κ′sectional1, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene1, κ″sectional1, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene2, northpole2, markersize = 0.05, color = :black)
GLMakie.meshscatter!(lscene2, origin, markersize = 0.05, color = :gold)
GLMakie.meshscatter!(lscene2, κobservable2, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene2, κ′observable2, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene2, κ″observable2, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene2, κprojectionobservable2, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene2, κ′projectionobservable2, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene2, κ″projectionobservable2, markersize = 0.05, color = colorants[3])
GLMakie.meshscatter!(lscene2, κsectional2, markersize = 0.05, color = colorants[1])
GLMakie.meshscatter!(lscene2, κ′sectional2, markersize = 0.05, color = colorants[2])
GLMakie.meshscatter!(lscene2, κ″sectional2, markersize = 0.05, color = colorants[3])

segmentP1 = GLMakie.@lift([$northpole1, $κobservable1, $κprojectionobservable1])
segmentP′1 = GLMakie.@lift([$northpole1, $κ′observable1, $κ′projectionobservable1])
segmentP″1 = GLMakie.@lift([$northpole1, $κ″observable1, $κ″projectionobservable1])
segmentP2 = GLMakie.@lift([$northpole2, $κobservable2, $κprojectionobservable2])
segmentP′2 = GLMakie.@lift([$northpole2, $κ′observable2, $κ′projectionobservable2])
segmentP″2 = GLMakie.@lift([$northpole2, $κ″observable2, $κ″projectionobservable2])
segmentcolors = GLMakie.Observable(collect(1:segments))
linewidth = 8.0
GLMakie.lines!(lscene1, segmentP1, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene1, segmentP′1, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene1, segmentP″1, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentP2, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentP′2, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)
GLMakie.lines!(lscene2, segmentP″2, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, segments), transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    ψ = progress * 2π
    M = exp(K(3) * ψ)
    spintransform = SpinTransformation(0.0, 0.0, 2ψ)
    κtransformed1 = 𝕍( vec(M * ℍ(vec(𝕍( SpinVector(Complex(κ) * cos(ψ), κ.timesign))))))
    κ′transformed1 = 𝕍( vec(M * ℍ(vec(𝕍( SpinVector(Complex(κ′) * cos(ψ), κ′.timesign))))))
    κ″transformed1 = 𝕍( vec(M * ℍ(vec(𝕍( SpinVector(Complex(κ″) * cos(ψ), κ″.timesign))))))
    κtransformed2 = 𝕍(spintransform * κ)
    κ′transformed2 = 𝕍(spintransform * κ′)
    κ″transformed2 = 𝕍(spintransform * κ″)
    northpole1[] = GLMakie.Point3f(project(M * normalize(ℍ(T, 0.0, 0.0, 1.0))))
    spherematrix1 = makesphere(M, T, compressedprojection = true, segments = segments)
    spherematrix2 = makesphere(spintransform, T, segments = segments)
    planematrix1 = makestereographicprojectionplane(M, T = T, segments = segments)
    planematrix2 = makestereographicprojectionplane(spintransform, T = 1.0, segments = segments)
    updatesurface!(planematrix1, planeobservable1)
    updatesurface!(planematrix2, planeobservable2)
    updatesurface!(spherematrix1, sphereobservable1)
    updatesurface!(spherematrix2, sphereobservable2)
    κflagplanematrix1 = makeflagplane(κtransformed1, 𝕍( LinearAlgebra.normalize(vec(κ′transformed1 - κtransformed1))), T, compressedprojection = true, segments = segments)
    κflagplanematrix2 = makeflagplane(κtransformed2, 𝕍( LinearAlgebra.normalize(vec(κ′transformed2 - κtransformed2))), T, compressedprojection = true, segments = segments)
    updatesurface!(κflagplanematrix1, κflagplaneobservable1)
    updatesurface!(κflagplanematrix2, κflagplaneobservable2)
    κflagplanecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([360.0 * progress; 1.0; 1.0])..., 0.8) for i in 1:segments, j in 1:segments]
    κobservable1[] = GLMakie.Point3f(project(normalize(ℍ(vec(κtransformed1)))))
    κ′observable1[] = GLMakie.Point3f(project(normalize(ℍ(vec(κ′transformed1)))))
    κ″observable1[] = GLMakie.Point3f(project(normalize(ℍ(vec(κ″transformed1)))))
    κprojectionobservable1[] = GLMakie.Point3f(projectontoplane(κtransformed1))
    κ′projectionobservable1[] = GLMakie.Point3f(projectontoplane(κ′transformed1))
    κ″projectionobservable1[] = GLMakie.Point3f(projectontoplane(κ″transformed1))
    κobservable2[] = GLMakie.Point3f(project(normalize(ℍ(vec(κtransformed2)))))
    κ′observable2[] = GLMakie.Point3f(project(normalize(ℍ(vec(κ′transformed2)))))
    κ″observable2[] = GLMakie.Point3f(project(normalize(ℍ(vec(κ″transformed2)))))
    κprojectionobservable2[] = GLMakie.Point3f(projectontoplane(κtransformed2))
    κ′projectionobservable2[] = GLMakie.Point3f(projectontoplane(κ′transformed2))
    κ″projectionobservable2[] = GLMakie.Point3f(projectontoplane(κ″transformed2))
    κsectional1[] = (κobservable1[] + κprojectionobservable1[]) * 0.5
    κ′sectional1[] = (κ′observable1[] + κ′projectionobservable1[]) * 0.5
    κ″sectional1[] = (κ″observable1[] + κ″projectionobservable1[]) * 0.5
    κsectional2[] = (κobservable2[] + κprojectionobservable2[]) * 0.5
    κ′sectional2[] = (κ′observable2[] + κ′projectionobservable2[]) * 0.5
    κ″sectional2[] = (κ″observable2[] + κ″projectionobservable2[]) * 0.5
    for (i, scale1) in enumerate(collect(range(0.0, stop = T, length = segments)))
        _κlinepoints1 = GLMakie.Point3f[]
        _κlinepoints2 = GLMakie.Point3f[]
        _κlinecolors = Int[]
        for (j, scale2) in enumerate(collect(range(0.0, stop = T, length = segments)))
            κvector = normalize(ℍ(vec(scale1 * κtransformed1 + scale2 * 𝕍( LinearAlgebra.normalize(vec(κ′transformed1 - κtransformed1))))))
            κpoint = GLMakie.Point3f(project(κvector))
            push!(_κlinepoints1, κpoint)
            κvector = normalize(ℍ(vec(scale1 * κtransformed2 + scale2 * 𝕍( LinearAlgebra.normalize(vec(κ′transformed2 - κtransformed2))))))
            κpoint = GLMakie.Point3f(project(κvector))
            push!(_κlinepoints2, κpoint)
            push!(_κlinecolors, i + j)
        end
        κlinepoints1[i][] = _κlinepoints1
        κlinepoints2[i][] = _κlinepoints2
        κlinecolors[i][] = _κlinecolors
    end
    global lookat1 = (1.0 / 3.0) * ℝ³(κsectional1[] + κ′sectional1[] + κ″sectional1[])
    global lookat2 = (1.0 / 3.0) * ℝ³(κsectional2[] + κ′sectional2[] + κ″sectional2[])
    global eyeposition = (x̂ + ŷ + ẑ) * float(π)
    updatecamera!(lscene1, eyeposition, lookat1, up)
    updatecamera!(lscene2, eyeposition, lookat2, up)
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)