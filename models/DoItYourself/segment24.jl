import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using Serialization
using ModelingToolkit, DifferentialEquations, Latexify
using Porta


resolution = (1920, 1080)
segments = 48
basemapsegments = 90
frames_number = 1440

τ(x, ϕ) = begin
    g = convert_to_geographic(x)
    r, _ϕ, _θ = g
    _ϕ += ϕ
    z₁ = ℯ^(im * 0) * √((1 + sin(_θ)) / 2)
    z₂ = ℯ^(im * _ϕ) * √((1 - sin(_θ)) / 2)
    Quaternion([z₁; z₂])
end

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

r₀ = 0.8 # radius of lambda path circle
λ₀ = λ₁ # center of lambda path circle
ϕ₀ = 0.0

operator = imag(λ₀) ≥ 0 ? "+" : "-"
version = "r₀=$(r₀)_λ₀=$(float(real(λ₀)))_$(operator)_𝑖$(abs(float(imag(λ₀))))"
modelname = "segment24_gamma3_$version"
L = 10.0 # max x range
L′ = -L
ẑ = [0.0; 0.0; 1.0]
α = 0.25
markersize = 0.04
linewidth = 8.0
arrowsize = GLMakie.Vec3f(0.02, 0.02, 0.04)


γ₁, θ₁, λ₁, w₁, t₁, latex1 = deserialize("gamma1_$version")
γ₂, θ₂, λ_array = deserialize("gamma2_$version")
γ₃, θ₃, s2_path₃, t₃, latex3 = deserialize("gamma3_$version")

makefigure() = GLMakie.Figure(resolution = resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=true, scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor= GLMakie.RGBf(0.0784, 0.0, 0.1019), clear=true))

# starman = FileIO.load("data/Starman_3.stl")
# starman_sprite = GLMakie.mesh!(
#     lscene,
#     starman,
#     color = [tri[1][2] for tri in starman for i in 1:3],
#     colormap = GLMakie.Reverse(:Spectral)
# )
# scale = 1 / 400
#GLMakie.scale!(starman_sprite, scale, scale, scale)

# cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
# eyeposition = GLMakie.Vec3f(cam.eyeposition[]...)
eyeposition = GLMakie.Vec3f(1, 1, 1)
lookat = GLMakie.Vec3f(0, 0, 0)
up = GLMakie.Vec3f(0, 0, 1)
GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask1.png")
## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = ["United States of America", "China", "Iran"]
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
for i in eachindex(boundary_nodes)
    color = getcolor(boundary_nodes[i], colorref, α)
    w = [τmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])]
    whirl1 = Whirl(lscene, w, [θ1 for _ in 1:length(w)], [θ2 for _ in 1:length(w)], segments, color, transparency = true)
    push!(whirls, whirl1)
end

steps_number = length(t₁)
basemap1 = Basemap(lscene, x -> G(θ1, τmap(x)), basemapsegments, basemap_color, transparency = true)
basemap2 = Basemap(lscene, x -> G(θ2, τmap(x)), basemapsegments, basemap_color, transparency = true)
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
maxindex = min(map(x -> length(x), γ₂)...)
for i in 1:maxindex - 1
    push!(band_points1, GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:steps_number]))
    push!(band_points2, GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:steps_number]))
    bandcolor = GLMakie.HSVA(i / maxindex * 360, 100, 100, α / 2)
    GLMakie.band!(lscene, band_points1[end], band_points2[end], color=bandcolor, transparency = true)
end

function animate(progress)
    q = Quaternion(sin(progress * 2π) * π, ẑ)
    frame = Int(floor(progress * frames_number))
    update!(basemap1, x -> G(θ1, τmap(x)) * q)
    update!(basemap2, x -> G(θ2, τmap(x)) * q)
    for (i, whirl) in enumerate(whirls)
        _w = τmap.(boundary_nodes[i])
        _w = map(x -> x * q, _w)
        update!(whirl, _w, [θ1 for _ in 1:length(boundary_nodes[i])], [θ2 for _ in 1:length(boundary_nodes[i])])
    end

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

    for i in 1:steps_number
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

    for j in 1:maxindex - 1
        points1 = [GLMakie.Point3f(project(γ₂[i][j] * q)...) for i in 1:steps_number]
        points2 = [GLMakie.Point3f(project(γ₂[i][j + 1] * q)...) for i in 1:steps_number]
        band_points1[j][] = points1
        band_points2[j][] = points2
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
end


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    progress = frame / frames_number
    println("Frame: $frame, Progress: $progress")
    animate(progress)
    global lookat = GLMakie.Vec3f(0.0, 0.0, 0.0)
    up = GLMakie.Vec3f(0, 0, 1)
    azimuth = π + π / 4 + 0.3 * sin(2π * progress) # set the view angle of the axis
    eyeposition = GLMakie.Vec3f(2π / 3 .* convert_to_cartesian([1; azimuth; π / 6])...)
    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
