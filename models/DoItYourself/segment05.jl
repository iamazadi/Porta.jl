import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using Porta

GLMakie.activate!(ssao=true)
GLMakie.closeall() # close any open screen
ssao = GLMakie.SSAO(radius=5.0, blur=3)

resolution = (1920, 1080)
segments = 60
basemapsegments = 150
frames_number = 1440

modelname = "segment05"
makefigure() = GLMakie.Figure(resolution=resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(0.1019, 0.1019, 0.0)
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw=(resolution=resolution, lights=[pl, al], backgroundcolor=backgroundcolor, clear=true, ssao=ssao))
# SSAO attributes are per scene
lscene.scene.ssao.bias[] = 0.025

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
eyeposition = GLMakie.Vec3f(cam.eyeposition[]...)
lookat = GLMakie.Vec3f(0, 0, 0)
up = GLMakie.Vec3f(0, 0, 1)
# GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask1.png")

## Load the Natural Earth data

attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"

countries = loadcountries(attributespath, nodespath)

country_name1 = "United States of America"
country_nodes1 = Vector{Vector{Float64}}()
for i in 1:length(countries["name"])
    if countries["name"][i] == country_name1
        global country_nodes1 = countries["nodes"][i]
        global country_nodes1 = convert(Vector{Vector{Float64}}, country_nodes1)
        println(typeof(country_nodes1))
        println(country_name1)
    end
end

α = 0.4
color1 = getcolor(country_nodes1, colorref, α)
color2 = getcolor(country_nodes1, colorref, 1.0)
w1 = [τmap(country_nodes1[i]) for i in eachindex(country_nodes1)]
θ = 3π / 2
whirl1 = Whirl(lscene, w1, [0.0 for i in 1:length(w1)], [θ for i in 1:length(w1)], segments, color1, transparency=true)
# whirl2 = Whirl(lscene, w1, [θ for i in 1:length(w1)], [2π for i in 1:length(w1)], segments, color1, transparency = true)
frame1 = Basemap(lscene, x -> G(0, τmap(x)), basemapsegments, basemap_color, transparency=true)
frame2 = Basemap(lscene, x -> G(θ, τmap(x)), basemapsegments, basemap_color, transparency=true)

sphereA = GLMakie.mesh!(lscene.scene, GLMakie.Sphere(GLMakie.Point3f(0), 0.05), color=:white)
sphereB = GLMakie.mesh!(lscene.scene, GLMakie.Sphere(GLMakie.Point3f(0), 0.05), color=:white)
GLMakie.scale!(sphereA, 0.1, 0.1, 0.1)
GLMakie.scale!(sphereB, 0.1, 0.1, 0.1)

ps = [GLMakie.Point3f(0, 0, 0) for i in 1:3]
ns = map(p -> 0.1 * GLMakie.Point3f(p[2], p[3], p[1]), ps)
tails = GLMakie.Observable(ps)
heads = GLMakie.Observable(ns)
lengths = norm.(ns)
GLMakie.arrows!(lscene,
    tails, heads, fxaa=true, # turn on anti-aliasing
    color=[:cyan, :white, :red],
    linewidth=0.01, arrowsize=GLMakie.Vec3f(0.03, 0.03, 0.04),
    align=:center
)

vertical_points = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:30])
GLMakie.lines!(lscene, vertical_points, color=:lightgreen, linewidth=7, fxaa=false)

initial = [0.0; 0.0; 1.0]
rotation = GLMakie.Observable(Quaternion(1.0, 0.0, 0.0, 0.0))
textotation = GLMakie.@lift(GLMakie.Quaternion(vec($rotation)[2], vec($rotation)[3], vec($rotation)[4], vec($rotation)[1]))
text_point = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:5])
fontsize = 0.05
GLMakie.text!(lscene.scene,
    text_point,
    text=["x", "v", "VₓP", "HₓP", "ωₓ"],
    rotation=textotation,
    color=[color2, :white, :lightgreen, color2, :red],
    align=(:left, :baseline),
    fontsize=fontsize,
    markerspace=:data
)

frame = 1

GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
    progress1 = progress
    progress2 = progress
    if progress < 0.5
        progress1 = 2progress
        progress2 = 0.0
    else
        progress1 = 1.0
        progress2 = 2(progress - 0.5)
    end
    τ(x, ϕ) = begin
        g = convert_to_geographic(x)
        r, _ϕ, _θ = g
        _ϕ += ϕ
        z₁ = ℯ^(im * 0) * √((1 + sin(_θ)) / 2)
        z₂ = ℯ^(im * _ϕ) * √((1 - sin(_θ)) / 2)
        Quaternion([z₁; z₂])
    end
    center = [0.0; 0.0; 0.0]
    for i in eachindex(country_nodes1)
        geographic = convert_to_geographic(country_nodes1[i])
        center = center + geographic
    end
    center = center ./ length(country_nodes1)
    center = convert_to_cartesian(center)
    θ1 = 0.0
    ϕ = progress * 2π
    index = max(2, Int(floor(progress2 * length(country_nodes1))))
    update!(frame1, x -> τ(x, ϕ))
    A = project(τ(center, ϕ))
    B = project(τ(country_nodes1[1], ϕ))
    C = project(τ(country_nodes1[index], ϕ))
    GLMakie.translate!(sphereA, GLMakie.Vec3f(A...))

    θ2 = 2π / 24 * cos(progress1 * 2π)
    if θ2 ≥ 0.0
        update!(whirl1, τ.(country_nodes1, ϕ), [θ2 for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])
    else
        update!(whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [θ2 for _ in 1:length(country_nodes1)])
    end
    update!(frame2, x -> G(θ2, τ(x, ϕ)))
    a = project(G(θ2, τ(center, ϕ)))
    b = project(G(θ2, τ(country_nodes1[1], ϕ)))
    c = project(G(θ2, τ(country_nodes1[index], ϕ)))

    GLMakie.translate!(sphereB, GLMakie.Vec3f(a...))

    vector1 = a - A
    vector2 = b - A
    vector3 = vector1 - vector2

    tails[] = [[GLMakie.Point3f((A + vector1)...)]; [GLMakie.Point3f((A + vector2)...)]; [GLMakie.Point3f((A + vector2 + vector3)...)]]
    heads[] = [[GLMakie.Point3f(vector1...)]; [GLMakie.Point3f(vector2...)]; [GLMakie.Point3f(vector3...)]]
    p1 = project(τ(center, ϕ))
    p2 = project(G(0.1, τ(center, ϕ)))
    v1 = p2 - p1
    vertical_points[] = [A + j .* GLMakie.Point3f(v1...) for j in range(-5.0, stop=5.0, length=30)]

    lookat = GLMakie.Vec3f(a...)
    up = GLMakie.Vec3f(v1...)
    product = normalize(cross(vector1, vector2))
    if frame == 1
        global eyeposition = GLMakie.Vec3f(π / 10 * (product + normalize(vector3) + [1.0; 1.0; 1.0]))
    else
        global eyeposition = 0.95 .* eyeposition + 0.05 .* GLMakie.Vec3f(π / 10 * (product + normalize(vector3) + normalize([1.0; 1.0; 1.0])))
    end

    text_point[] = [GLMakie.Point3f((A - 0.02 .* a + 0.02 .* vector3)...), GLMakie.Point3f((A + 1.2 .* vector2)...), GLMakie.Point3f((A + 4.0 .* v1)...), GLMakie.Point3f(B...), GLMakie.Point3f((A + vector2 + 1.5 .* vector3)...)]
    ang, u = getrotation(initial, [Float64.(eyeposition - lookat)...])
    q = Quaternion(ang / 2, u)
    initial1 = vec(q * Quaternion([0; initial]) * conj(q))[2:4]
    ang1, u1 = getrotation(cross(initial1, up), [Float64.(up)...])
    q1 = Quaternion(ang1 / 2, u1)
    rotation[] = q1 * q

    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
