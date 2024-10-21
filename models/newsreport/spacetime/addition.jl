import FileIO
import GLMakie
import LinearAlgebra
import Symbolics
import ModelingToolkit
import NonlinearSolve
using Porta


GLMakie.Quaternion(q::Porta.Quaternion) = GLMakie.Quaternion(vec(q)[2:4]..., vec(q)[1])


function makeplane(u::𝕍, v::𝕍, M::Matrix{Float64})
    lspace = range(-1.0, stop = 1.0, length = segments)
    [project(M * normalize(Quaternion((f * u + s * v).a))) for f in lspace, s in lspace]
end


function makeflagplane(u::𝕍, v::𝕍, M::Matrix{Float64})
    lspace1 = range(-1.0, stop = 1.0, length = segments)
    lspace2 = range(0.0, stop = 1.0, length = segments)
    [project(M * normalize(Quaternion((f * u + s * v).a))) for f in lspace1, s in lspace2]
end


figuresize = (4096, 2160)
# figuresize = (1920, 1080)
segments = 60
frames_number = 1440
modelname = "addition"
indices = Dict()
T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
u = 𝕍(T, X, Y, Z)
q = Quaternion(T, X, Y, Z)
tolerance = 1e-3
@assert(isnull(u, atol = tolerance), "u in not a null vector, $u.")
@assert(isapprox(norm(q), 1, atol = tolerance), "q in not a unit quaternion, $(norm(q)).")
origin = 𝕍(0.0, 0.0, 0.0, 0.0)
tetrad = Tetrad(ℝ⁴(1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, -1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, -1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, -1.0))
gauge1 = 0.0
gauge2 = π / 2
gauge3 = float(π)
gauge4 = 3π / 2
gauge5 = 2π
chart = (-π / 4, π / 4, -π / 4, π / 4)
M = I(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
totalstages = 1

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = Set()
while length(boundary_names) < 15
    push!(boundary_names, rand(countries["name"]))
end
boundary_nodes = Vector{Vector{ℝ³}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            println(name)
            indices[name] = length(boundary_nodes)
        end
    end
end

points = Vector{Quaternion}[]
for i in eachindex(boundary_nodes)
    _points = Quaternion[]
    for node in boundary_nodes[i]
        r, θ, ϕ = convert_to_geographic(node)
        push!(_points, q * Quaternion(exp(ϕ / 4 * K(1) + θ / 2 * K(2))))
    end
    push!(points, _points)
end

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

reference = FileIO.load("data/basemap_color.png")
mask = FileIO.load("data/basemap_mask.png")
basemap1 = Basemap(lscene, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene, q, gauge2, M, chart, segments, mask, transparency = true)
basemap3 = Basemap(lscene, q, gauge3, M, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene, q, 2π, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.25)
    color2 = getcolor(boundary_nodes[i], reference, 0.5)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
end

timesign = -1
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
gauge1 = -imag(dot(κ, ω))
gauge2 = -imag(dot(κ, τ))
gauge3 = float(π)
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


t = 𝕍(1.0, 0.0, 0.0, 0.0)
x = 𝕍(0.0, 1.0, 0.0, 0.0)
y = 𝕍(0.0, 0.0, 1.0, 0.0)
z = 𝕍(0.0, 0.0, 0.0, 1.0)
οv = √2 * (t + z)
ιv = √2 * (t - z)
οv′ = 0.999 * √2 * (t + z)
ιv′ = 0.999 * √2 * (t - z)

κv = 𝕍(κ)
κv′ = 𝕍(κ′)
ωv = 𝕍(ω)
ωv′ = 𝕍(ω′)
τv = 𝕍(τ)
τv′ = 𝕍(τ′)
zero = 𝕍(0.0, 0.0, 0.0, 0.0)
B = stack([vec(κv), vec(ωv), vec(zero), vec(zero)])
N = LinearAlgebra.nullspace(B)
a = 𝕍(N[begin:end, 1])
b = 𝕍(N[begin:end, 2])

a = 𝕍(LinearAlgebra.normalize(vec(a - κv - ωv)))
b = 𝕍(LinearAlgebra.normalize(vec(b - κv - ωv)))

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

ê₁ = 𝕍(ê₁)
ê₂ = 𝕍(ê₂)
ê₃ = 𝕍(ê₃)
ê₄ = 𝕍(ê₄)

u = 𝕍(LinearAlgebra.normalize(rand(4)))
v = 𝕍(LinearAlgebra.normalize(rand(4)))
p = 𝕍(LinearAlgebra.normalize(vec(u + v)))

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
tail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
οtail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
ιtail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
κtail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
ωtail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
τtail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
thead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(t))))...))
xhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(x))))...))
yhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(y))))...))
zhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(z))))...))
οhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(οv))))...))
ιhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(ιv))))...))
κhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(κv))))...))
ωhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(ωv))))...))
τhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(τv))))...))
uhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(u))))...))
vhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(v))))...))
phead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(p))))...))
ps = GLMakie.@lift([$tail, $tail, $tail, $tail, $οtail, $ιtail, $κtail, $ωtail, $τtail, $tail, $tail, $tail])
ns = GLMakie.@lift([$thead, $xhead, $yhead, $zhead, $οhead, $ιhead, $κhead, $ωhead, $τhead, $uhead, $vhead, $phead])
colorants = [:red, :blue, :green, :orange, :black, :silver, :purple, :navyblue, :olive , :purple, :navyblue, :gold]
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

linewidth = 20
collection = collect(range(0.0, stop = 1.0, length = segments))
οlinepoints = []
ιlinepoints = []
κlinepoints = []
ωlinepoints = []
τlinepoints = []
οlinecolors = []
ιlinecolors = []
κlinecolors = []
ωlinecolors = []
τlinecolors = []
οlines = []
ιlines = []
κlines = []
ωlines = []
τlines = []
for (i, scale1) in enumerate(collection)
    _οlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _ιlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _κlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _ωlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _τlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _οlinecolors = GLMakie.Observable(Int[])
    _ιlinecolors = GLMakie.Observable(Int[])
    _κlinecolors = GLMakie.Observable(Int[])
    _ωlinecolors = GLMakie.Observable(Int[])
    _τlinecolors = GLMakie.Observable(Int[])
    for (j, scale2) in enumerate(collection)
        οvector = LinearAlgebra.normalize(vec(scale1 * οv + scale2 * x))
        ιvector = LinearAlgebra.normalize(vec(scale1 * ιv + scale2 * -x))
        κvector = LinearAlgebra.normalize(vec(scale1 * κv + scale2 * κv′))
        ωvector = LinearAlgebra.normalize(vec(scale1 * ωv + scale2 * ωv′))
        τvector = LinearAlgebra.normalize(vec(scale1 * τv + scale2 * τv′))
        οpoint = GLMakie.Point3f(vec(project(Quaternion(οvector)))...)
        ιpoint = GLMakie.Point3f(vec(project(Quaternion(ιvector)))...)
        κpoint = GLMakie.Point3f(vec(project(Quaternion(κvector)))...)
        ωpoint = GLMakie.Point3f(vec(project(Quaternion(ωvector)))...)
        τpoint = GLMakie.Point3f(vec(project(Quaternion(τvector)))...)
        push!(_οlinepoints[], οpoint)
        push!(_ιlinepoints[], ιpoint)
        push!(_κlinepoints[], κpoint)
        push!(_ωlinepoints[], ωpoint)
        push!(_τlinepoints[], τpoint)
        push!(_οlinecolors[], i + j)
        push!(_ιlinecolors[], i + j)
        push!(_κlinecolors[], i + j)
        push!(_ωlinecolors[], i + j)
        push!(_τlinecolors[], i + j)
    end
    push!(οlinepoints, _οlinepoints)
    push!(ιlinepoints, _ιlinepoints)
    push!(κlinepoints, _κlinepoints)
    push!(ωlinepoints, _ωlinepoints)
    push!(τlinepoints, _τlinepoints)
    push!(οlinecolors, _οlinecolors)
    push!(ιlinecolors, _ιlinecolors)
    push!(κlinecolors, _κlinecolors)
    push!(ωlinecolors, _ωlinecolors)
    push!(τlinecolors, _τlinecolors)
    οline = GLMakie.lines!(lscene, οlinepoints[i], color = οlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :spring)
    ιline = GLMakie.lines!(lscene, ιlinepoints[i], color = ιlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :summer)
    κline = GLMakie.lines!(lscene, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :fall)
    ωline = GLMakie.lines!(lscene, ωlinepoints[i], color = ωlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :winter)
    τline = GLMakie.lines!(lscene, τlinepoints[i], color = τlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :rainbow)
    push!(οlines, οline)
    push!(ιlines, ιline)
    push!(κlines, κline)
    push!(ωlines, ωline)
    push!(τlines, τline)
end

arcpoints = GLMakie.Observable(GLMakie.Point3f[])
arccolors = GLMakie.Observable(Int[])
arc = GLMakie.lines!(lscene, arcpoints, color = arccolors, linewidth = 3linewidth, colorrange = (1, segments), colormap = :prism)

circlepoints = GLMakie.Observable(GLMakie.Point3f[])
circlecolors = GLMakie.Observable(Int[])
circle = GLMakie.lines!(lscene, circlepoints, color = circlecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :Paired_12)

titles = ["t", "x", "y", "z", "ο", "ι", "κ", "ω", "κ+ω", "U", "V", "p"]
eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation1 = GLMakie.@lift(Porta.Quaternion(getrotation(ẑ, $rotationaxis)...))
rotation2 = GLMakie.@lift(Porta.Quaternion($rotationangle, $rotationaxis))
rotation = GLMakie.@lift(GLMakie.Quaternion($rotation2 * $rotation1))
GLMakie.text!(lscene,
    GLMakie.@lift(map(x -> GLMakie.Point3f(vec((isnan(x) ? ẑ : x))), [$thead, $xhead, $yhead, $zhead, $οhead + $οtail, $ιhead + $ιtail, $κhead + $κtail, $ωhead + $ωtail, $τhead + $τtail, $uhead, $vhead, $phead])),
    text = titles,
    color = colorants[begin:end],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

planematrix = makeplane(κv, ωv, M)
planecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
planeobservable = buildsurface(lscene, planematrix, planecolor, transparency = true)

orthogonalplanematrix = makeplane(a, b, M)
orthogonalplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
orthogonalplaneobservable = buildsurface(lscene, orthogonalplanematrix, orthogonalplanecolor, transparency = true)

κflagplanematrix = makeflagplane(κv, κv′ - κv, M)
κflagplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
κflagplaneobservable = buildsurface(lscene, κflagplanematrix, κflagplanecolor, transparency = false)
ωflagplanematrix = makeflagplane(ωv, ωv′ - ωv, M)
ωflagplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
ωflagplaneobservable = buildsurface(lscene, ωflagplanematrix, ωflagplanecolor, transparency = false)
τflagplanematrix = makeflagplane(τv, τv′ - τv, M)
τflagplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
τflagplaneobservable = buildsurface(lscene, τflagplanematrix, τflagplanecolor, transparency = false)


updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


updatehopfbundle(M::Matrix{Float64}) = begin
    update!(basemap1, q, gauge1, M)
    update!(basemap2, q, gauge2, M)
    update!(basemap3, q, gauge3, M)
    update!(basemap4, q, 2π, M)
    for i in eachindex(whirls1)
        update!(whirls1[i], points[i], min(gauge1, gauge2), max(gauge1, gauge2), M)
        update!(whirls2[i], points[i], gauge3, 2π, M)
    end
end


animate1(frame::Int) = begin
    κflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(κv′ - κv)))
    ωflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(ωv′ - ωv)))
    global u = LinearAlgebra.normalize(vec((-dot(ê₃, κflagplanedirection) * ê₃ + -dot(ê₄, κflagplanedirection) * ê₄)))
    global v = LinearAlgebra.normalize(vec((-dot(ê₃, ωflagplanedirection) * ê₃ + -dot(ê₄, ωflagplanedirection) * ê₄)))
    p = -𝕍(LinearAlgebra.normalize(u + v))
    global p = dot(ê₃, p) * ê₃ + dot(ê₄, p) * ê₄
    axis = normalize(ℝ³(vec(p)[2:4]))
    progress = Float64(frame / frames_number)
    M = mat4(Quaternion(progress * 4π, axis))
    t_transformed = M * Quaternion(vec(t))
    x_transformed = M * Quaternion(vec(x))
    y_transformed = M * Quaternion(vec(y))
    z_transformed = M * Quaternion(vec(z))
    ο_transformed = M * Quaternion(vec(οv))
    ι_transformed = M * Quaternion(vec(ιv))
    κ_transformed = M * Quaternion(vec(κv))
    κ′_transformed = M * Quaternion(vec(κv′))
    ω_transformed = M * Quaternion(vec(ωv))
    ω′_transformed = M * Quaternion(vec(ωv′))
    τ_transformed = M * Quaternion(vec(τv))
    τ′_transformed = M * Quaternion(vec(τv′))
    u_transformed = M * Quaternion(vec(u))
    v_transformed = M * Quaternion(vec(v))
    p_transformed = M * Quaternion(vec(p))
    updatehopfbundle(M)
    planematrix = makeplane(ê₁, ê₂, M) # the timelike 2-plane spanned by the flagpoles of κ and ω
    orthogonalplanematrix = makeplane(ê₃, ê₄, M) # σ, the spacelike 2-plane through O, which is the orthogonal complement of the timelike 2-plane spanned by the flagpoles of κ and ω
    updatesurface!(planematrix, planeobservable)
    updatesurface!(orthogonalplanematrix, orthogonalplaneobservable)
    hue = Float64(frame) / Float64(frames_number) * 360.0
    planecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([hue; 1.0; 1.0])..., 0.25) for i in 1:segments, j in 1:segments]
    orthogonalplanecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([360.0 - hue; 1.0; 1.0])..., 0.25) for i in 1:segments, j in 1:segments]
    κflagplanematrix = makeflagplane(𝕍(vec(κv)), 𝕍(LinearAlgebra.normalize(vec(κv′ - κv))), M)
    ωflagplanematrix = makeflagplane(𝕍(vec(ωv)), 𝕍(LinearAlgebra.normalize(vec(ωv′ - ωv))), M)
    τflagplanematrix = makeflagplane(𝕍(vec(τv)), 𝕍(LinearAlgebra.normalize(vec(τv′ - τv))), M)
    updatesurface!(κflagplanematrix, κflagplaneobservable)
    updatesurface!(ωflagplanematrix, ωflagplaneobservable)
    updatesurface!(τflagplanematrix, τflagplaneobservable)
    κflagplanecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([277.0; 0.87; 0.94])..., 0.75) for i in 1:segments, j in 1:segments]
    ωflagplanecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([240.0; 1.0; 0.5])..., 0.75) for i in 1:segments, j in 1:segments]
    τflagplanecolor[] = [GLMakie.RGBAf(convert_hsvtorgb([58.0; 0.42; 0.73])..., 0.75) for i in 1:segments, j in 1:segments]
    κhead[] = GLMakie.Point3f(vec(project(Quaternion(LinearAlgebra.normalize(vec(κ′_transformed - κ_transformed)))))...)
    ωhead[] = GLMakie.Point3f(vec(project(Quaternion(LinearAlgebra.normalize(vec(ω′_transformed - ω_transformed)))))...)
    τhead[] = GLMakie.Point3f(vec(project(Quaternion(LinearAlgebra.normalize(vec(τ′_transformed - τ_transformed)))))...)
    κtail[] = GLMakie.Point3f(vec(project(κ_transformed))...)
    ωtail[] = GLMakie.Point3f(vec(project(ω_transformed))...)
    τtail[] = GLMakie.Point3f(vec(project(τ_transformed))...)
    οtail[] = GLMakie.Point3f(vec(project(κ_transformed))...)
    ιtail[] = GLMakie.Point3f(vec(project(κ_transformed))...)
    οhead[] = GLMakie.Point3f(vec(project(Quaternion(LinearAlgebra.normalize(vec(ο_transformed)))))...) * 0.25
    ιhead[] = GLMakie.Point3f(vec(project(Quaternion(LinearAlgebra.normalize(vec(ι_transformed)))))...) * 0.25
    thead[] = GLMakie.Point3f(vec(project(t_transformed))...) * 0.5
    xhead[] = GLMakie.Point3f(vec(project(x_transformed))...) * 0.5
    yhead[] = GLMakie.Point3f(vec(project(y_transformed))...) * 0.5
    zhead[] = GLMakie.Point3f(vec(project(z_transformed))...) * 0.5
    uhead[] = GLMakie.Point3f(vec(project(u_transformed))...)
    vhead[] = GLMakie.Point3f(vec(project(v_transformed))...)
    phead[] = GLMakie.Point3f(vec(project(p_transformed))...)
    point = project(κ_transformed) + project(ω_transformed) + project(τ_transformed)
    point = isnan(vec(point)[1]) ? ẑ : normalize(point)
    global lookat = point
    global eyeposition = normalize(point) * float(π)
end


animate(frame::Int) = begin
    animate1(frame)
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    κflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(κv′ - κv)))
    ωflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(ωv′ - ωv)))
    global u = LinearAlgebra.normalize(vec((-dot(ê₃, κflagplanedirection) * ê₃ + -dot(ê₄, κflagplanedirection) * ê₄)))
    global v = LinearAlgebra.normalize(vec((-dot(ê₃, ωflagplanedirection) * ê₃ + -dot(ê₄, ωflagplanedirection) * ê₄)))
    p = -𝕍(LinearAlgebra.normalize(u + v))
    global p = dot(ê₃, p) * ê₃ + dot(ê₄, p) * ê₄
    axis = normalize(ℝ³(vec(p)[2:4]))
    M = mat4(Quaternion(progress * 4π, axis))
    _arcpoints = GLMakie.Point3f[]
    _arccolors = Int[]
    for (i, scale) in enumerate(collection)
        vector = M * normalize(Quaternion(vec(scale * u + (1.0 - scale) * v)))
        point = GLMakie.Point3f(vec(project(vector))...)
        push!(_arcpoints, point)
        push!(_arccolors, i)
    end
    arcpoints[] = _arcpoints
    arccolors[] = _arccolors
    GLMakie.notify(arcpoints)
    GLMakie.notify(arccolors)
    _circlepoints = GLMakie.Point3f[]
    _circlecolors = Int[]
    for (i, ϕ) in enumerate(collect(range(-4π, stop = 4π, length = segments)))
        κζ = Complex(κ)
        ωζ = Complex(ω)
        ζ = κζ - ωζ
        circlevector = M * Quaternion(vec(𝕍(SpinVector(κζ + ϕ * ζ, timesign))))
        circlepoint = GLMakie.Point3f(vec(project(circlevector))...)
        push!(_circlepoints, circlepoint)
        push!(_circlecolors, i)
    end
    circlepoints[] = _circlepoints
    circlecolors[] = _circlecolors
    GLMakie.notify(circlepoints)
    GLMakie.notify(circlecolors)
    # the flag planes
    for (i, scale1) in enumerate(collection)
        _οlinepoints = GLMakie.Point3f[]
        _ιlinepoints = GLMakie.Point3f[]
        _κlinepoints = GLMakie.Point3f[]
        _ωlinepoints = GLMakie.Point3f[]
        _τlinepoints = GLMakie.Point3f[]
        _οlinecolors = Int[]
        _ιlinecolors = Int[]
        _κlinecolors = Int[]
        _ωlinecolors = Int[]
        _τlinecolors = Int[]
        for (j, scale2) in enumerate(collection)
            οvector = M * normalize(Quaternion(vec(scale1 * κv + scale2 * x)))
            ιvector = M * normalize(Quaternion(vec(scale1 * κv + scale2 * -x)))
            κvector = M * normalize(Quaternion(vec(scale1 * κv + scale2 * 𝕍(LinearAlgebra.normalize(vec(κv′ - κv))))))
            ωvector = M * normalize(Quaternion(vec(scale1 * ωv + scale2 * 𝕍(LinearAlgebra.normalize(vec(ωv′ - ωv))))))
            τvector = M * normalize(Quaternion(vec(scale1 * τv + scale2 * 𝕍(LinearAlgebra.normalize(vec(τv′ - τv))))))
            οpoint = GLMakie.Point3f(vec(project(οvector))...)
            ιpoint = GLMakie.Point3f(vec(project(ιvector))...)
            κpoint = GLMakie.Point3f(vec(project(κvector))...)
            ωpoint = GLMakie.Point3f(vec(project(ωvector))...)
            τpoint = GLMakie.Point3f(vec(project(τvector))...)
            push!(_οlinepoints, οpoint)
            push!(_ιlinepoints, ιpoint)
            push!(_κlinepoints, κpoint)
            push!(_ωlinepoints, ωpoint)
            push!(_τlinepoints, τpoint)
            push!(_οlinecolors, i + j)
            push!(_ιlinecolors, i + j)
            push!(_κlinecolors, i + j)
            push!(_ωlinecolors, i + j)
            push!(_τlinecolors, i + j)
        end
        οlinepoints[i][] = _οlinepoints
        ιlinepoints[i][] = _ιlinepoints
        κlinepoints[i][] = _κlinepoints
        ωlinepoints[i][] = _ωlinepoints
        τlinepoints[i][] = _τlinepoints
        οlinecolors[i][] = _οlinecolors
        ιlinecolors[i][] = _ιlinecolors
        κlinecolors[i][] = _κlinecolors
        ωlinecolors[i][] = _ωlinecolors
        τlinecolors[i][] = _τlinecolors
        GLMakie.notify(οlinepoints[i])
        GLMakie.notify(ιlinepoints[i])
        GLMakie.notify(κlinepoints[i])
        GLMakie.notify(ωlinepoints[i])
        GLMakie.notify(τlinepoints[i])
        GLMakie.notify(οlinecolors[i])
        GLMakie.notify(ιlinecolors[i])
        GLMakie.notify(κlinecolors[i])
        GLMakie.notify(ωlinecolors[i])
        GLMakie.notify(τlinecolors[i])
    end
    updatecamera()
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)