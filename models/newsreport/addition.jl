import FileIO
import GLMakie
import LinearAlgebra
using Porta


GLMakie.Quaternion(q::Porta.Quaternion) = GLMakie.Quaternion(vec(q)[2:4]..., vec(q)[1])


function makeplane(u::𝕍, v::𝕍, M::Matrix{Float64})
    lspace = range(-1.0, stop = 1.0, length = segments)
    [project(M * normalize(Quaternion((f * u + s * v).a))) for f in lspace, s in lspace]
end


figuresize = (4096, 2160)
# figuresize = (1920, 1080)
segments = 30
frames_number = 1440
modelname = "addition1"
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
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0))
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
totalstages = 1

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = Set()
while length(boundary_names) < 10
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
basemap4 = Basemap(lscene, q, gauge4, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.1)
    color2 = getcolor(boundary_nodes[i], reference, 0.2)
    color3 = getcolor(boundary_nodes[i], reference, 0.3)
    color4 = getcolor(boundary_nodes[i], reference, 0.4)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end

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

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
tail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
thead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(t))))...))
xhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(x))))...))
yhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(y))))...))
zhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(z))))...))
οhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(ο))))...))
ιhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(ι))))...))
κhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(κ))))...))
ωhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(ω))))...))
uhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(u))))...))
vhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(v))))...))
phead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(p))))...))
ps = GLMakie.@lift([$tail, $tail, $tail, $tail, $tail, $tail, $tail, $tail, $tail, $tail, $tail])
ns = GLMakie.@lift([$thead, $xhead, $yhead, $zhead, $οhead, $ιhead, $κhead, $ωhead, $uhead, $vhead, $phead])
colorants = [:red, :blue, :green, :orange, :black, :silver, :purple, :navyblue, :purple, :navyblue, :gold]
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
οlinecolors = []
ιlinecolors = []
κlinecolors = []
ωlinecolors = []
οlines = []
ιlines = []
κlines = []
ωlines = []
for (i, scale1) in enumerate(collection)
    _οlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _ιlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _κlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _ωlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _οlinecolors = GLMakie.Observable(Int[])
    _ιlinecolors = GLMakie.Observable(Int[])
    _κlinecolors = GLMakie.Observable(Int[])
    _ωlinecolors = GLMakie.Observable(Int[])
    for (j, scale2) in enumerate(collection)
        οvector = LinearAlgebra.normalize(vec(scale1 * ο + scale2 * x))
        ιvector = LinearAlgebra.normalize(vec(scale1 * ι + scale2 * -x))
        κvector = LinearAlgebra.normalize(vec(scale1 * κ + scale2 * κ′))
        ωvector = LinearAlgebra.normalize(vec(scale1 * ω + scale2 * ω′))
        οpoint = GLMakie.Point3f(vec(project(Quaternion(οvector)))...)
        ιpoint = GLMakie.Point3f(vec(project(Quaternion(ιvector)))...)
        κpoint = GLMakie.Point3f(vec(project(Quaternion(κvector)))...)
        ωpoint = GLMakie.Point3f(vec(project(Quaternion(ωvector)))...)
        push!(_οlinepoints[], οpoint)
        push!(_ιlinepoints[], ιpoint)
        push!(_κlinepoints[], κpoint)
        push!(_ωlinepoints[], ωpoint)
        push!(_οlinecolors[], i + j)
        push!(_ιlinecolors[], i + j)
        push!(_κlinecolors[], i + j)
        push!(_ωlinecolors[], i + j)
    end
    push!(οlinepoints, _οlinepoints)
    push!(ιlinepoints, _ιlinepoints)
    push!(κlinepoints, _κlinepoints)
    push!(ωlinepoints, _ωlinepoints)
    push!(οlinecolors, _οlinecolors)
    push!(ιlinecolors, _ιlinecolors)
    push!(κlinecolors, _κlinecolors)
    push!(ωlinecolors, _ωlinecolors)
    οline = GLMakie.lines!(lscene, οlinepoints[i], color = οlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :spring)
    ιline = GLMakie.lines!(lscene, ιlinepoints[i], color = ιlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :summer)
    κline = GLMakie.lines!(lscene, κlinepoints[i], color = κlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :fall)
    ωline = GLMakie.lines!(lscene, ωlinepoints[i], color = ωlinecolors[i], linewidth = linewidth, colorrange = (1, 2segments), colormap = :winter)
    push!(οlines, οline)
    push!(ιlines, ιline)
    push!(κlines, κline)
    push!(ωlines, ωline)
end

arcpoints = GLMakie.Observable(GLMakie.Point3f[])
arccolors = GLMakie.Observable(Int[])
arc = GLMakie.lines!(lscene, arcpoints, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism)

titles = ["t", "x", "y", "z", "ο", "ι", "κ", "ω", "U", "V", "p"]
eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation1 = GLMakie.@lift(Porta.Quaternion(getrotation(ẑ, $rotationaxis)...))
rotation2 = GLMakie.@lift(Porta.Quaternion($rotationangle, $rotationaxis))
rotation = GLMakie.@lift(GLMakie.Quaternion($rotation2 * $rotation1))
GLMakie.text!(lscene,
    GLMakie.@lift(map(x -> GLMakie.Point3f(vec((isnan(x) ? ẑ : x))), [$thead, $xhead, $yhead, $zhead, $οhead, $ιhead, $κhead, $ωhead, $uhead, $vhead, $phead])),
    text = titles,
    color = colorants[begin:end],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

planematrix = makeplane(κ, ω, M)
planecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
planeobservable = buildsurface(lscene, planematrix, planecolor, transparency = true)

orthogonalplanematrix = makeplane(a, b, M)
orthogonalplanecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.5, 0.5, 0.5, 0.5), segments, segments))
orthogonalplaneobservable = buildsurface(lscene, orthogonalplanematrix, orthogonalplanecolor, transparency = true)


updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


animate(frame::Int) = begin
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    κflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(κ′ - κ)))
    ωflagplanedirection = 𝕍(LinearAlgebra.normalize(vec(ω′ - ω)))
    global u = LinearAlgebra.normalize(vec((-dot(ê₃, κflagplanedirection) * ê₃ + -dot(ê₄, κflagplanedirection) * ê₄)))
    global v = LinearAlgebra.normalize(vec((-dot(ê₃, ωflagplanedirection) * ê₃ + -dot(ê₄, ωflagplanedirection) * ê₄)))
    _p = 𝕍(SpinVector(κ) + SpinVector(ω))
    _p = dot(ê₁, _p) * ê₁ + dot(ê₂, _p) * ê₂
    p = 𝕍(LinearAlgebra.normalize(u + v))
    global p = -dot(ê₃, p) * ê₃ + -dot(ê₄, p) * ê₄
    axis = normalize(ℝ³(vec(_p)[2:4]))
    M = mat4(Quaternion(progress * 4π, axis))
    t_transformed = normalize(M * Quaternion(vec(t)))
    x_transformed = normalize(M * Quaternion(vec(x)))
    y_transformed = normalize(M * Quaternion(vec(y)))
    z_transformed = normalize(M * Quaternion(vec(z)))
    ο_transformed = normalize(M * Quaternion(vec(ο)))
    ι_transformed = normalize(M * Quaternion(vec(ι)))
    κ_transformed = normalize(M * Quaternion(vec(κ)))
    ω_transformed = normalize(M * Quaternion(vec(ω)))
    u_transformed = normalize(M * Quaternion(vec(u)))
    v_transformed = normalize(M * Quaternion(vec(v)))
    p_transformed = normalize(M * Quaternion(vec(p)))
    _p_transformed = M * Quaternion(vec(_p))

    update!(basemap1, q, gauge1, M)
    update!(basemap2, q, gauge2, M)
    update!(basemap3, q, gauge3, M)
    update!(basemap4, q, gauge4, M)
    for i in eachindex(whirls1)
        update!(whirls1[i], points[i], gauge1, gauge2, M)
        update!(whirls2[i], points[i], gauge2, gauge3, M)
        update!(whirls3[i], points[i], gauge3, gauge4, M)
        update!(whirls4[i], points[i], gauge4, gauge5, M)
    end

    # the timelike 2-plane spanned by the flagpoles of κ and ω
    planematrix = makeplane(ê₁, ê₂, M)
    # σ, the spacelike 2-plane through O,
    # which is the orthogonal complement of the timelike 2-plane spanned by the flagpoles of κ and ω
    orthogonalplanematrix = makeplane(ê₃, ê₄, M)
    updatesurface!(planematrix, planeobservable)
    updatesurface!(orthogonalplanematrix, orthogonalplaneobservable)
    hue = Float64(frame) / Float64(frames_number) * 360.0
    planecolor[] = fill(GLMakie.RGBAf(convert_hsvtorgb([0.9 * hue + 0.1 * rand() - 0.1 * rand(); 1.0; 1.0])..., 0.4), segments, segments)
    orthogonalplanecolor[] = fill(GLMakie.RGBAf(convert_hsvtorgb([360.0 - (0.9 * hue + 0.1 * rand() - 0.1 * rand()); 1.0; 1.0])..., 0.4), segments, segments)

    thead[] = GLMakie.Point3f(vec(project(t_transformed))...)
    xhead[] = GLMakie.Point3f(vec(project(x_transformed))...)
    yhead[] = GLMakie.Point3f(vec(project(y_transformed))...)
    zhead[] = GLMakie.Point3f(vec(project(z_transformed))...)
    οhead[] = GLMakie.Point3f(vec(project(ο_transformed))...)
    ιhead[] = GLMakie.Point3f(vec(project(ι_transformed))...)
    κhead[] = GLMakie.Point3f(vec(project(κ_transformed))...)
    ωhead[] = GLMakie.Point3f(vec(project(ω_transformed))...)
    uhead[] = GLMakie.Point3f(vec(project(u_transformed))...)
    vhead[] = GLMakie.Point3f(vec(project(v_transformed))...)
    phead[] = GLMakie.Point3f(vec(project(p_transformed))...)

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

    # the flag planes
    for (i, scale1) in enumerate(collection)
        _οlinepoints = GLMakie.Point3f[]
        _ιlinepoints = GLMakie.Point3f[]
        _κlinepoints = GLMakie.Point3f[]
        _ωlinepoints = GLMakie.Point3f[]
        _οlinecolors = Int[]
        _ιlinecolors = Int[]
        _κlinecolors = Int[]
        _ωlinecolors = Int[]
        for (j, scale2) in enumerate(collection)
            οvector = M * normalize(Quaternion(vec(scale1 * ο + scale2 * x)))
            ιvector = M * normalize(Quaternion(vec(scale1 * ι + scale2 * -x)))
            κvector = M * normalize(Quaternion(vec(scale1 * κ + scale2 * 𝕍(LinearAlgebra.normalize(vec(κ′ - κ))))))
            ωvector = M * normalize(Quaternion(vec(scale1 * ω + scale2 * 𝕍(LinearAlgebra.normalize(vec(ω′ - ω))))))
            οpoint = GLMakie.Point3f(vec(project(οvector))...)
            ιpoint = GLMakie.Point3f(vec(project(ιvector))...)
            κpoint = GLMakie.Point3f(vec(project(κvector))...)
            ωpoint = GLMakie.Point3f(vec(project(ωvector))...)
            push!(_οlinepoints, οpoint)
            push!(_ιlinepoints, ιpoint)
            push!(_κlinepoints, κpoint)
            push!(_ωlinepoints, ωpoint)
            push!(_οlinecolors, i + j)
            push!(_ιlinecolors, i + j)
            push!(_κlinecolors, i + j)
            push!(_ωlinecolors, i + j)
        end
        οlinepoints[i][] = _οlinepoints
        ιlinepoints[i][] = _ιlinepoints
        κlinepoints[i][] = _κlinepoints
        ωlinepoints[i][] = _ωlinepoints
        οlinecolors[i][] = _οlinecolors
        ιlinecolors[i][] = _ιlinecolors
        κlinecolors[i][] = _κlinecolors
        ωlinecolors[i][] = _ωlinecolors
        GLMakie.notify(οlinepoints[i])
        GLMakie.notify(ιlinepoints[i])
        GLMakie.notify(κlinepoints[i])
        GLMakie.notify(ωlinepoints[i])
        GLMakie.notify(οlinecolors[i])
        GLMakie.notify(ιlinecolors[i])
        GLMakie.notify(κlinecolors[i])
        GLMakie.notify(ωlinecolors[i])
    end

    global lookat = project(_p_transformed)
    updatecamera()
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end