import FileIO
import GLMakie
import LinearAlgebra
using Porta


GLMakie.Quaternion(q::Porta.Quaternion) = GLMakie.Quaternion(vec(q)[2:4]..., vec(q)[1])


figuresize = (4096, 2160)
segments = 360
segments2 = 30
frames_number = 1440
modelname = "liebracket"
indices = Dict()
T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
u = 𝕍(T, X, Y, Z)
q = Quaternion(T, X, Y, Z)
tolerance = 1e-3
@assert(isnull(u, atol = tolerance), "u in not a null vector, $u.")
@assert(isapprox(norm(q), 1, atol = tolerance), "q in not a unit quaternion, $(norm(q)).")
gauge1 = 0.0
gauge2 = π / 2
gauge3 = float(π)
gauge4 = 3π / 2
gauge5 = 2π
chart = (-π / 4, π / 4, -π / 4, π / 4)
M = I(4)
eyeposition = normalize(ℝ³(1.0, 0.0, 1.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(1.0, 0.0, 0.0))
ẑ = ℝ³([0.0; 0.0; 1.0])
α = 0.99
totalstages = 100

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = Set()
while length(boundary_names) < 10
    push!(boundary_names, rand(countries["name"]))
end
boundary_nodes = Vector{Vector{ℝ³}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            println(name)
            indices[name] = length(boundary_nodes)
        end
    end
end

points = Vector{Quaternion}[]
for i in eachindex(boundary_nodes)
    _points = Quaternion[]
    for node in boundary_nodes[i]
        r, θ, ϕ = convert_to_geographic(node)
        push!(_points, q * Quaternion(exp(ϕ / 4 * K(1) + θ / 2 * K(2))))
    end
    push!(points, _points)
end

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

reference = FileIO.load("data/basemap_color.png")
mask = FileIO.load("data/basemap_mask.png")
basemap1 = Basemap(lscene, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene, q, gauge2, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.2)
    color2 = getcolor(boundary_nodes[i], reference, 0.4)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
end

ϵ = π / 2
i₁ = rand(1:length(points))
i₂ = rand(1:length(points[i₁]))
q₀ = points[i₁][i₂]
q₁ = q₀ * Quaternion(exp(ϵ * K(1)))
q₂ = q₁ * Quaternion(exp(ϵ * K(2)))
q₃ = q₂ * Quaternion(exp(-ϵ * K(1)))
q₄ = q₃ * Quaternion(exp(-ϵ * K(2)))
linepoints = []
linecolors = []
lines = []
for i in 1:totalstages
    push!(linepoints, GLMakie.Observable(GLMakie.Point3f[]))
    push!(linecolors, GLMakie.Observable(Int[]))
    push!(lines, GLMakie.lines!(lscene, linepoints[i], color = linecolors[i], linewidth = 10, colorrange = (1, frames_number), colormap = :rainbow))
end

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
g1tail = GLMakie.Observable(GLMakie.Point3f(vec(project(q₀))...))
g2tail = GLMakie.Observable(GLMakie.Point3f(vec(project(q₁))...))
_g1tail = GLMakie.Observable(GLMakie.Point3f(vec(project(q₂))...))
_g2tail = GLMakie.Observable(GLMakie.Point3f(vec(project(q₃))...))
motiontail = GLMakie.Observable(GLMakie.Point3f(vec(project(q₀))...))
g1head = GLMakie.Observable(g2tail[] - g1tail[])
g2head = GLMakie.Observable(_g1tail[] - g2tail[])
_g1head = GLMakie.Observable(_g2tail[] - _g1tail[])
_g2head = GLMakie.Observable(GLMakie.Point3f(vec(project(q₄))...) - _g2tail[])
motionhead = GLMakie.Observable(GLMakie.Point3f(vec(project(q₄))...) - motiontail[])
ps = GLMakie.@lift([$g1tail, $g2tail, $_g1tail, $_g2tail, $motiontail])
ns = GLMakie.@lift([$g1head, $g2head, $_g1head, $_g2head, $motionhead])
colorants = [:red, :green, :blue, :orange, :black]
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation1 = GLMakie.@lift(Porta.Quaternion(getrotation(ẑ, $rotationaxis)...))
rotation2 = GLMakie.@lift(Porta.Quaternion($rotationangle, $rotationaxis))
rotation = GLMakie.@lift(GLMakie.Quaternion($rotation2 * $rotation1))
titles = ["g₁", "g₂", "-g₁", "-g₂", "motion"]
GLMakie.text!(lscene,
    GLMakie.@lift(map(x -> GLMakie.Point3f(vec((isnan(x) ? ẑ : x))), [$g1tail + $g1head, $g2tail + $g2head, $_g1tail + $_g1head, $_g2tail + $_g2head, $motiontail + $motionhead])),
    text = titles,
    color = colorants,
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)
previousstage = 0
prevoiusq₀ = deepcopy(-q₁)


updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


flow(linecolors, linepoints, q, ϵ, direction, stage, frame) = begin
    _q = q * Quaternion(exp(ϵ * direction))
    _point = GLMakie.Point3f(vec(project(_q)))
    point = GLMakie.Point3f(vec(project(q)))
    push!(linepoints[], _point)
    push!(linecolors[], frame)
    GLMakie.notify(linepoints)
    GLMakie.notify(linecolors)
    if previousstage == 4 && stage == 1
        global prevoiusq₀ = deepcopy(q₀)
        global q₀ = deepcopy(q₄)
    end
    global previousstage = deepcopy(stage)
    p = GLMakie.Point3f(LinearAlgebra.normalize(vec(_point) - vec(point)))
    if stage == 1
        g1tail[] = point
        g1head[] = p * 0.5
    end
    if stage == 2
        g2tail[] = point
        g2head[] = p * 0.5
    end
    if stage == 3
        _g1tail[] = point
        _g1head[] = p * 0.5
    end
    if stage == 4
        _g2tail[] = point
        _g2head[] = p * 0.5
    end
    motiontail[] = point
    motionhead[] = GLMakie.Point3f(vec(normalize(project(q * Quaternion(exp(10ϵ * K(3))) - q)))) * 0.5
    _q
end

stageflow(frame, stageprogress, linecolors, linepoints) = begin
    tempq = deepcopy(q₀)
    if stageprogress < 0.25
        _q = frame == 1 ? q₀ : q₁
        global q₁ = flow(linecolors, linepoints, _q, ϵ / float(segments2), K(1), 1, frame)
        tempq = deepcopy(q₁)
        if frame == 1
            global lookat = project(q₁)
            global up = -project(q₁)
            global eyeposition = ẑ * Float64(π)
        end
        global lookat = α * lookat + (1.0 - α) * project(q₁)
        global up = α * lookat + (1.0 - α) * -project(q₁)
        global q₂ = q₁
    end
    if 0.25 < stageprogress ≤ 0.5
        global q₂ = flow(linecolors, linepoints, q₂, ϵ / float(segments2), K(2), 2, frame)
        tempq = deepcopy(q₂)
        global lookat = α * lookat + (1.0 - α) * project(q₂)
        global up = α * lookat + (1.0 - α) * -project(q₂)
        global q₃ = q₂
    end
    if 0.5 < stageprogress ≤ 0.75
        global q₃ = flow(linecolors, linepoints, q₃, -ϵ / float(segments2), K(1), 3, frame)
        tempq = deepcopy(q₃)
        global lookat = α * lookat + (1.0 - α) * project(q₃)
        global up = α * lookat + (1.0 - α) * -project(q₃)
        global q₄ = q₃
    end
    if 0.75 < stageprogress
        global q₄ = flow(linecolors, linepoints, q₄, -ϵ / float(segments2), K(2), 4, frame)
        tempq = deepcopy(q₄)
        global lookat = α * lookat + (1.0 - α) * project(q₄)
        global up = α * lookat + (1.0 - α) * -project(q₄)
        global q₁ = q₄
    end
    global eyeposition = α * eyeposition + (1.0 - α) * (normalize(project(q₀) - project(prevoiusq₀)) * π)
end


animate(frame::Int) = begin
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    stageflow(frame, stageprogress, linecolors[stage], linepoints[stage])
    if frame == 1
        update!(basemap1, q, gauge1, M)
        update!(basemap2, q, gauge3, M)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1, gauge3, M)
            update!(whirls2[i], points[i], gauge3, gauge5, M)
        end
    end
    updatecamera()
end


# animate(1)

# for i in 2:1440
#     animate(i)
# end


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)