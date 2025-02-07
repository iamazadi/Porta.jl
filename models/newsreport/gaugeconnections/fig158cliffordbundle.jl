using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 90
frames_number = 360
modelname = "fig158cliffordbundle"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition1 = normalize(ℝ³(1.0, 1.0, 1.0)) * float(2π)
eyeposition2 = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat1 = ℝ³(0.0, 0.0, 0.0)
lookat2 = ℝ³(0.0, 0.0, 0.0)
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
lscene1 = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = LScene(fig[1, 2], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
while length(boundary_names) < 30
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

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.2)
    color2 = getcolor(boundary_nodes[i], reference, 0.4)
    color3 = getcolor(boundary_nodes[i], reference, 0.6)
    color4 = getcolor(boundary_nodes[i], reference, 0.8)
    whirl1 = Whirl(lscene1, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene1, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene1, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene1, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end

point1 = Observable(Point3f(0.0, 0.0, 0.0))
point2 = Observable(Point3f(0.0, 0.0, 0.0))
point3 = Observable(Point3f(0.0, 0.0, 0.0))
point4 = Observable(Point3f(0.0, 0.0, 0.0))
planepoint = Observable(Point3f(0.0, 0.0, 0.0))
meshscatter!(lscene1, point1, markersize = markersize, color = :red)
meshscatter!(lscene1, point2, markersize = markersize, color = :red)
meshscatter!(lscene1, point3, markersize = markersize, color = :red)
meshscatter!(lscene1, point4, markersize = markersize, color = :red)
meshscatter!(lscene1, planepoint, markersize = markersize, color = :red)
sphereorigin = ℝ³(0.0, 0.0, 0.0)
lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
sphere = [sphereorigin + ℝ³([-θ; ϕ; -1.0]) for θ in lspace2, ϕ in lspace1]
sphereobservable = buildsurface(lscene1, sphere, mask, transparency = true)
linepoints1 = @lift([$point1, $planepoint])
linepoints2 = @lift([$point2, $planepoint])
linepoints3 = @lift([$point3, $planepoint])
linepoints4 = @lift([$point4, $planepoint])
linecolors = collect(1:2)
lines!(lscene1, linepoints1, color = linecolors, linewidth = linewidth, colorrange = (1, 2), colormap = :plasma)
lines!(lscene1, linepoints2, color = linecolors, linewidth = linewidth, colorrange = (1, 2), colormap = :plasma)
lines!(lscene1, linepoints3, color = linecolors, linewidth = linewidth, colorrange = (1, 2), colormap = :plasma)
lines!(lscene1, linepoints4, color = linecolors, linewidth = linewidth, colorrange = (1, 2), colormap = :plasma)
fiber = Observable([Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)])
linecolors = collect(1:segments)
lines!(lscene1, fiber, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :inferno)
basepath = Observable(Point3f[])
pathcolors = Observable(Int[])
lines!(lscene1, basepath, color = pathcolors, linewidth = linewidth / 4, colorrange = (1, frames_number), colormap = :magma)

origin = Observable(Point3f(ℝ³(0.0, 0.0, 0.0)))
c2point = Observable(Point3f(normalize(x̂ + ŷ)))
antipode = Observable(Point3f(-normalize(x̂ + ŷ)))
meshscatter!(lscene2, origin, markersize = markersize, color = :black)
meshscatter!(lscene2, c2point, markersize = markersize, color = :red)
meshscatter!(lscene2, antipode, markersize = markersize, color = :red)
circle = [Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)]
lines!(lscene2, circle, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :rainbow)
whead = Observable(Point3f(x̂))
zhead = Observable(Point3f(ŷ))
ps = @lift([$origin, $origin, $origin, $origin])
ns = @lift([$whead, $zhead, $c2point, $antipode])
colorants1 = [:red, :red, :red]
colorants2 = [:black, :black, :red, :red]
arrows!(lscene2,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants2,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)
titles1 = ["q ∈ ℂ²", "-q ∈ ℂ²", "π(q)"]
titles2 = ["w ∈ ℂ", "z ∈ ℂ", "q ∈ ℂ²", "-q ∈ ℂ²"]
rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)
text!(lscene1,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$point1, $point3, $planepoint])),
    text = titles1,
    color = colorants1,
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data
)
text!(lscene2,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$whead, $zhead, $c2point, $antipode])),
    text = titles2,
    color = colorants2,
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data
)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    ψ = progress * 2π
    θ, ϕ = cos(2ψ) * π / 2, sin(4ψ) * π
    planepoint[] = Point3f(ℝ³(θ, ϕ, -1.0))
    push!(basepath[], planepoint[])
    notify(basepath)
    _q = q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2)))
    a, b, c, d = vec(_q)
    w = a + im * b
    z = c + im * d
    @assert(isapprox(abs(w)^2 + abs(z)^2, 1), "The point $_q is not in S³, in other words: |w|² + |z|² ≠ 1.")
    c2point[] = Point3f(ℝ³(abs(w), abs(z), 0.0))
    antipode[] = Point3f(-ℝ³(abs(w), abs(z), 0.0))
    point1[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge1))))))
    point2[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge2))))))
    point3[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge3))))))
    point4[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge4))))))
    fiber[] = [Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments)]
    pathcolors[] = collect(1:frame)
    if frame == 1
        global eyeposition1 = float(π) * (x̂ + ẑ)
    end
    global lookat1 = ℝ³(planepoint[] + point1[] + point2[] + point3[] + point4[]) * (1 / 5)
    global lookat2 = ℝ³(c2point[] + antipode[]) * (1 / 2)
    updatecamera!(lscene1, eyeposition1, lookat1, up)
    updatecamera!(lscene2, eyeposition2, lookat2, up)
end


animate(1)

basepath[] = Point3f[]
record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end