import FileIO
import DataFrames
import CSV
import Makie
using LinearAlgebra
using Serialization
using ModelingToolkit, DifferentialEquations, Latexify
import GLMakie
using Porta


figuresize = (1920, 1080)
segments = 30
basemapsegments = 120
frames_number = 1440

r₁ = 0.8 # experiments: 1-6
λ₁ = 1 + 0.2 * im # experiment 1
λ₂ = im # experiment 2
λ₃ = 2 + im # experiment 3
λ₄ = 0 # experiment 4
λ₅ = 1 # experiment 5
λ₆ = -im # experiment 6

r₇ = 0.5 # experiment 7
λ₇ = -im # experiment 7

r₈ = 0.8 # experiment 8
λ₈ = 2 - im # experiment 8

r₀ = 3.0 # radius of lambda path circle
λ₀ = λ₈ # center of lambda path circle
ϕ₀ = 0.0
ϕ = 0.0

operator = imag(λ₀) ≥ 0 ? "+" : "-"
version = "r₀=$(r₀)_λ₀=$(float(real(λ₀)))_$(operator)_𝑖$(abs(float(imag(λ₀))))"
modelname = "segment25_staircase_$version"
L = 10.0 # max x range
L′ = -L
x̂ = [1.0; 0.0; 0.0]
ŷ = [0.0; 1.0; 0.0]
ẑ = [0.0; 1.0; 0.0]
α = 0.25
markersize = 0.04
linewidth = 8.0
arrowsize = GLMakie.Vec3f(0.02, 0.02, 0.04)

γ₁, θ₁, λ₁, w₁, t₁, latex1 = deserialize(joinpath("data", "solutions", "gamma1_$version"))
γ₂, θ₂, λ_array = deserialize(joinpath("data", "solutions", "gamma2_$version"))
γ₃, θ₃, s2_path₃, t₃, latex3 = deserialize(joinpath("data", "solutions", "gamma3_$version"))

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(0.1019, 0.0, 0.1019)
lscene = GLMakie.LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = backgroundcolor))

# cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
# eyeposition = GLMakie.Vec3f(cam.eyeposition[]...)
eyeposition = [1; 1; 1]
lookat = [0; 0; 0]
up = [0; 0; 1]
# GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask1.png")
## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = ["Antarctica"]
boundary_nodes = Vector{Vector{Vector{Float64}}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
        end
    end
end
whirls = []
θ1 = float(π)
θ2 = 0.0
# for i in eachindex(boundary_nodes)
#     color = getcolor(boundary_nodes[i], colorref, 0.1)
#     w = [σmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])]
#     # whirl1 = Whirl(lscene, w, [θ1 for _ in 1:length(w)], [θ2 for _ in 1:length(w)], segments, color, transparency = true)
#     whirl1 = Whirl(lscene, w, [0.0 for _ in 1:length(w)], [2π for _ in 1:length(w)], basemapsegments, color, transparency = true)
#     push!(whirls, whirl1)
# end
color = getcolor(πmap.(γ₃), colorref, 0.05)
whirl1 = Whirl(lscene, γ₃, [0.0 for _ in 1:length(γ₃)], [2π for _ in 1:length(γ₃)], 360, color, transparency = true)

steps_number = length(t₁)
basemap1 = Basemap(lscene, x -> G(θ1, σmap(x)), basemapsegments, basemap_color, transparency = true)
# basemap2 = Basemap(lscene, x -> G(θ2, σmap(x)), basemapsegments, basemap_color, transparency = true)
points1 = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors1 = GLMakie.Observable(Int[])
lines1 = GLMakie.lines!(lscene, points1, linewidth = 2linewidth, color = colors1, colormap = :reds, transparency = false)
points2 = [GLMakie.Observable(GLMakie.Point3f[]) for _ in 1:steps_number]
colors2 = [GLMakie.Observable(Int[]) for _ in 1:steps_number]
lines2 = [GLMakie.lines!(lscene, points2[i], linewidth = linewidth, color = colors2[i], colormap = :greens, transparency = false) for i in 1:steps_number]
points3 = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors3 = GLMakie.Observable(Int[])
lines3 = GLMakie.lines!(lscene, points3, linewidth = 2linewidth, color = colors3, colormap = :blues, transparency = false)
lines1.colorrange = (0, frames_number) # update plot attribute directly
for i in eachindex(lines2)
    lines2[i].colorrange = (0, frames_number) # update plot attribute directly
end
lines3.colorrange = (0, frames_number) # update plot attribute directly

band_points1 = []
band_points2 = []
band_colors = []
maxindex = min(map(x -> length(x), γ₂)...)
for i in 1:steps_number - 1
    p1 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:maxindex])
    p2 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:maxindex])
    push!(band_points1, p1)
    push!(band_points2, p2)
    bandcolor = GLMakie.Observable(GLMakie.HSVA(Int(floor(float(i) / float(steps_number - 1) * 360.0)), 100, 100, α))
    push!(band_colors, bandcolor)
    GLMakie.band!(lscene, p1, p2, color=bandcolor, transparency = true)
end

ps = [GLMakie.Point3f(0, 0, 0) for _ in 1:steps_number]
ns = map(p -> 0.1 * GLMakie.Point3f(p[2], p[3], p[1]), ps)
tails = GLMakie.Observable(ps)
heads = GLMakie.Observable(ns)
arrowcolor = GLMakie.Observable([GLMakie.HSVA(Int(floor(float(i) / float(steps_number) * 360.0)), 100, 100, 1.0) for i in 1:steps_number])
lengths = norm.(ns)
GLMakie.arrows!(lscene,
    tails, heads, fxaa = true, # turn on anti-aliasing
    color = arrowcolor,
    linewidth = 0.02, arrowsize = GLMakie.Vec3f(0.04, 0.04, 0.04),
    align = :center)

starman = FileIO.load("data/Starman_3.stl")
starman_sprite = GLMakie.mesh!(
    lscene,
    starman,
    color = [tri[1][2] for tri in starman for i in 1:3],
    colormap = GLMakie.Reverse(:Spectral)
)
scale = 1 / 400
GLMakie.scale!(starman_sprite, scale, scale, scale)
p = [0.0; 0.0; 0.0]

function animate(stage, progress)
    _ϕ = progress * 4π
    q = Quaternion(_ϕ / 2, ẑ)
    transform() = begin
        frame = Int(floor(progress * frames_number))
        update!(basemap1, x -> G(θ1, σmap(x)) * q)
        # update!(basemap2, x -> G(θ2, σmap(x)) * q)
        # for (i, whirl) in enumerate(whirls)
        #     _w = σmap.(boundary_nodes[i])
        #     _w = map(x -> x * q, _w)
        #     update!(whirl, _w, [θ1 for _ in 1:length(boundary_nodes[i])], [θ2 for _ in 1:length(boundary_nodes[i])])
        # end
        update!(whirl1, map(x -> x * q, γ₃), [0.0 for _ in 1:length(γ₃)], [2π for _ in 1:length(γ₃)])

        _points1 = []
        _colors1 = []
        for i in eachindex(γ₁)
            p = project(γ₁[i] * q)
            push!(_points1, GLMakie.Point3f(p...))
            push!(_colors1, frame)
        end
        points1[] = _points1
        colors1[] = _colors1
        notify(points1); notify(colors1) # tell points and colors that their value has been updated

        for i in 1:steps_number - 1
            _points2 = []
            _colors2 = []
            for j in eachindex(γ₂[i])
                _p = project(γ₂[i][j] * q)
                push!(_points2, _p)
                push!(_colors2, frame)
            end
            points2[i][] = _points2
            colors2[i][] = _colors2
            notify(points2[i]); notify(colors2[i]) # tell points and colors that their value has been updated
        end

        for i in 1:steps_number - 1
            points1 = [GLMakie.Point3f(project(γ₂[i][j] * q)...) for j in 1:maxindex]
            points2 = [GLMakie.Point3f(project(γ₂[i + 1][j] * q)...) for j in 1:maxindex]
            band_points1[i][] = points1
            band_points2[i][] = points2
            bandcolor = GLMakie.HSVA(Int(floor(sin(float(i) / float(steps_number - 1) * 2π) * 360.0)), 100, 100, α)
            band_colors[i][] = bandcolor
        end

        _points3 = []
        _colors3 = []
        for i in eachindex(γ₃)
            p = project(γ₃[i] * q)
            push!(_points3, p)
            push!(_colors3, frame)
        end
        points3[] = _points3
        colors3[] = _colors3
        notify(points3); notify(colors3) # tell points and colors that their value has been updated

        tails[] = [GLMakie.Point3f(project(γ₂[i][begin] * q)) for i in 1:steps_number]
        heads[] = [GLMakie.Point3f(project(γ₂[i][begin] * q)) - GLMakie.Point3f(project(γ₂[i][end] * q)) for i in 1:steps_number]
        hues = [Int(floor(float(i) / float(steps_number) * 360.0)) for i in 1:steps_number]
        hues = hues .+ (progress * 360.0)
        hues = Int.(floor.(hues .% 360.0))
        arrowcolor[] = [GLMakie.HSVA(hues[i], 100, 100, 1.0) for i in 1:steps_number]
        index = max(1, Int(floor(progress * steps_number)))
        vector = project(γ₂[index][begin] * q) - project(γ₂[index][end] * q)
        global up = 0.95 .* up + 0.05 .* vector
    end
    upvector = ẑ
    transform()
    if stage == 1
        i = max(1, Int(floor(progress * length(γ₁))))
        _p = project(γ₁[i] * q)
        global p = 0.95 .* p + 0.05 .* _p
        axis1 = Float64.(normalize(project(K(1) * γ₁[i] * q)))
        tail = p
        head = axis1
        upvector = normalize(head - tail)
    end
    if stage == 2
        i = max(1, Int(floor(progress * length(γ₂[end]))))
        _p = project(γ₂[end][i] * q)
        global p = 0.95 .* p + 0.05 .* _p
        axis1 = Float64.(normalize(project(K(1) * γ₂[end][i] * q)))
        tail = p
        head = axis1
        upvector = normalize(head - tail)
    end
    if stage == 3
        i = max(1, Int(floor(progress * length(γ₃))))
        _p = project(γ₃[i] * q)
        global p = 0.95 .* p + 0.05 .* _p
        axis1 = Float64.(normalize(project(K(1) * γ₃[i] * q)))
        tail = p
        head = axis1
        upvector = normalize(head - tail)
    end
    ang, u = getrotation(ẑ, [Float64.(eyeposition - lookat)...])
    _q = Quaternion(ang / 2, u)
    initial1 = vec(_q * Quaternion([0; ẑ]) * conj(_q))[2:4]
    ang1, u1 = getrotation(cross(initial1, upvector), [Float64.(upvector)...])
    q1 = Quaternion(ang1 / 2, u1)
    rotation = q1 * _q
    rotation = GLMakie.Quaternion(vec(rotation)[2], vec(rotation)[3], vec(rotation)[4], vec(rotation)[1])
    GLMakie.rotate!(starman_sprite, rotation)
    GLMakie.translate!(starman_sprite, GLMakie.Point3f(_p))
end

updatecamera(progress) = begin
    global lookat = 0.95 .* lookat + 0.05 .* p
    azimuth = π + π / 4 + 0.3 * sin(2π * progress) # set the view angle of the axis
    eyeposition = 1.1 * 2π / 3 .* convert_to_cartesian([1; azimuth; π / 6])
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(0.0, 0.0, 1.0))
end

GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    progress = frame / frames_number
    totalstages = 3
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    animate(stage, stageprogress)
    updatecamera(progress)
end