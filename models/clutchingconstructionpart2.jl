import FileIO
import GLMakie

using Porta

segments = 30
resolution = (1920, 1080)
resolution1 = (1080, 1080)
FPS = 60
startframe = 1
modelname = "clutchingconstructionpart2"

# The marker's position in a chart
p₀ = GLMakie.Observable([0.0; 0.0; 0.0])
p₁ = GLMakie.Observable([0.0; 0.0; 0.0])
v = GLMakie.Observable(ℝ⁴(1, 0, 0, 0))
r₀ = GLMakie.Observable(ℝ³(0, 0, 0))

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

# Spheres for showing the boundary of S³ as the skin of a solid ball

q = Biquaternion(ℝ³(0, 0, 0))
sphere = Sphere(q, lscene, color = GLMakie.RGBAf(1.0, 1.0, 1.0, 0.25), radius = 1.0, segments = segments, transparency = true)
sphere_n = Sphere(q, lscene_n, color = GLMakie.RGBAf(1.0, 0.0, 1.0, 0.25), radius = 1.0, segments = segments, transparency = true)
sphere_s = Sphere(q, lscene_s, color = GLMakie.RGBAf(1.0, 1.0, 0.0, 0.25), radius = 1.0, segments = segments, transparency = true)

# Text labels for specifying landmarks
textsize = 0.5
GLMakie.text!(lscene.scene, GLMakie.Point3f(1, 0, 0), text = "a", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(0, 1, 0), text = "b", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(-1, 0, 0), text = "c", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(0, -1, 0), text = "d", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(0, 0, 1), text = "e", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(0, 0, -1), text = "f", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)

GLMakie.text!(lscene_n.scene, GLMakie.Point3f(1, 0, 0), text = "a", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(0, 1, 0), text = "b", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(-1, 0, 0), text = "c", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(0, -1, 0), text = "d", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(0, 0, 1), text = "e", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(0, 0, -1), text = "f", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)

GLMakie.text!(lscene_s.scene, GLMakie.Point3f(1, 0, 0), text = "a", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(0, 1, 0), text = "b", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(-1, 0, 0), text = "c", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(0, -1, 0), text = "d", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(0, 0, 1), text = "e", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(0, 0, -1), text = "f", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)

# The arrows pointing to the current location of the frame

width = 0.05
color = GLMakie.RGBA(1.0, 1.0, 1.0, 0.5)
tail, head = ℝ³(0, 0, 0), ℝ³(0, 0, 1)
arrow = Arrow(tail, head, lscene.scene, width = width, color = color)
arrow_n = Arrow(tail, head, lscene_n.scene, width = width, color = color)
arrow_s = Arrow(tail, head, lscene_s.scene, width = width, color = color)

# The frames

color = GLMakie.RGBA(1.0, 0.0, 0.0, 1.0)
tail, head = ℝ³(0, 0, 0), ℝ³(1, 0, 0)
arrowx¹ = Arrow(tail, head, lscene.scene, width = width, color = color)
arrowx¹_n = Arrow(tail, head, lscene_n.scene, width = width, color = color)
arrowx¹_s = Arrow(tail, head, lscene_s.scene, width = width, color = color)
color = GLMakie.RGBA(0.0, 1.0, 0.0, 1.0)
head = ℝ³(0, 1, 0)
arrowx² = Arrow(tail, head, lscene.scene, width = width, color = color)
arrowx²_n = Arrow(tail, head, lscene_n.scene, width = width, color = color)
arrowx²_s = Arrow(tail, head, lscene_s.scene, width = width, color = color)
color = GLMakie.RGBA(0.0, 0.0, 1.0, 1.0)
head = ℝ³(0, 0, 1)
arrowx³ = Arrow(tail, head, lscene.scene, width = width, color = color)
arrowx³_n = Arrow(tail, head, lscene_n.scene, width = width, color = color)
arrowx³_s = Arrow(tail, head, lscene_s.scene, width = width, color = color)

snapthreshold = 0.01 # threshold for snapping to a boundary


"""
    getpointonpath(t)

FInd the point on a specific path with the given time `t`.
"""
function getpointonpath(t::Float64)
    if t < 3
        step = t / 3
        p = ℝ³(1, 0, 0) * step
    elseif 3 ≤ t < 6
        step = (t - 3) / 3
        p = ℝ³(cos(step * π), sin(step * π), 0)
    elseif 6 ≤ t < 9
        step = (t - 6) / 3
        p = Geographic(Cartesian(ℝ³(-1, 0, 0)))
        p = ℝ³(Cartesian(Geographic(p.r, p.ϕ, step * π / 2)))
    elseif 9 ≤ t < 12
        step = (t - 9) / 3
        p = Geographic(Cartesian(ℝ³(0, 0, 1)))
        p = ℝ³(Cartesian(Geographic(p.r, p.ϕ, (1 - step) * π / 2)))
    elseif t ≥ 12
        step = (t - 12) / 3
        p = ℝ³(1, 0, 0) * (1 - step)
    end
    return p
end


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


"""
    updateui()

Updates the User Interface (UI) such as camera, controls and scene objects.
"""
function updateui()
    chart = GLMakie.to_value(toggle.active)
    p = GLMakie.to_value(p₁)

    q = Quaternion(ℝ⁴(p[1], p[2], p[3], Φ(p)))
    r = compressedλmap(q)
    # check to see if stereographic projection should be applied since supplying [0; 0; 0; 1] returns a vector of NaN
    if isnan(vec(r)[1])
        r = GLMakie.to_value(r₀)
    else
        r₀[] = r
    end

    # update the white arrow for pinpointing the position of the current point in the related chart
    tail = ℝ³(0, 0, 0)
    head = r
    update(arrow, tail, head)
    head = ℝ³(p)
    if chart
        update(arrow_s, tail, head)
    else
        update(arrow_n, tail, head)
    end

    # update the frame in the related chart
    tail = head
    if chart
        update(arrowx¹_s, tail, arrowx¹_s.head)
        update(arrowx²_s, tail, arrowx²_s.head)
        update(arrowx³_s, tail, arrowx³_s.head)
    else
        update(arrowx¹_n, tail, arrowx¹_n.head)
        update(arrowx²_n, tail, arrowx²_n.head)
        update(arrowx³_n, tail, arrowx³_n.head)
    end

    _v = GLMakie.to_value(v)
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


GLMakie.on(sliderx¹.value) do x¹
    # refuse to update the current point whenever controling is off
    if !GLMakie.to_value(controlstatus) return end

    # snap to the boundary of a solid ball if applicable
    x² = GLMakie.to_value(sliderx².value)
    x³ = GLMakie.to_value(sliderx³.value)
    radius = √(x¹^2 + x²^2 + x³^2)
    if radius > 1 - snapthreshold
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

    # snap to the boundary of a solid ball if applicable
    x¹ = GLMakie.to_value(sliderx¹.value)
    x³ = GLMakie.to_value(sliderx³.value)
    radius = √(x¹^2 + x²^2 + x³^2)
    if radius > 1 - snapthreshold
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

    # snap to the boundary of a solid ball if applicable
    x¹ = GLMakie.to_value(sliderx¹.value)
    x² = GLMakie.to_value(sliderx².value)
    radius = √(x¹^2 + x²^2 + x³^2)
    if radius > 1 - snapthreshold
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
framerate = 30
timestamps = range(0, 15, step = 1 / framerate)
GLMakie.record(fig, "gallery/time_animation.mp4", timestamps; framerate = framerate) do t
    point = getpointonpath(t)
    x¹, x², x³ = vec(point)
    GLMakie.set_close_to!(sliderx¹, x¹)
    GLMakie.set_close_to!(sliderx², x²)
    GLMakie.set_close_to!(sliderx³, x³)
end