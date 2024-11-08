using FileIO
using GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig122spinvectorssumargandplane"
M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
timesign = 1
T = Float64(timesign)
ϵ = 0.01
linewidth = 20
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
markersize = 0.05
mask = load("data/basemap_mask.png")

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

generate() = 10rand() - 5 + im * (10rand() - 5)
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
ζ = Complex(κ + ω)
τ = SpinVector(ζ, timesign)
ζ′ = ζ - 1.0 / √2 * ϵ / τ.a[2]
τ′ = SpinVector(ζ′, timesign)

w = (Complex(κ + ω) - Complex(κ)) / (Complex(ω) - Complex(κ))
@assert(imag(w) ≤ 0 || isapprox(imag(w), 0.0), "The flagpoles are not collinear: $(Complex(κ)), $(Complex(ω)), $(Complex(κ + ω))")

κv = 𝕍( normalize(ℝ⁴(𝕍( κ))))
κ′v = 𝕍( normalize(ℝ⁴(𝕍( κ′))))
ωv = 𝕍( normalize(ℝ⁴(𝕍( ω))))
ω′v = 𝕍( normalize(ℝ⁴(𝕍( ω′))))
τv = 𝕍( normalize(ℝ⁴(𝕍(τ))))
τ′v = 𝕍( normalize(ℝ⁴(𝕍(τ′))))

κtail = Observable(Point3f(0.0, 0.0, 0.0))
ωtail = Observable(Point3f(0.0, 0.0, 0.0))
τtail = Observable(Point3f(0.0, 0.0, 0.0))
κhead = Observable(Point3f(project(ℍ(vec(κv)))))
ωhead = Observable(Point3f(project(ℍ(vec(ωv)))))
τhead = Observable(Point3f(project(ℍ(vec(τv)))))
ps = @lift([$κtail, $ωtail, $τtail])
ns = @lift([$κhead, $ωhead, $τhead])
colorants = [:red, :green, :blue]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

circlepoints = Observable(Point3f[])
circlecolors = Observable(Int[])
circle = lines!(lscene, circlepoints, color = circlecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :rainbow)

titles = ["κ", "ω", "κ+ω", "P", "Q", "R"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$κhead + $κtail, $ωhead + $ωtail, $τhead + $τtail, $κtail, $ωtail, $τtail])),
    text = titles,
    color = [colorants..., colorants...],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

spherematrix = makesphere(M, T, compressedprojection = true, segments = segments)
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)

κflagplanematrix = makeflagplane(κv, κ′v - κv, T, segments = segments)
κflagplanecolor = Observable(fill(RGBAf(1.0, 0.0, 0.0, 0.8), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = false)
ωflagplanematrix = makeflagplane(ωv, ω′v - ωv, T, segments = segments)
ωflagplanecolor = Observable(fill(RGBAf(0.0, 1.0, 0.0, 0.8), segments, segments))
ωflagplaneobservable = buildsurface(lscene, ωflagplanematrix, ωflagplanecolor, transparency = false)
τflagplanematrix = makeflagplane(τv, τ′v - τv, T, segments = segments)
τflagplanecolor = Observable(fill(RGBAf(0.0, 0.0, 1.0, 0.8), segments, segments))
τflagplaneobservable = buildsurface(lscene, τflagplanematrix, τflagplanecolor, transparency = false)

meshscatter!(lscene, κtail, markersize = markersize, color = colorants[1])
meshscatter!(lscene, ωtail, markersize = markersize, color = colorants[2])
meshscatter!(lscene, τtail, markersize = markersize, color = colorants[3])


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    z₁ = Complex(κ)
    z₂ = Complex(ω)
    z₃ = Complex(κ + ω)
    w₁ = progress * exp(im * 0.0) + (1 - progress) * z₁
    w₂ = progress * exp(im * 2π / 3.0) + (1 - progress) * z₂
    w₃ = progress * exp(im * 4π / 3.0) + (1 - progress) * z₃
    f = calculatetransformation(z₁, z₂, z₃, w₁, w₂, w₃)
    _κ = SpinVector(f(Complex(κ)), timesign)
    _ω = SpinVector(f(Complex(-ω)), timesign)
    _κ′ = SpinVector(f(Complex(κ′)), timesign)
    _ω′ = SpinVector(f(Complex(ω′)), timesign)
    _κv = 𝕍( normalize(ℝ⁴(𝕍( _κ))))
    _κ′v = 𝕍( normalize(ℝ⁴(𝕍( _κ′))))
    _ωv = 𝕍( normalize(ℝ⁴(𝕍( _ω))))
    _ω′v = 𝕍( normalize(ℝ⁴(𝕍( _ω′))))
    
    _τ = _κ + _ω
    _τ′ = SpinVector(Complex(_τ) - 1.0 / √2 * ϵ / _τ.a[2], timesign)
    _τv = 𝕍( normalize( ℝ⁴( 𝕍( _τ))))
    _τ′v = 𝕍( normalize( ℝ⁴( 𝕍( _τ′))))
    κflagplane1 = _κv
    κflagplane2 = 𝕍( normalize( ℝ⁴( _κ′v - _κv)))
    ωflagplane1 = _ωv
    ωflagplane2 = 𝕍( normalize( ℝ⁴( _ω′v - _ωv)))
    τflagplane1 = _τv
    τflagplane2 = 𝕍( normalize( ℝ⁴( _τ′v - _τv)))
    updatesurface!(makesphere(f, T, compressedprojection = true, segments = segments), sphereobservable)
    updatesurface!(makeflagplane(κflagplane1, κflagplane2, T, segments = segments), κflagplaneobservable)
    updatesurface!(makeflagplane(ωflagplane1, ωflagplane2, T, segments = segments), ωflagplaneobservable)
    updatesurface!(makeflagplane(τflagplane1, τflagplane2, T, segments = segments), τflagplaneobservable)
    κtail[] = Point3f(project(ℝ⁴(_κv)))
    ωtail[] = Point3f(project(ℝ⁴(_ωv)))
    τtail[] = Point3f(project(ℝ⁴(_τv)))
    κhead[] = Point3f(project(normalize(ℝ⁴(_κ′v - _κv))))
    ωhead[] = Point3f(project(normalize(ℝ⁴(_ω′v - _ωv))))
    τhead[] = Point3f(project(normalize(ℝ⁴(_τ′v - _τv))))
    _circlepoints = Point3f[]
    _circlecolors = Int[]
    for (i, ϕ) in enumerate(collect(range(-4π, stop = 4π, length = segments)))
        κζ = Complex(_κ)
        ωζ = Complex(_ω)
        ζ = κζ - ωζ
        circlevector = normalize(ℝ⁴(𝕍( SpinVector(κζ + ϕ * ζ, timesign))))
        circlepoint = Point3f(project(circlevector))
        push!(_circlepoints, circlepoint)
        push!(_circlecolors, i)
    end
    circlepoints[] = _circlepoints
    circlecolors[] = _circlecolors
    notify(circlepoints)
    notify(circlecolors)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end