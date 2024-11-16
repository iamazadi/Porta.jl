using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 120
frames_number = 360
modelname = "fig1511complexlinebundle"
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
colorants = [:red, :green, :blue, :orange, :gold]
colormap1 = :reds
colormap2 = :Greens
colormap3 = :Blues
colormap4 = :Oranges
colormap5 = :gold

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

origin = Observable(zero)
tangenttail1 = Observable(zero)
tangenttail2 = Observable(zero)
tangenttail3 = Observable(zero)
tangenttail4 = Observable(zero)
tangenttail5 = Observable(zero)
tangenthead1 = Observable(Point3f(x̂))
tangenthead2 = Observable(Point3f(x̂))
tangenthead3 = Observable(Point3f(x̂))
tangenthead4 = Observable(Point3f(x̂))
tangenthead5 = Observable(Point3f(x̂))
pointa1 = Observable(zero)
pointa2 = Observable(zero)
pointa3 = Observable(zero)
pointa4 = Observable(zero)
pointa5 = Observable(zero)
pointb1 = Observable(zero)
pointb2 = Observable(zero)
pointb3 = Observable(zero)
pointb4 = Observable(zero)
pointb5 = Observable(zero)
pointc1 = Observable(zero)
pointc2 = Observable(zero)
pointc3 = Observable(zero)
pointc4 = Observable(zero)
pointc5 = Observable(zero)
pointd1 = Observable(zero)
pointd2 = Observable(zero)
pointd3 = Observable(zero)
pointd4 = Observable(zero)
pointd5 = Observable(zero)

meshscatter!(lscene, origin, markersize = markersize, color = :black)
meshscatter!(lscene, pointa1, markersize = markersize, color = colorants[1])
meshscatter!(lscene, pointb1, markersize = markersize, color = colorants[1])
meshscatter!(lscene, pointc1, markersize = markersize, color = colorants[1])
meshscatter!(lscene, pointd1, markersize = markersize, color = colorants[1])
meshscatter!(lscene, pointa2, markersize = markersize, color = colorants[2], transparency = true)
meshscatter!(lscene, pointb2, markersize = markersize, color = colorants[2], transparency = true)
meshscatter!(lscene, pointc2, markersize = markersize, color = colorants[2], transparency = true)
meshscatter!(lscene, pointd2, markersize = markersize, color = colorants[2], transparency = true)
meshscatter!(lscene, pointa3, markersize = markersize, color = colorants[3], transparency = true)
meshscatter!(lscene, pointb3, markersize = markersize, color = colorants[3], transparency = true)
meshscatter!(lscene, pointc3, markersize = markersize, color = colorants[3], transparency = true)
meshscatter!(lscene, pointd3, markersize = markersize, color = colorants[3], transparency = true)
meshscatter!(lscene, pointa4, markersize = markersize, color = colorants[4], transparency = true)
meshscatter!(lscene, pointb4, markersize = markersize, color = colorants[4], transparency = true)
meshscatter!(lscene, pointc4, markersize = markersize, color = colorants[4], transparency = true)
meshscatter!(lscene, pointd4, markersize = markersize, color = colorants[4], transparency = true)
meshscatter!(lscene, pointa5, markersize = markersize, color = colorants[5], transparency = true)
meshscatter!(lscene, pointb5, markersize = markersize, color = colorants[5], transparency = true)
meshscatter!(lscene, pointc5, markersize = markersize, color = colorants[5], transparency = true)
meshscatter!(lscene, pointd5, markersize = markersize, color = colorants[5], transparency = true)
meshscatter!(lscene, tangenttail1, markersize = markersize, color = colorants[1])
meshscatter!(lscene, tangenttail2, markersize = markersize, color = colorants[2], transparency = true)
meshscatter!(lscene, tangenttail3, markersize = markersize, color = colorants[3], transparency = true)
meshscatter!(lscene, tangenttail4, markersize = markersize, color = colorants[4], transparency = true)
meshscatter!(lscene, tangenttail5, markersize = markersize, color = colorants[5], transparency = true)

linepointsa1 = @lift([$pointa1, $tangenttail1])
linepointsb1 = @lift([$pointb1, $tangenttail1])
linepointsc1 = @lift([$pointc1, $tangenttail1])
linepointsd1 = @lift([$pointd1, $tangenttail1])

linepointsa2 = @lift([$pointa2, $tangenttail2])
linepointsb2 = @lift([$pointb2, $tangenttail2])
linepointsc2 = @lift([$pointc2, $tangenttail2])
linepointsd2 = @lift([$pointd2, $tangenttail2])

linepointsa3 = @lift([$pointa3, $tangenttail3])
linepointsb3 = @lift([$pointb3, $tangenttail3])
linepointsc3 = @lift([$pointc3, $tangenttail3])
linepointsd3 = @lift([$pointd3, $tangenttail3])

linepointsa4 = @lift([$pointa4, $tangenttail4])
linepointsb4 = @lift([$pointb4, $tangenttail4])
linepointsc4 = @lift([$pointc4, $tangenttail4])
linepointsd4 = @lift([$pointd4, $tangenttail4])

linepointsa5 = @lift([$pointa5, $tangenttail5])
linepointsb5 = @lift([$pointb5, $tangenttail5])
linepointsc5 = @lift([$pointc5, $tangenttail5])
linepointsd5 = @lift([$pointd5, $tangenttail5])

linecolors = Observable(collect(1:segments))
lines!(lscene, linepointsa1, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap1)
lines!(lscene, linepointsb1, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap1)
lines!(lscene, linepointsc1, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap1)
lines!(lscene, linepointsd1, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap1)

lines!(lscene, linepointsa2, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap2, transparency = true)
lines!(lscene, linepointsb2, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap2, transparency = true)
lines!(lscene, linepointsc2, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap2, transparency = true)
lines!(lscene, linepointsd2, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap2, transparency = true)

lines!(lscene, linepointsa3, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap3, transparency = true)
lines!(lscene, linepointsb3, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap3, transparency = true)
lines!(lscene, linepointsc3, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap3, transparency = true)
lines!(lscene, linepointsd3, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap3, transparency = true)

lines!(lscene, linepointsa4, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap4, transparency = true)
lines!(lscene, linepointsb4, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap4, transparency = true)
lines!(lscene, linepointsc4, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap4, transparency = true)
lines!(lscene, linepointsd4, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap4, transparency = true)

lines!(lscene, linepointsa5, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap5, transparency = true)
lines!(lscene, linepointsb5, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap5, transparency = true)
lines!(lscene, linepointsc5, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap5, transparency = true)
lines!(lscene, linepointsd5, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap5, transparency = true)

fiber1 = Observable([Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)])
fiber2 = Observable([Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)])
fiber3 = Observable([Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)])
fiber4 = Observable([Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)])
fiber5 = Observable([Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)])
lines!(lscene, fiber1, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = colormap1)
lines!(lscene, fiber2, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = colormap2, transparency = true)
lines!(lscene, fiber3, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = colormap3, transparency = true)
lines!(lscene, fiber4, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = colormap4, transparency = true)
lines!(lscene, fiber5, color = linecolors, linewidth = 2linewidth, colorrange = (1, segments), colormap = colormap5, transparency = true)
basepath1 = Observable(Point3f[])
basepath2 = Observable(Point3f[])
basepath3 = Observable(Point3f[])
basepath4 = Observable(Point3f[])
basepath5 = Observable(Point3f[])
pathcolors = collect(1:frames_number)
lines!(lscene, basepath1, color = pathcolors, linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = colormap1)
lines!(lscene, basepath2, color = pathcolors, linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = colormap2, transparency = true)
lines!(lscene, basepath3, color = pathcolors, linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = colormap3, transparency = true)
lines!(lscene, basepath4, color = pathcolors, linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = colormap4, transparency = true)
lines!(lscene, basepath5, color = pathcolors, linewidth = linewidth / 2, colorrange = (1, frames_number), colormap = colormap5, transparency = true)
tangentcircle1 = Observable(Point3f[])
tangentcircle2 = Observable(Point3f[])
tangentcircle3 = Observable(Point3f[])
tangentcircle4 = Observable(Point3f[])
tangentcircle5 = Observable(Point3f[])
lines!(lscene, tangentcircle1, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap1)
lines!(lscene, tangentcircle2, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap2, transparency = true)
lines!(lscene, tangentcircle3, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap3, transparency = true)
lines!(lscene, tangentcircle4, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap4, transparency = true)
lines!(lscene, tangentcircle5, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap5, transparency = true)

ps = @lift([$origin, $origin, $origin, $origin, $origin, $origin, $origin, $origin, $origin, $origin, $tangenttail1, $tangenttail2, $tangenttail3, $tangenttail4, $tangenttail5])
ns = @lift([$pointa1, $pointc1, $pointa2, $pointc2, $pointa3, $pointc3, $pointa4, $pointc4, $pointa5, $pointc5, $tangenthead1, $tangenthead2, $tangenthead3, $tangenthead4, $tangenthead5])
colorants1 = [colorants[1], colorants[1], colorants[2], colorants[2], colorants[3], colorants[3], colorants[4], colorants[4], colorants[5], colorants[5], colorants...]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants1,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)
titles = ["O", "q₁", "-q₁", "q₂", "-q₂", "q₃", "-q₃", "q₄", "-q₄", "q₅", "-q₅", "π(q₁)", "π(q₂)", "π(q₃)", "π(q₄)", "π(q₅)"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$origin, $pointa1, $pointc1, $pointa2, $pointc2, $pointa3, $pointc3, $pointa4, $pointc4, $pointa5, $pointc5, $tangenttail1, $tangenttail2, $tangenttail3, $tangenttail4, $tangenttail5])),
    text = titles,
    color = [:black, colorants1...],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data
)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    println("Frame: $frame, Progress: $progress")
    ψ = progress * 2π
    θ, ϕ = cos(4ψ) * π / 2, sin(6ψ) * π
    _q = q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2)))
    a, b, c, d = vec(_q)
    w = a + im * b
    z = c + im * d
    @assert(isapprox(abs(w)^2 + abs(z)^2, 1), "The point $_q is not in S³, in other words: |w|² + |z|² ≠ 1.")
    κ = SpinVector(w, z, timesign)
    κ′ = SpinVector(Complex(κ) - 1.0 / √2 * ϵ / κ.a[2], timesign)
    κprojection = project(normalize(ℍ(vec( 𝕍( κ)))))
    κ′projection = project(normalize(ℍ(vec( 𝕍( κ′)))))
    tangenthead5[] = tangenthead4[]
    tangenthead4[] = tangenthead3[]
    tangenthead3[] = tangenthead2[]
    tangenthead2[] = tangenthead1[]
    tangenthead1[] = Point3f(normalize(κ′projection - κprojection))
    tangenttail5[] = tangenttail4[]
    tangenttail4[] = tangenttail3[]
    tangenttail3[] = tangenttail2[]
    tangenttail2[] = tangenttail1[]
    pointa5[] = pointa4[]
    pointa4[] = pointa3[]
    pointa3[] = pointa2[]
    pointa2[] = pointa1[]
    pointa1[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge1))))))
    pointb5[] = pointb4[]
    pointb4[] = pointb3[]
    pointb3[] = pointb2[]
    pointb2[] = pointb1[]
    pointb1[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge2))))))
    pointc5[] = pointc4[]
    pointc4[] = pointc3[]
    pointc3[] = pointc2[]
    pointc2[] = pointc1[]
    pointc1[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge3))))))
    pointd5[] = pointd4[]
    pointd4[] = pointd3[]
    pointd3[] = pointd2[]
    pointd2[] = pointd1[]
    pointd1[] = Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * gauge4))))))
    fiber5[] = fiber4[]
    fiber4[] = fiber3[]
    fiber3[] = fiber2[]
    fiber2[] = fiber1[]
    fiber1[] = [Point3f(project(normalize(M * (_q * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments)]
    tangentcircle5[] = tangentcircle4[]
    tangentcircle4[] = tangentcircle3[]
    tangentcircle3[] = tangentcircle2[]
    tangentcircle2[] = tangentcircle1[]
    tangentcircle1[] = Point3f[]
    basepath5[] = basepath4[]
    basepath4[] = basepath3[]
    basepath3[] = basepath2[]
    basepath2[] = basepath1[]
    for i in 1:segments
        α = exp(im * i / segments * 2π)
        κ = SpinVector(α * w, α * z, timesign)
        κ′ = SpinVector(Complex(κ) - 1.0 / √2 * ϵ / κ.a[2], timesign)
        pa = ℝ³(hopfmap(normalize(ℍ(vec(κ)))))
        pb = ℝ³(hopfmap(normalize(ℍ(vec(κ′)))))
        if i == 1
            tangenttail1[] = Point3f(pa)
            push!(basepath1[], tangenttail1[])
        end
        push!(tangentcircle1[], Point3f(pa + normalize(pb - pa)))
    end
    notify(basepath1)
    notify(basepath2)
    notify(basepath3)
    notify(basepath4)
    notify(basepath5)
    notify(tangentcircle1)
    notify(tangentcircle2)
    notify(tangentcircle3)
    notify(tangentcircle4)
    notify(tangentcircle5)
    global lookat =  ℝ³(tangenttail1[] + (tangenttail1[] + tangenthead1[]) + pointa1[] + pointb1[] + pointc1[] + pointd1[]) * (1 / 6)
    # global eyeposition = -normalize(ℝ³(tangenttail1[])) * float(π)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

for i in 1:5
    animate(1)
end
basepath1[] = Point3f[]
basepath2[] = Point3f[]
basepath3[] = Point3f[]
basepath4[] = Point3f[]
basepath5[] = Point3f[]
record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end