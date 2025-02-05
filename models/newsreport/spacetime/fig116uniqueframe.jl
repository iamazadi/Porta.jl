using FileIO
using GLMakie
using LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig116uniqueframe"

M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
T = 1.0
ϵ = 1e-2
linewidth = 20
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
mask = load("data/basemap_mask.png")

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), Int(T))
ζ = Complex(κ)
κ = SpinVector(ζ, Int(T))
κantipode = SpinVector(-1.0 / conj(ζ), Int(T))
ζ′ = ζ - (1.0 / √2) * 10ϵ * (1.0 / κ.a[2]^2)
κ′ = SpinVector(ζ′, Int(T))
κv = 𝕍( κ)
κ′v = 𝕍( κ′)
κvantipode = 𝕍( κantipode)

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

spherematrix = makesphere(M, T, compressedprojection = true, segments = segments)
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)

origin = Observable(Point3f(0.0, 0.0, 0.0))
κobservable = Observable(Point3f(project(normalize(ℍ(vec(κv))))))
κ′observable = Observable(Point3f(project(normalize(ℍ(vec(κ′v))))))
κvobservable = Observable(κv)
κ′vobservable = Observable(κ′v)
A = Observable(ℝ⁴(1.0, 0.0, 0.0, 0.0))
B = Observable(ℝ⁴(0.0, 1.0, 0.0, 0.0))
C = Observable(ℝ⁴(0.0, 0.0, 1.0, 0.0))
D = Observable(ℝ⁴(0.0, 0.0, 0.0, 1.0))
Ahead = @lift(Point3f(normalize(project(ℍ($A)))))
Bhead = @lift(Point3f(normalize(project(ℍ($B)))))
Chead = @lift(Point3f(normalize(project(ℍ($C)))))
Dhead = @lift(Point3f(normalize(project(ℍ($D)))))
ps = @lift([$origin, $κobservable, $κobservable, $κobservable, $κobservable, $κobservable])
ns = @lift([$κobservable, normalize($κ′observable - $κobservable), $Ahead, $Bhead, $Chead, $Dhead])
colorants = [:black, :gray, :red, :green, :blue, :orange]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

rotation = gettextrotation(lscene)
titles = ["O", "P", "P′", "A", "B", "C", "D"]
text!(lscene,
    @lift(map(x -> Point3f(isnan(x) ? ẑ : x), [$origin, $κobservable, $κ′observable, $κobservable + $Ahead, $κobservable + $Bhead, $κobservable + $Chead, $κobservable + $Dhead])),
    text = titles,
    color = [:black, colorants...],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

κflagplanematrix = @lift(makeflagplane($κvobservable, $κ′vobservable - $κvobservable, T, compressedprojection = true, segments = segments))
κflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.8), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = true)

# balls
meshscatter!(lscene, origin, markersize = 0.05, color = :black)
meshscatter!(lscene, κobservable, markersize = 0.05, color = colorants[1])
meshscatter!(lscene, κ′observable, markersize = 0.05, color = colorants[2])


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    θ₁ = sin(progress * 2π) * float(π)
    a = ℍ(exp(K(1) * θ₁))
    θ₂ = cos(progress * 2π) * float(π)
    b = ℍ(exp(K(2) * θ₂))

    _κv = a * ℍ(vec(κv)) * b
    _κvantipode = a * ℍ(vec(κvantipode)) * b
    _κ′v = a * ℍ(vec(κ′v)) * b
    κvobservable[] = 𝕍( vec(_κv))
    κ′vobservable[] = 𝕍( vec(_κ′v))
    κobservable[] = Point3f(project(normalize(_κv)))
    κ′observable[] = Point3f(project(normalize(_κ′v)))

    A[] = ℝ⁴(vec(normalize(_κv + _κvantipode)))
    v = normalize(ℝ⁴(vec(_κv)))
    B[] = normalize(v - dot(v, A[]) * A[])
    v = ℝ⁴(vec(normalize(_κ′v - _κv)))
    C[] = normalize(v - dot(v, A[]) * A[])
    v = normalize(ℝ⁴(1.0, 1.0, 1.0, 1.0))
    D[] = normalize(v - dot(v, A[]) * A[] - dot(v, B[]) * B[] - dot(v, C[]) * C[])

    κflagplanecolor[] = [RGBAf(convert_hsvtorgb([359.0 * progress; 1.0; 1.0])..., 0.8) for i in 1:segments, j in 1:segments]

    spherematrix = makesphere(a, b, T, compressedprojection = true, segments = segments)
    updatesurface!(spherematrix, sphereobservable)

    ratio = frame == 1 ? 0.0 : 0.95
    global up = ratio * up + (1.0 - ratio) * ℝ³(Ahead[])
    global lookat = ratio * lookat + (1.0 - ratio) * (1.0 / 4.0) * ℝ³(Ahead[] + Bhead[] + Chead[])
    global eyeposition = ratio * eyeposition + (1.0 - ratio) * normalize(lookat) * float(π)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end