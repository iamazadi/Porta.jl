using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig119sumofangles"
M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
linewidth = 20
markersize = 0.05
timesign = 1
ϵ = 0.01
T = Float64(timesign)
mask = load("data/basemap_mask.png")

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

ο = SpinVector([Complex(1.0); Complex(0.0)], timesign)
ι = SpinVector([Complex(0.0); Complex(1.0)], timesign)
@assert(isapprox(dot(ο, ι), 1.0), "The inner product of spin vectors $ι and $ο is not unity.")
@assert(isapprox(dot(ι, ο), -1.0), "The inner product of spin vectors $ι and $ο is not unity.")

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
ω = SpinVector(generate(), generate(), timesign)
ζ = Complex(κ)
ζ′ = ζ - 1.0 / √2 * ϵ / κ.a[2]
κ = SpinVector(ζ, timesign)
κ′ = SpinVector(ζ′, timesign)
ζ = Complex(ω)
ζ′ = ζ - 1.0 / √2 * ϵ / ω.a[2]
ω = SpinVector(ζ, timesign)
ω′ = SpinVector(ζ′, timesign)
@assert(isapprox(dot(κ, ι), vec(κ)[1]), "The first component of the spin vector $κ is not equal to the inner product of $κ and $ι.")
@assert(isapprox(dot(κ, ο), -vec(κ)[2]), "The second component of the spin vector $κ is not equal to minus the inner product of $κ and $ο.")
@assert(isapprox(dot(ω, ι), vec(ω)[1]), "The first component of the spin vector $ω is not equal to the inner product of $ω and $ι.")
@assert(isapprox(dot(ω, ο), -vec(ω)[2]), "The second component of the spin vector $ω is not equal to minus the inner product of $ω and $ο.")
@assert(isapprox(dot(ω, ι), vec(ω)[1]), "The first component of the spin vector $ω is not equal to the inner product of $ω and $ι.")

w = (Complex(κ + ω) - Complex(κ)) / (Complex(ω) - Complex(κ))
@assert(imag(w) ≤ 0 || isapprox(imag(w), 0.0), "The flagpoles are not collinear: $(Complex(κ)), $(Complex(ω)), $(Complex(κ + ω))")

κv = 𝕍( normalize(ℝ⁴(𝕍( κ))))
κ′v = 𝕍( normalize(ℝ⁴(𝕍( κ′))))
ωv = 𝕍( normalize(ℝ⁴(𝕍( ω))))
ω′v = 𝕍( normalize(ℝ⁴(𝕍( ω′))))

northpole = Observable(Point3f(0.0, 0.0, 1.0))
tail = Observable(Point3f(0.0, 0.0, 0.0))
κtail = Observable(Point3f(0.0, 0.0, 0.0))
ωtail = Observable(Point3f(0.0, 0.0, 0.0))
κhead = Observable(Point3f(project(ℍ(vec(κv)))))
ωhead = Observable(Point3f(project(ℍ(vec(ωv)))))
ps = @lift([$κtail, $ωtail])
ns = @lift([$κhead, $ωhead])
colorants = [:red, :green]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

circlepoints1 = Observable(Point3f[])
circlecolors1 = Observable(Int[])
circlepoints2 = Observable(Point3f[])
circlecolors2 = Observable(Int[])
lines!(lscene, circlepoints1, color = circlecolors1, linewidth = 2linewidth, colorrange = (1, segments), colormap = :Paired_12)
lines!(lscene, circlepoints2, color = circlecolors2, linewidth = 2linewidth, colorrange = (1, segments), colormap = :Dark2_8)

titles = ["N", "L", "M", "P", "Q"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$northpole, $κhead + $κtail, $ωhead + $ωtail, $κtail, $ωtail])),
    text = titles,
    color = [:black, colorants..., colorants...],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

κflagplanematrix = makeflagplane(κv, κ′v - κv, T, segments = segments)
κflagplanecolor = Observable(fill(RGBAf(1.0, 0.0, 0.0, 0.8), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = false)
ωflagplanematrix = makeflagplane(ωv, ω′v - ωv, T, segments = segments)
ωflagplanecolor = Observable(fill(RGBAf(0.0, 1.0, 0.0, 0.8), segments, segments))
ωflagplaneobservable = buildsurface(lscene, ωflagplanematrix, ωflagplanecolor, transparency = false)

meshscatter!(lscene, northpole, markersize = markersize, color = :black)
meshscatter!(lscene, tail, markersize = markersize, color = :black)
meshscatter!(lscene, κtail, markersize = markersize, color = colorants[1])
meshscatter!(lscene, ωtail, markersize = markersize, color = colorants[2])

spherematrix = makesphere(M, T, compressedprojection = true, segments = segments)
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    spintransform = SpinTransformation(progress * 2π, progress * 2π, progress * 2π)
    _κ = spintransform * κ
    _ω = spintransform * ω
    _κ′ = spintransform * κ′
    _ω′ = spintransform * ω′
    _κv = 𝕍( normalize(ℝ⁴(𝕍( _κ))))
    _κ′v = 𝕍( normalize(ℝ⁴(𝕍( _κ′))))
    _ωv = 𝕍( normalize(ℝ⁴(𝕍( _ω))))
    _ω′v = 𝕍( normalize(ℝ⁴(𝕍( _ω′))))
    κflagplane1 = _κv
    κflagplane2 = 𝕍(normalize(ℝ⁴(_κ′v - _κv)))
    ωflagplane1 = _ωv
    ωflagplane2 = 𝕍(normalize(ℝ⁴(_ω′v - _ωv)))
    northpole[] = Point3f(project(normalize(ℝ⁴(𝕍( spintransform * SpinVector(Inf, timesign))))))
    spherematrix = makesphere(spintransform, T, compressedprojection = true, segments = segments)
    updatesurface!(spherematrix, sphereobservable)
    κflagplanematrix = makeflagplane(κflagplane1, κflagplane2, T, segments = segments)
    ωflagplanematrix = makeflagplane(ωflagplane1, ωflagplane2, T, segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable)
    updatesurface!(ωflagplanematrix, ωflagplaneobservable)
    κtail[] = Point3f(project(normalize(ℝ⁴(_κv))))
    ωtail[] = Point3f(project(normalize(ℝ⁴(_ωv))))
    κhead[] = Point3f(project(normalize(ℝ⁴(_κ′v - _κv))))
    ωhead[] = Point3f(project(normalize(ℝ⁴(_ω′v - _ωv))))
    _circlepoints1 = Point3f[]
    _circlecolors1 = Int[]
    _circlepoints2 = Point3f[]
    _circlecolors2 = Int[]
    for (i, ϕ) in enumerate(collect(range(-4π, stop = 4π, length = segments)))
        κζ = Complex(κ)
        ωζ = Complex(ω)
        ζ = κζ - ωζ
        circlevector = normalize(ℝ⁴(𝕍(spintransform * SpinVector(κζ + ϕ * ζ, timesign))))
        circlepoint = Point3f(project(circlevector))
        push!(_circlepoints1, circlepoint)
        push!(_circlecolors1, i)
        κζ = Complex(κ)
        ωζ = Complex(ω)
        center = κζ + (ωζ - κζ) / 2.0
        radius = abs(ωζ - κζ) / 2.0
        circlevector = normalize(ℝ⁴(𝕍(spintransform * SpinVector(center + radius * exp(im * ϕ / 4.0), timesign))))
        circlepoint = Point3f(project(circlevector))
        push!(_circlepoints2, circlepoint)
        push!(_circlecolors2, i)
    end
    circlepoints1[] = _circlepoints1
    circlecolors1[] = _circlecolors1
    circlepoints2[] = _circlepoints2
    circlecolors2[] = _circlecolors2
    notify(circlepoints1)
    notify(circlecolors1)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end