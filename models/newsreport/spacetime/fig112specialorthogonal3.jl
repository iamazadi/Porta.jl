using GLMakie
using Porta

segments = 30
resolution = (1920, 1080)
resolution1 = (1080, 1080)
framerate = 60
startframe = 1
modelname = "fig112specialorthogonal3"
tolerance = 1e-3
# Text labels for specifying landmarks
fontsize = 0.5
arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.05
markersize = 0.05
lookat = ℝ³(0.0, 0.0, 0.0)
lookatn = ℝ³(0.0, 0.0, 0.0)
lookats = ℝ³(0.0, 0.0, 0.0)
up = ℝ³(0.0, 0.0, 1.0)
# the small radius of a torus
smallradius = 0.04
# the large radius of a torus
bigradius = 1.0
sphereradius = 1.0
transparency = true
# The marker's position in a chart
p₀ = Observable(ℝ⁴(0.0, 0.0, 0.0, 0.0))
p₁ = Observable(ℝ⁴(0.0, 0.0, 0.0, 0.0))
tangentvector = Observable(ℝ⁴(1.0, 0.0, 0.0, 0.0))
objectives = []
currentobjective = Observable("Determine the clutching function!")
islabeled = Dict{String, Bool}()
transparentcolor = RGBAf(0.0, 0.0, 0.0, 0.0)
clearwhite = RGBAf(1.0, 1.0, 1.0, 0.5)
red = RGBAf(1.0, 0.0, 0.0, 1.0)
green = RGBAf(0.0, 1.0, 0.0, 1.0)
blue = RGBAf(0.0, 0.0, 1.0, 1.0)
x̂ = ℝ³(1.0, 0.0, 0.0)
ŷ = ℝ³(0.0, 1.0, 0.0)
ẑ = ℝ³(0.0, 0.0, 1.0)
# The coordinates of the vertices of a hybercube
points = Dict{String, ℝ⁴}()
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

path1 = ["b"; "j"; "q"; "h"]
path2 = ["d"; "f"; "n"; "l"]

q₁ = Dualquaternion(ℍ(π / 4, ẑ) * ℍ(π / 2, x̂))
q₂ = Dualquaternion(ℍ(-π / 4, ẑ) * ℍ(π / 2, x̂))

makefigure() = Figure(size = resolution)

fig = with_theme(makefigure, theme_black())
toggle = Toggle(fig, active = false)
controlstatus = Observable(true) # in order to prevent a recursive call when updating UI controls
pl = PointLight(Point3f(0), RGBf(20, 20, 20))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1:8, 1:2], show_axis=true,
                        scenekw = (size = resolution, lights = [pl, al], backgroundcolor=:white, clear=true))
lscenen = LScene(fig[1:2, 3], show_axis=true,
                          scenekw = (size = resolution1, lights = [pl, al], backgroundcolor=:white, clear=true))
lscenes = LScene(fig[3:4, 3], show_axis=true,
                          scenekw = (size = resolution1, lights = [pl, al], backgroundcolor=:white, clear=true))

eyeposition = ℝ³(Float64.(vec(lscene.scene.camera.eyeposition[]))...)
eyepositionn = ℝ³(Float64.(vec(lscenen.scene.camera.eyeposition[]))...)
eyepositions = ℝ³(Float64.(vec(lscenes.scene.camera.eyeposition[]))...)

sliderx¹ = Slider(fig[5, 3], range = -1:0.00001:1, startvalue = 0)
sliderx² = Slider(fig[6, 3], range = -1:0.00001:1, startvalue = 0)
sliderx³ = Slider(fig[7, 3], range = -1:0.00001:1, startvalue = 0)
sliderx⁴ = Slider(fig[8, 3], range = -1:0.00001:1, startvalue = 0)

textbox = Textbox(fig, placeholder = "Enter a name", width = 115)
textbox.stored_string = "I"
# theme buttons for a dark theme
buttoncolor = RGBf(0.3, 0.3, 0.3)
markbutton = Button(fig, label = "Mark the frame", buttoncolor = buttoncolor)
resetbutton = Button(fig, label = "Reset frame", buttoncolor = buttoncolor)
label = Label(fig, lift(x -> x ? "Chart S" : "Chart N", toggle.active))
fig[9, 3] = grid!(hcat(textbox, markbutton, resetbutton, toggle, label), tellheight = false)
status = Label(fig, currentobjective, fontsize = 30)
fig[9, 1:2] = status

# Spheres for showing the boundary of S³ as the skin of a solid ball
configurationq = Dualquaternion(ℝ³(0.0, 0.0, 0.0))
colorarray = Observable(fill(RGBAf(1.0, 1.0, 1.0, 0.2), segments, segments))
sphere = buildsurface(lscene, constructsphere(configurationq, sphereradius, segments = segments), colorarray, transparency = transparency)
colorarray = Observable(fill(RGBAf(1.0, 0.0, 1.0, 0.2), segments, segments))
spheren = buildsurface(lscenen, constructsphere(configurationq, sphereradius, segments = segments), colorarray, transparency = transparency)
colorarray = Observable(fill(RGBAf(1.0, 1.0, 0.0, 0.2), segments, segments))
spheres = buildsurface(lscenes, constructsphere(configurationq, sphereradius, segments = segments), colorarray, transparency = transparency)

toruscolor = RGBAf(0.0, 0.0, 0.0, 0.0)
toruscolorarray = Observable(fill(toruscolor, segments, segments))

torus = buildsurface(lscene, constructtorus(configurationq, smallradius, bigradius, segments = segments), toruscolorarray, transparency = transparency)
torusn = buildsurface(lscenen, constructtorus(configurationq, smallradius, bigradius, segments = segments), toruscolorarray, transparency = transparency)
toruss = buildsurface(lscenes, constructtorus(configurationq, smallradius, bigradius, segments = segments), toruscolorarray, transparency = transparency)

segmentsmemo = []
for (keya, valuea) in points
    for (keyb, valueb) in points
        if isapprox(abs(norm(valuea - valueb)), 1.0)
            if (keya, keyb) ∉ segmentsmemo && (keyb, keya) ∉ segmentsmemo
                lines!(lscene, [Point3f(project(valuea)), Point3f(project(valueb))], color = collect(1:2), linewidth = 5, colorrange = (1, 2), colormap = :gold)
                lines!(lscenen, [Point3f(project(valuea)), Point3f(project(valueb))], color = collect(1:2), linewidth = 5, colorrange = (1, 2), colormap = :gold, visible = @lift(!$(toggle.active)))
                lines!(lscenes, [Point3f(project(valuea)), Point3f(project(valueb))], color = collect(1:2), linewidth = 5, colorrange = (1, 2), colormap = :gold, visible = toggle.active)
                push!(segmentsmemo, (keya, keyb))
            end
        end
    end
end
# Add the origin point after drawing the edges of the hypercube
points["o"] = ℝ⁴(0.0, 0.0, 0.0, 0.0)

# The arrows pointing to the current location of the frame
arrowcolor = Observable([RGBAf(1.0, 0.0, 0.0, 1.0)])
arrowcolorn = Observable([RGBAf(1.0, 0.0, 0.0, 1.0)])
arrowcolors = Observable([RGBAf(1.0, 0.0, 0.0, 1.0)])
tail, head = Observable(Point3f(0.0, 0.0, 0.0)), Observable(Point3f(0.0, 0.0, 1.0))
ps = @lift([$tail])
ns = @lift([$head])
psn = @lift([$tail])
nsn = @lift([$head])
pss = @lift([$tail])
nss = @lift([$head])
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = arrowcolor,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
arrows!(lscenen,
    psn, nsn, fxaa = true, # turn on anti-aliasing
    color = arrowcolorn,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
arrows!(lscenes,
    pss, nss, fxaa = true, # turn on anti-aliasing
    color = arrowcolors,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

# The frames
tailn = Observable(Point3f(0.0, 0.0, 0.0))
tails = Observable(Point3f(0.0, 0.0, 0.0))
arrowx¹head = Observable(Point3f(x̂))
arrowx²head = Observable(Point3f(ŷ))
arrowx³head = Observable(Point3f(ẑ))
arrowx¹headn = Observable(Point3f(x̂))
arrowx²headn = Observable(Point3f(ŷ))
arrowx³headn = Observable(Point3f(ẑ))
arrowx¹heads = Observable(Point3f(x̂))
arrowx²heads = Observable(Point3f(ŷ))
arrowx³heads = Observable(Point3f(ẑ))
arrowxcolor = Observable([red, green, blue])
arrowxcolorn = Observable([red, green, blue])
arrowxcolors = Observable([red, green, blue])

arrows!(lscene,
    @lift([$tail, $tail, $tail]), @lift([$arrowx¹head, $arrowx²head, $arrowx³head]), fxaa = true, # turn on anti-aliasing
    color = arrowxcolor,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
arrows!(lscenen,
    @lift([$tailn, $tailn, $tailn]), @lift([$arrowx¹headn, $arrowx²headn, $arrowx³headn]), fxaa = true, # turn on anti-aliasing
    color = arrowxcolorn,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
arrows!(lscenes,
    @lift([$tails, $tails, $tails]), @lift([$arrowx¹heads, $arrowx²heads, $arrowx³heads]), fxaa = true, # turn on anti-aliasing
    color = arrowxcolors,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
ghostps = Observable([tail[], tail[], tail[]])
ghostns = Observable([arrowx¹head[], arrowx²head[], arrowx³head[]])
arrows!(lscene,
    ghostps, ghostns, fxaa = true, # turn on anti-aliasing
    color = [RGBAf(1.0, 1.0, 0.0, 0.5), RGBAf(0.0, 1.0, 0.0, 0.5), RGBAf(0.0, 1.0, 1.0, 0.5)],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

rotation = gettextrotation(lscene)
rotationn = gettextrotation(lscenen)
rotations = gettextrotation(lscenes)

set1visible = Observable(true)
set2visible = Observable(true)

push!(objectives, x -> labelpoint("o", points["o"], islabeled, set1, set1visible, set2visible, toggle.active, markersize, lscene, lscenen, lscenes, rotation, rotationn, rotations, fontsize, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up))

for name in set1
    push!(objectives, x -> labelpoint(name, points[name], islabeled, set1, set1visible, set2visible, toggle.active, markersize, lscene, lscenen, lscenes, rotation, rotationn, rotations, fontsize, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up))
end

push!(objectives, x -> rotatecamera(x, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes))

push!(objectives, x -> showset1(set1visible, set2visible))

for name in set1
    push!(objectives, x -> paralleltransport("o", name, x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
    visible = name ∈ set1 ? set1visible : set2visible
    push!(objectives, x -> markframe(name, "I", islabeled, visible, tail, arrowx¹head, arrowx²head, arrowx³head, linewidth, arrowsize, fontsize, rotation, rotationn, rotations, lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up))
    push!(objectives, x -> paralleltransport(name, "o", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
end

push!(objectives, x -> paralleltransport("o", "a", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
push!(objectives, x -> switchcharts("S", toggle.active))
push!(objectives, x -> paralleltransport("a", "o", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))

for name in set1
    push!(objectives, x -> paralleltransport("o", name, x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
    visible = name ∈ set1 ? set1visible : set2visible
    push!(objectives, x -> markframe(name, "II", islabeled, visible, tail, arrowx¹head, arrowx²head, arrowx³head, linewidth, arrowsize, fontsize, rotation, rotationn, rotations, lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up))
    push!(objectives, x -> paralleltransport(name, "o", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
end

push!(objectives, x -> rotatecamera(x, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes))

push!(objectives, x -> paralleltransport("o", "a", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
push!(objectives, x -> switchcharts("N", toggle.active))
push!(objectives, x -> paralleltransport("a", "o", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))

push!(objectives, x -> showset2(set1visible, set2visible))

for name in set2
    push!(objectives, x -> labelpoint(name, points[name], islabeled, set1, set1visible, set2visible, toggle.active, markersize, lscene, lscenen, lscenes, rotation, rotationn, rotations, fontsize, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up))
end

push!(objectives, x -> rotatecamera(x, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes))

for name in set2
    push!(objectives, x -> paralleltransport("o", name, x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
    visible = name ∈ set1 ? set1visible : set2visible
    push!(objectives, x -> markframe(name, "I", islabeled, visible, tail, arrowx¹head, arrowx²head, arrowx³head, linewidth, arrowsize, fontsize, rotation, rotationn, rotations, lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up))
    push!(objectives, x -> paralleltransport(name, "o", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
end

push!(objectives, x -> paralleltransport("o", "a", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
push!(objectives, x -> switchcharts("S", toggle.active))
push!(objectives, x -> paralleltransport("a", "o", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))

for name in set2
    push!(objectives, x -> paralleltransport("o", name, x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
    visible = name ∈ set1 ? set1visible : set2visible
    push!(objectives, x -> markframe(name, "II", islabeled, visible, tail, arrowx¹head, arrowx²head, arrowx³head, linewidth, arrowsize, fontsize, rotation, rotationn, rotations, lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up))
    push!(objectives, x -> paralleltransport(name, "o", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
end

push!(objectives, x -> paralleltransport("o", "a", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))
push!(objectives, x -> switchcharts("N", toggle.active))
push!(objectives, x -> paralleltransport("a", "o", x, points, sliderx¹, sliderx², sliderx³, sliderx⁴))

push!(objectives, x -> rotatecamera(x, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes))

on(sliderx¹.value) do x¹
    # refuse to update the current point whenever controling is off
    if !to_value(controlstatus) return end

    x² = to_value(sliderx².value)
    x³ = to_value(sliderx³.value)
    x⁴ = to_value(sliderx⁴.value)
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
    updatepoint(ℝ⁴(x¹, x², x³, x⁴), p₀, p₁, toggle.active[], tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)
end

on(sliderx².value) do x²
    # refuse to update the current point whenever controling is off
    if !to_value(controlstatus) return end

    x¹ = to_value(sliderx¹.value)
    x³ = to_value(sliderx³.value)
    x⁴ = to_value(sliderx⁴.value)
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
    updatepoint(ℝ⁴(x¹, x², x³, x⁴), p₀, p₁, toggle.active[], tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)
end

on(sliderx³.value) do x³
    # refuse to update the current point whenever controling is off
    if !to_value(controlstatus) return end

    x¹ = to_value(sliderx¹.value)
    x² = to_value(sliderx².value)
    x⁴ = to_value(sliderx⁴.value)
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
    updatepoint(ℝ⁴(x¹, x², x³, x⁴), p₀, p₁, toggle.active[], tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)
end

on(sliderx⁴.value) do x⁴
    # refuse to update the current point whenever controling is off
    if !to_value(controlstatus) return end

    x¹ = to_value(sliderx¹.value)
    x² = to_value(sliderx².value)
    x³ = to_value(sliderx³.value)
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
    updatepoint(ℝ⁴(x¹, x², x³, x⁴), p₀, p₁, toggle.active[], tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)
end

on(toggle.active) do chart
    x¹, x², x³, x⁴ = vec(to_value(p₁))
    controlstatus[] = false
    if !isapprox(to_value(sliderx¹.value), x¹)
        set_close_to!(sliderx¹, x¹)
    end
    if !isapprox(to_value(sliderx².value), x²)
        set_close_to!(sliderx², x²)
    end
    if !isapprox(to_value(sliderx³.value), x³)
        set_close_to!(sliderx³, x³)
    end
    if !isapprox(to_value(sliderx⁴.value), x⁴)
        set_close_to!(sliderx⁴, x⁴)
    end
    controlstatus[] = true
    updateui(chart, p₁[], tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)
end


# animate a path
f = 1
N = f * length(objectives)
timestamps = range(0, N, step = 1 / framerate)
record(fig, "gallery/$modelname.mp4", timestamps; framerate = framerate) do t
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
rotatetorus(q₁, q₂, 0.0, segments, smallradius, bigradius, torus, torusn, toruss)
showtori(toruscolorarray, toruscolor)
resetcamera(lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)

push!(objectives, x -> showset1(set1visible, set2visible))

push!(objectives, x -> paralleltransport(path1, x, points, toggle.active[], p₁[], tail, arrowx¹head, arrowx²head, arrowx³head, ghostps, ghostns, sliderx¹, sliderx², sliderx³, sliderx⁴, tolerance = tolerance))

push!(objectives, x -> rotatecamera(x, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes))

push!(objectives, x -> showset2(set1visible, set2visible))

push!(objectives, x -> rotatetorus(q₁, q₂, x, segments, smallradius, bigradius, torus, torusn, toruss))
push!(objectives, x -> paralleltransport(path2, x, points, toggle.active[], p₁[], tail, arrowx¹head, arrowx²head, arrowx³head, ghostps, ghostns, sliderx¹, sliderx², sliderx³, sliderx⁴, tolerance = tolerance))

push!(objectives, x -> rotatecamera(x, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes))

# animate a path
f = 15
N = f * (length(objectives) - previouslength)
timestamps = range(0, N, step = 1 / framerate)
record(fig, "gallery/$(modelname)part2.mp4", timestamps; framerate = framerate) do t
    τ = t / f + 1 + previouslength
    index = isapprox(τ, length(objectives) + 1) ? Int(floor(τ) - 1) : Int(floor(τ))
    objective = objectives[index]
    step = min(1.0, τ % floor(τ) + 1 / framerate)
    detail = objectives[index](step)
    currentobjective[] = "Current objective ($index): $detail"
    progress = round(100step)
    println("($index) $detail . $progress")
end