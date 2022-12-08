import FileIO
import GLMakie

using Porta

segments = 30
resolution = (1920, 1080)
resolution1 = (1080, 1080)
FPS = 60
startframe = 1
modelname = "clutchingfunction1"
objectives = []


# The scalar field over three dimensions such that all four functions x¹, x², x³ and x⁴ refer to a point in S³
Φ(p) = begin
    chart = GLMakie.to_value(toggle.active)
    squarednorm = sum(p.^2)
    if isapprox(squarednorm, 1)
        return 0
    else
        chart ? -√(1 - squarednorm) : √(1 - squarednorm) # x⁴
    end
end
Φ(p::Array{Float64,1}, chart::Bool) = begin
    squarednorm = sum(p.^2)
    if isapprox(squarednorm, 1)
        return 0
    else
        chart ? -√(1 - squarednorm) : √(1 - squarednorm) # x⁴
    end
end


# The marker's position in a chart
p₀ = GLMakie.Observable([0.0; 0.0; 0.0])
p₁ = GLMakie.Observable([0.0; 0.0; 0.0])
v = GLMakie.Observable(ℝ⁴(1, 0, 0, 0))
r₀ = GLMakie.Observable(ℝ³(0, 0, 0))
currentobjective = GLMakie.Observable("Determine the clutching function!")

islabeled = Dict()

x̂ = ℝ³(1, 0, 0)
ŷ = ℝ³(0, 1, 0)
ẑ = ℝ³(0, 0, 1)

makefigure() = GLMakie.Figure(resolution = resolution)

fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
toggle = GLMakie.Toggle(fig, active = false)
controlstatus = GLMakie.Observable(true) # in order to prevent a recursive call when updating UI controls
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
screen = GLMakie.display(fig, resolution = resolution)
lscene = GLMakie.LScene(fig[1:8, 1:2], show_axis=true,
                        scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=:black, clear=true))
lscene_n = GLMakie.LScene(fig[1:2, 3], show_axis=true,
                          scenekw = (resolution = resolution1, lights = [pl, al], backgroundcolor=:black, clear=true))
lscene_s = GLMakie.LScene(fig[3:4, 3], show_axis=true,
                          scenekw = (resolution = resolution1, lights = [pl, al], backgroundcolor=:black, clear=true))

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
cam_n = GLMakie.camera(lscene_n.scene) # this is how to access the scenes camera
cam_s = GLMakie.camera(lscene_s.scene) # this is how to access the scenes camera
eyeposition = ℝ³(cam.eyeposition[]...)
eyeposition_n = ℝ³(cam_n.eyeposition[]...)
eyeposition_s = ℝ³(cam_s.eyeposition[]...)

sliderx¹ = GLMakie.Slider(fig[5, 3], range = -1:0.00001:1, startvalue = 0)
sliderx² = GLMakie.Slider(fig[6, 3], range = -1:0.00001:1, startvalue = 0)
sliderx³ = GLMakie.Slider(fig[7, 3], range = -1:0.00001:1, startvalue = 0)

textbox = GLMakie.Textbox(fig, placeholder = "Enter a name", width = 115)
textbox.stored_string = "I"
# theme buttons for a dark theme
buttoncolor = GLMakie.RGBf(0.3, 0.3, 0.3)
markbutton = GLMakie.Button(fig, label = "Mark the frame", buttoncolor = buttoncolor)
resetbutton = GLMakie.Button(fig, label = "Reset frame", buttoncolor = buttoncolor)
label = GLMakie.Label(fig, GLMakie.lift(x -> x ? "Chart S" : "Chart N", toggle.active))
fig[8, 3] = GLMakie.grid!(GLMakie.hcat(textbox, markbutton, resetbutton, toggle, label), tellheight = false)
status = GLMakie.Label(fig, currentobjective, textsize = 30)
fig[9, 1:3] = status

# Spheres for showing the boundary of S³ as the skin of a solid ball

q = Biquaternion(ℝ³(0, 0, 0))
# 0.755
sphere = Sphere(q, lscene, color = GLMakie.RGBAf(1.0, 1.0, 1.0, 0.2), radius = 1.0, segments = segments, transparency = true)
sphere_n = Sphere(q, lscene_n, color = GLMakie.RGBAf(1.0, 0.0, 1.0, 0.2), radius = 1.0, segments = segments, transparency = true)
sphere_s = Sphere(q, lscene_s, color = GLMakie.RGBAf(1.0, 1.0, 0.0, 0.2), radius = 1.0, segments = segments, transparency = true)

r = 0.02
R = 1.0
toruscolor = GLMakie.RGBAf(1.0, 1.0, 1.0, 0.0)
torus = Torus(q, lscene, r = r, R = R, segments = segments, color = toruscolor, transparency = true)
torus_n = Torus(q, lscene_n, r = r, R = R, segments = segments, color = toruscolor, transparency = true)
torus_s = Torus(q, lscene_s, r = r, R = R, segments = segments, color = toruscolor, transparency = true)

# landmarks
points = Dict()
points["o"] = ℝ³(0, 0, 0)

points["a"] = ℝ³(1, 0, 0)
points["b"] = ℝ³(0, 1, 0)
points["c"] = ℝ³(-1, 0, 0)
points["d"] = ℝ³(0, -1, 0)
points["e"] = ℝ³(0, 0, 1)
points["f"] = ℝ³(0, 0, -1)

points["g"] = ℝ³(√2 / 2, √2 / 2, 0)
points["h"] = ℝ³(-√2 / 2, √2 / 2, 0)
points["i"] = ℝ³(-√2 / 2, -√2 / 2, 0)
points["j"] = ℝ³(√2 / 2, -√2 / 2, 0)

points["k"] = ℝ³(√2 / 2, 0, √2 / 2)
points["l"] = ℝ³(-√2 / 2, 0, √2 / 2)
points["m"] = ℝ³(-√2 / 2, 0, -√2 / 2)
points["n"] = ℝ³(√2 / 2, 0, -√2 / 2)

points["p"] = ℝ³(0, √2 / 2, √2 / 2)
points["q"] = ℝ³(0, -√2 / 2, √2 / 2)
points["r"] = ℝ³(0, -√2 / 2, -√2 / 2)
points["s"] = ℝ³(0, √2 / 2, -√2 / 2)

set1 = ["a", "b", "c", "d", "e", "f"]
set2 = ["g", "h", "i", "j", "k", "l", "m", "n", "p", "q", "r", "s"]

# Text labels for specifying landmarks
textsize = 0.5

lookat = ℝ³(0, 0, 0)
up = ℝ³(0, 0, 1)

# The arrows pointing to the current location of the frame

width = 0.05
color = GLMakie.RGBA(1.0, 1.0, 1.0, 0.5)
tail, head = ℝ³(0, 0, 0), ℝ³(0, 0, 1)
arrow = Arrow(tail, head, lscene.scene, width = width, color = color)
arrow_n = Arrow(tail, head, lscene_n.scene, width = width, color = color)
arrow_s = Arrow(tail, head, lscene_s.scene, width = width, color = color)

# The frames

transparentcolor = GLMakie.RGBAf(0.0, 0.0, 0.0, 0.0)
clearwhite = GLMakie.RGBAf(1.0, 1.0, 1.0, 0.5)
red = GLMakie.RGBAf(1.0, 0.0, 0.0, 1.0)
green = GLMakie.RGBAf(0.0, 1.0, 0.0, 1.0)
blue = GLMakie.RGBAf(0.0, 0.0, 1.0, 1.0)
tail, head = ℝ³(0, 0, 0), ℝ³(1, 0, 0)
arrowx¹ = Arrow(tail, head, lscene.scene, width = width, color = red)
_arrowx¹ = Arrow(tail, head, lscene.scene, width = width, color = GLMakie.RGBAf(red.r, red.g, red.b, 0.5))
arrowx¹_n = Arrow(tail, head, lscene_n.scene, width = width, color = red)
arrowx¹_s = Arrow(tail, head, lscene_s.scene, width = width, color = red)
color = GLMakie.RGBA(0.0, 1.0, 0.0, 1.0)
head = ℝ³(0, 1, 0)
arrowx² = Arrow(tail, head, lscene.scene, width = width, color = green)
_arrowx² = Arrow(tail, head, lscene.scene, width = width, color = GLMakie.RGBAf(green.r, green.g, green.b, 0.5))
arrowx²_n = Arrow(tail, head, lscene_n.scene, width = width, color = green)
arrowx²_s = Arrow(tail, head, lscene_s.scene, width = width, color = green)
color = GLMakie.RGBA(0.0, 0.0, 1.0, 1.0)
head = ℝ³(0, 0, 1)
arrowx³ = Arrow(tail, head, lscene.scene, width = width, color = blue)
_arrowx³ = Arrow(tail, head, lscene.scene, width = width, color = GLMakie.RGBAf(blue.r, blue.g, blue.b, 0.5))
arrowx³_n = Arrow(tail, head, lscene_n.scene, width = width, color = blue)
arrowx³_s = Arrow(tail, head, lscene_s.scene, width = width, color = blue)


function showtori()
    color = GLMakie.to_value(torus.color)[1]
    if isapprox(color.alpha, 0)
        color = GLMakie.RGBAf(toruscolor.r, toruscolor.g, toruscolor.b, 0.5)
        update(torus, color)
        update(torus_n, color)
        update(torus_s, color)
    end
    "Show the great circle that contains points a; b; c; d"
end


"""
    getpoint(r₀, r₁, t)

Calculate a point along the connecting path from the starting point `r₀` to the destination `r₁` with the given time `t`.
"""
function getpoint(r₀::ℝ³, r₁::ℝ³, t::Float64)
    p = r₁ * t + (1 - t) * r₀
    if norm(p) > 1
        return normalize(p)
    else
        return p
    end
end


"""
    paralleltransport(source, sink, t)
    
Parallel transport the frame to `source` to `sink` with the given time `t` by setting the sliders to the correct values.
"""
function paralleltransport(source, sink, t::Float64)
    point1 = typeof(source) <: ℝ³ ? source : points[source]
    point2 = typeof(sink) <: ℝ³ ? sink : points[sink]
    point = getpoint(point1, point2, t)
    x¹, x², x³ = vec(point)
    GLMakie.set_close_to!(sliderx¹, x¹)
    GLMakie.set_close_to!(sliderx², x²)
    GLMakie.set_close_to!(sliderx³, x³)
    GLMakie.notify(sliderx¹.value)
    GLMakie.notify(sliderx².value)
    GLMakie.notify(sliderx³.value)
    # atol = 5e-1
    # if isapprox(point, points["o"])
    #     condition = isapprox(arrowx¹.head, x̂, atol = atol) && isapprox(arrowx².head, ŷ, atol = atol) && isapprox(arrowx³.head, ẑ, atol = atol)
    #     @assert(condition, "The frame is misaligned at the origin.")
    # end
    "parallel transport the frame from point `$source` to '$sink'"
end

function paralleltransport(source, sink)
    for t in range(0, stop = 1, length = 30)
        paralleltransport(source, sink, t)
    end
    "parallel transport the frame from point `$source` to '$sink'"
end



"""
    mark(name)

Marks te current frame with the given `name` as a prefix.
"""
function mark(name::String, label::String)
    index = name * label
    if get(islabeled, index, false)
        return "mark the frame using the identifier '$label'"
    end
    colors = [GLMakie.RGBAf(1.0, 0, 0, 0.5); GLMakie.RGBAf(0, 1.0, 0, 0.5); GLMakie.RGBAf(0, 0, 1.0, 0.5)]
    tail = arrowx¹.tail
    headx¹ = arrowx¹.head * 0.5
    headx² = arrowx².head * 0.5
    headx³ = arrowx³.head * 0.5
    Arrow(tail, headx¹, lscene.scene, width = width / 2, color = colors[1])
    Arrow(tail, headx², lscene.scene, width = width / 2, color = colors[2])
    Arrow(tail, headx³, lscene.scene, width = width / 2, color = colors[3])
    GLMakie.text!(lscene,
                  GLMakie.Point3f(vec(tail + headx¹)),
                  text = "$(label)₁",
                  color = colors[1],
                  align = (:left, :baseline),
                  textsize = textsize / 2,
                  rotation = 90,
                  markerspace = :data)
    GLMakie.text!(lscene,
                  GLMakie.Point3f(vec(tail + headx²)),
                  text = "$(label)₂",
                  color = colors[2],
                  align = (:left, :baseline),
                  textsize = textsize / 2,
                  rotation = 90,
                  markerspace = :data)
    GLMakie.text!(lscene,
                  GLMakie.Point3f(vec(tail + headx³)),
                  text = "$(label)₃",
                  color = colors[3],
                  align = (:left, :baseline),
                  textsize = textsize / 2,
                  rotation = 90,
                  markerspace = :data)
    resetcam()
    islabeled[index] = true
    "mark the frame at poinr $name with identifier '$label'"
end


getr(p::Array{Float64,1}) = begin
    # q = Quaternion(ℝ⁴(p[1], p[2], p[3], Φ(p)))
    # r = compressedλmap(q)
    # check to see if stereographic projection should be applied since supplying [0; 0; 0; 1] returns a vector of NaN
    # if isnan(vec(r)[1])
    #     x¹, x², x³, x⁴ = vec(q)
    #     if isapprox(x⁴, 0)
    #         r = ℝ³(x¹, x², x³)
    #     else
    #         r = GLMakie.to_value(r₀)
    #     end
    # else
    #     r₀[] = r
    # end
    ℝ³(p)
end


"""
    updateui()

Updates the User Interface (UI) such as camera, controls and scene objects.
"""
function updateui()
    chart = GLMakie.to_value(toggle.active)
    p = GLMakie.to_value(p₁)

    r = getr(p)

    # update the white arrow for pinpointing the position of the current point in the related chart
    tail = ℝ³(0, 0, 0)
    head = r
    update(arrow, tail, head)
    head = ℝ³(p)
    if chart
        update(arrow_s, tail, head)
        update(arrow_s, clearwhite)
        update(arrow_n, transparentcolor)
    else
        update(arrow_n, tail, head)
        update(arrow_n, clearwhite)
        update(arrow_s, transparentcolor)
    end

    # update the frame in the related chart
    tail = head
    if chart
        update(arrowx¹_s, tail, arrowx¹_s.head)
        update(arrowx²_s, tail, arrowx²_s.head)
        update(arrowx³_s, tail, arrowx³_s.head)
        update(arrowx¹_s, red)
        update(arrowx²_s, green)
        update(arrowx³_s, blue)
        # hide the frame in the inactive chart
        update(arrowx¹_n, transparentcolor)
        update(arrowx²_n, transparentcolor)
        update(arrowx³_n, transparentcolor)
    else
        update(arrowx¹_n, tail, arrowx¹_n.head)
        update(arrowx²_n, tail, arrowx²_n.head)
        update(arrowx³_n, tail, arrowx³_n.head)
        update(arrowx¹_n, red)
        update(arrowx²_n, green)
        update(arrowx³_n, blue)
        # hide the frame in the inactive chart
        update(arrowx¹_s, transparentcolor)
        update(arrowx²_s, transparentcolor)
        update(arrowx³_s, transparentcolor)
    end

    _v = GLMakie.to_value(v)
    q = Quaternion(ℝ⁴(p[1], p[2], p[3], Φ(p)))
    h = q.r
    perp = (dot(_v, h) / norm(h)) * h
    _v = _v - perp
    _v = normalize(_v)
    v[] = _v
    
    tail = r
    g = Quaternion(_v)
    headx¹ = rotate(x̂, g)
    headx² = rotate(ŷ, g)
    headx³ = rotate(ẑ, g)
    update(arrowx¹, tail, headx¹)
    update(arrowx², tail, headx²)
    update(arrowx³, tail, headx³)
    update(_arrowx¹, tail, headx¹)
    update(_arrowx², tail, headx²)
    update(_arrowx³, tail, headx³)
end


"""
    resetcam()

Resets the eyeposition, look at and up vactors of cameras (caused by creating objects in the scene.)
"""
function resetcam()
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
    GLMakie.update_cam!(lscene_n.scene, GLMakie.Vec3f(vec(eyeposition_n)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
    GLMakie.update_cam!(lscene_s.scene, GLMakie.Vec3f(vec(eyeposition_s)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
    "Reset 'the eyeposition', 'look at' and 'up' vactors of cameras."
end


"""
    rotatecam(step)

Resets the eyeposition, look at and up vactors of cameras caused by creating objects in the scene,
with the given `step` which determines the rotation degree.
"""
function rotatecam(step::Float64)
    q = Quaternion(step * π, ẑ)
    _eyeposition = rotate(eyeposition, q)
    _eyeposition_n = rotate(eyeposition_n, q)
    _eyeposition_s = rotate(eyeposition_s, q)
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(_eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
    GLMakie.update_cam!(lscene_n.scene, GLMakie.Vec3f(vec(_eyeposition_n)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
    GLMakie.update_cam!(lscene_s.scene, GLMakie.Vec3f(vec(_eyeposition_s)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
    "Rotate the camera about the ẑ axis."
end


"""
    updatepoint(p)

Updates the current point with the given coordinates `p`.
"""
function updatepoint(p)
    point₀ = GLMakie.to_value(p₁)
    # verify that the point in in a solid ball
    radius = √sum(p.^2)
    if radius > 1
        point₁ = p ./ radius
    else
        point₁ = p
    end

    # prevent the update if the current point has not changed compare to the previous one
    threshold = 1e-8
    if isapprox(point₀[1], point₁[1], atol = threshold) && isapprox(point₀[2], point₁[2], atol = threshold) &&
       isapprox(point₀[3], point₁[3], atol = threshold)
        return
    end

    # commit the changes
    p₀[] = point₀
    p₁[] = point₁

    # update the UI
    updateui()
end


labelpoint(name::String) = begin
    point = points[name]
    if !get(islabeled, name, false)
        GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(point)), text = name, color = :white,
                      align = (:left, :baseline), rotation = 90, textsize = textsize, markerspace = :data)
        GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(point)), text = name, color = :white,
                      align = (:left, :baseline), rotation = 90, textsize = textsize, markerspace = :data)
        GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(point)), text = name, color = :white,
                      align = (:left, :baseline), rotation = 90, textsize = textsize, markerspace = :data)
        resetcam()
        islabeled[name] = true
    end
    "Labeled point $name in $point"
end


switchcharts(chart::String) = begin
    if chart == "S"
        toggle.active = true
        return "Switched coordinate charts from N to S."
    end
    if chart == "N"
        toggle.active = false
        return "Switched coordinate charts from S to N."
    end
end


function paralleltransport(path::Array{String,1}, t::Float64)
    if isapprox(t, 1, atol = 1e-9)
        source = path[end-1]
        sink = path[end]
        return "Parallel transport the frame from $source to $sink"
    end
    N = length(path)
    τ = floor(t * N)
    sourceindex = Int(τ) + 1
    sinkindex = sourceindex == N ? 1 : sourceindex + 1
    source = path[sourceindex]
    sink = path[sinkindex]
    intervallength = 1 / N
    t₀ = (sourceindex - 1) * intervallength
    step = (t - t₀) * N

    # parallel transport the frame to the center of chart N and leave it there
    chart = GLMakie.to_value(toggle.active)
    point₁ = ℝ³(GLMakie.to_value(p₁))
    if !isapprox(point₁, points["o"])
        paralleltransport(point₁, "o")
    end
    if chart
        paralleltransport("o", "a")
        switchcharts("N")
        paralleltransport("a", "o")
    end

    point = normalize(getpoint(points[source], points[sink], step))
    
    # Basis I
    v₁ = ℝ⁴(1, 0, 0, 0)
    chart = false # the N chart
    for i in range(0, stop = 1.0, length = 30)
        p = vec(i * point)
        q = Quaternion(ℝ⁴(p[1], p[2], p[3], Φ(p, chart)))
        perp = (dot(v₁, q.r) / norm(q.r)) * q.r
        v₁ = normalize(v₁ - perp)
    end

    # Basis II
    v₂ = ℝ⁴(1, 0, 0, 0)
    chart = false
    for i in range(0, stop = 1.0, length = 30)
        p = vec(i * points["a"])
        q = Quaternion(ℝ⁴(p[1], p[2], p[3], Φ(p, chart)))
        perp = (dot(v₂, q.r) / norm(q.r)) * q.r
        v₂ = normalize(v₂ - perp)
    end
    chart = true # the S chart
    for i in range(0, stop = 1.0, length = 30)
        p = vec((1 - i) * points["a"])
        q = Quaternion(ℝ⁴(p[1], p[2], p[3], Φ(p, chart)))
        perp = (dot(v₂, q.r) / norm(q.r)) * q.r
        v₂ = normalize(v₂ - perp)
    end
    for i in range(0, stop = 1.0, length = 30)
        p = vec(i * point)
        q = Quaternion(ℝ⁴(p[1], p[2], p[3], Φ(p, chart)))
        perp = (dot(v₂, q.r) / norm(q.r)) * q.r
        v₂ = normalize(v₂ - perp)
    end
    
    tail = point
    g = Quaternion(v₁)
    headx¹ = rotate(x̂, g)
    headx² = rotate(ŷ, g)
    headx³ = rotate(ẑ, g)
    update(arrowx¹, tail, headx¹)
    update(arrowx², tail, headx²)
    update(arrowx³, tail, headx³)
    g = Quaternion(v₂)
    headx¹ = rotate(x̂, g)
    headx² = rotate(ŷ, g)
    headx³ = rotate(ẑ, g)
    update(_arrowx¹, tail, headx¹)
    update(_arrowx², tail, headx²)
    update(_arrowx³, tail, headx³)
    "Parallel transport the frame from $source to $sink"
end


function _paralleltransport(path::Array{String,1}, t::Float64)
    if isapprox(t, 1, atol = 1e-9)
        source = path[end-1]
        sink = path[end]
        return "Parallel transport the frame from $source to $sink"
    end
    N = length(path)
    τ = floor(t * N)
    sourceindex = Int(τ) + 1
    sinkindex = sourceindex == N ? 1 : sourceindex + 1
    source = path[sourceindex]
    sink = path[sinkindex]
    intervallength = 1 / N
    t₀ = (sourceindex - 1) * intervallength
    step = (t - t₀) * N
    chart = GLMakie.to_value(toggle.active)
    point₁ = ℝ³(GLMakie.to_value(p₁))

    # if !isapprox(point₁, points["o"])
    #     paralleltransport(point₁, "o")
    # end
    paralleltransport(point₁, "o")
    # transport to the origin of chart S
    if !chart
        paralleltransport("o", "a")
        switchcharts("S")
        paralleltransport("a", "o")
    end

    # basis II
    point = normalize(getpoint(points[source], points[sink], step))
    paralleltransport("o", point)
    _tail = getr(vec(point))
    _headx¹ = arrowx¹.head
    _headx² = arrowx².head
    _headx³ = arrowx³.head
    
    if !isapprox(point, points["o"])
        paralleltransport(point, "o")
    end
    # transport to the origin of chart N
    if chart
        paralleltransport("o", "a")
        switchcharts("N")
        paralleltransport("a", "o")
    end

    # basis I
    point = normalize(getpoint(points[source], points[sink], step))
    paralleltransport("o", point)

    update(_arrowx¹, _tail, _headx¹)
    update(_arrowx², _tail, _headx²)
    update(_arrowx³, _tail, _headx³)
    "Parallel transport the frame from $source to $sink"
end


function rotatecircle(q₁::Biquaternion, q₂::Biquaternion, t::Float64)
    r₁, r₂ = getrotation(q₁), getrotation(q₂)
    q = t * r₂ + (1 - t) * r₁
    q = Biquaternion(normalize(q))
    update(torus, q)
    update(torus_n, q)
    update(torus_s, q)
    rotation = getrotation(q)
    "rotate the great circle with $rotation"
end

path1 = ["a"; "g"; "b"; "h"; "c"; "i"; "d"; "j"]
path2 = ["a"; "k"; "e"; "l"; "c"; "m"; "f"; "n"]
path3 = ["b"; "p"; "e"; "q"; "d"; "r"; "f"; "s"]

q₁ = Biquaternion(Quaternion(0, x̂))
q₂ = Biquaternion(Quaternion(π / 4, x̂))
q₃ = Biquaternion(Quaternion(π / 4, ẑ))

push!(objectives, x -> labelpoint("o"))

for name in set1
    push!(objectives, x -> labelpoint(name))
end

push!(objectives, x -> rotatecam(x))

for name in set1
    push!(objectives, x -> paralleltransport("o", name, x))
    push!(objectives, x -> mark(name, "I"))
    push!(objectives, x -> paralleltransport(name, "o", x))
end

push!(objectives, x -> paralleltransport("o", "a", x))
push!(objectives, x -> switchcharts("S"))
push!(objectives, x -> paralleltransport("a", "o", x))

for name in set1
    push!(objectives, x -> paralleltransport("o", name, x))
    push!(objectives, x -> mark(name, "II"))
    push!(objectives, x -> paralleltransport(name, "o", x))
end

push!(objectives, x -> rotatecam(x))

push!(objectives, x -> paralleltransport("o", "a", x))
push!(objectives, x -> switchcharts("N"))
push!(objectives, x -> paralleltransport("a", "o", x))

for name in set2
    push!(objectives, x -> labelpoint(name))
end

push!(objectives, x -> rotatecam(x))

for name in set2
    push!(objectives, x -> paralleltransport("o", name, x))
    push!(objectives, x -> mark(name, "I"))
    push!(objectives, x -> paralleltransport(name, "o", x))
end

push!(objectives, x -> paralleltransport("o", "a", x))
push!(objectives, x -> switchcharts("S"))
push!(objectives, x -> paralleltransport("a", "o", x))

for name in set2
    push!(objectives, x -> paralleltransport("o", name, x))
    push!(objectives, x -> mark(name, "II"))
    push!(objectives, x -> paralleltransport(name, "o", x))
end

push!(objectives, x -> paralleltransport("o", "a", x))
push!(objectives, x -> switchcharts("N"))
push!(objectives, x -> paralleltransport("a", "o", x))

push!(objectives, x -> rotatecam(x))

GLMakie.on(sliderx¹.value) do x¹
    # refuse to update the current point whenever controling is off
    if !GLMakie.to_value(controlstatus) return end

    x² = GLMakie.to_value(sliderx².value)
    x³ = GLMakie.to_value(sliderx³.value)
    radius = √(x¹^2 + x²^2 + x³^2)
    if radius > 1
        # in order to prevent DomainError with negative values
        intermediate = 1 - (x²^2 + x³^2)
        if isapprox(intermediate, 0, atol = 1e-3)
            intermediate = 0
        end
        x¹ = √intermediate * sign(x¹)
    end

    # update the current point
    updatepoint([x¹; x²; x³])
end

GLMakie.on(sliderx².value) do x²
    # refuse to update the current point whenever controling is off
    if !GLMakie.to_value(controlstatus) return end

    x¹ = GLMakie.to_value(sliderx¹.value)
    x³ = GLMakie.to_value(sliderx³.value)
    radius = √(x¹^2 + x²^2 + x³^2)
    if radius > 1
        # in order to prevent DomainError with negative values
        intermediate = 1 - min(1, (x¹^2 + x³^2))
        if isapprox(intermediate, 0, atol = 1e-3)
            intermediate = 0
        end
        x² = √intermediate * sign(x²)
    end

    # update the current point
    updatepoint([x¹; x²; x³])
end

GLMakie.on(sliderx³.value) do x³
    # refuse to update the current point whenever controling is off
    if !GLMakie.to_value(controlstatus) return end

    x¹ = GLMakie.to_value(sliderx¹.value)
    x² = GLMakie.to_value(sliderx².value)
    radius = √(x¹^2 + x²^2 + x³^2)
    if radius > 1
        # in order to prevent DomainError with negative values
        intermediate = 1 - (x¹^2 + x²^2)
        if isapprox(intermediate, 0, atol = 1e-3)
            intermediate = 0
        end
        x³ = √intermediate * sign(x³)
    end

    # update the current point
    updatepoint([x¹; x²; x³])
end

GLMakie.on(toggle.active) do chart
    p = GLMakie.to_value(p₁)
    x¹, x², x³ = p
    controlstatus[] = false
    if !isapprox(GLMakie.to_value(sliderx¹.value), x¹)
        GLMakie.set_close_to!(sliderx¹, x¹)
    end
    if !isapprox(GLMakie.to_value(sliderx².value), x²)
        GLMakie.set_close_to!(sliderx², x²)
    end
    if !isapprox(GLMakie.to_value(sliderx³.value), x³)
        GLMakie.set_close_to!(sliderx³, x³)
    end
    controlstatus[] = true
    updateui()
end

# animate a path
framerate = 60
f = 1
N = f * length(objectives)
timestamps = range(0, N, step = 1 / framerate)
GLMakie.record(fig, "gallery/$modelname.mp4", timestamps; framerate = framerate) do t
    τ = t / f + 1
    index = isapprox(τ, length(objectives) + 1) ? Int(floor(τ) - 1) : Int(floor(τ))
    objective = objectives[index]
    step = min(1.0, τ % floor(τ) + 1 / framerate)
    detail = objectives[index](step)
    currentobjective[] = "Current objective ($index): $detail"
    progress = round(100step)
    println("($index) $detail . $progress")
end

previouslength = length(objectives)
push!(objectives, x -> showtori())

push!(objectives, x -> paralleltransport(path1, x))

push!(objectives, x -> rotatecircle(q₁, q₂, x))
push!(objectives, x -> rotatecam(x))

push!(objectives, x -> paralleltransport(path2, x))

push!(objectives, x -> rotatecircle(q₂, q₃ * q₂, x))
push!(objectives, x -> rotatecam(x))

push!(objectives, x -> paralleltransport(path3, x))

push!(objectives, x -> rotatecam(x))

# animate a path
framerate = 60
f = 15
N = f * (length(objectives) - previouslength)
timestamps = range(0, N, step = 1 / framerate)
GLMakie.record(fig, "gallery/$(modelname)1.mp4", timestamps; framerate = framerate) do t
    τ = t / f + 1 + previouslength
    index = isapprox(τ, length(objectives) + 1) ? Int(floor(τ) - 1) : Int(floor(τ))
    objective = objectives[index]
    step = min(1.0, τ % floor(τ) + 1 / framerate)
    detail = objectives[index](step)
    currentobjective[] = "Current objective ($index): $detail"
    progress = round(100step)
    println("($index) $detail . $progress")
end