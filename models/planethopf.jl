import FileIO
import DataFrames
import CSV
import GLMakie
using Porta


figuresize = (1080, 1920)
segments = 30
basemapsegments = 30
modelname = "planethopf"
boundary_names = ["Australia", "Japan", "United States of America", "United Kingdom", "Antarctica", "Iran", "Chile", "France", "South Africa", "Turkey", "Pakistan", "India", "Russia", "Canada", "Mexico"]
frames_number = 720 # 360 * length(boundary_names)
samplename = "United States of America"
indices = Dict()
ratio = 0.999
x̂ = ℝ³(1.0, 0.0, 0.0)
ŷ = ℝ³(0.0, 1.0, 0.0)
ẑ = ℝ³(0.0, 0.0, 1.0)
linewidth = 10.0
arrowsize = GLMakie.Vec3f(0.02, 0.02, 0.04)
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(1.0, 0.0, 0.0))
totalstages = 1 # length(boundary_names)
initialized = [false for _ in 1:totalstages]


"""
    paralleltransport(q, α, θ, segments)

Parallel transport the basis frame at point `q` in the direction angle `α` with distance `θ`,
and smoothness `segments`.
"""
function paralleltransport(q::SpinVector, α::Float64, θ::Float64, segments::Int)
    h = Quaternion(q)
    x¹ = K(1) * h
    x² = K(2) * h
    x³ = K(3) * h
    v = sin(α) * K(1) + cos(α) * K(2)
    θ₀ = θ / segments
    track = [h]
    track1 = [x¹]
    track2 = [x²]
    track3 = [x³]
    for i in 1:segments
        n = exp(v * i * θ₀) * h
        x¹ = normalize(x¹ - dot(x¹, n) * n)
        x² = normalize(x² - dot(x², n) * n)
        x³ = normalize(x³ - dot(x³, n) * n)
        push!(track, n)
        push!(track1, x¹)
        push!(track2, x²)
        push!(track3, x³)
    end
    track, track1, track2, track3
end


makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :black))

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask.png")
## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_nodes = Vector{Vector{ℝ³}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            indices[name] = length(boundary_nodes)
        end
    end
end


function getcenter(nodes)
    center = [0.0; 0.0; 0.0]
    for i in eachindex(nodes)
        geographic = convert_to_geographic(nodes[i])
        center = center + geographic
    end
    center[1] = 1.0 # the unit spherical Earth
    center[2] = center[2] ./ length(nodes)
    center[3] = center[3] ./ length(nodes)
    convert_to_cartesian(center)
end


θ1 = float(π)
timesign = 1
q = SpinVector(ℝ³(0.0, 1.0, 0.0), timesign)
chart = (π / 2, -π / 2, π / 2, -π / 2)
basemap1 = Basemap(lscene, q, chart, basemapsegments, basemap_color, transparency = true)
basemap2 = Basemap(lscene, q, chart, basemapsegments, basemap_color, transparency = true)

whirls = []
_whirls = []
for i in eachindex(boundary_nodes)
    center = getcenter(boundary_nodes[i])
    hue = dot(Quaternion(0.0, 0.0, 1.0, 0.0), Quaternion(0.0, vec(center)...)) * 360
    # hue = i / length(boundary_names) * 360
    color = GLMakie.HSVA(hue, 100, 100, 0.25) # getcolor(boundary_nodes[i], colorref, 0.5)
    _color = GLMakie.HSVA(hue, 100, 100, 0.05) # getcolor(boundary_nodes[i], colorref, 0.1)
    w = [SpinVector(boundary_nodes[i][j], timesign) for j in eachindex(boundary_nodes[i])]
    whirl = Whirl(lscene, w, 0.0, θ1, segments, color, transparency = true)
    _whirl = Whirl(lscene, w, θ1, 2π, segments, _color, transparency = true)
    push!(whirls, whirl)
    push!(_whirls, _whirl)
end

ps = [GLMakie.Point3f(0.0, 0.0, 0.0) for _ in 1:3]
tails = []
heads = []
arrowcolors = []
for i in 1:segments
    hue = Int(floor(i / segments * 360.0))
    arrowcolor = GLMakie.Observable([GLMakie.HSVA(hue, 100, 100, 1.0), GLMakie.HSVA(hue, 100, 100, 0.5), GLMakie.HSVA(hue, 100, 100, 0.25)])
    push!(arrowcolors, arrowcolor)
    _tails = GLMakie.Observable(ps)
    _heads = GLMakie.Observable(ps)
    push!(tails, _tails)
    push!(heads, _heads)
    GLMakie.arrows!(lscene, _tails, _heads, fxaa = true, color = arrowcolor, linewidth = 0.01, arrowsize = GLMakie.Vec3f(0.02, 0.02, 0.02))
end

linepoints = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
linecolors = GLMakie.Observable(Int[])
lines = GLMakie.lines!(lscene, linepoints, linewidth = linewidth, color = linecolors, colormap = :rainbow, transparency = false)
lines.colorrange = (0, frames_number) # update plot attribute directly
starman = FileIO.load("data/Starman_3.stl")
starman_sprite = GLMakie.mesh!(
    lscene,
    starman,
    color = [tri[1][2] for tri in starman for i in 1:3],
    colormap = GLMakie.Reverse(:Spectral)
)
scale = 1 / 350
GLMakie.scale!(starman_sprite, scale, scale, scale)


function animate(progress, totalprogress, frame)
    index = indices[samplename]
    center = getcenter(boundary_nodes[index])
    r, θ, ϕ = convert_to_geographic(center)
    ψ = totalprogress * 4π
    α = exp(im * ψ / 2.0)
    β = Complex(0.0)
    γ = Complex(0.0)
    δ = exp(-im * ψ / 2.0)
    transform = SpinTransformation(α, β, γ, δ)
    q = transform * SpinVector(θ , ϕ, timesign)
    update!(basemap1, q)
    update!(basemap2, antipodal(q))
    # update!(basemap1, chart)
    # update!(basemap2, chart)
    for i in eachindex(boundary_nodes)
        points = SpinVector[]
        for node in boundary_nodes[i]
            r, θ, ϕ = convert_to_geographic(node)
            push!(points, transform * SpinVector(θ, ϕ, timesign))
        end
        update!(whirls[i], points, θ1, 2π)
        update!(_whirls[i], points, 0.0, θ1)
    end

    α = sin(totalprogress * 2π) * 2π
    θ = cos(progress * 2π) * 2π
    track, track1, track2, track3 = paralleltransport(q, α, θ, segments)
    for i in 1:segments
        x = project(track[i])
        x¹ = normalize(project(track1[i]))
        x² = normalize(project(track2[i]))
        x³ = normalize(project(track3[i]))
        tails[i][] = [GLMakie.Point3f(vec(x)...) for _ in 1:3]
        heads[i][] = [GLMakie.Point3f(vec(x¹)...), GLMakie.Point3f(vec(x²)...), GLMakie.Point3f(vec(x³)...)]
        hue = Int(floor(i / segments * 360.0))
        arrowcolors[i][] = [GLMakie.HSVA(hue, 100, 100, 0.25), GLMakie.HSVA(hue, 100, 100, 0.5), GLMakie.HSVA(hue, 100, 100, 1.0)]
    end

    linepoints[] = map(x -> GLMakie.Point3f(vec(project(x))...), track)
    push!(linecolors[], frame)
    notify(linecolors) # tell points and colors that their value has been updated

    ang, u = getrotation(ẑ, normalize(project(track3[end])))
    _q = Quaternion(ang / 2, u)
    initial1 = ℝ³(vec(_q * Quaternion(0.0, vec(ẑ)...) * conj(_q))[2:4])
    v = project(normalize(track1[end]))
    ang1, u1 = getrotation(cross(initial1, v), v)
    q1 = Quaternion(ang1 / 2, u1)
    rotation = q1 * _q
    rotation = GLMakie.Quaternion(vec(rotation)[2], vec(rotation)[3], vec(rotation)[4], vec(rotation)[1])
    GLMakie.rotate!(starman_sprite, rotation)
    p = project(track[end])
    GLMakie.translate!(starman_sprite, GLMakie.Point3f(vec(p)...))
    global lookat = ratio * lookat + (1.0 - ratio) * p
end

updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


write(frame::Int) = begin
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    global samplename = boundary_names[stage]
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    animate(stageprogress, progress, frame)
    updatecamera()
end


write(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    write(frame)
end