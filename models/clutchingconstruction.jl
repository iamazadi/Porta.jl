import ColorTypes
import FixedPointNumbers
import GeometryBasics
import GLMakie
import Makie
import FileIO
import DataFrames
import CSV

using Porta


segments = 30
segments1 = 30
resolution = (1920, 1080)

# The path to the dataset
attributespath = "data/gdp/geometry-attributes.csv"
attributes = DataFrames.DataFrame(CSV.File(attributespath))
attributes = DataFrames.sort(attributes, :shapeid, rev = true)
nodespath = "data/gdp/geometry-nodes.csv"
nodes = DataFrames.DataFrame(CSV.File(nodespath))

attributesgroup = DataFrames.groupby(attributes, :NAME)
nodesgroup = DataFrames.groupby(nodes, :shapeid)
number = length(attributesgroup)
ϵ = 1e-3
countries = Dict("shapeid" => [], "name" => [], "gdpmd" => [],
                 "gdpyear" => [], "economy" => [], "partid" => [], "nodes" => [])
for i in 1:number
    shapeid = attributesgroup[i][!, :shapeid][1]
    name = attributesgroup[i][!, :NAME][1]
    gdpmd = attributesgroup[i][!, :GDP_MD][1]
    gdpyear = attributesgroup[i][!, :GDP_YEAR][1]
    economy = attributesgroup[i][!, :ECONOMY][1]
    subdataframe = nodes[nodes.shapeid .== shapeid, :]
    uniquepartid = unique(subdataframe[!, :partid])

    histogram = Dict()
    for id in uniquepartid
        sub = subdataframe[subdataframe.partid .== id, :]
        ϕ = sub.x ./ 180 .* π
        θ = sub.y ./ 180 .* π
        coordinates = map(x -> Geographic(1, x[1], x[2]), eachrow([ϕ θ]))[begin:end-1]
        coordinates = decimate(coordinates, ϵ)
        histogram[id] = length(coordinates)
    end
    partsnumber = max(values(histogram)...)
    index = findfirst(x -> histogram[x] == partsnumber, uniquepartid)
    partid = uniquepartid[index]
    subdataframe = subdataframe[subdataframe.partid .== partid, :]
    ϕ = subdataframe.x ./ 180 .* π
    θ = subdataframe.y ./ 180 .* π
    coordinates = map(x -> Geographic(1, x[1], x[2]), eachrow([ϕ θ]))[begin:end-1]
    println("Length of points: $name : $(length(coordinates))")
    coordinates = decimate(coordinates, ϵ)
    if length(coordinates) < segments1
        continue
    end
    println("Length of points: $name : $(length(coordinates))")
    push!(countries["shapeid"], shapeid)
    push!(countries["name"], name)
    push!(countries["gdpmd"], gdpmd)
    push!(countries["gdpyear"], gdpyear)
    push!(countries["economy"], economy)
    push!(countries["partid"], partid)
    push!(countries["nodes"], coordinates)
end

for i in 1:length(countries["nodes"])
    println(length(countries["nodes"][i]))
end


p₀ = GLMakie.Observable([0.0; 0.0])
p₁ = GLMakie.Observable([0.0; 0.0])
controlstatus = GLMakie.Observable(true)
cumulativetwist = GLMakie.Observable(0.0)
gauges = GLMakie.Observable([U1(0.0) for i in 1:segments1])
pathinitialized = false
uppathinitialized = false
ghostsnumber = 6
groupactions = GLMakie.Observable([U1(0) for i in 1:ghostsnumber])

Φ(p) = begin
    chart = GLMakie.to_value(toggle.active)
    magnitude = p[1]^2 + p[2]^2
    if chart
        if isapprox(magnitude, 1)
            return 0
        else
            -√(1 - magnitude) # z
        end
    else
        if isapprox(magnitude, 1)
            return 0
        else
            √(1 - magnitude) # z
        end
    end
end

textsize = 30
textsize1 = 0.25
fig = GLMakie.Figure(resolution = resolution)
toggle = GLMakie.Toggle(fig, active = false)
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
#pl = GLMakie.PointLight(GLMakie.@lift(GLMakie.Point3f([$(p₁)[1], $(p₁)[2], Φ($(p₁))]...)), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
# GLMakie.set_window_config!(pause_renderloop=true)
screen = GLMakie.display(fig, resolution = resolution)
lscene = GLMakie.LScene(fig[1:7, 1:2], show_axis=true, scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=:white, clear=true))

q1 = Biquaternion(ℝ³(0, 0, 0))
radius = 1.0
color = GLMakie.RGBAf(255, 0, 255, 0.2)
transparency = true
n_hemisphere = Hemisphere(q1,
                          lscene,
                          radius = radius,
                          segments = segments,
                          color = color,
                          transparency = transparency)

q1 = Biquaternion(Quaternion(π / 2, ℝ³(1, 0, 0)), ℝ³(0, 0, 0))
color = GLMakie.RGBAf(255, 255, 0, 0.2)
s_hemisphere = Hemisphere(q1,
                          lscene,
                          radius = radius,
                          segments = segments,
                          color = color,
                          transparency = transparency)

q1 = Biquaternion(ℝ³(0, 0, 0))
sphere = RGBSphere(q1, lscene, FileIO.load("data/basemap_mask.png"), radius = 1.01, segments = segments, transparency = false)

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
eyeposition = GLMakie.Observable(ℝ³(1, 1, 1))
lookat = GLMakie.Observable(ℝ³(0, 1, 0))
up = GLMakie.Observable(ℝ³(0, 0, 1))
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(GLMakie.to_value(eyeposition))...), GLMakie.Vec3f(vec(GLMakie.to_value(lookat))...), GLMakie.Vec3f(vec(GLMakie.to_value(up))...))

width = 0.05
transparency = true
color = GLMakie.RGBA(255.0, 0.0, 0.0, 0.25)
tail, head = ℝ³(0, 0, 1), ℝ³(0.3, 0, 0)
x_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBA(0.0, 255.0, 0.0, 0.25)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0.3, 0)
y_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBA(0.0, 0.0, 255.0, 0.25)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0, 0.3)
z_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)

color = GLMakie.RGBA(1.0, 0.1, 0.1, 0.5)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0, 0.3)
a_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBA(0.1, 1.0, 0.1, 0.5)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0, 0.3)
b_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBA(0.1, 0.1, 1.0, 0.5)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0, 0.3)
c_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)

textbox = GLMakie.Textbox(fig, placeholder = "Enter a name", width = 115)
textbox.stored_string = "I"
markbutton = GLMakie.Button(fig, label = "Mark the frame")
resetbutton = GLMakie.Button(fig, label = "Reset frame")
label = GLMakie.Label(fig, GLMakie.lift(x -> x ? "Disk S" : "Disk N", toggle.active))
fig[4, 3] = GLMakie.grid!(GLMakie.hcat(textbox, markbutton, resetbutton, toggle, label), tellheight = false)

rotation = GLMakie.Observable(Quaternion(1, 0, 0, 0))

# rotation = GLMakie.lift(eyeposition) do _eyeposition
#     _lookat = GLMakie.to_value(lookat)
#     v = _eyeposition - _lookat
#     # v = _lookat
#     n = ℝ³(0, 0, 1)
    
#     if GLMakie.to_value(toggle.active) 
#         v = -v
#         #h = Quaternion(π / 2, ℝ³(0, 1, 0)) * getrotation(n, v)
#     end

#     pᵢ = ℝ³(0, 0, 1)
#     pᵢ₊₁ = normalize(v)
#     qᵢ = getrotation(n, pᵢ)
#     qᵢ₊₁ = getrotation(n, pᵢ₊₁)

#     p = Quaternion([0; vec(pᵢ₊₁)]) * conj(Quaternion([0; vec(pᵢ)]))

#     p′ = Quaternion([vec(p)[1] + 1; vec(p)[2:4]])
#     Δᵢ = normalize(p′)

#     r = conj(qᵢ) * conj(Δᵢ) * qᵢ₊₁

#     θ = 2atan(vec(r)[2] / vec(r)[1])

#     r1 = normalize(_eyeposition - (dot(_eyeposition, v) / norm(v)) * v)

#     update(a_arrow, _lookat, normalize(ℝ³(vec(Δᵢ)[2:4]...)))
#     update(b_arrow, _lookat, normalize(ℝ³(vec(r)[2:4]...)))
#     update(c_arrow, _lookat, r1)

#     #θ = acos(dot(r1, normalize(ℝ³(vec(Δᵢ)[2:4]...))))
#     println(θ)
#     if GLMakie.to_value(toggle.active) 
#         h = Quaternion(π / 2, ℝ³(0, 1, 0)) * getrotation(n, v)
#     else
#         h = getrotation(n, v)
#     end
#     h #* Quaternion(θ / 2, normalize(v))
# end

textotation = GLMakie.@lift(GLMakie.Quaternion(-vec($rotation)[2], -vec($rotation)[3], -vec($rotation)[4], vec($rotation)[1]))

GLMakie.text!(GLMakie.Point3f(1, 0, 0), text = "a", color = :black, align = (:left, :baseline), textsize = textsize1, rotation = textotation, markerspace = :data)
GLMakie.text!(GLMakie.Point3f(0, 1, 0), text = "b", color = :black, align = (:left, :baseline), textsize = textsize1, rotation = textotation, markerspace = :data)
GLMakie.text!(GLMakie.Point3f(-1, 0, 0), text = "c", color = :black, align = (:left, :baseline), rotation = textotation, textsize = textsize1, markerspace = :data)
GLMakie.text!(GLMakie.Point3f(0, -1, 0), text = "d", color = :black, align = (:left, :baseline), rotation = textotation, textsize = textsize1, markerspace = :data)

GLMakie.text!(lscene,
              GLMakie.@lift(GLMakie.Point3f(vec(ℝ³($(x_arrow.tailobservable)[1].data...) + ℝ³($(x_arrow.headobservable)[1].data...)))),
              text = "1",
              color = :red,
              align = (:left, :baseline),
              textsize = textsize1,
              rotation = textotation,
              markerspace = :data)
GLMakie.text!(lscene,
              GLMakie.@lift(GLMakie.Point3f(vec(ℝ³($(y_arrow.tailobservable)[1].data...) + ℝ³($(y_arrow.headobservable)[1].data...)))),
              text = "2",
              color = :green,
              align = (:left, :baseline),
              textsize = textsize1,
              rotation = textotation,
              markerspace = :data)
GLMakie.text!(lscene,
              GLMakie.@lift(GLMakie.Point3f(vec(ℝ³($(z_arrow.tailobservable)[1].data...) + ℝ³($(z_arrow.headobservable)[1].data...)))),
              text = "3",
              color = :blue,
              align = (:left, :baseline),
              textsize = textsize1,
              rotation = textotation,
              markerspace = :data)

pathpoints = 720
uppathpoints = 720
pathobservable = GLMakie.Observable([ℝ³(0, 0, 1) for i in 1:pathpoints])
uppath = GLMakie.Observable([ℝ³(0, 0, 1.5) for i in 1:uppathpoints])
xs = GLMakie.@lift([vec(($pathobservable)[i])[1] for i in 1:pathpoints])
ys = GLMakie.@lift([vec(($pathobservable)[i])[2] for i in 1:pathpoints])
zs = GLMakie.@lift([vec(($pathobservable)[i])[3] for i in 1:pathpoints])
pathcolor = [GLMakie.RGBAf(hsvtorgb([(i - 1) / pathpoints * 360, 1.0, 1.0])..., 1.0) for i in 1:pathpoints]
uppathcolor = [GLMakie.RGBAf(hsvtorgb([(i - 1) / uppathpoints * 360, 1.0, 1.0])..., 1.0) for i in 1:uppathpoints]
GLMakie.linesegments!(lscene, xs, ys, zs, linewidth = 10, linestyle = :dot, color = pathcolor)
upxs = GLMakie.@lift([vec(i)[1] for i in $uppath])
upys = GLMakie.@lift([vec(i)[2] for i in $uppath])
upzs = GLMakie.@lift([vec(i)[3] for i in $uppath])
GLMakie.linesegments!(lscene, upxs, upys, upzs, linewidth = 10, linestyle = :dot, color = uppathcolor)

image = GLMakie.load("gallery/plane.png")
surf(tail, xhead, yhead) = begin
    x, y = 0.15 * xhead, 0.15 * yhead
    p = Array{ℝ³}(undef, 2, 2)
    p[1, 1] = normalize(x + y + ℝ³((1e-5 .* rand(3))...)) + tail
    p[1, 2] = normalize(-x + y + ℝ³((1e-5 .* rand(3))...)) + tail
    p[2, 1] = normalize(x - y + ℝ³((1e-5 .* rand(3))...)) + tail
    p[2, 2] = normalize(-x - y + ℝ³((1e-5 .* rand(3))...)) + tail
    p
end
surfacepoints = GLMakie.@lift(surf(ℝ³($(x_arrow.tailobservable)[1].data...), ℝ³($(x_arrow.headobservable)[1].data...), ℝ³($(y_arrow.headobservable)[1].data...)))
GLMakie.surface!(lscene, GLMakie.@lift(map(x -> x.a[1], $surfacepoints)), GLMakie.@lift(map(x -> x.a[2], $surfacepoints)), GLMakie.@lift(map(x -> x.a[3], $surfacepoints)), color = image, transparency = true)


##### construct the Hopf fibration

point = GLMakie.to_value(p₁)
point = Geographic(ℝ³(point[1], point[2], Φ(point)))
radius = 0.2
points = [Geographic(1, radius * cos(α) + point.ϕ, radius * sin(α) + point.θ) for α in range(0, stop = 2π, length = segments1)]
points1 = map(x -> σmap(x), points)
configuration = Biquaternion(GLMakie.to_value(rotation), 2 * ℝ³(GLMakie.to_value(p₁)..., Φ(GLMakie.to_value(p₁))))
colorref = FileIO.load("data/basemap_color.png")
solidcolor = getcolor(points, colorref, 1.0)
ghostcolor = getcolor(points, colorref, 0.1)
solidtop = U1(0)
solidbottom = U1(GLMakie.to_value(cumulativetwist))
ghosttop = solidbottom
ghostbottom = U1(2π)
solidgauge1 = [solidtop for i in 1:segments1]
solidgauge2 = [solidbottom for i in 1:segments1]
ghostgauge1 = [ghosttop for i in 1:segments1]
ghostgauge2 = [ghostbottom for i in 1:segments1]
scale = 1.0
solidwhirlsprites = [Whirl(lscene, points1, solidgauge1, solidgauge2, configuration = configuration, segments = segments, color = solidcolor, transparency = false, scale = scale) for i in 1:ghostsnumber]
ghostwhirlsprites = [Whirl(lscene, points1, ghostgauge1, ghostgauge2, configuration = configuration, segments = segments, color = ghostcolor, transparency = true, scale = scale) for i in 1:ghostsnumber]
colortransparent = FileIO.load("data/basemap_mask1.png")
framesprites = [Frame(lscene, σmap, colortransparent, configuration = configuration, segments = 4segments, transparency = true, scale = scale) for i in 1:ghostsnumber]

#####

# sl_ϕ = GLMakie.Slider(fig[1:end, 2], range = float(-π):0.01:float(π), startvalue = 0)
# sl_θ = GLMakie.Slider(fig[1:end, 3], range = float(-π / 2):0.01:float(π / 2), startvalue = 0)
# sl_α = GLMakie.Slider(fig[1:end, 4], range = 0:0.01:float(2π), startvalue = 0)


# fig[6, 1:2] = buttongrid = GLMakie.GridLayout(tellwidth = false)
# crossbutton = GLMakie.Button(fig, label = "Cross the boundary")
# buttongrid[1, 1:2] = [crossbutton, markbutton]

n_ax = GLMakie.Axis(fig[1:2, 3], title = "Disk N")
s_ax = GLMakie.Axis(fig[5:6, 3], title = "Disk S")
n_ax.aspect = 1
s_ax.aspect = 1
GLMakie.xlims!(n_ax, [-1.4, 1.4])
GLMakie.ylims!(n_ax, [-1.4, 1.4])
GLMakie.xlims!(s_ax, [-1.4, 1.4])
GLMakie.ylims!(s_ax, [-1.4, 1.4])

GLMakie.poly!(n_ax.scene, GeometryBasics.Circle(GLMakie.Point2f(0, 0), 1f0), strokecolor = "black", strokewidth = 2, color = :pink)
GLMakie.poly!(s_ax.scene, GeometryBasics.Circle(GLMakie.Point2f(0, 0), 1f0), strokecolor = "black", strokewidth = 2, color = :yellow)

GLMakie.text!(n_ax.scene, 1, 0, text = "a", align = (:center, :center), textsize = textsize)
GLMakie.text!(n_ax.scene, 0, 1, text = "b", align = (:center, :center), textsize = textsize)
GLMakie.text!(n_ax.scene, -1, 0, text = "c", align = (:center, :center), textsize = textsize)
GLMakie.text!(n_ax.scene, 0, -1, text = "d", align = (:center, :center), textsize = textsize)

GLMakie.text!(s_ax.scene, 1, 0, text = "a", align = (:center, :center), textsize = textsize)
GLMakie.text!(s_ax.scene, 0, 1, text = "b", align = (:center, :center), textsize = textsize)
GLMakie.text!(s_ax.scene, -1, 0, text = "c", align = (:center, :center), textsize = textsize)
GLMakie.text!(s_ax.scene, 0, -1, text = "d", align = (:center, :center), textsize = textsize)

n_xs = GLMakie.Observable([0.0; 0.0])
n_ys = GLMakie.Observable([0.0; 0.0])
n_us = GLMakie.Observable([0.3; 0.0])
n_vs = GLMakie.Observable([0.0; 0.3])
s_xs = GLMakie.Observable([10.0; 10.0])
s_ys = GLMakie.Observable([10.0; 10.0])
s_us = GLMakie.Observable([0.3; 0.0])
s_vs = GLMakie.Observable([0.0; 0.3])
n_colors = GLMakie.Observable([:red; :green])
s_colors = GLMakie.Observable([:red; :green])
GLMakie.arrows!(n_ax.scene, n_xs, n_ys, n_us, n_vs, arrowsize = 30, linewidth = 5, lengthscale = 1.0, arrowcolor = n_colors, linecolor = n_colors)
GLMakie.arrows!(s_ax.scene, s_xs, s_ys, s_us, s_vs, arrowsize = 30, linewidth = 5, lengthscale = 1.0, arrowcolor = s_colors, linecolor = s_colors)
GLMakie.text!(n_ax.scene, GLMakie.@lift(($n_xs)[1] + ($n_us)[1] + 0.1 * sign(($n_xs)[1] + ($n_us)[1])), GLMakie.@lift(($n_ys)[1] + ($n_vs)[1] + 0.1 * sign(($n_ys)[1] + ($n_vs)[1])), text = "1", color = :red, align = (:center, :center), textsize = textsize)
GLMakie.text!(n_ax.scene, GLMakie.@lift(($n_xs)[2] + ($n_us)[2] + 0.1 * sign(($n_xs)[2] + ($n_us)[2])), GLMakie.@lift(($n_ys)[2] + ($n_vs)[2] + 0.1 * sign(($n_ys)[2] + ($n_vs)[2])), text = "2", color = :green, align = (:center, :center), textsize = textsize)
GLMakie.text!(s_ax.scene, GLMakie.@lift(($s_xs)[1] + ($s_us)[1] + 0.1 * sign(($s_xs)[1] + ($s_us)[1])), GLMakie.@lift(($s_ys)[1] + ($s_vs)[1] + 0.1 * sign(($s_ys)[1] + ($s_vs)[1])), text = "1", color = :red, align = (:center, :center), textsize = textsize)
GLMakie.text!(s_ax.scene, GLMakie.@lift(($s_xs)[2] + ($s_us)[2] + 0.1 * sign(($s_xs)[2] + ($s_us)[2])), GLMakie.@lift(($s_ys)[2] + ($s_vs)[2] + 0.1 * sign(($s_ys)[2] + ($s_vs)[2])), text = "2", color = :green, align = (:center, :center), textsize = textsize)

n_pathobservable = GLMakie.Observable([ℝ³(0, 0, 1) for i in 1:pathpoints])
s_pathobservable = GLMakie.Observable([ℝ³(0, 0, 1) for i in 1:pathpoints])
n_chartpathxs = GLMakie.@lift([vec(($n_pathobservable)[i])[1] for i in 1:pathpoints])
n_chartpathys = GLMakie.@lift([vec(($n_pathobservable)[i])[2] for i in 1:pathpoints])
s_chartpathxs = GLMakie.@lift([vec(($s_pathobservable)[i])[1] for i in 1:pathpoints])
s_chartpathys = GLMakie.@lift([vec(($s_pathobservable)[i])[2] for i in 1:pathpoints])
GLMakie.linesegments!(n_ax, n_chartpathxs, n_chartpathys, linewidth = 10, linestyle = :dot, color = pathcolor)
GLMakie.linesegments!(s_ax, s_chartpathxs, s_chartpathys, linewidth = 10, linestyle = :dot, color = pathcolor)

sl_nx = GLMakie.Slider(fig[3, 3], range = -1:0.0001:1, startvalue = 0)
sl_ny = GLMakie.Slider(fig[1:2, 4], range = -1:0.0001:1, horizontal = false, startvalue = 0)

sl_sx = GLMakie.Slider(fig[7, 3], range = -1:0.0001:1, startvalue = 0)
sl_sy = GLMakie.Slider(fig[5:6, 4], range = -1:0.0001:1, horizontal = false, startvalue = 0)

# ϕ₀ = GLMakie.Observable(0.0)
# θ₀ = GLMakie.Observable(0.0)
# ϕ₁ = GLMakie.Observable(0.0)
# θ₁ = GLMakie.Observable(0.0)

q1 = Biquaternion(ℝ³(0, 0, 1))
radius = 0.05
color = GLMakie.RGBAf(0, 0, 0, 1.0)
transparency = false
markersphere = Sphere(q1,
                      lscene,
                      radius = radius,
                      segments = segments,
                      color = color,
                      transparency = transparency)


q1 = Biquaternion(ℝ³(0, 0, 0))
r = 0.02
R = 1.0
color = GLMakie.RGBAf(0, 0, 0, 1.0)
transparency = true
torus = Torus(q1,
              lscene,
              r = r,
              R = R,
              segments = segments,
              color = color,
              transparency = transparency)


#snapthreshold = 0.02
snapthreshold = 0.0

updatep(p) = begin
    point₀ = GLMakie.to_value(p₁)
    point₁ = p
    threshold = 1e-8
    if isapprox(point₀[1], point₁[1], atol = threshold) && isapprox(point₀[2], point₁[2], atol = threshold)
        return
    end
    point = ℝ³(point₁[1], point₁[2], Φ(point₁))
    dummy = Geographic(Cartesian(point))
    if isapprox(dummy.θ, -π / 2)
        point = ℝ³(Cartesian(Geographic(dummy.r, dummy.ϕ, dummy.θ * 0.99)))
    end
    point₁ = vec(point)[1:2]
    p₀[] = point₀
    p₁[] = point₁
    
    path = GLMakie.to_value(pathobservable)
    if pathinitialized
        path = [point * 1.02; path[1:end-1]]
    else
        path = [point * 1.02 for i in 1:pathpoints]
        global pathinitialized = true
    end
    pathobservable[] = path
    
    if GLMakie.to_value(toggle.active)

        s_path = GLMakie.to_value(s_pathobservable)
        s_path = [point; s_path[1:end-1]]
        s_pathobservable[] = s_path

        n_path = GLMakie.to_value(n_pathobservable)
        n_path = [n_path[1]; n_path[1:end-1]]
        n_pathobservable[] = n_path
    else

        n_path = GLMakie.to_value(n_pathobservable)
        n_path = [point; n_path[1:end-1]]
        n_pathobservable[] = n_path

        s_path = GLMakie.to_value(s_pathobservable)
        s_path = [s_path[1]; s_path[1:end-1]]
        s_pathobservable[] = s_path
    end

    ẑ = ℝ³(0, 0, 1)

    pᵢ = ℝ³(point₀[1], point₀[2], Φ(point₀))
    pᵢ₊₁ = ℝ³(point₁[1], point₁[2], Φ(point₁))

    qᵢ = getrotation(Quaternion(ẑ), Quaternion(pᵢ))
    qᵢ₊₁ = getrotation(Quaternion(ẑ), Quaternion(pᵢ₊₁))

    p = getrotation(Quaternion(pᵢ), Quaternion(pᵢ₊₁))
    p′ = Quaternion([vec(p)[1] + 1; vec(p)[2:4]])
    Δᵢ = normalize(p′)

    r = conj(qᵢ) * conj(Δᵢ) * qᵢ₊₁
    θ = 2atan(vec(r)[4] / vec(r)[1])
    θ = GLMakie.to_value(cumulativetwist) + θ
    θ = θ % 2π
    cumulativetwist[] = θ
    println(θ)
    
    h = getrotation(Quaternion(ẑ), Quaternion(pᵢ₊₁))
    r′ = Quaternion(-θ / 2, ẑ)
    h′ = h * r′
    update(a_arrow, pᵢ₊₁, rotate(ℝ³(1, 0, 0), h′))
    update(b_arrow, pᵢ₊₁, rotate(ℝ³(0, 1, 0), h′))
    update(c_arrow, pᵢ₊₁, rotate(ℝ³(0, 0, 1), h′))

    θ₀ = π / 2 + π / 4
    r′ = Quaternion(-(θ + θ₀) / 2, ẑ)
    h′ = h * r′
    rotation[] = h′

    configuration = Biquaternion(h′, 2 * pᵢ₊₁)

    point = Geographic(Cartesian(pᵢ₊₁))
    inside = false
    index = 1
    for (i, boundary) in enumerate(countries["nodes"])
        index = i
        ϕ = sum(map(x -> x.ϕ, boundary)) / length(boundary)
        θ = sum(map(x -> x.θ, boundary))  / length(boundary)
        isnear = abs(ϕ - point.ϕ) < π / 6 && abs(θ - point.θ) < π / 6
        inside = isinside(point, boundary)
        if inside && isnear
            break
        end
    end
    if inside
        points = countries["nodes"][index]
        indices = Int.(floor.(collect(range(1, stop = segments1, length = segments1))))
        points = points[indices]
    else
        points = [Geographic(1, radius * cos(α) + point.ϕ, radius * sin(α) + point.θ) for α in range(0, stop = 2π, length = segments1)]
    end

    # modify points in order to avoid the South Pole
    _points = []
    for item in points
        if isapprox(item.θ, -π / 2)
            _item = deepcopy(item)
            _points = [Geographic(_item.r, _item.ϕ, 0.99 * _item.θ); _points]
        else
            _item = deepcopy(item)
            _points = [_item; _points]
        end
    end
    points = deepcopy(_points)
    points = convert(Array{Geographic,1}, points)

    points1 = map(w -> σmap(w), points)
    points1 = convert(Array{ComplexPlane,1}, points1)

    g = transformg(σmap(point), U1(0), U1(2π), segments1)
    θ = GLMakie.to_value(cumulativetwist)
    index = min(segments1, Int(floor(abs(θ / 2π * segments1))) + 1)
    gauge = [g[index] for i in 1:segments1]

    # shidt the animation for one sprite to the past before updating the current sprite
    # but only properties related to the internal dimensions (i.e. not configuration)
    for i in 2:ghostsnumber
        update(solidwhirlsprites[i], solidwhirlsprites[i - 1].points, solidwhirlsprites[i - 1].gauge1, solidwhirlsprites[i - 1].gauge2, configuration)
        update(ghostwhirlsprites[i], ghostwhirlsprites[i - 1].points, ghostwhirlsprites[i - 1].gauge1, ghostwhirlsprites[i - 1].gauge2, configuration)
    end

    if θ ≥ 0
        update(solidwhirlsprites[1], points1, solidgauge1, gauge, configuration)
        update(ghostwhirlsprites[1], points1, gauge, ghostgauge2, configuration)
    else
        index = segments1 + 1 - index
        gauge = [g[index] for i in 1:segments1]

        update(solidwhirlsprites[1], points1, gauge, ghostgauge2, configuration)
        update(ghostwhirlsprites[1], points1, solidgauge1, gauge, configuration)
    end

    gauges[] = gauge
    # keep track of previous group actions for animating a trail of frames
    _groupactions = GLMakie.to_value(groupactions)
    _groupactions = [gauge[1]; _groupactions[1:end-1]]
    groupactions[] = _groupactions

    solidcolor = getcolor(points, colorref, 1.0)
    ghostcolor = getcolor(points, colorref, 0.25)
    if isapprox(solidcolor.r, 1) && isapprox(solidcolor.g, 1) && isapprox(solidcolor.b, 1) && isapprox(solidcolor.alpha, 1)
        if GLMakie.to_value(toggle.active)
            solidcolor = GLMakie.RGBA{FixedPointNumbers.Normed{UInt8, 8}}(1.0, 1.0, 0.0, 1.0)
            ghostcolor = GLMakie.RGBA{FixedPointNumbers.Normed{UInt8, 8}}(1.0, 1.0, 0.0, 0.5)
        else
            solidcolor = GLMakie.RGBA{FixedPointNumbers.Normed{UInt8, 8}}(1.0, 0.0, 1.0, 1.0)
            ghostcolor = GLMakie.RGBA{FixedPointNumbers.Normed{UInt8, 8}}(1.0, 0.0, 1.0, 0.5)
        end
    end
    for i in 2:ghostsnumber
        update(solidwhirlsprites[i], GLMakie.to_value(solidwhirlsprites[i - 1].color)[1])
        update(ghostwhirlsprites[i], GLMakie.to_value(ghostwhirlsprites[i - 1].color)[1])
    end
    update(solidwhirlsprites[1], solidcolor)
    update(ghostwhirlsprites[1], ghostcolor)
    for i in 1:ghostsnumber
        update(framesprites[i], x -> S¹action(σmap(x), _groupactions[i]), configuration)
    end
    
    path = GLMakie.to_value(pathobservable)
    liftedpath = map(x -> compressedλmap(S¹action(σmap(Geographic(Cartesian(x))), gauge[1])), path)
    # if uppathinitialized
    #     _uppath = [point1; _uppath[1:end-1]]
    # else
    #     _uppath = [point1 for i in 1:uppathpoints]
    #     global uppathinitialized = true
    # end
    uppath[] = applyconfig(liftedpath, configuration)

    # chart controls
    n = ℝ³(0, 0, 1)
    x, y, z = vec(ℝ³(Cartesian(point)))
    if GLMakie.to_value(toggle.active)
        u = a_arrow.head - (dot(a_arrow.head, a_arrow.tail) / norm(n)) * n
        v = b_arrow.head - (dot(b_arrow.head, b_arrow.tail) / norm(n)) * n
        u.a[3] = 0.0
        v.a[3] = 0.0
        u = 0.3 * normalize(u)
        v = 0.3 * normalize(v)
        s_xs[] = [x; x]
        s_ys[] = [y; y]
        s_us[] = [u.a[1]; v.a[1]]
        s_vs[] = [u.a[2]; v.a[2]]

        # send the deactive frame to out of axis limits
        n_xs[] = [10.0; 10.0]
        n_ys[] = [10.0; 10.0]
        n_us[] = [11.0; 11.0]
        n_vs[] = [11.0; 11.0]
    else
        u = a_arrow.head - (dot(a_arrow.head, a_arrow.tail) / norm(n)) * n
        v = b_arrow.head - (dot(b_arrow.head, b_arrow.tail) / norm(n)) * n
        u.a[3] = 0.0
        v.a[3] = 0.0
        u = 0.3 * normalize(u)
        v = 0.3 * normalize(v)

        n_xs[] = [x; x]
        n_ys[] = [y; y]
        n_us[] = [u.a[1]; v.a[1]]
        n_vs[] = [u.a[2]; v.a[2]]

        # send the deactive frame to out of axis limits
        s_xs[] = [10.0; 10.0]
        s_ys[] = [10.0; 10.0]
        s_us[] = [11.0; 11.0]
        s_vs[] = [11.0; 11.0]
    end

    # camera controls
    _eyeposition = 2.0 * a_arrow.tail + 2.0 * a_arrow.head + 2.0 * b_arrow.head + c_arrow.head
    _lookat = a_arrow.tail
    _up = a_arrow.tail
    eyeposition[] = 0.95 * GLMakie.to_value(eyeposition) + 0.05 * _eyeposition
    lookat[] = 0.95 * GLMakie.to_value(lookat) + 0.05 * _lookat
    up[] = 0.95 * GLMakie.to_value(up) + 0.05 * _up
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(_eyeposition)...), GLMakie.Vec3f(vec(_lookat)...), GLMakie.Vec3f(vec(_up)...))
end

GLMakie.on(sl_nx.value) do nx
    if !GLMakie.to_value(controlstatus)
        return
    end
    chart = GLMakie.to_value(toggle.active)
    if chart
        return
    end
    x = nx
    y = GLMakie.to_value(sl_ny.value)
    r = √(x^2 + y^2)
    if r > 1 - snapthreshold
        x = √(1 - y^2) * sign(x)
    end
    p = [x; y]
    magnitude = √(p[1]^2 + p[2]^2)
    if magnitude > 1
        p = p ./ magnitude
    end
    updatep(p)
end

GLMakie.on(sl_ny.value) do ny
    if !GLMakie.to_value(controlstatus)
        return
    end
    chart = GLMakie.to_value(toggle.active)
    if chart
        return
    end
    x = GLMakie.to_value(sl_nx.value)
    y = ny
    r = √(x^2 + y^2)
    if r > 1 - snapthreshold
        y = √(1 - x^2) * sign(y)
    end
    p = [x; y]
    magnitude = √(p[1]^2 + p[2]^2)
    if magnitude > 1
        p = p ./ magnitude
    end
    updatep(p)
end

GLMakie.on(sl_sx.value) do sx
    if !GLMakie.to_value(controlstatus)
        return
    end
    chart = GLMakie.to_value(toggle.active)
    if !chart
        return
    end
    x = sx
    y = GLMakie.to_value(sl_sy.value)
    r = √(x^2 + y^2)
    if r > 1 - snapthreshold
        x = √(1 - y^2) * sign(x)
    end
    p = [x; y]
    magnitude = √(p[1]^2 + p[2]^2)
    if magnitude > 1
        p = p ./ magnitude
    end
    updatep(p)
end

GLMakie.on(sl_sy.value) do sy
    if !GLMakie.to_value(controlstatus)
        return
    end
    chart = GLMakie.to_value(toggle.active)
    if !chart
        return
    end
    x = GLMakie.to_value(sl_sx.value)
    y = sy
    r = √(x^2 + y^2)
    if r > 1 - snapthreshold
        y = √(1 - x^2) * sign(y)
    end
    p = [x; y]
    magnitude = √(p[1]^2 + p[2]^2)
    if magnitude > 1
        p = p ./ magnitude
    end
    
    updatep(p)
end

GLMakie.on(p₁) do p
    x, y = p
    z = Φ(p)
    point = normalize(ℝ³(x, y, z))
    q = Biquaternion(point)
    update(markersphere, q)

    tail = point
    xhead = GLMakie.to_value(x_arrow.head)
    perp = (dot(xhead, tail) / norm(tail)) * tail
    xhead = xhead - perp
    if !isapprox(norm(xhead), 0)
        xhead = 0.3 * normalize(xhead)
        update(x_arrow, tail, xhead)
    end
    
    yhead = GLMakie.to_value(y_arrow.head)
    perp = (dot(yhead, tail) / norm(tail)) * tail
    yhead = yhead - perp
    if !isapprox(norm(yhead), 0)
        yhead = 0.3 * normalize(yhead)
        update(y_arrow, tail, yhead)
    end

    zhead = tail * 0.3
    update(z_arrow, tail, zhead)

    xhead = normalize(xhead)
    yhead = normalize(yhead)

    # _eyeposition = 2 * tail + 2 * xhead + 2 * yhead + 6 * zhead
end

GLMakie.on(toggle.active) do chart
    p = GLMakie.to_value(p₁)
    x, y = p
    if chart
        s_xs[] = [x; x]
        s_ys[] = [y; y]
        n_xs[] = [10.0; 10.0]
        n_ys[] = [10.0; 10.0]
    else
        s_xs[] = [11.0; 11.0]
        s_ys[] = [11.0; 11.0]
        n_xs[] = [x; x]
        n_ys[] = [y; y]
    end
    controlstatus[] = false
    if !isapprox(GLMakie.to_value(sl_sx.value), x)
        GLMakie.set_close_to!(sl_sx, x)
    end
    if !isapprox(GLMakie.to_value(sl_sy.value), y)
        GLMakie.set_close_to!(sl_sy, y)
    end
    if !isapprox(GLMakie.to_value(sl_nx.value), x)
        GLMakie.set_close_to!(sl_nx, x)
    end
    if !isapprox(GLMakie.to_value(sl_ny.value), y)
        GLMakie.set_close_to!(sl_ny, y)
    end
    controlstatus[] = true
    p₁[] = GLMakie.to_value(p₁)
end

dummyarrows = []
GLMakie.on(markbutton.clicks) do n
    name = GLMakie.to_value(textbox.stored_string)
    if GLMakie.to_value(toggle.active)
        xs = GLMakie.to_value(s_xs)
        ys = GLMakie.to_value(s_ys)
        us = GLMakie.to_value(s_us)
        vs = GLMakie.to_value(s_vs)
        ax = s_ax
    else
        xs = GLMakie.to_value(n_xs)
        ys = GLMakie.to_value(n_ys)
        us = GLMakie.to_value(n_us)
        vs = GLMakie.to_value(n_vs)
        ax = n_ax
    end
    color = [GLMakie.RGBAf(255, 0, 0, 0.5); GLMakie.RGBAf(0, 255, 0, 0.5); GLMakie.RGBAf(0, 0, 255, 0.5)]
    GLMakie.arrows!(ax.scene, xs, ys, us, vs, arrowsize = 30, linewidth = 5, lengthscale = 1.0, arrowcolor = color[1:2], linecolor = color[1:2])
    GLMakie.text!(ax.scene, xs[1] + us[1] + 0.1 * sign(xs[1] + us[1]), ys[1] + vs[1] + 0.1 * sign(ys[1] + vs[1]), text = "$(name)₁", color = color[1], align = (:center, :center), textsize = textsize)
    GLMakie.text!(ax.scene, xs[2] + us[2] + 0.1 * sign(xs[2] + us[2]), ys[2] + vs[2] + 0.1 * sign(ys[2] + vs[2]), text = "$(name)₂", color = color[2], align = (:center, :center), textsize = textsize)

    p = GLMakie.to_value(p₁)
    x, y = p
    z = Φ(p)
    p = ℝ³(x, y, z)
    tail = x_arrow.tail
    head = x_arrow.head
    Arrow(tail, head, lscene.scene, width = width, color = color[1])
    head = y_arrow.head
    Arrow(tail, head, lscene.scene, width = width, color = color[2])
    head = z_arrow.head
    Arrow(tail, head, lscene.scene, width = width, color = color[3])
    GLMakie.text!(lscene,
                  GLMakie.Point3f(vec(ℝ³(GLMakie.to_value(x_arrow.tailobservable)[1].data...) + ℝ³(GLMakie.to_value(x_arrow.headobservable)[1].data...))),
                  text = "$(name)₁",
                  color = color[1],
                  align = (:left, :baseline),
                  textsize = textsize1,
                  rotation = textotation,
                  markerspace = :data)
    GLMakie.text!(lscene,
                  GLMakie.Point3f(vec(ℝ³(GLMakie.to_value(y_arrow.tailobservable)[1].data...) + ℝ³(GLMakie.to_value(y_arrow.headobservable)[1].data...))),
                  text = "$(name)₂",
                  color = color[2],
                  align = (:left, :baseline),
                  textsize = textsize1,
                  rotation = textotation,
                  markerspace = :data)
    GLMakie.text!(lscene,
                  GLMakie.Point3f(vec(ℝ³(GLMakie.to_value(z_arrow.tailobservable)[1].data...) + ℝ³(GLMakie.to_value(z_arrow.headobservable)[1].data...))),
                  text = "$(name)₃",
                  color = color[3],
                  align = (:left, :baseline),
                  textsize = textsize1,
                  rotation = textotation,
                  markerspace = :data)
    p₁[] = GLMakie.to_value(p₁)
end

GLMakie.on(resetbutton.clicks) do n
    toggle.active[] = false
    x, y = 0.0, 0.0
    GLMakie.set_close_to!(sl_nx, x)
    GLMakie.set_close_to!(sl_ny, y)
    GLMakie.set_close_to!(sl_sx, x)
    GLMakie.set_close_to!(sl_sy, y)
    s_xs[] = [x; x]
    s_ys[] = [y; y]
    n_xs[] = [x; x]
    n_ys[] = [y; y]
    n_us[] = [0.3; 0.0]
    n_vs[] = [0.0; 0.3]
    s_us[] = [0.3; 0.0]
    s_vs[] = [0.0; 0.3]

    tail = ℝ³(0, 0, 1)
    update(x_arrow, tail, ℝ³(0.3, 0, 0))
    update(y_arrow, tail, ℝ³(0, 0.3, 0))
    update(z_arrow, tail, ℝ³(0, 0, 0.3))
    pathobservable[] = [ℝ³(0, 0, 1) for i in 1:pathpoints]
    uppath[] = [ℝ³(0, 0, 1.5) for i in 1:uppathpoints]
    global pathinitialized = false
    global uppathinitialized = false
    p₁[] = GLMakie.to_value(p₁)
    cumulativetwist[] = 0.0
    update(a_arrow, tail, ℝ³(1, 0, 0))
    update(b_arrow, tail, ℝ³(0, 1, 0))
    update(c_arrow, tail, ℝ³(0, 0, 1))
end

# GLMakie.on(sl_θ.value) do θ
#     θ₀[] = GLMakie.to_value(θ₁)
#     θ₁[] = θ
#     q = Biquaternion(ℝ³(Cartesian(Geographic(1.0, GLMakie.to_value(ϕ₁), θ))))
#     update(markersphere, q)
# end

# point = lift(sl_x.value, sl_y.value) do x, y
#     Point2f(x, y)
# end

# scatter!(point, color = :red, markersize = 20)

# limits!(ax, -5, 5, -5, 5)

# fps = 10
# GLMakie.record(lscene.scene, "test.mp4"; framerate = fps) do io
#     for i = 1:1000
#         sleep(1/fps)
#         GLMakie.recordframe!(io)
#     end
# end

fig

frames = 7200
totalpath = getbutterflycurve(frames)
firstpoint = totalpath[1]
firstpoint = Geographic(firstpoint)
initialpoint = Geographic(Cartesian(ℝ³(0, 0, 1)))
N = 45
for i in 1:N
    r, ϕ, θ = vec(firstpoint)
    r₀, ϕ₀, θ₀ = vec(initialpoint)
    η = i / N
    ϕ′ = η * ϕ + (1 - η) * ϕ₀
    θ′ = η * θ + (1 - η) * θ₀
    point′ = Geographic(1, ϕ′, θ′)
    x, y, z = vec(ℝ³(Cartesian(point′)))
    chart = GLMakie.to_value(toggle.active)
    if point′.θ < 0 && !chart
        toggle.active[] = true
    end
    if point′.θ ≥ 0 && chart
        toggle.active[] = false
    end
    if chart
        GLMakie.set_close_to!(sl_sx, x)
        GLMakie.set_close_to!(sl_sy, y)
    else
        GLMakie.set_close_to!(sl_nx, x)
        GLMakie.set_close_to!(sl_ny, y)
    end
end


FPS = 60
startframe = 1
modelname = "holonomy5"

animate(i) = begin
    point = Geographic(totalpath[i])
    chart = GLMakie.to_value(toggle.active)
    if point.θ < 0 && !chart
        toggle.active[] = true
    end
    if point.θ ≥ 0 && chart
        toggle.active[] = false
    end

    x, y, z = vec(ℝ³(Cartesian(point)))
    if chart
        GLMakie.set_close_to!(sl_sx, x)
        GLMakie.set_close_to!(sl_sy, y)
    else
        GLMakie.set_close_to!(sl_nx, x)
        GLMakie.set_close_to!(sl_ny, y)
    end
end


exportmode = ["gif", "frames", "video"]
exportmode = exportmode[2]


if exportmode ∈ ["gif", "video"]
    outputextension = exportmode == "gif" ? "gif" : "mkv"
    Makie.record(scene, "gallery/$modelname.$outputextension",
                            framerate = FPS) do io
        for i in startframe:frames
            animate(i) # animate the scene
            Makie.recordframe!(io) # record a new frame
            step = (i - 1) / frames
            println("Completed step $(100step).\n")
        end
    end
elseif exportmode == "frames"
    directory = joinpath("gallery", modelname)
    !isdir(directory) && mkdir(directory)
    for i in startframe:frames
        start = time()
        animate(i) # animate the scene
        elapsed = round(time() - start, digits = 4)
        sleep(0.1)
        println("Generating frame $i took $elapsed (s).")
        sleep(0.1)

        start = time()

        paddingnumber = length(digits(frames))
        imageid = lpad(i, paddingnumber, "0")
        imagename = "$(modelname)_$(resolution[2])p_$(FPS)fps_$imageid.jpeg"
        filepath = joinpath(directory, imagename)
        GLMakie.set_window_config!(pause_renderloop=true)
        # FileIO.save(filepath, Makie.colorbuffer(screen), resolution = resolution, pt_per_unit = 400.0, px_per_unit = 400.0)
        FileIO.save(filepath, Makie.colorbuffer(screen))
        GLMakie.set_window_config!(pause_renderloop=false)
        # GLMakie.save(joinpath(diskndir, "diskn_$(resolution[2])p_$(FPS)fps_$imageid.jpeg"), n_ax.scene; resolution = (2160, 2160), pt_per_unit = 400.0, px_per_unit = 400.0, Makie.colorbuffer(screen))
        # GLMakie.save(joinpath(disksdir, "disks_$(resolution[2])p_$(FPS)fps_$imageid.jpeg"), s_ax.scene; resolution = (2160, 2160), pt_per_unit = 400.0, px_per_unit = 400.0, Makie.colorbuffer(screen))
        # GLMakie.set_window_config!(pause_rendering=false)

        elapsed = round(time() - start, digits = 4)
        sleep(0.1)
        println("Saving file $filepath took $elapsed (s).")
        sleep(0.1)

        step = round((i - 1) / frames, digits = 4)
        sleep(0.1)
        println("Completed step $(100step).\n")
        sleep(0.1)

        stitch() = begin
            part = i
            exportdir = joinpath(directory, "export")
            !isdir(exportdir) && mkdir(exportdir)
            WxH = "$(resolution[1])x$(resolution[2])"
            WxH = "1920x1080"
            commonpart = "$(modelname)_$(resolution[2])p_$(FPS)fps"
            inputname = "$(commonpart)_%0$(paddingnumber)d.jpeg"
            inputpath = joinpath(directory, inputname)
            outputname = "$(commonpart)_$(part).mp4"
            outputpath = joinpath(exportdir, outputname)
            command1 = `ffmpeg -y -f image2 -framerate $FPS -i $inputpath -s $WxH -pix_fmt yuvj420p $outputpath`
            run(command1)
        end

        if i == frames
            sleep(1)
            stitch()
            sleep(1)
        end
        # break
    end
end