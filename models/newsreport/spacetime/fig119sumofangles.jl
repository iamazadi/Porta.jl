using FileIO
using GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 60
frames_number = 360
modelname = "fig119sumofangles"
M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
mask = load("data/basemap_mask.png")

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

timesign = -1
T = Float64(timesign)
ο = SpinVector([Complex(1.0); Complex(0.0)], timesign)
ι = SpinVector([Complex(0.0); Complex(1.0)], timesign)
@assert(isapprox(dot(ο, ι), 1.0), "The inner product of spin vectors $ι and $ο is not unity.")
@assert(isapprox(dot(ι, ο), -1.0), "The inner product of spin vectors $ι and $ο is not unity.")

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
ω = SpinVector(generate(), generate(), timesign)
ϵ = 0.01
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
ζ′ = Complex(κ′ + ω′)
τ′ = SpinVector(ζ′, timesign)
@assert(isapprox(dot(κ, ι), vec(κ)[1]), "The first component of the spin vector $κ is not equal to the inner product of $κ and $ι.")
@assert(isapprox(dot(κ, ο), -vec(κ)[2]), "The second component of the spin vector $κ is not equal to minus the inner product of $κ and $ο.")
@assert(isapprox(dot(ω, ι), vec(ω)[1]), "The first component of the spin vector $ω is not equal to the inner product of $ω and $ι.")
@assert(isapprox(dot(ω, ο), -vec(ω)[2]), "The second component of the spin vector $ω is not equal to minus the inner product of $ω and $ο.")
@assert(isapprox(dot(ω, ι), vec(ω)[1]), "The first component of the spin vector $ω is not equal to the inner product of $ω and $ι.")
@assert(isapprox(dot(τ, ι), vec(τ)[1]), "The second component of the spin vector $τ  is not equal to minus the inner product of $τ and $ι.")
@assert(isapprox(dot(τ, ο), -vec(τ)[2]), "The second component of the spin vector $τ is not equal to minus the inner product of $τ and $ο.")

w = (Complex(κ + ω) - Complex(κ)) / (Complex(ω) - Complex(κ))
@assert(imag(w) ≤ 0 || isapprox(imag(w), 0.0), "The flagpoles are not collinear: $(Complex(κ)), $(Complex(ω)), $(Complex(κ + ω))")

center = (Complex(ω) - Complex(κ)) * (w - abs(w)^2) / (2im * imag(w)) + Complex(κ)  # Simplified denominator
radius = abs(Complex(κ) - center)

t = 𝕍( 1.0, 0.0, 0.0, 0.0)
x = 𝕍( 0.0, 1.0, 0.0, 0.0)
y = 𝕍( 0.0, 0.0, 1.0, 0.0)
z = 𝕍( 0.0, 0.0, 0.0, 1.0)
οv = √2 * (t + z)
ιv = √2 * (t - z)

οv = 𝕍( LinearAlgebra.normalize(vec(𝕍( ο))))
ιv = 𝕍( LinearAlgebra.normalize(vec(𝕍( ι))))

κv = 𝕍( κ)
κv′ = 𝕍( κ′)
ωv = 𝕍( ω)
ωv′ = 𝕍( ω′)
τv = 𝕍( τ)
τv′ = 𝕍( τ′)
zero = 𝕍( 0.0, 0.0, 0.0, 0.0)
B = stack([vec(κv), vec(ωv), vec(zero), vec(zero)])
N = LinearAlgebra.nullspace(B)
a = 𝕍( N[begin:end, 1])
b = 𝕍( N[begin:end, 2])

a = 𝕍( LinearAlgebra.normalize(vec(a - κv - ωv)))
b = 𝕍( LinearAlgebra.normalize(vec(b - κv - ωv)))

v₁ = κv.a
v₂ = ωv.a
v₃ = a.a
v₄ = b.a

e₁ = v₁
ê₁ = normalize(e₁)
e₂ = v₂ - dot(ê₁, v₂) * ê₁
ê₂ = normalize(e₂)
e₃ = v₃ - dot(ê₁, v₃) * ê₁ - dot(ê₂, v₃) * ê₂
ê₃ = normalize(e₃)
e₄ = v₄ - dot(ê₁, v₄) * ê₁ - dot(ê₂, v₄) * ê₂ - dot(ê₃, v₄) * ê₃
ê₄ = normalize(e₄)

ê₁ = 𝕍( ê₁)
ê₂ = 𝕍( ê₂)
ê₃ = 𝕍( ê₃)
ê₄ = 𝕍( ê₄)

u = 𝕍( LinearAlgebra.normalize(rand(4)))
v = 𝕍( LinearAlgebra.normalize(rand(4)))
p = 𝕍( LinearAlgebra.normalize(vec(u + v)))

arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
northpole = Observable(Point3f(0.0, 0.0, 1.0))
tail = Observable(Point3f(0.0, 0.0, 0.0))
κtail = Observable(Point3f(0.0, 0.0, 0.0))
ωtail = Observable(Point3f(0.0, 0.0, 0.0))
κhead = Observable(Point3f(vec(project(ℍ(vec(κv))))...))
ωhead = Observable(Point3f(vec(project(ℍ(vec(ωv))))...))
ps = @lift([$κtail, $ωtail])
ns = @lift([$κhead, $ωhead])
colorants = [:red, :green]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

linewidth = 20
collection = collect(range(0.0, stop = 1.0, length = segments))
κlinepoints = []
ωlinepoints = []
κlinecolors = []
ωlinecolors = []
κlines = []
ωlines = []
for (i, scale1) in enumerate(collection)
    _κlinepoints = Observable(Point3f[])
    _ωlinepoints = Observable(Point3f[])
    _κlinecolors = Observable(Int[])
    _ωlinecolors = Observable(Int[])
    for (j, scale2) in enumerate(collection)
        κvector = LinearAlgebra.normalize(vec(scale1 * κv + scale2 * κv′))
        ωvector = LinearAlgebra.normalize(vec(scale1 * ωv + scale2 * ωv′))
        κpoint = Point3f(vec(project(ℍ(κvector)))...)
        ωpoint = Point3f(vec(project(ℍ(ωvector)))...)
        push!(_κlinepoints[], κpoint)
        push!(_ωlinepoints[], ωpoint)
        push!(_κlinecolors[], i + j)
        push!(_ωlinecolors[], i + j)
    end
    push!(κlinepoints, _κlinepoints)
    push!(ωlinepoints, _ωlinepoints)
    push!(κlinecolors, _κlinecolors)
    push!(ωlinecolors, _ωlinecolors)
    κline = lines!(lscene, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :fall)
    ωline = lines!(lscene, ωlinepoints[i], color = ωlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :winter)
    push!(κlines, κline)
    push!(ωlines, ωline)
end

arcpoints = Observable(Point3f[])
arccolors = Observable(Int[])
arc = lines!(lscene, arcpoints, color = arccolors, linewidth = 3linewidth, colorrange = (1, segments), colormap = :prism)

circlepoints = Observable(Point3f[])
circlecolors = Observable(Int[])
circle = lines!(lscene, circlepoints, color = circlecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :Paired_12)

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

planematrix = makeplane(κv, ωv, M)
planecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
planeobservable = buildsurface(lscene, planematrix, planecolor, transparency = true)

orthogonalplanematrix = makeplane(a, b, M)
orthogonalplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
orthogonalplaneobservable = buildsurface(lscene, orthogonalplanematrix, orthogonalplanecolor, transparency = true)

κflagplanematrix = makeflagplane(κv, κv′ - κv, T, segments = segments)
κflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = false)
ωflagplanematrix = makeflagplane(ωv, ωv′ - ωv, T, segments = segments)
ωflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
ωflagplaneobservable = buildsurface(lscene, ωflagplanematrix, ωflagplanecolor, transparency = false)

meshscatter!(lscene, northpole, markersize = 0.05, color = :black)
meshscatter!(lscene, tail, markersize = 0.05, color = :black)
meshscatter!(lscene, κtail, markersize = 0.05, color = colorants[1])
meshscatter!(lscene, ωtail, markersize = 0.05, color = colorants[2])

spherematrix = makesphere(M, T, compressedprojection = true, segments = segments)
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)


animate1(frame::Int) = begin
    κflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(κv′ - κv)))
    ωflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(ωv′ - ωv)))
    global u = LinearAlgebra.normalize(vec((-dot(ê₃, κflagplanedirection) * ê₃ + -dot(ê₄, κflagplanedirection) * ê₄)))
    global v = LinearAlgebra.normalize(vec((-dot(ê₃, ωflagplanedirection) * ê₃ + -dot(ê₄, ωflagplanedirection) * ê₄)))
    p = -𝕍(LinearAlgebra.normalize(u + v))
    global p = dot(ê₃, p) * ê₃ + dot(ê₄, p) * ê₄
    axis = normalize(ℝ³(vec(p)[2:4]))
    progress = Float64(frame / frames_number)
    M = mat4(ℍ(progress * 4π, axis))
    κ_transformed = M * ℍ(vec(κv))
    κ′_transformed = M * ℍ(vec(κv′))
    ω_transformed = M * ℍ(vec(ωv))
    ω′_transformed = M * ℍ(vec(ωv′))
    northpole[] = Point3f(project(M * ℍ(vec(𝕍( SpinVector(Complex(0.0), timesign))))))
    planematrix = makeplane(ê₁, ê₂, M) # the timelike 2-plane spanned by the flagpoles of κ and ω
    orthogonalplanematrix = makeplane(ê₃, ê₄, M) # σ, the spacelike 2-plane through O, which is the orthogonal complement of the timelike 2-plane spanned by the flagpoles of κ and ω
    spherematrix = makesphere(M, T, compressedprojection = true, segments = segments)
    updatesurface!(planematrix, planeobservable)
    updatesurface!(orthogonalplanematrix, orthogonalplaneobservable)
    updatesurface!(spherematrix, sphereobservable)
    hue = Float64(frame) / Float64(frames_number) * 360.0
    planecolor[] = [RGBAf(convert_hsvtorgb([hue; 1.0; 1.0])..., 0.25) for i in 1:segments, j in 1:segments]
    orthogonalplanecolor[] = [RGBAf(convert_hsvtorgb([360.0 - hue; 1.0; 1.0])..., 0.25) for i in 1:segments, j in 1:segments]
    _κ = 𝕍( vec(κ_transformed))
    _κ′ = 𝕍( vec(κ′_transformed))
    _ω = 𝕍( vec(ω_transformed))
    _ω′ = 𝕍( vec(ω′_transformed))
    κflagplanematrix = makeflagplane(𝕍(vec(_κ)), 𝕍(LinearAlgebra.normalize(vec(_κ′ - _κ))), T, segments = segments)
    ωflagplanematrix = makeflagplane(𝕍(vec(_ω)), 𝕍(LinearAlgebra.normalize(vec(_ω′ - _ω))), T, segments = segments)
    updatesurface!(κflagplanematrix, κflagplaneobservable)
    updatesurface!(ωflagplanematrix, ωflagplaneobservable)
    κflagplanecolor[] = [RGBAf(convert_hsvtorgb([277.0; 0.87; 0.94])..., 0.8) for i in 1:segments, j in 1:segments]
    ωflagplanecolor[] = [RGBAf(convert_hsvtorgb([240.0; 1.0; 0.5])..., 0.8) for i in 1:segments, j in 1:segments]
    κhead[] = Point3f(vec(project(ℍ(LinearAlgebra.normalize(vec(κ_transformed - κ′_transformed)))))...)
    ωhead[] = Point3f(vec(project(ℍ(LinearAlgebra.normalize(vec(ω_transformed - ω′_transformed)))))...)
    κtail[] = Point3f(vec(project(κ_transformed))...)
    ωtail[] = Point3f(vec(project(ω_transformed))...)
end


animate(frame::Int) = begin
    animate1(frame)
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    κflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(κv′ - κv)))
    ωflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(ωv′ - ωv)))
    global u = LinearAlgebra.normalize(vec((-dot(ê₃, κflagplanedirection) * ê₃ + -dot(ê₄, κflagplanedirection) * ê₄)))
    global v = LinearAlgebra.normalize(vec((-dot(ê₃, ωflagplanedirection) * ê₃ + -dot(ê₄, ωflagplanedirection) * ê₄)))
    p = -𝕍(LinearAlgebra.normalize(u + v))
    global p = dot(ê₃, p) * ê₃ + dot(ê₄, p) * ê₄
    axis = normalize(ℝ³(vec(p)[2:4]))
    M = mat4(ℍ(progress * 4π, axis))
    _arcpoints = Point3f[]
    _arccolors = Int[]
    for (i, scale) in enumerate(collection)
        vector = M * normalize(ℍ(vec(scale * u + (1.0 - scale) * v)))
        point = Point3f(vec(project(vector))...)
        push!(_arcpoints, point)
        push!(_arccolors, i)
    end
    arcpoints[] = _arcpoints
    arccolors[] = _arccolors
    notify(arcpoints)
    notify(arccolors)
    _circlepoints = Point3f[]
    _circlecolors = Int[]
    for (i, ϕ) in enumerate(collect(range(-4π, stop = 4π, length = segments)))
        κζ = Complex(κ)
        ωζ = Complex(ω)
        ζ = κζ - ωζ
        circlevector = M * ℍ(vec(𝕍(SpinVector(κζ + ϕ * ζ, timesign))))
        circlepoint = Point3f(vec(project(circlevector))...)
        push!(_circlepoints, circlepoint)
        push!(_circlecolors, i)
    end
    circlepoints[] = _circlepoints
    circlecolors[] = _circlecolors
    notify(circlepoints)
    notify(circlecolors)
    # the flag planes
    for (i, scale1) in enumerate(collection)
        _κlinepoints = Point3f[]
        _ωlinepoints = Point3f[]
        _κlinecolors = Int[]
        _ωlinecolors = Int[]
        for (j, scale2) in enumerate(collection)
            κvector = M * normalize(ℍ(vec(scale1 * κv + scale2 * 𝕍(LinearAlgebra.normalize(vec(κv - κv′))))))
            ωvector = M * normalize(ℍ(vec(scale1 * ωv + scale2 * 𝕍(LinearAlgebra.normalize(vec(ωv - ωv′))))))
            κpoint = Point3f(vec(project(κvector))...)
            ωpoint = Point3f(vec(project(ωvector))...)
            push!(_κlinepoints, κpoint)
            push!(_ωlinepoints, ωpoint)
            push!(_κlinecolors, i + j)
            push!(_ωlinecolors, i + j)
        end
        κlinepoints[i][] = _κlinepoints
        ωlinepoints[i][] = _ωlinepoints
        κlinecolors[i][] = _κlinecolors
        ωlinecolors[i][] = _ωlinecolors
        notify(κlinepoints[i])
        notify(ωlinepoints[i])
        notify(κlinecolors[i])
        notify(ωlinecolors[i])
    end
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end