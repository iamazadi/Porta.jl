import FileIO
import GLMakie

using Porta

segments = 30
resolution = (1920, 1080)
resolution1 = (1080, 1080)
FPS = 60
startframe = 1
modelname = "fig112specialorthogonal3"
objectives = []
tolerance = 1e-3

# The marker's position in a chart
p₀ = GLMakie.Observable(ℝ⁴(0.0, 0.0, 0.0, 0.0))
p₁ = GLMakie.Observable(ℝ⁴(0.0, 0.0, 0.0, 0.0))
tangentvector = GLMakie.Observable(ℝ⁴(1.0, 0.0, 0.0, 0.0))
currentobjective = GLMakie.Observable("Determine the clutching function!")

islabeled = Dict()

x̂ = ℝ³(1.0, 0.0, 0.0)
ŷ = ℝ³(0.0, 1.0, 0.0)
ẑ = ℝ³(0.0, 0.0, 1.0)

makefigure() = GLMakie.Figure(resolution = resolution)

fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
toggle = GLMakie.Toggle(fig, active = false)
controlstatus = GLMakie.Observable(true) # in order to prevent a recursive call when updating UI controls
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
screen = GLMakie.display(fig, resolution = resolution)
lscene = GLMakie.LScene(fig[1:8, 1:2], show_axis=true,
                        scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=:white, clear=true))
lscene_n = GLMakie.LScene(fig[1:2, 3], show_axis=true,
                          scenekw = (resolution = resolution1, lights = [pl, al], backgroundcolor=:white, clear=true))
lscene_s = GLMakie.LScene(fig[3:4, 3], show_axis=true,
                          scenekw = (resolution = resolution1, lights = [pl, al], backgroundcolor=:white, clear=true))

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
cam_n = GLMakie.camera(lscene_n.scene) # this is how to access the scenes camera
cam_s = GLMakie.camera(lscene_s.scene) # this is how to access the scenes camera
eyeposition = ℝ³(Float64.(vec(lscene.scene.camera.eyeposition[]))...)
eyeposition_n = ℝ³(Float64.(vec(lscene_n.scene.camera.eyeposition[]))...)
eyeposition_s = ℝ³(Float64.(vec(lscene_s.scene.camera.eyeposition[]))...)

sliderx¹ = GLMakie.Slider(fig[5, 3], range = -1:0.00001:1, startvalue = 0)
sliderx² = GLMakie.Slider(fig[6, 3], range = -1:0.00001:1, startvalue = 0)
sliderx³ = GLMakie.Slider(fig[7, 3], range = -1:0.00001:1, startvalue = 0)
sliderx⁴ = GLMakie.Slider(fig[8, 3], range = -1:0.00001:1, startvalue = 0)

textbox = GLMakie.Textbox(fig, placeholder = "Enter a name", width = 115)
textbox.stored_string = "I"
# theme buttons for a dark theme
buttoncolor = GLMakie.RGBf(0.3, 0.3, 0.3)
markbutton = GLMakie.Button(fig, label = "Mark the frame", buttoncolor = buttoncolor)
resetbutton = GLMakie.Button(fig, label = "Reset frame", buttoncolor = buttoncolor)
label = GLMakie.Label(fig, GLMakie.lift(x -> x ? "Chart S" : "Chart N", toggle.active))
fig[9, 3] = GLMakie.grid!(GLMakie.hcat(textbox, markbutton, resetbutton, toggle, label), tellheight = false)
status = GLMakie.Label(fig, currentobjective, fontsize = 30)
fig[9, 1:2] = status

# Spheres for showing the boundary of S³ as the skin of a solid ball
transparency = true
configurationq = Dualquaternion(ℝ³(0.0, 0.0, 0.0))
radius = 1.0
colorarray = GLMakie.Observable(fill(GLMakie.RGBAf(1.0, 1.0, 1.0, 0.2), segments, segments))
sphere = buildsurface(lscene, constructsphere(configurationq, radius, segments = segments), colorarray, transparency = transparency)
colorarray = GLMakie.Observable(fill(GLMakie.RGBAf(1.0, 0.0, 1.0, 0.2), segments, segments))
sphere_n = buildsurface(lscene_n, constructsphere(configurationq, radius, segments = segments), colorarray, transparency = transparency)
colorarray = GLMakie.Observable(fill(GLMakie.RGBAf(1.0, 1.0, 0.0, 0.2), segments, segments))
sphere_s = buildsurface(lscene_s, constructsphere(configurationq, radius, segments = segments), colorarray, transparency = transparency)

r = 0.04
R = 1.0
toruscolor = GLMakie.RGBAf(0.0, 0.0, 0.0, 0.0)
colorarray = GLMakie.Observable(fill(toruscolor, segments, segments))

torus = buildsurface(lscene, constructtorus(configurationq, r, R, segments = segments), colorarray, transparency = transparency)
torus_n = buildsurface(lscene_n, constructtorus(configurationq, r, R, segments = segments), colorarray, transparency = transparency)
torus_s = buildsurface(lscene_s, constructtorus(configurationq, r, R, segments = segments), colorarray, transparency = transparency)

# landmarks
points = Dict()


points["a"] = ℝ⁴(-0.5, -0.5, -0.5, -0.5)
points["b"] = ℝ⁴(0.5, -0.5, -0.5, -0.5)
points["c"] = ℝ⁴(-0.5, 0.5, -0.5, -0.5)
points["d"] = ℝ⁴(0.5, 0.5, -0.5, -0.5)
points["e"] = ℝ⁴(-0.5, -0.5, 0.5, -0.5)
points["f"] = ℝ⁴(0.5, -0.5, 0.5, -0.5)
points["g"] = ℝ⁴(-0.5, 0.5, 0.5, -0.5)
points["h"] = ℝ⁴(0.5, 0.5, 0.5, -0.5)

points["i"] = ℝ⁴(-0.5, -0.5, -0.5, 0.5)
points["j"] = ℝ⁴(0.5, -0.5, -0.5, 0.5)
points["k"] = ℝ⁴(-0.5, 0.5, -0.5, 0.5)
points["l"] = ℝ⁴(0.5, 0.5, -0.5, 0.5)
points["m"] = ℝ⁴(-0.5, -0.5, 0.5, 0.5)
points["n"] = ℝ⁴(0.5, -0.5, 0.5, 0.5)
points["p"] = ℝ⁴(-0.5, 0.5, 0.5, 0.5)
points["q"] = ℝ⁴(0.5, 0.5, 0.5, 0.5)

set1 = ["i", "m", "k", "p", "a", "e", "c", "g"]
set2 = ["n", "j", "l", "q", "b", "d", "f", "h"]
segmentsmemo = []
for (keya, valuea) in points
    for (keyb, valueb) in points
        if isapprox(abs(norm(valuea - valueb)), 1.0)
            if (keya, keyb) ∉ segmentsmemo && (keyb, keya) ∉ segmentsmemo
                GLMakie.lines!(lscene, [GLMakie.Point3f(project(valuea)), GLMakie.Point3f(project(valueb))], color = collect(1:2), linewidth = 5, colorrange = (1, 2), colormap = :gold)
                GLMakie.lines!(lscene_n, [GLMakie.Point3f(project(valuea)), GLMakie.Point3f(project(valueb))], color = collect(1:2), linewidth = 5, colorrange = (1, 2), colormap = :gold, visible = GLMakie.@lift(!$(toggle.active)))
                GLMakie.lines!(lscene_s, [GLMakie.Point3f(project(valuea)), GLMakie.Point3f(project(valueb))], color = collect(1:2), linewidth = 5, colorrange = (1, 2), colormap = :gold, visible = toggle.active)
                push!(segmentsmemo, (keya, keyb))
            end
        end
    end
end

points["o"] = ℝ⁴(0.0, 0.0, 0.0, 0.0)

# Text labels for specifying landmarks
fontsize = 0.5

lookat = ℝ³(0.0, 0.0, 0.0)
up = ℝ³(0.0, 0.0, 1.0)

# The arrows pointing to the current location of the frame

width = 0.05
arrowcolor = GLMakie.Observable([GLMakie.RGBA(1.0, 0.0, 0.0, 1.0)])
arrowcolorn = GLMakie.Observable([GLMakie.RGBA(1.0, 0.0, 0.0, 1.0)])
arrowcolors = GLMakie.Observable([GLMakie.RGBA(1.0, 0.0, 0.0, 1.0)])
tail, head = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0)), GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 1.0))
ps = GLMakie.@lift([$tail])
ns = GLMakie.@lift([$head])
psn = GLMakie.@lift([$tail])
nsn = GLMakie.@lift([$head])
pss = GLMakie.@lift([$tail])
nss = GLMakie.@lift([$head])
colorants = [:red]
arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.05
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = arrowcolor,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
GLMakie.arrows!(lscene_n,
    psn, nsn, fxaa = true, # turn on anti-aliasing
    color = arrowcolorn,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
GLMakie.arrows!(lscene_s,
    pss, nss, fxaa = true, # turn on anti-aliasing
    color = arrowcolors,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

# The frames

transparentcolor = GLMakie.RGBAf(0.0, 0.0, 0.0, 0.0)
clearwhite = GLMakie.RGBAf(1.0, 1.0, 1.0, 0.5)
red = GLMakie.RGBAf(1.0, 0.0, 0.0, 1.0)
green = GLMakie.RGBAf(0.0, 1.0, 0.0, 1.0)
blue = GLMakie.RGBAf(0.0, 0.0, 1.0, 1.0)
tail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
tailn = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
tails = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
arrowx¹head = GLMakie.Observable(GLMakie.Point3f(x̂))
arrowx²head = GLMakie.Observable(GLMakie.Point3f(ŷ))
arrowx³head = GLMakie.Observable(GLMakie.Point3f(ẑ))
arrowx¹headn = GLMakie.Observable(GLMakie.Point3f(x̂))
arrowx²headn = GLMakie.Observable(GLMakie.Point3f(ŷ))
arrowx³headn = GLMakie.Observable(GLMakie.Point3f(ẑ))
arrowx¹heads = GLMakie.Observable(GLMakie.Point3f(x̂))
arrowx²heads = GLMakie.Observable(GLMakie.Point3f(ŷ))
arrowx³heads = GLMakie.Observable(GLMakie.Point3f(ẑ))
arrowxcolor = GLMakie.Observable([red, green, blue])
arrowxcolorn = GLMakie.Observable([red, green, blue])
arrowxcolors = GLMakie.Observable([red, green, blue])

GLMakie.arrows!(lscene,
    GLMakie.@lift([$tail, $tail, $tail]), GLMakie.@lift([$arrowx¹head, $arrowx²head, $arrowx³head]), fxaa = true, # turn on anti-aliasing
    color = arrowxcolor,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
GLMakie.arrows!(lscene_n,
    GLMakie.@lift([$tailn, $tailn, $tailn]), GLMakie.@lift([$arrowx¹headn, $arrowx²headn, $arrowx³headn]), fxaa = true, # turn on anti-aliasing
    color = arrowxcolorn,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
GLMakie.arrows!(lscene_s,
    GLMakie.@lift([$tails, $tails, $tails]), GLMakie.@lift([$arrowx¹heads, $arrowx²heads, $arrowx³heads]), fxaa = true, # turn on anti-aliasing
    color = arrowxcolors,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
ghostps = GLMakie.Observable([tail[], tail[], tail[]])
ghostns = GLMakie.Observable([arrowx¹head[], arrowx²head[], arrowx³head[]])
GLMakie.arrows!(lscene,
    ghostps, ghostns, fxaa = true, # turn on anti-aliasing
    color = [GLMakie.RGBAf(1.0, 1.0, 0.0, 0.5), GLMakie.RGBAf(0.0, 1.0, 0.0, 0.5), GLMakie.RGBAf(0.0, 1.0, 1.0, 0.5)],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

rotation = gettextrotation(lscene)
rotationn = gettextrotation(lscene_n)
rotations = gettextrotation(lscene_s)

set1visible = GLMakie.Observable(true)
set2visible = GLMakie.Observable(true)


function showtori()
    color = GLMakie.to_value(colorarray)[1]
    if isapprox(color.alpha, 0)
        color = GLMakie.RGBAf(toruscolor.r, toruscolor.g, toruscolor.b, 0.5)
        colorarray[] = fill(color, segments, segments)
    end
    "Show the great circle that contains points a; b; c; d"
end


"""
    getpoint(r₀, r₁, t)

Calculate a point along the connecting path from the starting point `r₀` to the destination `r₁` with the given time `t`.
"""
function getpoint(r₀::ℝ⁴, r₁::ℝ⁴, t::Float64)
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
    point1 = typeof(source) <: ℝ⁴ ? source : points[source]
    point2 = typeof(sink) <: ℝ⁴ ? sink : points[sink]
    point = getpoint(point1, point2, t)
    x¹, x², x³, x⁴ = vec(point)
    GLMakie.set_close_to!(sliderx¹, x¹)
    GLMakie.set_close_to!(sliderx², x²)
    GLMakie.set_close_to!(sliderx³, x³)
    GLMakie.set_close_to!(sliderx⁴, x⁴)
    GLMakie.notify(sliderx¹.value)
    GLMakie.notify(sliderx².value)
    GLMakie.notify(sliderx³.value)
    GLMakie.notify(sliderx⁴.value)
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
    mark(name, label, visible)

Marks te current frame with the given `name` as a prefix.
"""
function mark(name::String, label::String, visible::GLMakie.Observable{Bool})
    index = name * label
    if get(islabeled, index, false)
        return "mark the frame using the identifier '$label'"
    end
    colors = [GLMakie.RGBAf(1.0, 0.0, 0.0, 0.5); GLMakie.RGBAf(0.0, 1.0, 0.0, 0.5); GLMakie.RGBAf(0.0, 0.0, 1.0, 0.5)]
    _ps = [tail[], tail[], tail[]]
    _ns = [arrowx¹head[], arrowx²head[], arrowx³head[]]
    GLMakie.arrows!(lscene,
        _ps, _ns, fxaa = true, # turn on anti-aliasing
        color = colors,
        linewidth = linewidth / 2.0, arrowsize = arrowsize,
        align = :origin,
        visible = visible
    )
    GLMakie.text!(lscene,
                  _ps .+ _ns,
                  text = ["$(label)₁", "$(label)₂", "$(label)₃"],
                  color = colors,
                  align = (:left, :baseline),
                  fontsize = fontsize / 2.0,
                  rotation = rotation,
                  markerspace = :data,
                  visible = visible)
    resetcam()
    islabeled[index] = true
    "mark the frame at poinr $name with identifier '$label'"
end


"""
    updateui()

Updates the User Interface (UI) such as camera, controls and scene objects.
"""
function updateui()
    chart = GLMakie.to_value(toggle.active)
    q = GLMakie.to_value(p₁)

    r = project(q)
    head = GLMakie.Point3f(r)

    # update the white arrow for pinpointing the position of the current point in the related chart
    ps[] = [GLMakie.Point3f(ℝ³(0.0, 0.0, 0.0))]
    ns[] = [head]
    
    if chart
        pss[] = [tail[], tail[], tail[]]
        nss[] = [arrowx¹heads[], arrowx²heads[], arrowx³heads[]]
        arrowcolors[] = [clearwhite]
        arrowcolorn[] = [transparentcolor]
    else
        psn[] = [tail[], tail[], tail[]]
        nsn[] = [arrowx¹headn[], arrowx²headn[], arrowx³headn[]]
        arrowcolorn[] = [clearwhite]
        arrowcolors[] = [transparentcolor]
    end

    # update the frame in the related chart
    tail[] = head
    if chart
        tails[] = tail[]
        arrowxcolors[] = [red, green, blue]
        # hide the frame in the inactive chart
        arrowxcolorn[] = [transparentcolor, transparentcolor, transparentcolor]
    else
        tailn[] = tail[]
        arrowxcolorn[] = [red, green, blue]
        # hide the frame in the inactive chart
        arrowxcolors[] = [transparentcolor]
    end

    _v = GLMakie.to_value(tangentvector)
    # println("_v: ($_v), h: ($h).")
    if !isapprox(dot(_v, q), 0)
        perp = dot(_v, q) * q
        _v = normalize(_v - perp)
    end
    # @assert(isapprox(_v, ℝ⁴(h)) && !isapprox(dot(_v, ℝ⁴(h)), 0), "_v ($_v) is not perpendicular to q ($q).")
    tangentvector[] = _v
    tail[] = GLMakie.Point3f(r)
    g = ℍ(tangentvector[])
    arrowx¹head[] = GLMakie.Point3f(rotate(x̂, g))
    arrowx²head[] = GLMakie.Point3f(rotate(ŷ, g))
    arrowx³head[] = GLMakie.Point3f(rotate(ẑ, g))
    ghostps[] = [tail[], tail[], tail[]]
    ghostns[] = [arrowx¹head[], arrowx²head[], arrowx³head[]]
end


"""
    resetcam()

Resets the eyeposition, look at and up vactors of cameras (caused by creating objects in the scene.)
"""
function resetcam()
    updatecamera!(lscene, eyeposition, lookat, up)
    updatecamera!(lscene_n, eyeposition_n, lookat, up)
    updatecamera!(lscene_s, eyeposition_s, lookat, up)
    "Reset 'the eyeposition', 'look at' and 'up' vactors of cameras."
end


"""
    rotatecam(step)

Resets the eyeposition, look at and up vactors of cameras caused by creating objects in the scene,
with the given `step` which determines the rotation degree.
"""
function rotatecam(step::Float64)
    q = ℍ(step * 2π, ẑ)
    _eyeposition = rotate(eyeposition, q)
    _eyeposition_n = rotate(eyeposition_n, q)
    _eyeposition_s = rotate(eyeposition_s, q)
    updatecamera!(lscene, _eyeposition, lookat, up)
    updatecamera!(lscene_n, _eyeposition_n, lookat, up)
    updatecamera!(lscene_s, _eyeposition_s, lookat, up)
    "Rotate the camera about the ẑ axis."
end


"""
    updatepoint(p)

Updates the current point with the given coordinates `p`.
"""
function updatepoint(p::ℝ⁴)
    point₀ = GLMakie.to_value(p₁)
    # verify that the point in in a solid ball
    if norm(p) > 1
        point₁ = normalize(p)
    else
        point₁ = p
    end

    # prevent the update if the current point has not changed compare to the previous one
    threshold = 1e-8
    if isapprox(point₀, point₁, atol = threshold)
        return
    end

    # commit the changes
    p₀[] = point₀
    p₁[] = point₁

    # update the UI
    updateui()
end


showset1() = begin
    set1visible[] = true
    set2visible[] = false
    "Show the first set of points for comparing frames."
end


showset2() = begin
    set1visible[] = false
    set2visible[] = true
    "Show the second set of points for comparing frames."
end


labelpoint(name::String) = begin
    point = GLMakie.Point3f(project(points[name]))
    if !get(islabeled, name, false)
        visible = name ∈ set1 ? set1visible : set2visible
        visiblen = GLMakie.@lift($visible && !$(toggle.active))
        visibles = GLMakie.@lift($visible && $(toggle.active))
        GLMakie.meshscatter!(lscene, point, markersize = 0.05, color = :black, visible = visible)
        GLMakie.meshscatter!(lscene_n, point, markersize = 0.05, color = :black, visible = visiblen)
        GLMakie.meshscatter!(lscene_s, point, markersize = 0.05, color = :black, visible = visibles)
        GLMakie.text!(lscene.scene, point, text = name, color = :black,
                      align = (:left, :baseline), rotation = rotation, fontsize = fontsize, markerspace = :data, visible = visible)
        GLMakie.text!(lscene_n.scene, point, text = name, color = :black,
                      align = (:left, :baseline), rotation = rotationn, fontsize = fontsize, markerspace = :data, visible = visiblen)
        GLMakie.text!(lscene_s.scene, point, text = name, color = :black,
                      align = (:left, :baseline), rotation = rotations, fontsize = fontsize, markerspace = :data, visible = visibles)
        resetcam()
        islabeled[name] = true
    end
    "Labeled point $name in $point"
end


switchcharts(chart::String) = begin
    if chart == "S"
        toggle.active[] = true
        return "Switched coordinate charts from N to S."
    end
    if chart == "N"
        toggle.active[] = false
        return "Switched coordinate charts from S to N."
    end
end


function paralleltransport(path::Vector{String}, t::Float64)
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
    point₁ = GLMakie.to_value(p₁)
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
    v₁ = ℝ⁴(1.0, 0.0, 0.0, 0.0)
    ϵ = 1e-4
    chart = false # the N chart
    for i in range(ϵ, stop = 1.0, length = 30)
        q = i * point
        if !isapprox(dot(v₁, q), 0)
            perp = dot(v₁, q) * q
            v₁ = normalize(v₁ - perp)
        end
    end
    @assert(isapprox(dot(v₁, point), 0, atol = tolerance), "v₁ $v₁ is not perpendicular to point $point.")

    # Basis II
    v₂ = ℝ⁴(1.0, 0.0, 0.0, 0.0)
    chart = false
    for i in range(ϵ, stop = 1.0, length = 30)
        q = i * points["a"]
        if !isapprox(dot(v₂, q), 0)
            perp = dot(v₂, q) * q
            v₂ = normalize(v₂ - perp)
        end
    end
    @assert(isapprox(dot(v₂, points["a"]), 0, atol = tolerance), "v₂ $v₂ is not perpendicular to point $(points["a"]).")
    chart = true # the S chart
    for i in range(ϵ, stop = 1.0, length = 30)
        q = (1 - i) * points["a"]
        if !isapprox(dot(v₂, q), 0)
            perp = dot(v₂, q) * q
            v₂ = normalize(v₂ - perp)
        end
    end
    @assert(isapprox(dot(v₂, points["a"]), 0, atol = tolerance), "v₂ $v₂ is not perpendicular to point $(points["a"]).")
    for i in range(ϵ, stop = 1.0, length = 30)
        q = i * point
        if !isapprox(dot(v₂, q), 0)
            perp = dot(v₂, q) * q
            v₂ = normalize(v₂ - perp)
        end
    end
    @assert(isapprox(dot(v₂, point), 0, atol = tolerance), "v₂ $v₂ is not perpendicular to point $point.")
    
    tail[] = GLMakie.Point3f(project(point))
    g = ℍ(v₁)
    arrowx¹head[] = GLMakie.Point3f(rotate(x̂, g))
    arrowx²head[] = GLMakie.Point3f(rotate(ŷ, g))
    arrowx³head[] = GLMakie.Point3f(rotate(ẑ, g))
    g = ℍ(v₂)
    _arrowx¹head = GLMakie.Point3f(rotate(x̂, g))
    _arrowx²head = GLMakie.Point3f(rotate(ŷ, g))
    _arrowx³head = GLMakie.Point3f(rotate(ẑ, g))
    ghostps[] = [tail[], tail[], tail[]]
    ghostns[] = [_arrowx¹head, _arrowx²head, _arrowx³head]
    "Parallel transport the frame from $source to $sink"
end


function rotatecircle(q₁::Dualquaternion, q₂::Dualquaternion, t::Float64)
    r₁, r₂ = getrotation(q₁), getrotation(q₂)
    q = t * r₂ + (1 - t) * r₁
    q = Dualquaternion(normalize(q))
    matrix = constructtorus(q, r, R, segments = segments)
    updatesurface!(matrix, torus)
    updatesurface!(matrix, torus_n)
    updatesurface!(matrix, torus_s)
    rotation = getrotation(q)
    "rotate the great circle with $rotation"
end


path1 = ["b"; "j"; "q"; "h"]
path2 = ["d"; "f"; "n"; "l"]

q₁ = Dualquaternion(ℍ(π / 4, ẑ) * ℍ(π / 2, x̂))
q₂ = Dualquaternion(ℍ(-π / 4, ẑ) * ℍ(π / 2, x̂))

push!(objectives, x -> labelpoint("o"))

for name in set1
    push!(objectives, x -> labelpoint(name))
end

push!(objectives, x -> rotatecam(x))

push!(objectives, x -> showset1())

for name in set1
    push!(objectives, x -> paralleltransport("o", name, x))
    visible = name ∈ set1 ? set1visible : set2visible
    push!(objectives, x -> mark(name, "I", visible))
    push!(objectives, x -> paralleltransport(name, "o", x))
end

push!(objectives, x -> paralleltransport("o", "a", x))
push!(objectives, x -> switchcharts("S"))
push!(objectives, x -> paralleltransport("a", "o", x))

for name in set1
    push!(objectives, x -> paralleltransport("o", name, x))
    visible = name ∈ set1 ? set1visible : set2visible
    push!(objectives, x -> mark(name, "II", visible))
    push!(objectives, x -> paralleltransport(name, "o", x))
end

push!(objectives, x -> rotatecam(x))

push!(objectives, x -> paralleltransport("o", "a", x))
push!(objectives, x -> switchcharts("N"))
push!(objectives, x -> paralleltransport("a", "o", x))

push!(objectives, x -> showset2())

for name in set2
    push!(objectives, x -> labelpoint(name))
end

push!(objectives, x -> rotatecam(x))

for name in set2
    push!(objectives, x -> paralleltransport("o", name, x))
    visible = name ∈ set1 ? set1visible : set2visible
    push!(objectives, x -> mark(name, "I", visible))
    push!(objectives, x -> paralleltransport(name, "o", x))
end

push!(objectives, x -> paralleltransport("o", "a", x))
push!(objectives, x -> switchcharts("S"))
push!(objectives, x -> paralleltransport("a", "o", x))

for name in set2
    push!(objectives, x -> paralleltransport("o", name, x))
    visible = name ∈ set1 ? set1visible : set2visible
    push!(objectives, x -> mark(name, "II", visible))
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
    x⁴ = GLMakie.to_value(sliderx⁴.value)
    radius = √abs(x¹^2 + x²^2 + x³^2 + x⁴^2)
    if radius > 1
        # in order to prevent DomainError with negative values
        intermediate = 1 - (x²^2 + x³^2 + x⁴^2)
        if isapprox(intermediate, 0, atol = 1e-3)
            intermediate = 0
        end
        x¹ = √intermediate * sign(x¹)
    end

    # update the current point
    updatepoint(ℝ⁴(x¹, x², x³, x⁴))
end

GLMakie.on(sliderx².value) do x²
    # refuse to update the current point whenever controling is off
    if !GLMakie.to_value(controlstatus) return end

    x¹ = GLMakie.to_value(sliderx¹.value)
    x³ = GLMakie.to_value(sliderx³.value)
    x⁴ = GLMakie.to_value(sliderx⁴.value)
    radius = √abs(x¹^2 + x²^2 + x³^2 + x⁴^2)
    if radius > 1
        # in order to prevent DomainError with negative values
        intermediate = 1 - min(1, (x¹^2 + x³^2 + x⁴^2))
        if isapprox(intermediate, 0, atol = 1e-3)
            intermediate = 0
        end
        x² = √intermediate * sign(x²)
    end

    # update the current point
    updatepoint(ℝ⁴(x¹, x², x³, x⁴))
end

GLMakie.on(sliderx³.value) do x³
    # refuse to update the current point whenever controling is off
    if !GLMakie.to_value(controlstatus) return end

    x¹ = GLMakie.to_value(sliderx¹.value)
    x² = GLMakie.to_value(sliderx².value)
    x⁴ = GLMakie.to_value(sliderx⁴.value)
    radius = √abs(x¹^2 + x²^2 + x³^2 + x⁴^2)
    if radius > 1
        # in order to prevent DomainError with negative values
        intermediate = 1 - (x¹^2 + x²^2 + x⁴^2)
        if isapprox(intermediate, 0, atol = 1e-3)
            intermediate = 0
        end
        x³ = √intermediate * sign(x³)
    end

    # update the current point
    updatepoint(ℝ⁴(x¹, x², x³, x⁴))
end

GLMakie.on(sliderx⁴.value) do x⁴
    # refuse to update the current point whenever controling is off
    if !GLMakie.to_value(controlstatus) return end

    x¹ = GLMakie.to_value(sliderx¹.value)
    x² = GLMakie.to_value(sliderx².value)
    x³ = GLMakie.to_value(sliderx³.value)
    radius = √abs(x¹^2 + x²^2 + x³^2 + x⁴^2)
    if radius > 1
        # in order to prevent DomainError with negative values
        intermediate = 1 - (x¹^2 + x²^2 + x³^2)
        if isapprox(intermediate, 0, atol = 1e-3)
            intermediate = 0
        end
        x⁴ = √intermediate * sign(x⁴)
    end

    # update the current point
    updatepoint(ℝ⁴(x¹, x², x³, x⁴))
end

GLMakie.on(toggle.active) do chart
    x¹, x², x³, x⁴ = vec(GLMakie.to_value(p₁))
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
    if !isapprox(GLMakie.to_value(sliderx⁴.value), x⁴)
        GLMakie.set_close_to!(sliderx⁴, x⁴)
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
# initialize the tori
rotatecircle(q₁, q₂, 0.0)
showtori()
resetcam()

push!(objectives, x -> showset1())

push!(objectives, x -> paralleltransport(path1, x))

push!(objectives, x -> rotatecam(x))

push!(objectives, x -> showset2())

push!(objectives, x -> rotatecircle(q₁, q₂, x))
push!(objectives, x -> paralleltransport(path2, x))

push!(objectives, x -> rotatecam(x))

# animate a path
framerate = 60
f = 15
N = f * (length(objectives) - previouslength)
timestamps = range(0, N, step = 1 / framerate)
GLMakie.record(fig, "gallery/$(modelname)part2.mp4", timestamps; framerate = framerate) do t
    τ = t / f + 1 + previouslength
    index = isapprox(τ, length(objectives) + 1) ? Int(floor(τ) - 1) : Int(floor(τ))
    objective = objectives[index]
    step = min(1.0, τ % floor(τ) + 1 / framerate)
    detail = objectives[index](step)
    currentobjective[] = "Current objective ($index): $detail"
    progress = round(100step)
    println("($index) $detail . $progress")
end
