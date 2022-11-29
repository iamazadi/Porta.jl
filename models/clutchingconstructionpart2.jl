import FileIO
import GLMakie

using Porta

segments = 30
resolution = (1920, 1080)
resolution1 = (1080, 1080)
FPS = 60
startframe = 1
modelname = "clutchingconstructionpart2"

objectives = Dict()
objectives[1] = "transport the frame to the origin of chart N"
objectives[2] = "reset the orientation of the frame such that it coincides with a triad made of x̂, ŷ and ẑ" # initial configuration

objectives[3] = "parallel transport the frame to 'a'"
objectives[4] = "mark the frame using the identifier I"
objectives[5] = "parallel transport the frame back to the origin of chart N (backtrack)"

objectives[6] = "parallel transport the frame to 'b'"
objectives[7] = "mark the frame using the identifier I"
objectives[8] = "parallel transport the frame back to the origin of chart N (backtrack)"

objectives[9] = "parallel transport the frame to 'c'"
objectives[10] = "mark the frame using the identifier I"
objectives[11] = "parallel transport the frame back to the origin of chart N (backtrack)"

objectives[12] = "parallel transport the frame to 'd'"
objectives[13] = "mark the frame using the identifier I"
objectives[14] = "parallel transport the frame back to the origin of chart N (backtrack)"

objectives[15] = "parallel transport the frame to 'e'"
objectives[16] = "mark the frame using the identifier I"
objectives[17] = "parallel transport the frame back to the origin of chart N (backtrack)"

objectives[18] = "parallel transport the frame to 'f'"
objectives[19] = "mark the frame using the identifier I"
objectives[20] = "parallel transport the frame back to the origin of chart N (backtrack)"

objectives[21] = "parallel transport the frame to 'a'"
objectives[22] = "jump over the boundary from chart N to chart S" # verify that the frame coincides with the marked frame at 'a'
objectives[23] = "parallel transport the frame to the origin of chart S"

objectives[24] = "parallel transport the frame to 'b'"
objectives[25] = "mark the frame using the identifier II"
objectives[26] = "parallel transport the frame back to the origin of chart S (backtrack)"

objectives[27] = "parallel transport the frame to 'c'"
objectives[28] = "mark the frame using the identifier II"
objectives[29] = "parallel transport the frame back to the origin of chart S (backtrack)"

objectives[30] = "parallel transport the frame to 'd'"
objectives[31] = "mark the frame using the identifier II"
objectives[32] = "parallel transport the frame back to the origin of chart S (backtrack)"

objectives[33] = "parallel transport the frame to 'e'"
objectives[34] = "mark the frame using the identifier II"
objectives[35] = "parallel transport the frame back to the origin of chart S (backtrack)"

objectives[36] = "parallel transport the frame to 'f'"
objectives[37] = "mark the frame using the identifier II"
objectives[38] = "parallel transport the frame back to the origin of chart S (backtrack)"

objectives[39] = "rotate the camera about ẑ for 2π"

objectives[40] = "parallel transport the frame to 'a' (backtrack)"
objectives[41] = "jump over the boundary from chart S to chart N" # verify that the frame coincides with the marked frame I at 'a'
objectives[42] = "parallel transport the frame to the origin of chart N  (backtrack)"
# verify that the frame coincides with the default frame (coinciding with a triad made of x̂, ŷ and ẑ)

objectives[43] = "locate the midpoint along the great circle between 'a' and 'b' and label it 'g'"
objectives[44] = "locate the midpoint along the great circle between 'a' and 'e' and label it 'h'"

objectives[45] = "parallel transport the frame to 'g'"
objectives[46] = "mark the frame using the identifier I"
objectives[47] = "parallel transport the frame back to the origin of chart N (backtrack)"

objectives[48] = "parallel transport the frame to 'h'"
objectives[49] = "mark the frame using the identifier I"
objectives[50] = "parallel transport the frame back to the origin of chart N (backtrack)"

objectives[51] = "parallel transport the frame to 'a'"
objectives[52] = "jump over the boundary from chart N into S" # verify that the frame coincides with the marked frame I at 'a'
objectives[53] = "parallel transport the frame to the origin of chart S"

objectives[54] = "parallel transport the frame to 'g'"
objectives[55] = "mark the frame using the identifier II"
objectives[56] = "parallel transport the frame back to the origin of chart S (backtrack)"

objectives[57] = "parallel transport the frame to 'h'"
objectives[58] = "mark the frame using the identifier II"
objectives[59] = "parallel transport the frame back to the origin of chart S (backtrack)"

objectives[60] = "rotate the camera about ẑ for 2π"

# The marker's position in a chart
p₀ = GLMakie.Observable([0.0; 0.0; 0.0])
p₁ = GLMakie.Observable([0.0; 0.0; 0.0])
v = GLMakie.Observable(ℝ⁴(1, 0, 0, 0))
r₀ = GLMakie.Observable(ℝ³(0, 0, 0))
currentobjective = GLMakie.Observable("Determine the clutching function!")

islabeled = Dict()
islabeled["Ia"] = false
islabeled["Ib"] = false
islabeled["Ic"] = false
islabeled["Id"] = false
islabeled["Ie"] = false
islabeled["If"] = false
islabeled["Ig"] = false
islabeled["Ih"] = false
islabeled["IIb"] = false
islabeled["IIc"] = false
islabeled["IId"] = false
islabeled["IIe"] = false
islabeled["IIf"] = false
islabeled["IIg"] = false
islabeled["IIh"] = false
islabeled["g"] = false
islabeled["h"] = false

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
eyeposition₀ = ℝ³((cam.eyeposition[])...)
lookat₀ = ℝ³(0, 0, 0)
up₀ = ℝ³(0, 0, 1)

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
status = GLMakie.Label(fig, GLMakie.lift(x -> "Current objective: $x", currentobjective), textsize = 30)
fig[9, 1:3] = status

# Spheres for showing the boundary of S³ as the skin of a solid ball

q = Biquaternion(ℝ³(0, 0, 0))
sphere = Sphere(q, lscene, color = GLMakie.RGBAf(1.0, 1.0, 1.0, 0.25), radius = 1.0, segments = segments, transparency = true)
sphere_n = Sphere(q, lscene_n, color = GLMakie.RGBAf(1.0, 0.0, 1.0, 0.25), radius = 1.0, segments = segments, transparency = true)
sphere_s = Sphere(q, lscene_s, color = GLMakie.RGBAf(1.0, 1.0, 0.0, 0.25), radius = 1.0, segments = segments, transparency = true)

# landmarks
pointa = ℝ³(1, 0, 0)
pointb = ℝ³(0, 1, 0)
pointc = ℝ³(-1, 0, 0)
pointd = ℝ³(0, -1, 0)
pointe = ℝ³(0, 0, 1)
pointf = ℝ³(0, 0, -1)
pointg = ℝ³(√2 / 2, √2 / 2, 0)
pointh = ℝ³(√2 / 2, 0, √2 / 2)

# Text labels for specifying landmarks
textsize = 0.5
GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(pointa)), text = "a", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(pointb)), text = "b", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(pointc)), text = "c", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(pointd)), text = "d", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(pointe)), text = "e", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(pointf)), text = "f", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)

GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(pointa)), text = "a", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(pointb)), text = "b", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(pointc)), text = "c", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(pointd)), text = "d", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(pointe)), text = "e", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(pointf)), text = "f", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)

GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(pointa)), text = "a", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(pointb)), text = "b", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(pointc)), text = "c", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(pointd)), text = "d", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(pointe)), text = "e", color = :white,
              align = (:left, :baseline), textsize = textsize, markerspace = :data)
GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(pointf)), text = "f", color = :white,
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
    getpoint(g₀, g₁, t)

Calculate a point along the connecting geodesic from the starting point `g₀` to the destination `g₁` with the given time `t`.
"""
function getpoint(g₀::Geographic, g₁::Geographic, t::Float64)
    ϕ₀, θ₀ = g₀.ϕ, g₀.θ
    ϕ₁, θ₁ = g₁.ϕ, g₁.θ
    ϕ = t * ϕ₁ + (1 - t) * ϕ₀
    θ = t * θ₁ + (1 - t) * θ₀
    Geographic(g₀.r, ϕ, θ)
end


"""
    getpoint(r₀, r₁, t)

Calculate a point along the connecting path from the starting point `r₀` to the destination `r₁` with the given time `t`.
"""
function getpoint(r₀::ℝ³, r₁::ℝ³, t::Float64)
    r₁ * t + (1 - t) * r₀
end


"""
    paralleltransport(point)
    
Parallel transport the frame to `point` by setting the sliders to the correct values.
"""
function paralleltransport(point::ℝ³)
    x¹, x², x³ = vec(point)
    GLMakie.set_close_to!(sliderx¹, x¹)
    GLMakie.set_close_to!(sliderx², x²)
    GLMakie.set_close_to!(sliderx³, x³)
end


"""
    mark(name)

Marks te current frame with the given `name` as a prefix.
"""
function mark(name::String)
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
                  text = "$(name)₁",
                  color = colors[1],
                  align = (:left, :baseline),
                  textsize = textsize / 2,
                  markerspace = :data)
    GLMakie.text!(lscene,
                  GLMakie.Point3f(vec(tail + headx²)),
                  text = "$(name)₂",
                  color = colors[2],
                  align = (:left, :baseline),
                  textsize = textsize / 2,
                  markerspace = :data)
    GLMakie.text!(lscene,
                  GLMakie.Point3f(vec(tail + headx³)),
                  text = "$(name)₃",
                  color = colors[3],
                  align = (:left, :baseline),
                  textsize = textsize / 2,
                  markerspace = :data)
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition₀)...), GLMakie.Vec3f(vec(lookat₀)...), GLMakie.Vec3f(vec(up₀)...))
end


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
framerate = 60
timestamps = range(0, 118, step = 1 / framerate)
GLMakie.record(fig, "gallery/time_animation.mp4", timestamps; framerate = framerate) do t
    τ = t / 2 + 1
    index = Int(floor(τ))
    objective = objectives[index]
    currentobjective[] = "($index) $objective"
    step = τ % floor(τ)
    progress = round(100step)
    println("($index) $objective . $progress")

    if index == 1 # transport the frame to the origin of chart N
        eyeposition = rotate(eyeposition₀, Quaternion(step * π, ẑ))
        GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat₀)...), GLMakie.Vec3f(vec(up₀)...))
    end

    if index == 2 # reset the orientation of the frame such that it coincides with a triad made of x̂, ŷ and ẑ
        eyeposition = rotate(eyeposition₀, Quaternion(-step * π, ẑ))
        GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat₀)...), GLMakie.Vec3f(vec(up₀)...))
    end

    if index == 3 # parallel transport the frame to 'a' 
        point = getpoint(ℝ³(0, 0, 0), pointa, step)
        paralleltransport(point)
    end

    if index == 4 # mark the frame using the identifier I
        if !islabeled["Ia"]
            mark("I")
            islabeled["Ia"] = true
        end
    end

    if index == 5 # parallel transport the frame back to the origin of chart N (backtrack)
        point = getpoint(pointa, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 6 # parallel transport the frame to 'b' 
        point = getpoint(ℝ³(0, 0, 0), pointb, step)
        paralleltransport(point)
    end

    if index == 7 # mark the frame using the identifier I
        if !islabeled["Ib"]
            mark("I")
            islabeled["Ib"] = true
        end
    end

    if index == 8 # parallel transport the frame back to the origin of chart N (backtrack)
        point = getpoint(pointb, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 9 # parallel transport the frame to 'c' 
        point = getpoint(ℝ³(0, 0, 0), pointc, step)
        paralleltransport(point)
    end

    if index == 10 # mark the frame using the identifier I
        if !islabeled["Ic"]
            mark("I")
            islabeled["Ic"] = true
        end
    end

    if index == 11 # parallel transport the frame back to the origin of chart N (backtrack)
        point = getpoint(pointc, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 12 # parallel transport the frame to 'd' 
        point = getpoint(ℝ³(0, 0, 0), pointd, step)
        paralleltransport(point)
    end

    if index == 13 # mark the frame using the identifier I
        if !islabeled["Id"]
            mark("I")
            islabeled["Id"] = true
        end
    end

    if index == 14 # parallel transport the frame back to the origin of chart N (backtrack)
        point = getpoint(pointd, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 15 # parallel transport the frame to 'e' 
        point = getpoint(ℝ³(0, 0, 0), pointe, step)
        paralleltransport(point)
    end

    if index == 16 # mark the frame using the identifier I
        if !islabeled["Ie"]
            mark("I")
            islabeled["Ie"] = true
        end
    end

    if index == 17 # parallel transport the frame back to the origin of chart N (backtrack)
        point = getpoint(pointe, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 18 # parallel transport the frame to 'f' 
        point = getpoint(ℝ³(0, 0, 0), pointf, step)
        paralleltransport(point)
    end

    if index == 19 # mark the frame using the identifier I
        if !islabeled["If"]
            mark("I")
            islabeled["If"] = true
        end
    end

    if index == 20 # parallel transport the frame back to the origin of chart N (backtrack)
        point = getpoint(pointf, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 21 # parallel transport the frame to 'a' 
        point = getpoint(ℝ³(0, 0, 0), pointa, step)
        paralleltransport(point)
    end

    if index == 22 # jump over the boundary from chart N to chart S
        if !(toggle.active[])
            toggle.active = true
        end
    end

    if index == 23 # parallel transport the frame to the origin of chart S 
        point = getpoint(pointa, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 24 # parallel transport the frame to 'b' 
        point = getpoint(ℝ³(0, 0, 0), pointb, step)
        paralleltransport(point)
    end

    if index == 25 # mark the frame using the identifier II
        if !islabeled["IIb"]
            mark("II")
            islabeled["IIb"] = true
        end
    end

    if index == 26 # parallel transport the frame back to the origin of chart S (backtrack)
        point = getpoint(pointb, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 27 # parallel transport the frame to 'c' 
        point = getpoint(ℝ³(0, 0, 0), pointc, step)
        paralleltransport(point)
    end

    if index == 28 # mark the frame using the identifier II
        if !islabeled["IIc"]
            mark("II")
            islabeled["IIc"] = true
        end
    end

    if index == 29 # parallel transport the frame back to the origin of chart S (backtrack)
        point = getpoint(pointc, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 30 # parallel transport the frame to 'd' 
        point = getpoint(ℝ³(0, 0, 0), pointd, step)
        paralleltransport(point)
    end

    if index == 31 # mark the frame using the identifier II
        if !islabeled["IId"]
            mark("II")
            islabeled["IId"] = true
        end
    end

    if index == 32 # parallel transport the frame back to the origin of chart S (backtrack)
        point = getpoint(pointd, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 33 # parallel transport the frame to 'e' 
        point = getpoint(ℝ³(0, 0, 0), pointe, step)
        paralleltransport(point)
    end

    if index == 34 # mark the frame using the identifier II
        if !islabeled["IIe"]
            mark("II")
            islabeled["IIe"] = true
        end
    end

    if index == 35 # parallel transport the frame back to the origin of chart S (backtrack)
        point = getpoint(pointe, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 36 # parallel transport the frame to 'f' 
        point = getpoint(ℝ³(0, 0, 0), pointf, step)
        paralleltransport(point)
    end

    if index == 37 # mark the frame using the identifier II
        if !islabeled["IIf"]
            mark("II")
            islabeled["IIf"] = true
        end
    end

    if index == 38 # parallel transport the frame back to the origin of chart S (backtrack)
        point = getpoint(pointf, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 39 # rotate the camera about ẑ for 2π
        eyeposition = rotate(eyeposition₀, Quaternion(step * π, ẑ))
        GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat₀)...), GLMakie.Vec3f(vec(up₀)...))
    end

    if index == 40 # parallel transport the frame to 'a' (backtrack)
        point = getpoint(ℝ³(0, 0, 0), pointa, step)
        paralleltransport(point)
    end

    if index == 41 # jump over the boundary from chart S to chart N
        if toggle.active[]
            toggle.active = false
        end
    end

    if index == 42 # parallel transport the frame to the origin of chart N (backtrack)
        point = getpoint(pointa, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 43 # locate the midpoint along the great circle between 'a' and 'b' and label it 'g'
        if !islabeled["g"]
            GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(pointg)), text = "g", color = :white,
                          align = (:left, :baseline), textsize = textsize, markerspace = :data)
            GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(pointg)), text = "g", color = :white,
                          align = (:left, :baseline), textsize = textsize, markerspace = :data)
            GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(pointg)), text = "g", color = :white,
                          align = (:left, :baseline), textsize = textsize, markerspace = :data)
            GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition₀)...), GLMakie.Vec3f(vec(lookat₀)...), GLMakie.Vec3f(vec(up₀)...))
            islabeled["g"] = true
        end
    end

    if index == 44 # locate the midpoint along the great circle between 'a' and 'e' and label it 'h'
        if !islabeled["h"]
            GLMakie.text!(lscene.scene, GLMakie.Point3f(vec(pointh)), text = "h", color = :white,
                          align = (:left, :baseline), textsize = textsize, markerspace = :data)
            GLMakie.text!(lscene_n.scene, GLMakie.Point3f(vec(pointh)), text = "h", color = :white,
                          align = (:left, :baseline), textsize = textsize, markerspace = :data)
            GLMakie.text!(lscene_s.scene, GLMakie.Point3f(vec(pointh)), text = "h", color = :white,
                          align = (:left, :baseline), textsize = textsize, markerspace = :data)
            GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition₀)...), GLMakie.Vec3f(vec(lookat₀)...), GLMakie.Vec3f(vec(up₀)...))
            islabeled["h"] = true
        end
    end

    if index == 45 # parallel transport the frame to 'g'
        point = getpoint(ℝ³(0, 0, 0), pointg, step)
        paralleltransport(point)
    end

    if index == 46 # mark the frame using the identifier I
        if !islabeled["Ig"]
            mark("I")
            islabeled["Ig"] = true
        end
    end

    if index == 47 # parallel transport the frame back to the origin of chart N (backtrack)
        point = getpoint(pointg, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 48 # parallel transport the frame to 'h'
        point = getpoint(ℝ³(0, 0, 0), pointh, step)
        paralleltransport(point)
    end

    if index == 49 # mark the frame using the identifier I
        if !islabeled["Ih"]
            mark("I")
            islabeled["Ih"] = true
        end
    end

    if index == 50 # parallel transport the frame back to the origin of chart N (backtrack)
        point = getpoint(pointh, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 51 # parallel transport the frame to 'a'
        point = getpoint(ℝ³(0, 0, 0), pointa, step)
        paralleltransport(point)
    end

    if index == 52 # jump over the boundary from chart N into S
        if !(toggle.active[])
            toggle.active = true
        end
    end

    if index == 53 # parallel transport the frame to the origin of chart S
        point = getpoint(pointa, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 54 # parallel transport the frame to 'g'
        point = getpoint(ℝ³(0, 0, 0), pointg, step)
        paralleltransport(point)
    end

    if index == 55 # mark the frame using the identifier II
        if !islabeled["IIg"]
            mark("II")
            islabeled["IIg"] = true
        end
    end

    if index == 56 # parallel transport the frame back to the origin of chart S (backtrack)
        point = getpoint(pointg, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 57 # parallel transport the frame to 'h'
        point = getpoint(ℝ³(0, 0, 0), pointh, step)
        paralleltransport(point)
    end

    if index == 58 # mark the frame using the identifier II
        if !islabeled["IIh"]
            mark("II")
            islabeled["IIh"] = true
        end
    end

    if index == 59 # parallel transport the frame back to the origin of chart S (backtrack)
        point = getpoint(pointh, ℝ³(0, 0, 0), step)
        paralleltransport(point)
    end

    if index == 60 # rotate the camera about ẑ for 2π
        eyeposition = rotate(eyeposition₀, Quaternion(step * π, ẑ))
        GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat₀)...), GLMakie.Vec3f(vec(up₀)...))
    end
end