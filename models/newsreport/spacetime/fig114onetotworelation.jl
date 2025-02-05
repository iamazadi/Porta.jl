using FileIO
using GLMakie
using LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig114onetotworelation"

M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition1 = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
eyeposition2 = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat1 = ℝ³(0.0, 0.0, 0.0)
lookat2 = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
totalstages = 1
mask = load("data/basemap_mask.png")

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 2], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

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
    _κlinepoints1 = Observable(Point3f[])
    _κlinepoints2 = Observable(Point3f[])
    _κlinecolors = Observable(Int[])
    for (j, scale2) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        κvector = normalize(vec(scale1 * κv + scale2 * κ′v))
        κpoint = Point3f(projectnocompression(ℍ(κvector)))
        push!(_κlinepoints1[], κpoint)
        push!(_κlinecolors[], i + j)
        κvector = normalize(vec(scale1 * κv + scale2 * κ′v))
        κpoint = Point3f(projectnocompression(ℍ(κvector)))
        push!(_κlinepoints2[], κpoint)
    end
    push!(κlinepoints1, _κlinepoints1)
    push!(κlinecolors, _κlinecolors)
    push!(κlinepoints2, _κlinepoints2)
    lines!(lscene1, κlinepoints1[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
    lines!(lscene2, κlinepoints2[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
end

arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
colorants = [:red, :green, :blue, :black]
origin = Observable(Point3f(0.0, 0.0, 0.0))
northpole1 = Observable(Point3f(0.0, 0.0, 1.0))
κobservable1 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′observable1 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″observable1 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
κprojectionobservable1 = Observable(Point3f(projectontoplane(κv)))
κ′projectionobservable1 = Observable(Point3f(projectontoplane(κ′v)))
κ″projectionobservable1 = Observable(Point3f(projectontoplane(κ″v)))
northpole2 = Observable(Point3f(0.0, 0.0, 1.0))
κobservable2 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′observable2 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″observable2 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
κprojectionobservable2 = Observable(Point3f(projectontoplane(κv)))
κ′projectionobservable2 = Observable(Point3f(projectontoplane(κ′v)))
κ″projectionobservable2 = Observable(Point3f(projectontoplane(κ″v)))
ps1 = @lift([$origin, $κobservable1, $origin, $κprojectionobservable1,
                    $origin, $κ′observable1, $origin, $κ′projectionobservable1,
                    $origin, $κ″observable1, $origin, $κ″projectionobservable1])
ns1 = @lift([$κobservable1, normalize($κ′observable1 - $κobservable1), $κprojectionobservable1, normalize($κ′projectionobservable1 - $κprojectionobservable1),
                    $κ′observable1, normalize($κ″observable1 - $κ′observable1), $κ′projectionobservable1, normalize($κ″projectionobservable1 - $κ′projectionobservable1),
                    $κ″observable1, normalize($κobservable1 - $κ″observable1), $κ″projectionobservable1, normalize($κprojectionobservable1 - $κ″projectionobservable1)])
ps2 = @lift([$origin, $κobservable2, $origin, $κprojectionobservable2,
                    $origin, $κ′observable2, $origin, $κ′projectionobservable2,
                    $origin, $κ″observable2, $origin, $κ″projectionobservable2])
ns2 = @lift([$κobservable2, normalize($κ′observable2 - $κobservable2), $κprojectionobservable2, normalize($κ′projectionobservable2 - $κprojectionobservable2),
                    $κ′observable2, normalize($κ″observable2 - $κ′observable2), $κ′projectionobservable2, normalize($κ″projectionobservable2 - $κ′projectionobservable2),
                    $κ″observable2, normalize($κobservable2 - $κ″observable2), $κ″projectionobservable2, normalize($κprojectionobservable2 - $κ″projectionobservable2)])
arrows!(lscene1,
    ps1, ns1, fxaa = true, # turn on anti-aliasing
    color = [colorants[1], colorants[4], colorants[1], colorants[4], colorants[2], colorants[4], colorants[2], colorants[4], colorants[3], colorants[4], colorants[3], colorants[4]],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
arrows!(lscene2,
    ps2, ns2, fxaa = true, # turn on anti-aliasing
    color = [colorants[1], colorants[4], colorants[1], colorants[4], colorants[2], colorants[4], colorants[2], colorants[4], colorants[3], colorants[4], colorants[3], colorants[4]],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)
titles = ["O", "N", "P", "P′", "P″", "P", "P′", "P″"]
text!(lscene1,
    @lift(map(x -> Point3f(isnan(x) ? ẑ : x), [$origin, $northpole1, $κobservable1, $κ′observable1, $κ″observable1, $κprojectionobservable1, $κ′projectionobservable1, $κ″projectionobservable1])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3], colorants[1], colorants[2], colorants[3]],
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)
text!(lscene2,
    @lift(map(x -> Point3f(isnan(x) ? ẑ : x), [$origin, $northpole2, $κobservable2, $κ′observable2, $κ″observable2, $κprojectionobservable2, $κ′projectionobservable2, $κ″projectionobservable2])),
    text = titles,
    color = [:gold, :black, colorants[1], colorants[2], colorants[3], colorants[1], colorants[2], colorants[3]],
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

κflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplanematrix1 = makeflagplane(κv, κ′v - κv, T, compressedprojection = true, segments = segments)
κflagplanematrix2 = makeflagplane(κv, κ′v - κv, T, compressedprojection = true, segments = segments)
κflagplaneobservable1 = buildsurface(lscene1, κflagplanematrix1, κflagplanecolor, transparency = true)
κflagplaneobservable2 = buildsurface(lscene2, κflagplanematrix2, κflagplanecolor, transparency = true)

κsectional1 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′sectional1 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″sectional1 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))
κsectional2 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κv))))))
κ′sectional2 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ′v))))))
κ″sectional2 = Observable(Point3f(projectnocompression(normalize(ℍ(vec(κ″v))))))

# balls
meshscatter!(lscene1, northpole1, markersize = 0.05, color = :black)
meshscatter!(lscene1, origin, markersize = 0.05, color = :gold)
meshscatter!(lscene1, κobservable1, markersize = 0.05, color = colorants[1])
meshscatter!(lscene1, κ′observable1, markersize = 0.05, color = colorants[2])
meshscatter!(lscene1, κ″observable1, markersize = 0.05, color = colorants[3])
meshscatter!(lscene1, κprojectionobservable1, markersize = 0.05, color = colorants[1])
meshscatter!(lscene1, κ′projectionobservable1, markersize = 0.05, color = colorants[2])
meshscatter!(lscene1, κ″projectionobservable1, markersize = 0.05, color = colorants[3])
meshscatter!(lscene1, κsectional1, markersize = 0.05, color = colorants[1])
meshscatter!(lscene1, κ′sectional1, markersize = 0.05, color = colorants[2])
meshscatter!(lscene1, κ″sectional1, markersize = 0.05, color = colorants[3])
meshscatter!(lscene2, northpole2, markersize = 0.05, color = :black)
meshscatter!(lscene2, origin, markersize = 0.05, color = :gold)
meshscatter!(lscene2, κobservable2, markersize = 0.05, color = colorants[1])
meshscatter!(lscene2, κ′observable2, markersize = 0.05, color = colorants[2])
meshscatter!(lscene2, κ″observable2, markersize = 0.05, color = colorants[3])
meshscatter!(lscene2, κprojectionobservable2, markersize = 0.05, color = colorants[1])
meshscatter!(lscene2, κ′projectionobservable2, markersize = 0.05, color = colorants[2])
meshscatter!(lscene2, κ″projectionobservable2, markersize = 0.05, color = colorants[3])
meshscatter!(lscene2, κsectional2, markersize = 0.05, color = colorants[1])
meshscatter!(lscene2, κ′sectional2, markersize = 0.05, color = colorants[2])
meshscatter!(lscene2, κ″sectional2, markersize = 0.05, color = colorants[3])

segmentP1 = @lift([$northpole1, $κobservable1, $κprojectionobservable1])
segmentP′1 = @lift([$northpole1, $κ′observable1, $κ′projectionobservable1])
segmentP″1 = @lift([$northpole1, $κ″observable1, $κ″projectionobservable1])
segmentP2 = @lift([$northpole2, $κobservable2, $κprojectionobservable2])
segmentP′2 = @lift([$northpole2, $κ′observable2, $κ′projectionobservable2])
segmentP″2 = @lift([$northpole2, $κ″observable2, $κ″projectionobservable2])
segmentcolors = Observable(collect(1:3))
linewidth = 8.0
lines!(lscene1, segmentP1, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene1, segmentP′1, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene1, segmentP″1, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene2, segmentP2, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene2, segmentP′2, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)
lines!(lscene2, segmentP″2, linewidth = 2linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = false)


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
    northpole1[] = Point3f(project(M * normalize(ℍ(T, 0.0, 0.0, 1.0))))
    spherematrix1 = makesphere(M, T, compressedprojection = true, segments = segments)
    spherematrix2 = makesphere(spintransform, T, segments = segments)
    planematrix1 = makestereographicprojectionplane(M, T = T, segments = segments)
    planematrix2 = makestereographicprojectionplane(spintransform, T = 1.0, segments = segments)
    updatesurface!(planematrix1, planeobservable1)
    updatesurface!(planematrix2, planeobservable2)
    updatesurface!(spherematrix1, sphereobservable1)
    updatesurface!(spherematrix2, sphereobservable2)
    κflagplanematrix1 = makeflagplane(κtransformed1, 𝕍( normalize(vec(κ′transformed1 - κtransformed1))), T, compressedprojection = true, segments = segments)
    κflagplanematrix2 = makeflagplane(κtransformed2, 𝕍( normalize(vec(κ′transformed2 - κtransformed2))), T, compressedprojection = true, segments = segments)
    updatesurface!(κflagplanematrix1, κflagplaneobservable1)
    updatesurface!(κflagplanematrix2, κflagplaneobservable2)
    κflagplanecolor[] = [RGBAf(convert_hsvtorgb([359.0 * progress; 1.0; 1.0])..., 0.8) for i in 1:segments, j in 1:segments]
    κobservable1[] = Point3f(project(normalize(ℍ(vec(κtransformed1)))))
    κ′observable1[] = Point3f(project(normalize(ℍ(vec(κ′transformed1)))))
    κ″observable1[] = Point3f(project(normalize(ℍ(vec(κ″transformed1)))))
    κprojectionobservable1[] = Point3f(projectontoplane(κtransformed1))
    κ′projectionobservable1[] = Point3f(projectontoplane(κ′transformed1))
    κ″projectionobservable1[] = Point3f(projectontoplane(κ″transformed1))
    κobservable2[] = Point3f(project(normalize(ℍ(vec(κtransformed2)))))
    κ′observable2[] = Point3f(project(normalize(ℍ(vec(κ′transformed2)))))
    κ″observable2[] = Point3f(project(normalize(ℍ(vec(κ″transformed2)))))
    κprojectionobservable2[] = Point3f(projectontoplane(κtransformed2))
    κ′projectionobservable2[] = Point3f(projectontoplane(κ′transformed2))
    κ″projectionobservable2[] = Point3f(projectontoplane(κ″transformed2))
    κsectional1[] = (κobservable1[] + κprojectionobservable1[]) * 0.5
    κ′sectional1[] = (κ′observable1[] + κ′projectionobservable1[]) * 0.5
    κ″sectional1[] = (κ″observable1[] + κ″projectionobservable1[]) * 0.5
    κsectional2[] = (κobservable2[] + κprojectionobservable2[]) * 0.5
    κ′sectional2[] = (κ′observable2[] + κ′projectionobservable2[]) * 0.5
    κ″sectional2[] = (κ″observable2[] + κ″projectionobservable2[]) * 0.5
    for (i, scale1) in enumerate(collect(range(0.0, stop = T, length = segments)))
        _κlinepoints1 = Point3f[]
        _κlinepoints2 = Point3f[]
        _κlinecolors = Int[]
        for (j, scale2) in enumerate(collect(range(0.0, stop = T, length = segments)))
            κvector = normalize(ℍ(vec(scale1 * κtransformed1 + scale2 * 𝕍( normalize(vec(κ′transformed1 - κtransformed1))))))
            κpoint = Point3f(project(κvector))
            push!(_κlinepoints1, κpoint)
            κvector = normalize(ℍ(vec(scale1 * κtransformed2 + scale2 * 𝕍( normalize(vec(κ′transformed2 - κtransformed2))))))
            κpoint = Point3f(project(κvector))
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

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end