using FileIO
using GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig120innerproductphase"
M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
timesign = 1
T = Float64(timesign)
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
linewidth = 20
ϵ = 0.01
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
ζ = Complex(κ)
ζ′ = ζ - 1.0 / √2 * ϵ / κ.a[2]
κ = SpinVector(ζ, timesign)
κ′ = SpinVector(ζ′, timesign)
ω = SpinVector(generate(), generate(), timesign)
ζ = Complex(ω)
ζ′ = ζ - 1.0 / √2 * ϵ / ω.a[2]
ω = SpinVector(ζ, timesign)
ω′ = SpinVector(ζ′, timesign)
@assert(isapprox(dot(κ, ι), vec(κ)[1]), "The first component of the spin vector $κ is not equal to the inner product of $κ and $ι.")
@assert(isapprox(dot(κ, ο), -vec(κ)[2]), "The second component of the spin vector $κ is not equal to minus the inner product of $κ and $ο.")
@assert(isapprox(dot(ω, ι), vec(ω)[1]), "The first component of the spin vector $ω is not equal to the inner product of $ω and $ι.")
@assert(isapprox(dot(ω, ο), -vec(ω)[2]), "The second component of the spin vector $ω is not equal to minus the inner product of $ω and $ο.")

κv = 𝕍( normalize(ℝ⁴(𝕍( κ))))
κ′v = 𝕍( normalize(ℝ⁴(𝕍( κ′))))
ωv = 𝕍( normalize(ℝ⁴(𝕍( ω))))
ω′v = 𝕍( normalize(ℝ⁴(𝕍( ω′))))

u = 𝕍(LinearAlgebra.normalize(rand(4)))
v = 𝕍(LinearAlgebra.normalize(rand(4)))
p = 𝕍(LinearAlgebra.normalize(vec(u + v)))

tail = Observable(Point3f(0.0, 0.0, 0.0))
κhead = Observable(Point3f(project(ℝ⁴(κv))))
ωhead = Observable(Point3f(project(ℝ⁴(ωv))))
uhead = Observable(Point3f(project(ℍ(vec(u)))))
vhead = Observable(Point3f(project(ℍ(vec(v)))))
phead = Observable(Point3f(project(ℍ(vec(p)))))
ps = @lift([$tail, $tail, $tail, $tail, $tail])
ns = @lift([$κhead, $ωhead, $uhead, $vhead, $phead])
colorants = [:red, :green, :red, :green, :black]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

arcpoints = Observable(Point3f[])
arccolors = Observable(Int[])
arc = lines!(lscene, arcpoints, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism)

titles = ["κ", "ω", "U", "V", "p"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$κhead, $ωhead, $uhead, $vhead, $phead])),
    text = titles,
    color = colorants,
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

planematrix = makeflagplane(κv, ωv, M)
planecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
planeobservable = buildsurface(lscene, planematrix, planecolor, transparency = true)
ê₁, ê₂, ê₃, ê₄ = calculatebasisvectors(κ, ω)
orthogonalplanematrix = makeflagplane(𝕍( ê₃), 𝕍( ê₄), M)
orthogonalplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
orthogonalplaneobservable = buildsurface(lscene, orthogonalplanematrix, orthogonalplanecolor, transparency = true)
κflagplanematrix = makeflagplane(κv, κ′v - κv, T, segments = segments)
κflagplanecolor = Observable(fill(RGBAf(1.0, 0.0, 0.0, 0.8), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = false)
ωflagplanematrix = makeflagplane(ωv, ω′v - ωv, T, segments = segments)
ωflagplanecolor = Observable(fill(RGBAf(0.0, 1.0, 0.0, 0.8), segments, segments))
ωflagplaneobservable = buildsurface(lscene, ωflagplanematrix, ωflagplanecolor, transparency = false)
meshscatter!(lscene, tail, markersize = 0.05, color = :black)


animate(frame::Int) = begin
    progress = frame / frames_number
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
    ê₁, ê₂, ê₃, ê₄ = calculatebasisvectors(_κ, _ω)
    κflagplane1 = _κv
    κflagplane2 = 𝕍(normalize(ℝ⁴(_κ′v - _κv)))
    ωflagplane1 = _ωv
    ωflagplane2 = 𝕍(normalize(ℝ⁴(_ω′v - _ωv)))
    global u = normalize(dot(ê₃, κflagplane1) * ê₃ + dot(ê₃, κflagplane2) * ê₃ + dot(ê₄, κflagplane1) * ê₄ + dot(ê₄, κflagplane2) * ê₄)
    global v = normalize(dot(ê₃, ωflagplane1) * ê₃ + dot(ê₃, ωflagplane2) * ê₃ + dot(ê₄, ωflagplane1) * ê₄ + dot(ê₄, ωflagplane2) * ê₄)
    global p = dot(ê₃, normalize(u + v)) * ê₃ + dot(ê₄, normalize(u + v)) * ê₄
    κflagplanematrix = makeflagplane(κflagplane1, κflagplane2, T, segments = segments)
    ωflagplanematrix = makeflagplane(ωflagplane1, ωflagplane2, T, segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable)
    updatesurface!(ωflagplanematrix, ωflagplaneobservable)
    planematrix = makeflagplane(𝕍( ê₁), 𝕍( ê₂), M) # the timelike 2-plane spanned by the flagpoles of κ and ω
    # σ, the spacelike 2-plane through O, which is the orthogonal complement of the timelike 2-plane spanned by the flagpoles of κ and ω
    orthogonalplanematrix = makeflagplane(𝕍( ê₃), 𝕍( ê₄), M)
    updatesurface!(planematrix, planeobservable)
    updatesurface!(orthogonalplanematrix, orthogonalplaneobservable)
    hue = Float64(frame) / Float64(frames_number) * 360.0
    planecolor[] = fill(RGBAf(convert_hsvtorgb([hue; 0.5; 0.5])..., 0.5), segments, segments)
    orthogonalplanecolor[] = fill(RGBAf(convert_hsvtorgb([360.0 - hue; 0.5; 0.5])..., 0.5), segments, segments)
    κhead[] = Point3f(project(ℝ⁴(_κv)))
    ωhead[] = Point3f(project(ℝ⁴(_ωv)))
    uhead[] = Point3f(project(u))
    vhead[] = Point3f(project(v))
    phead[] = Point3f(project(p))
    _arcpoints = Point3f[]
    _arccolors = Int[]
    for (i, scale) in enumerate(collect(range(0.0, stop = 1.0, length = segments)))
        vector = normalize(scale * u + (1.0 - scale) * v)
        point = Point3f(project(vector))
        push!(_arcpoints, point)
        push!(_arccolors, i)
    end
    arcpoints[] = _arcpoints
    arccolors[] = _arccolors
    notify(arcpoints)
    notify(arccolors)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end