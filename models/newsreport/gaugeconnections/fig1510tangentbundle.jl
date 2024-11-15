using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 90
frames_number = 360
modelname = "fig1510tangentbundle"
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
T = -1.0
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
    color1 = getcolor(boundary_nodes[i], reference, 0.2)
    color2 = getcolor(boundary_nodes[i], reference, 0.4)
    color3 = getcolor(boundary_nodes[i], reference, 0.6)
    color4 = getcolor(boundary_nodes[i], reference, 0.8)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end

origin = Observable(Point3f(ℝ³(0.0, 0.0, 0.0)))
tangenttail = Observable(Point3f(0.0, 0.0, 0.0))
tangenthead = Observable(Point3f(x̂))
point1 = Observable(Point3f(0.0, 0.0, 0.0))
point2 = Observable(Point3f(0.0, 0.0, 0.0))
point3 = Observable(Point3f(0.0, 0.0, 0.0))
point4 = Observable(Point3f(0.0, 0.0, 0.0))
meshscatter!(lscene, origin, markersize = markersize, color = :black)
meshscatter!(lscene, point1, markersize = markersize, color = :red)
meshscatter!(lscene, point2, markersize = markersize, color = :red)
meshscatter!(lscene, point3, markersize = markersize, color = :red)
meshscatter!(lscene, point4, markersize = markersize, color = :red)
meshscatter!(lscene, tangenttail, markersize = markersize, color = :red)
# sphereorigin = ℝ³(0.0, 3.0, 0.0)
lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
# sphere = Observable([sphereorigin + convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1])
# sphereobservable = buildsurface(lscene, sphere, mask, transparency = true)
linepoints1 = @lift([$point1, $tangenttail])
linepoints2 = @lift([$point2, $tangenttail])
linepoints3 = @lift([$point3, $tangenttail])
linepoints4 = @lift([$point4, $tangenttail])
linecolors = Observable(collect(1:segments))
lines!(lscene, linepoints1, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :plasma)
lines!(lscene, linepoints2, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :plasma)
lines!(lscene, linepoints3, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :plasma)
lines!(lscene, linepoints4, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :plasma)
fiber = Observable([Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)])
lines!(lscene, fiber, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :inferno)
basepath = Observable(Point3f[])
pathcolors = collect(1:frames_number)
lines!(lscene, basepath, color = pathcolors, linewidth = linewidth / 4, colorrange = (1, frames_number), colormap = :magma)
tangentcircle = Observable(Point3f[])
lines!(lscene, tangentcircle, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :rainbow)

ps = @lift([$origin, $origin, $tangenttail])
ns = @lift([$point1, $point3, $tangenthead])
colorants = [:red, :green, :blue]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)
titles = ["O", "q ∈ ℂ²", "-q ∈ ℂ²", "π(q) ∈ S²"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$origin, $point1, $point3, $tangenttail])),
    text = titles,
    color = [:black, colorants...],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data
)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    ψ = progress * 2π
    θ, ϕ = cos(2ψ) * π / 2, sin(4ψ) * π
    notify(basepath)
    _q = q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2)))
    a, b, c, d = vec(_q)
    w = a + im * b
    z = c + im * d
    @assert(isapprox(abs(w)^2 + abs(z)^2, 1), "The point $_q is not in S³, in other words: |w|² + |z|² ≠ 1.")
    # tangenttail[] = Point3f(sphereorigin + ℝ³(hopfmap(_q)))
    timesign = 1
    κ = SpinVector(w, z, timesign)
    κ′ = SpinVector(Complex(κ) - 1.0 / √2 * ϵ / κ.a[2], timesign)
    κprojection = project(normalize(ℍ(vec(𝕍(κ)))))
    κ′projection = project(normalize(ℍ(vec(𝕍(κ′)))))
    tangenthead[] = Point3f(normalize(κ′projection - κprojection))
    point1[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge1))))))
    point2[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge2))))))
    point3[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge3))))))
    point4[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge4))))))
    fiber[] = [Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments)]
    tangentcircle[] = Point3f[]
    for i in 1:segments
        α = exp(im * i / segments * 2π)
        κ = SpinVector(α * w, α * z, timesign)
        κ′ = SpinVector(Complex(κ) - 1.0 / √2 * ϵ / κ.a[2], timesign)
        p₁ = ℝ³(hopfmap(normalize(ℍ(vec(κ)))))
        p₂ = ℝ³(hopfmap(normalize(ℍ(vec(κ′)))))
        push!(tangentcircle[], Point3f(p₁ + normalize(p₂ - p₁)))
        if i == 1
            tangenttail[] = Point3f(p₁)
            push!(basepath[], tangenttail[])
        end
    end
    notify(tangentcircle)
    global lookat = ℝ³(tangenttail[] + (tangenttail[] + tangenthead[]) + point1[] + point2[] + point3[] + point4[]) * (1 / 6)
    global eyeposition = normalize(ℝ³(tangenttail[])) * float(π)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

basepath[] = Point3f[]
record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end