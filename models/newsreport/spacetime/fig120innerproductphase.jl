using FileIO
using GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 60
frames_number = 360
modelname = "fig120innerproductphase"
M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

timesign = -1
ο = SpinVector([Complex(1.0); Complex(0.0)], timesign)
ι = SpinVector([Complex(0.0); Complex(1.0)], timesign)
@assert(isapprox(dot(ο, ι), 1.0), "The inner product of spin vectors $ι and $ο is not unity.")
@assert(isapprox(dot(ι, ο), -1.0), "The inner product of spin vectors $ι and $ο is not unity.")

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
ϵ = 0.01
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

t = 𝕍(1.0, 0.0, 0.0, 0.0)
x = 𝕍(0.0, 1.0, 0.0, 0.0)
y = 𝕍(0.0, 0.0, 1.0, 0.0)
z = 𝕍(0.0, 0.0, 0.0, 1.0)
ο = √2 * (t + z)
ι = √2 * (t - z)

κ = 𝕍(κ)
κ′ = 𝕍(κ′)
ω = 𝕍(ω)
ω′ = 𝕍(ω′)
zero = 𝕍(0.0, 0.0, 0.0, 0.0)
B = stack([vec(κ), vec(ω), vec(zero), vec(zero)])
N = LinearAlgebra.nullspace(B)
a = 𝕍(N[begin:end, 1])
b = 𝕍(N[begin:end, 2])
a = 𝕍(LinearAlgebra.normalize(vec(a - κ - ω)))
b = 𝕍(LinearAlgebra.normalize(vec(b - κ - ω)))

v₁ = κ.a
v₂ = ω.a
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

ê₁ = 𝕍(ê₁)
ê₂ = 𝕍(ê₂)
ê₃ = 𝕍(ê₃)
ê₄ = 𝕍(ê₄)

u = 𝕍(LinearAlgebra.normalize(rand(4)))
v = 𝕍(LinearAlgebra.normalize(rand(4)))
p = 𝕍(LinearAlgebra.normalize(vec(u + v)))

arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
tail = Observable(Point3f(0.0, 0.0, 0.0))
thead = Observable(Point3f(vec(project(ℍ(vec(t))))...))
xhead = Observable(Point3f(vec(project(ℍ(vec(x))))...))
yhead = Observable(Point3f(vec(project(ℍ(vec(y))))...))
zhead = Observable(Point3f(vec(project(ℍ(vec(z))))...))
οhead = Observable(Point3f(vec(project(ℍ(vec(ο))))...))
ιhead = Observable(Point3f(vec(project(ℍ(vec(ι))))...))
κhead = Observable(Point3f(vec(project(ℍ(vec(κ))))...))
ωhead = Observable(Point3f(vec(project(ℍ(vec(ω))))...))
uhead = Observable(Point3f(vec(project(ℍ(vec(u))))...))
vhead = Observable(Point3f(vec(project(ℍ(vec(v))))...))
phead = Observable(Point3f(vec(project(ℍ(vec(p))))...))
ps = @lift([$tail, $tail, $tail, $tail, $tail])
ns = @lift([$κhead, $ωhead, $uhead, $vhead, $phead])
colorants = [:red, :green, :blue, :orange, :black]
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
        κvector = LinearAlgebra.normalize(vec(scale1 * κ + scale2 * κ′))
        ωvector = LinearAlgebra.normalize(vec(scale1 * ω + scale2 * ω′))
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
arc = lines!(lscene, arcpoints, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism)

titles = ["L", "M", "U", "V", "p"]
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

planematrix = makeplane(κ, ω, M)
planecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
planeobservable = buildsurface(lscene, planematrix, planecolor, transparency = true)

orthogonalplanematrix = makeplane(a, b, M)
orthogonalplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
orthogonalplaneobservable = buildsurface(lscene, orthogonalplanematrix, orthogonalplanecolor, transparency = true)

meshscatter!(lscene, tail, markersize = 0.05, color = :black)


animate(frame::Int) = begin
    progress = frame / frames_number
    println("Frame: $frame, Progress: $progress")
    κflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(κ′ - κ)))
    ωflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(ω′ - ω)))
    global u = LinearAlgebra.normalize(vec((-dot(ê₃, κflagplanedirection) * ê₃ + -dot(ê₄, κflagplanedirection) * ê₄)))
    global v = LinearAlgebra.normalize(vec((-dot(ê₃, ωflagplanedirection) * ê₃ + -dot(ê₄, ωflagplanedirection) * ê₄)))
    p = 𝕍(LinearAlgebra.normalize(u + v))
    global p = -dot(ê₃, p) * ê₃ + -dot(ê₄, p) * ê₄
    axis = normalize(ℝ³(vec(p)[2:4]))
    M = mat4(ℍ(progress * 4π, axis))
    κ_transformed = M * ℍ(vec(κ))
    ω_transformed = M * ℍ(vec(ω))
    u_transformed = M * ℍ(vec(u))
    v_transformed = M * ℍ(vec(v))
    p_transformed = M * ℍ(vec(p))
    point = project(p_transformed)
    point = isnan(vec(point)[1]) ? ẑ : normalize(point)
    global lookat = point
    point = cross(project(u_transformed), project(v_transformed)) + cross(project(κ_transformed), project(ω_transformed))
    point = isnan(vec(point)[1]) ? ẑ : normalize(point)
    global eyeposition = normalize(point) * float(π)

    # the timelike 2-plane spanned by the flagpoles of κ and ω
    planematrix = makeplane(ê₁, ê₂, M)
    # σ, the spacelike 2-plane through O,
    # which is the orthogonal complement of the timelike 2-plane spanned by the flagpoles of κ and ω
    orthogonalplanematrix = makeplane(ê₃, ê₄, M)
    updatesurface!(planematrix, planeobservable)
    updatesurface!(orthogonalplanematrix, orthogonalplaneobservable)
    hue = Float64(frame) / Float64(frames_number) * 360.0
    planecolor[] = fill(RGBAf(convert_hsvtorgb([hue; 1.0; 1.0])..., 0.5), segments, segments)
    orthogonalplanecolor[] = fill(RGBAf(convert_hsvtorgb([360.0 - hue; 1.0; 1.0])..., 0.5), segments, segments)

    κhead[] = Point3f(vec(project(κ_transformed))...)
    ωhead[] = Point3f(vec(project(ω_transformed))...)
    uhead[] = Point3f(vec(project(u_transformed))...)
    vhead[] = Point3f(vec(project(v_transformed))...)
    phead[] = Point3f(vec(project(p_transformed))...)

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

    # the flag planes
    for (i, scale1) in enumerate(collection)
        _κlinepoints = Point3f[]
        _ωlinepoints = Point3f[]
        _κlinecolors = Int[]
        _ωlinecolors = Int[]
        for (j, scale2) in enumerate(collection)
            κvector = M * normalize(ℍ(vec(scale1 * κ + scale2 * 𝕍(LinearAlgebra.normalize(vec(κ′ - κ))))))
            ωvector = M * normalize(ℍ(vec(scale1 * ω + scale2 * 𝕍(LinearAlgebra.normalize(vec(ω′ - ω))))))
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