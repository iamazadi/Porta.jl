import FileIO
import GLMakie
import LinearAlgebra
using Porta


# figuresize = (4096, 2160)
figuresize = (1920, 1080)
segments = 120
frames_number = 1800
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
eyeposition = normalize(ℝ³(-0.25, 0.25, -0.0)) * π * 0.2
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(1.0, 0.0, 0.0))
totalstages = 30

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = ["United States of America", "Antarctica", "Iran"]
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
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :black))

reference = FileIO.load("data/basemap_color.png")
mask = FileIO.load("data/basemap_mask.png")
basemap1 = Basemap(lscene, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene, q, gauge2, M, chart, segments, mask, transparency = true)
basemap3 = Basemap(lscene, q, gauge3, M, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene, q, gauge4, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.2)
    color2 = getcolor(boundary_nodes[i], reference, 0.4)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
end


q₀ = points[3][92]
q₁ = q₀
q₂ = q₀
q₃ = q₀
q₄ = q₀
ϵ = 1.0
θ_collection = collect(range(0.0, stop = ϵ, length = segments))
linepoints = []
linecolors = []
lines = []
for i in 1:totalstages
    push!(linepoints, GLMakie.Observable(GLMakie.Point3f[]))
    push!(linecolors, GLMakie.Observable(Int[]))
    push!(lines, GLMakie.lines!(lscene, linepoints[i], color = linecolors[i], linewidth = 10))
end

ps = GLMakie.Observable([GLMakie.Point3f(0, 0, 0)])
ns = GLMakie.Observable([GLMakie.Vec3f(0, 0, 1)])
arrowsize = GLMakie.Vec3f(0.01, 0.02, 0.03)
linewidth = 0.005
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:gold],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :center
)

updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


flow(line, linecolors, linepoints, q, ϵ, direction, frame) = begin
    _q = q * Quaternion(exp(ϵ * direction))
    _point = GLMakie.Point3f(vec(project(_q)))
    point = GLMakie.Point3f(vec(project(q)))
    push!(linepoints[], _point)
    push!(linecolors[], frame)
    GLMakie.notify(linepoints)
    GLMakie.notify(linecolors)
    line.colorrange = (0, frame)
    ps[] = [_point]
    ns[] = [GLMakie.Vec3f(LinearAlgebra.normalize(vec(_point) - vec(point)) .* 0.1)]
    _q
end

stageflow(frame, stageprogress, line, linecolors, linepoints) = begin
    if stageprogress < 0.25
        global q₁ = flow(line, linecolors, linepoints, q₁, ϵ / float(segments), K(1), frame)
        global lookat = project(q₁)
        global up = -project(q₁)
        global q₂ = q₁
    end
    if 0.25 < stageprogress ≤ 0.5
        global q₂ = flow(line, linecolors, linepoints, q₂, ϵ / float(segments), K(2), frame)
        global lookat = project(q₂)
        global up = -project(q₂)
        global q₃ = q₂
    end
    if 0.5 < stageprogress ≤ 0.75
        global q₃ = flow(line, linecolors, linepoints, q₃, -ϵ / float(segments), K(1), frame)
        global lookat = project(q₃)
        global up = -project(q₃)
        global q₄ = q₃
    end
    if 0.75 < stageprogress
        global q₄ = flow(line, linecolors, linepoints, q₄, -ϵ / float(segments), K(2), frame)
        global lookat = project(q₄)
        global up = -project(q₄)
        global q₁ = q₄
    end
end


animate(frame::Int) = begin
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    stageflow(frame, stageprogress, lines[stage], linecolors[stage], linepoints[stage])
    if frame == 1
        update!(basemap1, q, gauge1, M)
        update!(basemap2, q, gauge2, M)
        update!(basemap3, q, gauge3, M)
        update!(basemap4, q, gauge4, M)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1, gauge3, M)
            update!(whirls2[i], points[i], gauge3, gauge5, M)
        end
    end
    updatecamera()
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end

# GLMakie.save(joinpath("gallery", "$(modelname)01.png"), fig)