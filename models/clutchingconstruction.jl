import GeometryBasics
import GLMakie

using Porta

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

GLMakie.text!(GLMakie.Point3f(1, 0, 0),
              text = "a", rotation = 0,
              color = :black,
              align = (:left, :baseline),
              textsize = textsize1,
              markerspace = :data)
GLMakie.text!(GLMakie.Point3f(0, 1, 0),
              text = "b", rotation = 0,
              color = :black,
              align = (:left, :baseline),
              textsize = textsize1,
              markerspace = :data)
GLMakie.text!(GLMakie.Point3f(-1, 0, 0),
              text = "c", rotation = 0,
              color = :black,
              align = (:left, :baseline),
              textsize = textsize1,
              markerspace = :data)
GLMakie.text!(GLMakie.Point3f(0, -1, 0),
              text = "d", rotation = 0,
              color = :black,
              align = (:left, :baseline),
              textsize = textsize1,
              markerspace = :data)

width = 0.05
transparency = false
color = GLMakie.RGBAf(255, 0, 0, 1.0)
tail, head = ℝ³(0, 0, 1), ℝ³(0.3, 0, 0)
x_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBAf(0, 255, 0, 1.0)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0.3, 0)
y_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)
color = GLMakie.RGBAf(0, 0, 255, 1.0)
tail, head = ℝ³(0, 0, 1), ℝ³(0, 0, 0.3)
z_arrow = Arrow(tail,
                head,
                lscene.scene,
                width = width,
                color = color)

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
xrotation = GLMakie.@lift(getrotation(ℝ³(0, 0, 1), ℝ³($(x_arrow.tailobservable)[1].data...) + ℝ³($(x_arrow.headobservable)[1].data...)))
yrotation = GLMakie.@lift(getrotation(ℝ³(0, 0, 1), ℝ³($(y_arrow.tailobservable)[1].data...) + ℝ³($(y_arrow.headobservable)[1].data...)))
zrotation = GLMakie.@lift(normalize(getrotation(ℝ³(0, 0, 1), ℝ³($(z_arrow.tailobservable)[1].data...) + ℝ³($(z_arrow.headobservable)[1].data...))))
GLMakie.text!(GLMakie.@lift(GLMakie.Point3f(vec(ℝ³($(x_arrow.tailobservable)[1].data...) + ℝ³($(x_arrow.headobservable)[1].data...)))),
              text = "1",
              color = :red,
              align = (:left, :baseline),
              textsize = textsize1,
              rotation = GLMakie.@lift(GLMakie.Quaternion(vec($xrotation)[2], vec($xrotation)[3], vec($xrotation)[4], vec($xrotation)[1])),
              markerspace = :data)
GLMakie.text!(GLMakie.@lift(GLMakie.Point3f(vec(ℝ³($(y_arrow.tailobservable)[1].data...) + ℝ³($(y_arrow.headobservable)[1].data...)))),
              text = "2",
              color = :green,
              align = (:left, :baseline),
              textsize = textsize1,
              rotation = GLMakie.@lift(GLMakie.Quaternion(vec($yrotation)[2], vec($yrotation)[3], vec($yrotation)[4], vec($yrotation)[1])),
              markerspace = :data)
GLMakie.text!(GLMakie.@lift(GLMakie.Point3f(vec(ℝ³($(z_arrow.tailobservable)[1].data...) + ℝ³($(z_arrow.headobservable)[1].data...)))),
              text = "3",
              color = :blue,
              align = (:left, :baseline),
              textsize = textsize1,
              rotation = GLMakie.@lift(GLMakie.Quaternion(vec($zrotation)[2], vec($zrotation)[3], vec($zrotation)[4], vec($zrotation)[1])),
              markerspace = :data)
# sl_ϕ = GLMakie.Slider(fig[1:end, 2], range = float(-π):0.01:float(π), startvalue = 0)
# sl_θ = GLMakie.Slider(fig[1:end, 3], range = float(-π / 2):0.01:float(π / 2), startvalue = 0)
# sl_α = GLMakie.Slider(fig[1:end, 4], range = 0:0.01:float(2π), startvalue = 0)

textbox = GLMakie.Textbox(fig, placeholder = "Enter a name", width = 115)
markbutton = GLMakie.Button(fig, label = "Mark the frame")
toggle = GLMakie.Toggle(fig, active = false)
label = GLMakie.Label(fig, GLMakie.lift(x -> x ? "Disk S" : "Disk N", toggle.active))
fig[4, 3] = GLMakie.grid!(GLMakie.hcat(textbox, markbutton, toggle, label), tellheight = false)
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
s_xs = GLMakie.Observable([0.0; 0.0])
s_ys = GLMakie.Observable([0.0; 0.0])
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

p₀ = GLMakie.Observable([0.0; 0.0])
p₁ = GLMakie.Observable([0.0; 0.0])
sl_nx = GLMakie.Slider(fig[3, 3], range = -1:0.0001:1, startvalue = 0)
sl_ny = GLMakie.Slider(fig[1:2, 4], range = -1:0.0001:1, horizontal = false, startvalue = 0)

sl_sx = GLMakie.Slider(fig[7, 3], range = -1:0.0001:1, startvalue = 0)
sl_sy = GLMakie.Slider(fig[5:6, 4], range = -1:0.0001:1, horizontal = false, startvalue = 0)

# ϕ₀ = GLMakie.Observable(0.0)
# θ₀ = GLMakie.Observable(0.0)
# ϕ₁ = GLMakie.Observable(0.0)
# θ₁ = GLMakie.Observable(0.0)

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


snapthreshold = 0.025

GLMakie.on(sl_nx.value) do nx
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
    p₀[] = GLMakie.to_value(p₁)
    p₁[] = p
end

GLMakie.on(sl_ny.value) do ny
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
    p₀[] = GLMakie.to_value(p₁)
    p₁[] = p
end

GLMakie.on(sl_sx.value) do sx
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
    p₀[] = GLMakie.to_value(p₁)
    p₁[] = p
end

GLMakie.on(sl_sy.value) do sy
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
    p₀[] = GLMakie.to_value(p₁)
    p₁[] = p
end

GLMakie.on(p₁) do p
    x, y = p
    z = Φ([x; y])
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
    u = xhead - (dot(xhead, tail) / norm(n)) * n
    v = yhead - (dot(yhead, tail) / norm(n)) * n
    u = 0.3 * normalize(u)
    v = 0.3 * normalize(v)

    n_xs[] = [x; x]
    n_ys[] = [y; y]
    n_us[] = [u.a[1]; v.a[1]]
    n_vs[] = [u.a[2]; v.a[2]]
    n = ℝ³(0, 0, -1)
    u = xhead - (dot(xhead, tail) / norm(n)) * n
    v = yhead - (dot(yhead, tail) / norm(n)) * n
    u = 0.3 * normalize(u)
    v = 0.3 * normalize(v)
    s_xs[] = [x; x]
    s_ys[] = [y; y]
    s_us[] = [u.a[1]; v.a[1]]
    s_vs[] = [u.a[2]; v.a[2]]
end

GLMakie.on(toggle.active) do chart
    p = GLMakie.to_value(p₁)
    x, y = p
    s_xs[] = [x; x]
    s_ys[] = [y; y]
    n_xs[] = [x; x]
    n_ys[] = [y; y]
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