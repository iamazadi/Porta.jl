using GLMakie


## test showtori
segments = rand(5:10)
toruscolor = RGBAf(rand(3)..., 0.0)
toruscolorarray = Observable(fill(toruscolor, segments, segments))
showtori(toruscolorarray, toruscolor)
samplecolor = toruscolorarray[][1, 1]
@test samplecolor.alpha > 0.0

## test getpoint
source = normalize(ℝ⁴(rand(4)))
sink = normalize(ℝ⁴(rand(4)))
timestep = rand()
point = getpoint(source, sink, timestep)
@test typeof(point) <: ℝ⁴

## test paralleltransport
points = Dict{String, ℝ⁴}()
points["o"] = ℝ⁴(0.0, 0.0, 0.0, 0.0)

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

fig = Figure()

sliderx¹ = Slider(fig[5, 3], range = -1:0.00001:1, startvalue = 0)
sliderx² = Slider(fig[6, 3], range = -1:0.00001:1, startvalue = 0)
sliderx³ = Slider(fig[7, 3], range = -1:0.00001:1, startvalue = 0)
sliderx⁴ = Slider(fig[8, 3], range = -1:0.00001:1, startvalue = 0)
sliders = [sliderx¹, sliderx², sliderx³, sliderx⁴]
initialvalues = [to_value(x.value) for x in sliders]
paralleltransport(source, sink, timestep, points, sliderx¹, sliderx², sliderx³, sliderx⁴)
modifiedvalues = [to_value(x.value) for x in sliders]
@test all(!isapprox(initialvalues[i], modifiedvalues[i]) for i in eachindex(sliders))

## test paralleltransport with a string name to represent a point
set = ["i", "m", "k", "p", "a", "e", "c", "g"]
source = rand(set)
sink = rand(set)
while source == sink
    global sink = rand(set)
end
initialvalues = [to_value(x.value) for x in sliders]
paralleltransport(source, sink, timestep, points, sliderx¹, sliderx², sliderx³, sliderx⁴)
modifiedvalues = [to_value(x.value) for x in sliders]
@test all(!isapprox(initialvalues[i], modifiedvalues[i]) for i in eachindex(sliders))

## test paralleltransport without a time step
source = rand(set)
sink = rand(set)
while source == sink
    global sink = rand(set)
end
initialvalues = [to_value(x.value) for x in sliders]
paralleltransport(source, sink, points, sliderx¹, sliderx², sliderx³, sliderx⁴)
modifiedvalues = [to_value(x.value) for x in sliders]
@test any(!isapprox(initialvalues[i], modifiedvalues[i]) for i in eachindex(sliders))

# test paralleltransport with a given path
path = ["d"; "f"; "n"; "l"]
toggle = Toggle(fig, active = false)
p₁ = Observable(points["d"])
tail = Observable(Point3f(rand(3)))
x̂ = ℝ³(1.0, 0.0, 0.0)
ŷ = ℝ³(0.0, 1.0, 0.0)
ẑ = ℝ³(0.0, 0.0, 1.0)
arrowx¹head = Observable(Point3f(x̂))
arrowx²head = Observable(Point3f(ŷ))
arrowx³head = Observable(Point3f(ẑ))
ghostps = Observable([tail[], tail[], tail[]])
ghostns = Observable([arrowx¹head[], arrowx²head[], arrowx³head[]])
tolerance = 1e-4
initialvalues = [to_value(x.value) for x in sliders]
paralleltransport(path, timestep, points, toggle.active[], p₁[], tail, arrowx¹head, arrowx²head, arrowx³head, ghostps, ghostns, sliderx¹, sliderx², sliderx³, sliderx⁴, tolerance = tolerance)
modifiedvalues = [to_value(x.value) for x in sliders]
@test any(!isapprox(initialvalues[i], modifiedvalues[i]) for i in eachindex(sliders))

## test resetcamera
lscene = LScene(fig[1:8, 1:2])
lscenen = LScene(fig[1:2, 3])
lscenes = LScene(fig[3:4, 3])
eyeposition = ℝ³(Float64.(vec(lscene.scene.camera.eyeposition[]))...)
eyepositionn = ℝ³(Float64.(vec(lscenen.scene.camera.eyeposition[]))...)
eyepositions = ℝ³(Float64.(vec(lscenes.scene.camera.eyeposition[]))...)
lookat = ℝ³(0.0, 0.0, 0.0)
lookatn = ℝ³(0.0, 0.0, 0.0)
lookats = ℝ³(0.0, 0.0, 0.0)
up = ℝ³(0.0, 0.0, 1.0)
message = resetcamera(lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)
@test typeof(message) <: String

## test markframe
name = rand(set)
identifier = "I"
islabeled = Dict{String, Bool}()
visible = Observable(rand([true, false]))
fontsize = 0.5
arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.05
rotation = gettextrotation(lscene)
rotationn = gettextrotation(lscenen)
rotations = gettextrotation(lscenes)
markframe(name, identifier, islabeled, visible, tail, arrowx¹head, arrowx²head, arrowx³head, linewidth, arrowsize, fontsize, rotation, rotationn, rotations, lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)
@test islabeled[name * identifier]


## test updateui
chart = toggle.active[]
p₁ = Observable(ℝ⁴(rand(4)))
tangentvector = Observable(ℝ⁴(1.0, 0.0, 0.0, 0.0))
tailn = Observable(Point3f(0.0, 0.0, 0.0))
tails = Observable(Point3f(0.0, 0.0, 0.0))
arrowx¹headn = Observable(Point3f(x̂))
arrowx²headn = Observable(Point3f(ŷ))
arrowx³headn = Observable(Point3f(ẑ))
arrowx¹heads = Observable(Point3f(x̂))
arrowx²heads = Observable(Point3f(ŷ))
arrowx³heads = Observable(Point3f(ẑ))
arrowcolorn = Observable([RGBAf(1.0, 0.0, 0.0, 1.0)])
arrowcolors = Observable([RGBAf(1.0, 0.0, 0.0, 1.0)])
red = RGBAf(1.0, 0.0, 0.0, 1.0)
green = RGBAf(0.0, 1.0, 0.0, 1.0)
blue = RGBAf(0.0, 0.0, 1.0, 1.0)
arrowxcolor = Observable([red, green, blue])
arrowxcolorn = Observable([red, green, blue])
arrowxcolors = Observable([red, green, blue])
tail, head = Observable(Point3f(rand(3))), Observable(Point3f(0.0, 0.0, 1.0))
ps = @lift([$tail])
ns = @lift([$head])
psn = @lift([$tail])
nsn = @lift([$head])
pss = @lift([$tail])
nss = @lift([$head])
initialtangentvector = tangentvector[]
updateui(chart, p₁[], tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)
@test !isapprox(initialtangentvector, tangentvector[])

## test updatepoint
point = ℝ⁴(rand(4))
p₁[] = ℝ⁴(rand(4))
p₀ = Observable(ℝ⁴(0.0, 0.0, 0.0, 0.0))
initialp₀ = p₀[]
initialp₁ = p₁[]
updatepoint(point, p₀, p₁, toggle.active[], tangentvector, tail, tailn, tails, arrowx¹head, arrowx²head, arrowx³head, arrowx¹headn, arrowx²headn,
        arrowx³headn, arrowx¹heads, arrowx²heads, arrowx³heads, arrowcolorn, arrowcolors, arrowxcolorn, arrowxcolors,
        ps, ns, psn, nsn, pss, nss, ghostps, ghostns)
@test all([!isapprox(p₁[], initialp₁), !isapprox(p₀[], initialp₀)])


## test rotatecamera
message = rotatecamera(timestep, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes)
@test typeof(message) <: String


## test labelpoint
label = "o"
point = ℝ⁴(rand(4))
set1visible = Observable(true)
set2visible = Observable(false)
markersize = 0.05
islabeled[label] = false
labelpoint(label, point, islabeled, set, set1visible, set2visible, toggle.active, markersize,
    lscene, lscenen, lscenes, rotation, rotationn, rotations, fontsize, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)
@test islabeled[label]


## test switchcharts
chartname = rand(["N", "S"])
message = switchcharts(chartname, toggle.active)
@test typeof(message) <: String


## test rotatetorus
q₁ = Dualquaternion(ℍ(π / 4, ẑ) * ℍ(π / 2, x̂))
q₂ = Dualquaternion(ℍ(-π / 4, ẑ) * ℍ(π / 2, x̂))
smallradius = rand()
bigradius = smallradius + rand()
toruscolor = GLMakie.RGBAf(0.0, 0.0, 0.0, 0.0)
toruscolorarray = GLMakie.Observable(fill(toruscolor, segments, segments))
configurationq = Dualquaternion(ℝ³(0.0, 0.0, 0.0))
torus = buildsurface(lscene, constructtorus(configurationq, smallradius, bigradius, segments = segments), toruscolorarray)
torusn = buildsurface(lscenen, constructtorus(configurationq, smallradius, bigradius, segments = segments), toruscolorarray)
toruss = buildsurface(lscenes, constructtorus(configurationq, smallradius, bigradius, segments = segments), toruscolorarray)
message = rotatetorus(q₁, q₂, timestep, segments, smallradius, bigradius, torus, torusn, toruss)
@test typeof(message) <: String


## test showset1
set1visible[] = false
set2visible[] = false
showset1(set1visible, set2visible)
@test set1visible[] && !(set2visible[])


## test showset2
showset2(set1visible, set2visible)
@test !(set1visible[]) && set2visible[]