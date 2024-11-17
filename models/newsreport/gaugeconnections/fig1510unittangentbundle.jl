using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig1510unittangentbundle"
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
fontsize = 0.25
zero = Point3f(0.0, 0.0, 0.0)
lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
names = ["q₁"]
colorants = [:black for _ in eachindex(names)]
colormaps = [:rainbow for _ in eachindex(names)]
number = length(names) # the number of tangent bundles
tangentbundles = TangentBundle[]
pathsegments = frames_number

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

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

for i in 1:number
    transparency = i == 1 ? false : true
    tangentbundle = TangentBundle(lscene, names[i], segments = segments, pathsegments = pathsegments, transparency = transparency,
        markersize = markersize, linewidth = linewidth, color = colorants[i], colormap = colormaps[i], arrowsize = arrowsize,
        arrowlinewidth = arrowlinewidth, fontsize = fontsize)
    push!(tangentbundles, tangentbundle)
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    ψ = progress * 2π
    θ, ϕ = cos(2ψ) * π / 2, sin(4ψ) * π
    _q = q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2)))
    a, b, c, d = vec(_q)
    w = a + im * b
    z = c + im * d
    @assert(isapprox(abs(w)^2 + abs(z)^2, 1), "The point $_q is not in S³, in other words: |w|² + |z|² ≠ 1.")
    κ = SpinVector(w, z, timesign)
    κ′ = SpinVector(Complex(κ) - 1.0 / √2 * ϵ / κ.a[2], timesign)
    κprojection = project(normalize(ℍ(vec( 𝕍( κ)))))
    κ′projection = project(normalize(ℍ(vec( 𝕍( κ′)))))
    # shift bundles one time step
    for i in (number - 1):-1:1
        tangentbundles[i + 1].tangenthead[] = tangentbundles[i].tangenthead[]
        tangentbundles[i + 1].tangenttail[] = tangentbundles[i].tangenttail[]
        tangentbundles[i + 1].a[] = tangentbundles[i].a[]
        tangentbundles[i + 1].b[] = tangentbundles[i].b[]
        tangentbundles[i + 1].c[] = tangentbundles[i].c[]
        tangentbundles[i + 1].d[] = tangentbundles[i].d[]
        tangentbundles[i + 1].fiber[] = tangentbundles[i].fiber[]
        tangentbundles[i + 1].tangentcircle[] = tangentbundles[i].tangentcircle[]
        tangentbundles[i + 1].basepath[] = tangentbundles[i].basepath[]
    end
    tangentbundles[1].tangenthead[] = Point3f(normalize(κ′projection - κprojection))
    tangentbundles[1].a[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge1))))))
    tangentbundles[1].b[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge2))))))
    tangentbundles[1].c[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge3))))))
    tangentbundles[1].d[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge4))))))
    tangentbundles[1].fiber[] = [Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments)]
    tangentbundles[1].tangentcircle[] = Point3f[]
    for i in 1:segments
        α = exp(im * i / segments * 2π)
        κ = SpinVector(α * w, α * z, timesign)
        κ′ = SpinVector(Complex(κ) - 1.0 / √2 * ϵ / κ.a[2], timesign)
        pa = ℝ³(hopfmap(normalize(ℍ(vec(κ)))))
        pb = ℝ³(hopfmap(normalize(ℍ(vec(κ′)))))
        if i == 1
            tangentbundles[1].tangenttail[] = Point3f(pa)
            push!(tangentbundles[1].basepath[], tangentbundles[1].tangenttail[])
        end
        push!(tangentbundles[1].tangentcircle[], Point3f(pa + normalize(pb - pa)))
    end
    for i in 1:number
        notify(tangentbundles[i].basepath)
        notify(tangentbundles[i].tangentcircle)
    end
    global lookat =  ℝ³(tangentbundles[1].tangenttail[] + (tangentbundles[1].tangenttail[] + tangentbundles[1].tangenthead[]) +
        tangentbundles[1].a[] + tangentbundles[1].b[] + tangentbundles[1].c[] + tangentbundles[1].d[]) * (1 / 6)
    global eyeposition = normalize(ℝ³(tangentbundles[1].tangenttail[])) * float(π)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

# initialize all instances of tangent bundles before recording
for i in 1:number
    animate(1)
end
for i in 1:number
    tangentbundles[i].basepath[] = Point3f[]
end
record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end