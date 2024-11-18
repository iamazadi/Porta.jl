using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig1512cotangentbundle"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
sphereradius = 1.0
mask = load("data/basemap_mask.png")
reference = load("data/basemap_color.png")
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set()
boundary_nodes = Vector{Vector{ℝ³}}()
points = Vector{Vector{ℍ}}()
indices = Dict()
T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
u = 𝕍(T, X, Y, Z)
q = ℍ(T, X, Y, Z)
tolerance = 1e-3
@assert(isnull(u, atol = tolerance), "u in not a null vector, $u.")
@assert(isapprox(norm(q), 1, atol = tolerance), "q in not a unit quaternion, $(norm(q)).")
ϵ = 0.1
timesign = 1
T = float(timesign)
gauge1 = 0.0
gauge2 = π / 2
gauge3 = float(π)
gauge4 = 3π / 2
gauge5 = 2π
latitudescale = 1 / 2
longitudescale = 1 / 4
chart = (-π * latitudescale / 2, π * latitudescale / 2, -π * longitudescale, π * longitudescale)
M = Identity(4)
markersize = 0.05
linewidth = 20
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
arrowscale = 0.5
fontsize = 0.25
zero = Point3f(0.0, 0.0, 0.0)
lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
names1 = ["q₁", "q₂", "q₃", "q₄", "q₅", "q₆"]
names2 = ["q"]
colorants1 = [:black for _ in eachindex(names1)]
colorants2 = [:black for _ in eachindex(names2)]
colormaps1 = [:rainbow for _ in eachindex(names1)]
colormaps2 = [:rainbow for _ in eachindex(names2)]
number1 = length(names1) # the number of tangent bundles
number2 = length(names2) # the number of tangent bundles
tangentbundles1 = TangentBundle[]
tangentbundles2 = TangentBundle[]
pathsegments = frames_number

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = LScene(fig[1, 2], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
while length(boundary_names) < 10
    push!(boundary_names, rand(countries["name"]))
end
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            println(name)
            indices[name] = length(boundary_nodes)
        end
    end
end
for i in eachindex(boundary_nodes)
    _points = Vector{ℍ}()
    for node in boundary_nodes[i]
        r, θ, ϕ = convert_to_geographic(node)
        push!(_points, q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2))))
    end
    push!(points, _points)
end
basemap1 = Basemap(lscene1, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene1, q, gauge2, M, chart, segments, mask, transparency = true)
basemap3 = Basemap(lscene1, q, gauge3, M, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene1, q, gauge4, M, chart, segments, mask, transparency = true)
basemap = Basemap(lscene2, q, gauge1, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.1)
    color2 = getcolor(boundary_nodes[i], reference, 0.2)
    color3 = getcolor(boundary_nodes[i], reference, 0.3)
    color4 = getcolor(boundary_nodes[i], reference, 0.4)
    whirl1 = Whirl(lscene1, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene1, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene1, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene1, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end

for i in 1:number1
    transparency = i == 1 ? false : true
    tangentbundle1 = TangentBundle(lscene1, names1[i], segments = segments, pathsegments = pathsegments, transparency = transparency,
        markersize = markersize, linewidth = linewidth, color = colorants1[i], colormap = colormaps1[i], arrowsize = arrowsize,
        arrowlinewidth = arrowlinewidth, fontsize = fontsize)
    push!(tangentbundles1, tangentbundle1)
end
for i in 1:number2
    transparency = i == 1 ? false : true
    tangentbundle2 = TangentBundle(lscene2, names2[i], segments = segments, pathsegments = pathsegments, transparency = transparency,
        markersize = markersize, linewidth = linewidth, color = colorants2[i], colormap = colormaps2[i], arrowsize = arrowsize,
        arrowlinewidth = arrowlinewidth, fontsize = fontsize)
    push!(tangentbundles2, tangentbundle2)
end

vobservable = Observable(Point3f(x̂))
uobservable = Observable(Point3f(ŷ))
zobservable = Observable(Point3f(ẑ))
aobservable = Observable("0.000 𝑖")
head = Observable(Point3f(x̂))

v2observable = Observable(Point3f(x̂))
v3observable = Observable(Point3f(x̂))
v4observable = Observable(Point3f(x̂))
u2observable = Observable(Point3f(ŷ))
u3observable = Observable(Point3f(ŷ))
u4observable = Observable(Point3f(ŷ))
z2observable = Observable(Point3f(ẑ))
z3observable = Observable(Point3f(ẑ))
z4observable = Observable(Point3f(ẑ))
a2observable = Observable("0.000 𝑖")
a3observable = Observable("0.000 𝑖")
a4observable = Observable("0.000 𝑖")

ps = @lift([$zobservable, $zobservable, $(tangentbundles2[1].tangenttail)])
ns = @lift([$uobservable, $vobservable, $head])
colorants = [:red, :green, :blue]
arrows!(lscene2,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin, transparency = false
)

ps234 = @lift([$z2observable, $z2observable, $z3observable, $z3observable, $z4observable, $z4observable])
ns234 = @lift([$u2observable, $v2observable, $u3observable, $v3observable, $u4observable, $v4observable])
arrows!(lscene2,
    ps234, ns234, fxaa = true, # turn on anti-aliasing
    color = [colorants[1:2]..., colorants[1:2]..., colorants[1:2]...],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin, transparency = true
)

znobservables = Observable(Point3f[])
vnobservables = Observable(Point3f[])
unobservables = Observable(Point3f[])
N = 30
for i in 1:N
    push!(znobservables[], Point3f(ẑ))
    push!(vnobservables[], Point3f(ẑ))
    push!(unobservables[], Point3f(ẑ))
end
psn = znobservables
nsvn = vnobservables
nsun = unobservables
arrows!(lscene2,
    psn, nsvn, fxaa = true, # turn on anti-aliasing
    color = [colorants[2] for _ in 1:N],
    linewidth = arrowlinewidth * arrowscale, arrowsize = arrowsize .* arrowscale,
    align = :origin, transparency = true
)
arrows!(lscene2,
    psn, nsun, fxaa = true, # turn on anti-aliasing
    color = [colorants[1] for _ in 1:N],
    linewidth = arrowlinewidth * arrowscale, arrowsize = arrowsize .* arrowscale,
    align = :origin, transparency = true
)

titles = @lift(["u", "v", $aobservable, "a"])
rotation = gettextrotation(lscene2)

text!(lscene2,
    @lift([$zobservable + $uobservable, $zobservable + $vobservable,
        $zobservable + Point3f(normalize(ℝ³($uobservable + $vobservable))),
        $(tangentbundles2[1].tangenttail) + $head]),
    text = titles,
    color = [colorants..., :blue],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data, transparency = false
)
titles234 = @lift([$a2observable, $a3observable, $a4observable])
text!(lscene2,
    @lift([$z2observable + Point3f(normalize(ℝ³($u2observable + $v2observable))),
        $z3observable + Point3f(normalize(ℝ³($u3observable + $v3observable))),
        $z4observable + Point3f(normalize(ℝ³($u4observable + $v4observable)))]),
    text = titles234,
    color = [:blue, :blue, :blue],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data, transparency = true
)

arcpoints = Observable(Point3f[])
_arcpoints = Observable(Point3f[])
arccolors = collect(1:segments)
lines!(lscene2, arcpoints, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism)
lines!(lscene2, _arcpoints, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism)

arcpoints2 = Observable(Point3f[])
arcpoints3 = Observable(Point3f[])
arcpoints4 = Observable(Point3f[])
lines!(lscene2, arcpoints2, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism, transparency = true)
lines!(lscene2, arcpoints3, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism, transparency = true)
lines!(lscene2, arcpoints4, color = arccolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = :prism, transparency = true)

sectionalpath = Observable(Point3f[])
sectionalpathcolors = collect(1:pathsegments)
lines!(lscene2, sectionalpath, color = sectionalpathcolors, linewidth = linewidth / 2, colorrange = (1, pathsegments), colormap = :lightrainbow)


getconnection(q::ℍ) = begin
    x₁, x₂, x₃, x₄ = vec(q)
    z₀ = x₁ + im * x₂
    z₁ = x₃ + im * x₄
    @assert(isapprox(abs(z₀)^2 + abs(z₁)^2, 1), "The point $_q is not in S³, in other words: |z₀|² + |z₁|² ≠ 1.")
    # the infinitestimal action of U(1) on S³
    v = ℝ⁴(vec(ℍ([im * z₀; im * z₁])))
    # z ∈ ℂ²
    z = ℝ⁴(x₁, x₂, x₃, x₄)
    # u ∈ TS³
    u = ℝ⁴(-x₂, x₁, -x₄, x₃)
    @assert(isapprox(dot(z, u), 0), "The vector $u is not tangent to S³ at point $z. in other words: <z, u> ≠ 0.")
    # a unique connection one-form on S³ with values in ℝ𝑖 such that ker a = v⟂
    a = dot(v, u) * im
    u, v, a
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    ψ = progress * π
    θ, ϕ = cos(2ψ) * π / 2, sin(4ψ) * π
    _q = q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2)))
    x₁, x₂, x₃, x₄ = vec(_q)
    z₀ = x₁ + im * x₂
    z₁ = x₃ + im * x₄
    z = ℝ⁴(x₁, x₂, x₃, x₄)
    u, v, a = getconnection(_q)
    
    zobservable[] = Point3f(project(z))
    uobservable[] = Point3f(normalize(project(u)))
    vobservable[] = Point3f(normalize(project(v)))
    aobservable[] = "$(round(imag(a), digits = 3)) 𝑖"

    q2 = _q * ℍ(exp(K(3) * gauge2))
    q3 = _q * ℍ(exp(K(3) * gauge3))
    q4 = _q * ℍ(exp(K(3) * gauge4))
    z2observable[] = Point3f(project(normalize(M * (q2))))
    z3observable[] = Point3f(project(normalize(M * (q3))))
    z4observable[] = Point3f(project(normalize(M * (q4))))
    u2, v2, a2 = getconnection(q2)
    u3, v3, a3 = getconnection(q3)
    u4, v4, a4 = getconnection(q4)
    u2observable[] = Point3f(normalize(project(u2)))
    u3observable[] = Point3f(normalize(project(u3)))
    u4observable[] = Point3f(normalize(project(u4)))
    v2observable[] = Point3f(normalize(project(v2)))
    v3observable[] = Point3f(normalize(project(v3)))
    v4observable[] = Point3f(normalize(project(v4)))
    a2observable[] = "$(round(imag(a2), digits = 3)) 𝑖"
    a3observable[] = "$(round(imag(a3), digits = 3)) 𝑖"
    a4observable[] = "$(round(imag(a4), digits = 3)) 𝑖"
    
    for i in 1:N
        gauge = i / N * 2π
        qn = _q * ℍ(exp(K(3) * gauge))
        znobservables[][i] = Point3f(project(normalize(M * (qn))))
        un, vn, an = getconnection(qn)
        unobservables[][i] = Point3f(normalize(project(un)) * arrowscale)
        vnobservables[][i] = Point3f(normalize(project(vn)) * arrowscale)
    end
    notify(znobservables)
    notify(vnobservables)
    notify(unobservables)

    κ = SpinVector(z₀, z₁, timesign)
    κ′ = SpinVector(Complex(κ) - 1.0 / √2 * ϵ / κ.a[2], timesign)
    κprojection = project(normalize(ℍ(vec( 𝕍( κ)))))
    κ′projection = project(normalize(ℍ(vec( 𝕍( κ′)))))
    # shift bundles one time step
    for i in (number1 - 1):-1:1
        tangentbundles1[i + 1].tangenthead[] = tangentbundles1[i].tangenthead[]
        tangentbundles1[i + 1].tangenttail[] = tangentbundles1[i].tangenttail[]
        tangentbundles1[i + 1].a[] = tangentbundles1[i].a[]
        tangentbundles1[i + 1].b[] = tangentbundles1[i].b[]
        tangentbundles1[i + 1].c[] = tangentbundles1[i].c[]
        tangentbundles1[i + 1].d[] = tangentbundles1[i].d[]
        tangentbundles1[i + 1].fiber[] = tangentbundles1[i].fiber[]
        tangentbundles1[i + 1].tangentcircle[] = tangentbundles1[i].tangentcircle[]
        tangentbundles1[i + 1].basepath[] = tangentbundles1[i].basepath[]
    end
    for i in (number2 - 1):-1:1
        tangentbundles2[i + 1].tangenthead[] = tangentbundles2[i].tangenthead[]
        tangentbundles2[i + 1].tangenttail[] = tangentbundles2[i].tangenttail[]
        tangentbundles2[i + 1].a[] = tangentbundles2[i].a[]
        tangentbundles2[i + 1].b[] = tangentbundles2[i].b[]
        tangentbundles2[i + 1].c[] = tangentbundles2[i].c[]
        tangentbundles2[i + 1].d[] = tangentbundles2[i].d[]
        tangentbundles2[i + 1].fiber[] = tangentbundles2[i].fiber[]
        tangentbundles2[i + 1].tangentcircle[] = tangentbundles2[i].tangentcircle[]
        tangentbundles2[i + 1].basepath[] = tangentbundles2[i].basepath[]
    end
    tangentbundles1[1].tangenthead[] = Point3f(normalize(κ′projection - κprojection))
    tangentbundles1[1].a[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge1))))))
    tangentbundles1[1].b[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge2))))))
    tangentbundles1[1].c[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge3))))))
    tangentbundles1[1].d[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge4))))))
    tangentbundles1[1].fiber[] = [Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments)]
    tangentbundles1[1].tangentcircle[] = Point3f[]
    tangentbundles2[1].tangenthead[] = Point3f(normalize(κ′projection - κprojection))
    tangentbundles2[1].a[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge1))))))
    tangentbundles2[1].b[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge2))))))
    tangentbundles2[1].c[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge3))))))
    tangentbundles2[1].d[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge4))))))
    tangentbundles2[1].fiber[] = [Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments)]
    tangentbundles2[1].tangentcircle[] = Point3f[]
    for i in 1:segments
        α = exp(im * i / segments * 2π)
        κ = SpinVector(α * z₀, α * z₁, timesign)
        κ′ = SpinVector(Complex(κ) - 1.0 / √2 * ϵ / κ.a[2], timesign)
        pa = ℝ³(hopfmap(normalize(ℍ(vec(κ)))))
        pb = ℝ³(hopfmap(normalize(ℍ(vec(κ′)))))
        if i == 1
            tangentbundles1[1].tangenttail[] = Point3f(pa)
            push!(tangentbundles1[1].basepath[], tangentbundles2[1].tangenttail[])
            tangentbundles2[1].tangenttail[] = Point3f(pa)
            push!(tangentbundles2[1].basepath[], tangentbundles2[1].tangenttail[])
        end
        push!(tangentbundles1[1].tangentcircle[], Point3f(pa + normalize(pb - pa)))
        push!(tangentbundles2[1].tangentcircle[], Point3f(pa + normalize(pb - pa)))
    end
    for i in 1:number1
        notify(tangentbundles1[i].basepath)
        notify(tangentbundles1[i].tangentcircle)
    end
    for i in 1:number2
        notify(tangentbundles2[i].basepath)
        notify(tangentbundles2[i].tangentcircle)
    end
    h = ℍ(imag(a), normalize(ℝ³(tangentbundles1[1].tangenttail[])))
    head[] = Point3f(rotate(ℝ³(tangentbundles1[1].tangenthead[]), h))
    arcpoints[] = [zobservable[] + Point3f(normalize(α * ℝ³(uobservable[]) + (1 - α) * ℝ³(vobservable[]))) for α in range(0, stop = 1, length = segments)]
    arcpoints2[] = [z2observable[] + Point3f(normalize(α * ℝ³(u2observable[]) + (1 - α) * ℝ³(v2observable[]))) for α in range(0, stop = 1, length = segments)]
    arcpoints3[] = [z3observable[] + Point3f(normalize(α * ℝ³(u3observable[]) + (1 - α) * ℝ³(v3observable[]))) for α in range(0, stop = 1, length = segments)]
    arcpoints4[] = [z4observable[] + Point3f(normalize(α * ℝ³(u4observable[]) + (1 - α) * ℝ³(v4observable[]))) for α in range(0, stop = 1, length = segments)]
    _arcpoints[] = [tangentbundles2[1].tangenttail[] + Point3f(normalize(α * ℝ³(tangentbundles2[1].tangenthead[])+ (1 - α) * ℝ³(head[]))) for α in range(0, stop = 1, length = segments)]
    push!(sectionalpath[], zobservable[])
    notify(arcpoints)
    notify(arcpoints2)
    notify(arcpoints3)
    notify(arcpoints4)
    notify(_arcpoints)
    notify(sectionalpath)
    global lookat =  ℝ³(tangentbundles1[1].tangenttail[])
    global eyeposition = normalize(lookat) * float(π + π / 2)
    updatecamera!(lscene1, eyeposition, lookat, up)
    updatecamera!(lscene2, eyeposition, lookat, up)
end


animate(1)

# initialize all instances of tangent bundles before recording
for i in 1:max(number1, number2)
    animate(1)
end
for i in 1:number1
    tangentbundles1[i].basepath[] = Point3f[]
end
for i in 1:number2
    tangentbundles2[i].basepath[] = Point3f[]
    sectionalpath[] = Point3f[]
end
record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end