import GeometryBasics
import GLMakie

using Porta


controlstatus = GLMakie.Observable(true)
cumulativetwist = GLMakie.Observable(0.0)

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

fig = GLMakie.Figure()

pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.2, 0.2, 0.2))
lscene = GLMakie.LScene(fig[1:7, 1:2], show_axis=true, scenekw = (lights = [pl, al], backgroundcolor=:white, clear=true))

q1 = Biquaternion(ℝ³(0, 0, 0))
radius = 1.0
segments = 30
color = GLMakie.RGBAf(255, 0, 255, 0.25)
transparency = true
n_hemisphere = Hemisphere(q1,
                          lscene,
                          radius = radius,
                          segments = segments,
                          color = color,
                          transparency = transparency)

q1 = Biquaternion(Quaternion(π / 2, ℝ³(1, 0, 0)), ℝ³(0, 0, 0))
color = GLMakie.RGBAf(255, 255, 0, 0.25)
s_hemisphere = Hemisphere(q1,
                          lscene,
                          radius = radius,
                          segments = segments,
                          color = color,
                          transparency = transparency)

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
eyeposition = GLMakie.Observable(ℝ³(1, 1, 1))
lookat = GLMakie.Observable(ℝ³(0, 1, 0))
up = GLMakie.Observable(ℝ³(0, 0, 1))
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(GLMakie.to_value(eyeposition))...), GLMakie.Vec3f(vec(GLMakie.to_value(lookat))...), GLMakie.Vec3f(vec(GLMakie.to_value(up))...))

width = 0.05
transparency = false
color = GLMakie.RGBA(255.0, 0.0, 0.0, 1.0)
tail, head = ℝ³(0, 0, 1), ℝ³(0.3, 0, 0)
x_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBA(0.0, 255.0, 0.0, 1.0)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0.3, 0)
y_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBA(0.0, 0.0, 255.0, 1.0)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0, 0.3)
z_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)

color = GLMakie.RGBA(10.0, 1.0, 1.0, 0.5)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0, 0.3)
a_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBA(1.0, 10.0, 1.0, 0.5)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0, 0.3)
b_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBA(1.0, 1.0, 10.0, 0.5)
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
toggle = GLMakie.Toggle(fig, active = false)
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

pathpoints = 180
pathobservable = GLMakie.Observable([ℝ³(0, 0, 1) for i in 1:pathpoints])
xs = GLMakie.@lift([vec(($pathobservable)[i])[1] for i in 1:pathpoints])
ys = GLMakie.@lift([vec(($pathobservable)[i])[2] for i in 1:pathpoints])
zs = GLMakie.@lift([vec(($pathobservable)[i])[3] for i in 1:pathpoints])
pathcolor = [GLMakie.RGBAf(hsvtorgb([(i - 1) / pathpoints * 360, 1.0, 1.0])..., 1.0) for i in 1:pathpoints]
GLMakie.linesegments!(lscene, xs, ys, zs, linewidth = 10, linestyle = :dot, color = pathcolor)

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

p₀ = GLMakie.Observable([0.0; 0.0])
p₁ = GLMakie.Observable([0.0; 0.0])
sl_nx = GLMakie.Slider(fig[3, 3], range = -1:0.00001:1, startvalue = 0)
sl_ny = GLMakie.Slider(fig[1:2, 4], range = -1:0.00001:1, horizontal = false, startvalue = 0)

sl_sx = GLMakie.Slider(fig[7, 3], range = -1:0.00001:1, startvalue = 0)
sl_sy = GLMakie.Slider(fig[5:6, 4], range = -1:0.00001:1, horizontal = false, startvalue = 0)

# ϕ₀ = GLMakie.Observable(0.0)
# θ₀ = GLMakie.Observable(0.0)
# ϕ₁ = GLMakie.Observable(0.0)
# θ₁ = GLMakie.Observable(0.0)

q1 = Biquaternion(ℝ³(0, 0, 1))
radius = 0.05
segments = 30
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
segments = 30
color = GLMakie.RGBAf(0, 0, 0, 1.0)
transparency = true
torus = Torus(q1,
              lscene,
              r = r,
              R = R,
              segments = segments,
              color = color,
              transparency = transparency)


snapthreshold = 0.02

updatep(p) = begin
    point₀ = GLMakie.to_value(p₁)
    point₁ = p
    threshold = 1e-8
    if isapprox(point₀[1], point₁[1], atol = threshold) && isapprox(point₀[2], point₁[2], atol = threshold)
        return
    end
    p₀[] = point₀
    p₁[] = point₁
    x, y = point₁
    point = ℝ³(x, y, Φ(point₁))

    if GLMakie.to_value(toggle.active)
        path = GLMakie.to_value(pathobservable)
        path = [point; path[1:end-1]]
        pathobservable[] = path

        s_path = GLMakie.to_value(s_pathobservable)
        s_path = [point; s_path[1:end-1]]
        s_pathobservable[] = s_path

        n_path = GLMakie.to_value(n_pathobservable)
        n_path = [n_path[1]; n_path[1:end-1]]
        n_pathobservable[] = n_path
    else
        path = GLMakie.to_value(pathobservable)
        path = [point; path[1:end-1]]
        pathobservable[] = path

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

    qᵢ = getrotation(ẑ, pᵢ)
    qᵢ₊₁ = getrotation(ẑ, pᵢ₊₁)
    # qᵢ = Quaternion([0; vec(ẑ)]) * conj(Quaternion([0; vec(pᵢ)]))
    # qᵢ₊₁ = Quaternion([0; vec(ẑ)]) * conj(Quaternion([0; vec(pᵢ₊₁)]))

    # p = Quaternion([0; vec(pᵢ)]) * conj(Quaternion([0; vec(pᵢ₊₁)]))
    p = getrotation(pᵢ, pᵢ₊₁)

    p′ = Quaternion([vec(p)[1] + 1; vec(p)[2:4]])
    Δᵢ = normalize(p′)

    r = conj(qᵢ) * conj(Δᵢ) * qᵢ₊₁

    θ = 2atan(vec(r)[4] / vec(r)[1])
    θ = θ / 2

    θ = GLMakie.to_value(cumulativetwist) + θ
    cumulativetwist[] = θ % 2π
    println(θ)
    
    if GLMakie.to_value(toggle.active) 
        h = Quaternion(π, ℝ³(0, 1, 0)) * conj(getrotation(ẑ, pᵢ₊₁))
        r′ = Quaternion(θ, pᵢ₊₁)
        h′ = conj(h * r′)
        rotation[] = h′
    else
        h = conj(getrotation(ẑ, pᵢ₊₁))
        r′ = Quaternion(θ, pᵢ₊₁)
        h′ = conj(h * r′)
        rotation[] = h′
    end

    update(a_arrow, pᵢ₊₁, rotate(ℝ³(1, 0, 0), h′))
    update(b_arrow, pᵢ₊₁, rotate(ℝ³(0, 1, 0), h′))
    update(c_arrow, pᵢ₊₁, rotate(ℝ³(0, 0, 1), h′))

    # if GLMakie.to_value(toggle.active) 
    #     update(a_arrow, -v, rotate(ℝ³(1, 0, 0), conj(h′)))
    #     update(b_arrow, -v, rotate(ℝ³(0, 1, 0), conj(h′)))
    #     update(c_arrow, -v, rotate(ℝ³(0, 0, 1), conj(h′)))
    # else
    #     update(a_arrow, v, rotate(ℝ³(1, 0, 0), conj(h′)))
    #     update(b_arrow, v, rotate(ℝ³(0, 1, 0), conj(h′)))
    #     update(c_arrow, v, rotate(ℝ³(0, 0, 1), conj(h′)))
    # end
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

    n = ℝ³(0, 0, 1)

    if GLMakie.to_value(toggle.active)
        u = xhead - (dot(xhead, tail) / norm(n)) * n
        v = yhead - (dot(yhead, tail) / norm(n)) * n
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
        u = xhead - (dot(xhead, tail) / norm(n)) * n
        v = yhead - (dot(yhead, tail) / norm(n)) * n
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

    _eyeposition = 2 * tail + 2 * xhead + 2 * yhead + 4 * zhead
    _lookat = tail
    _up = tail
    eyeposition[] = _eyeposition
    lookat[] = _lookat
    up[] = _up
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(_eyeposition)...), GLMakie.Vec3f(vec(_lookat)...), GLMakie.Vec3f(vec(_up)...))
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

fig