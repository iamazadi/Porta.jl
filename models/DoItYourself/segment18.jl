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
basemapsegments = 100
frames_number = 1440

modelname = "segment18"
makefigure() = GLMakie.Figure(resolution=resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(0.0, 0.0392, 0.1019)
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

country_name1 = "Iran"
country_name2 = "United States of America"
country_name3 = "France"
country_nodes1 = Vector{Vector{Float64}}()
country_nodes2 = Vector{Vector{Float64}}()
country_nodes3 = Vector{Vector{Float64}}()
for i in 1:length(countries["name"])
    if countries["name"][i] == country_name1
        global country_nodes1 = countries["nodes"][i]
        global country_nodes1 = convert(Vector{Vector{Float64}}, country_nodes1)
        println(typeof(country_nodes1))
        println(country_name1)
    end
    if countries["name"][i] == country_name2
        global country_nodes2 = countries["nodes"][i]
        global country_nodes2 = convert(Vector{Vector{Float64}}, country_nodes2)
        println(typeof(country_nodes2))
        println(country_name2)
    end
    if countries["name"][i] == country_name3
        global country_nodes3 = countries["nodes"][i]
        global country_nodes3 = convert(Vector{Vector{Float64}}, country_nodes3)
        println(typeof(country_nodes3))
        println(country_name3)
    end
end

α = 0.2
_color1 = getcolor(country_nodes1, colorref, 1.0)
__color1 = getcolor(country_nodes1, colorref, α)
α2 = 1.0
color1 = getcolor(country_nodes1, colorref, α2)
color2 = getcolor(country_nodes2, colorref, α2)
color3 = getcolor(country_nodes3, colorref, α2)
w1 = [τmap(country_nodes1[i]) for i in eachindex(country_nodes1)]
w2 = [τmap(country_nodes2[i]) for i in eachindex(country_nodes2)]
w3 = [τmap(country_nodes3[i]) for i in eachindex(country_nodes3)]
θ = 3π / 2
elementsnumber = 30
boundarywhirl = Whirl(lscene, w1[1:elementsnumber], [θ for i in 1:elementsnumber], [2π for i in 1:elementsnumber], segments, _color1, transparency=false)
centerwhirl = Whirl(lscene, w1[1:elementsnumber], [θ for i in 1:elementsnumber], [2π for i in 1:elementsnumber], segments, _color1, transparency=false)
_whirl1 = Whirl(lscene, w1, [θ for i in 1:length(w1)], [2π for i in 1:length(w1)], segments, __color1, transparency=true)
whirl1 = Whirl(lscene, w1, [0.0 for i in 1:length(w1)], [θ for i in 1:length(w1)], segments, color1, transparency=false)
whirl2 = Whirl(lscene, w2, [0.0 for i in 1:length(w2)], [θ for i in 1:length(w2)], segments, color2, transparency = false)
whirl3 = Whirl(lscene, w3, [0.0 for i in 1:length(w3)], [θ for i in 1:length(w3)], segments, color3, transparency = false)
basemap = Basemap(lscene, x -> G(0, τmap(x)), basemapsegments, basemap_color, transparency=true)
frame1 = Basemap(lscene, x -> G(0, τmap(x)), basemapsegments, basemap_color, transparency=false)
frame2 = Basemap(lscene, x -> G(θ, τmap(x)), basemapsegments, basemap_color, transparency=false)

sphereA = GLMakie.mesh!(lscene.scene, GLMakie.Sphere(GLMakie.Point3f(0), 0.05), color=_color1)
sphereB = GLMakie.mesh!(lscene.scene, GLMakie.Sphere(GLMakie.Point3f(0), 0.05), color=_color1)
spherev2 = GLMakie.mesh!(lscene.scene, GLMakie.Sphere(GLMakie.Point3f(0), 0.05), color = :blue)
spherevector2 = GLMakie.mesh!(lscene.scene, GLMakie.Sphere(GLMakie.Point3f(0), 0.05), color = :orange)
GLMakie.scale!(sphereA, 0.1, 0.1, 0.1)
GLMakie.scale!(sphereB, 0.1, 0.1, 0.1)
GLMakie.scale!(spherev2, 0.1, 0.1, 0.1)
GLMakie.scale!(spherevector2, 0.1, 0.1, 0.1)

ps = [GLMakie.Point3f(0, 0, 0) for i in 1:4]
ns = map(p -> 0.1 * GLMakie.Point3f(p[2], p[3], p[1]), ps)
tails = GLMakie.Observable(ps)
heads = GLMakie.Observable(ns)
lengths = norm.(ns)
GLMakie.arrows!(lscene,
    tails, heads, fxaa=true, # turn on anti-aliasing
    color=[:cyan, :white, :red, :red],
    linewidth=0.005, arrowsize=GLMakie.Vec3f(0.01, 0.01, 0.01),
    align=:center
)

vertical_points1 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:elementsnumber])
vertical_points2 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:elementsnumber])
vertical_points3 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:elementsnumber])
GLMakie.lines!(lscene, vertical_points1, color=:lightgreen, linewidth=5, fxaa=false)
GLMakie.lines!(lscene, vertical_points2, color=:blue, linewidth=8, fxaa=false)
GLMakie.lines!(lscene, vertical_points3, color=:orange, linewidth=8, fxaa=false)
bandcolor = GLMakie.RGBAf(1.0, 0.8431, 0.0, 0.5)
GLMakie.band!(lscene, vertical_points2, vertical_points3, color=bandcolor, transparency = true)

initial = [0.0; 0.0; 1.0]
rotation = GLMakie.Observable(Quaternion(1.0, 0.0, 0.0, 0.0))
textotation = GLMakie.@lift(GLMakie.Quaternion(vec($rotation)[2], vec($rotation)[3], vec($rotation)[4], vec($rotation)[1]))
text = ["x", "m", "n", "v", "VₓP", "HₓP", "ωₓ", "VₙP", "VₘP"]
text_point = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:length(text)])
fontsize = 0.05
GLMakie.text!(lscene.scene,
    text_point,
    text = text,
    rotation = textotation,
    color = [_color1, :orange, :blue, :white, :lightgreen, _color1, :red, :blue, :orange],
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data
)

frame = 1

GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
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
    θ2 = 2π / 21 * abs(sin(progress * 2π))
    ϕ = progress * -2π
    index = max(1, Int(floor(progress * length(country_nodes1))))
    update!(frame1, x -> τ(x, ϕ))
    update!(frame2, x -> G(θ, τ(x, ϕ)))
    A = project(G(θ, τ(center, ϕ)))
    B = project(G(θ, τ(country_nodes1[index], ϕ)))
    C = project(G(θ + θ2, τ(country_nodes1[index], ϕ)))
    GLMakie.translate!(sphereA, GLMakie.Vec3f(A...))

    centerr, centerϕ, centerθ = convert_to_geographic(center)
    boundaryr, boundaryϕ, boundaryθ = convert_to_geographic(country_nodes1[index])
    scale = 0.01
    centerneighborhood = [convert_to_cartesian([centerr; scale * cos(β) + centerϕ; scale * sin(β) + centerθ]) for β in range(0, stop = 2π, length = elementsnumber)]
    boundaryneighborhood = [convert_to_cartesian([boundaryr; scale * cos(β) + boundaryϕ; scale * sin(β) + boundaryθ]) for β in range(0, stop = 2π, length = elementsnumber)]

    update!(centerwhirl, τ.(centerneighborhood, ϕ), [0.0 for _ in 1:elementsnumber], [2π for _ in 1:elementsnumber])
    update!(boundarywhirl, τ.(boundaryneighborhood, ϕ), [0.0 for _ in 1:elementsnumber], [2π for _ in 1:elementsnumber])
    update!(_whirl1, τ.(country_nodes1, ϕ), [θ + θ2 for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])
    update!(whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
    update!(whirl2, τ.(country_nodes2, ϕ), [θ for _ in 1:length(country_nodes2)], [θ2 for _ in 1:length(country_nodes2)])
    update!(whirl3, τ.(country_nodes3, ϕ), [θ for _ in 1:length(country_nodes3)], [θ2 for _ in 1:length(country_nodes3)])
    update!(basemap, x -> G(θ + θ2, τ(x, ϕ)))
    a = project(G(θ + θ2, τ(center, ϕ)))
    a′ = project(G(θ + θ2 + 0.1, τ(center, ϕ)))
    b = project(G(θ + θ2, τ(country_nodes1[index], ϕ)))
    b′ = project(G(θ + θ2 + 0.1, τ(country_nodes1[index], ϕ)))
    B′ = project(G(θ + 0.1, τ(country_nodes1[index], ϕ)))

    GLMakie.translate!(sphereB, GLMakie.Vec3f(a...))
    vector1 = a - A
    vector2 = b - A
    vector3 = vector1 - vector2
    
    v1 = a′ - a
    v2 = b′ - b
    v3 = B′ - B
    vertical_points1[] = [A + j .* GLMakie.Point3f(v1...) for j in range(-5.0, stop=5.0, length=30)]
    vertical_points2[] = [b + j .* GLMakie.Point3f(v2...) for j in range(-5.0, stop=10.0, length=30)]
    vertical_points3[] = [B + j .* GLMakie.Point3f(v3...) for j in range(-5.0, stop=5.0, length=30)]

    tails[] = [[GLMakie.Point3f((A + vector1)...)];
               [GLMakie.Point3f((A + vector2)...)];
               [GLMakie.Point3f((A + vector2 + vector3)...)];
               [GLMakie.Point3f(A...)]]
    heads[] = [[GLMakie.Point3f(vector1...)]; [GLMakie.Point3f(vector2...)]; [GLMakie.Point3f(vector3...)]; [GLMakie.Point3f(vector3...)]]

    GLMakie.translate!(spherev2, GLMakie.Vec3f(b...))
    GLMakie.translate!(spherevector2, GLMakie.Vec3f(B...))

    lookat = GLMakie.Vec3f(a...)
    v1 = normalize(v1)
    up = GLMakie.Vec3f(v1...)
    product = normalize(cross(vector1, vector2))
    position = GLMakie.Vec3f(π / 38 * (1.5 .* normalize(v1) + product + normalize(vector3) + [1.0; 1.0; 1.0]))
    if frame == 1
        global eyeposition = position
    else
        if all([!isnan(position[i]) for i in 1:3])
            global eyeposition = 0.95 .* eyeposition + 0.05 .* position
        end
    end

    global eyeposition = [0.1977; -0.6339; -0.9127] # [0.29628783; -0.6057904; -0.9411617]
    # global eyeposition = [0.38999197; -0.5074851; -1.1170261]

    text_point[] = [GLMakie.Point3f((A - 0.02 .* a + 0.02 .* vector3)...),
                    GLMakie.Point3f(B...),
                    GLMakie.Point3f(b...),
                    GLMakie.Point3f((A + 1.2 .* vector2)...),
                    GLMakie.Point3f((A + 0.3 .* v1)...),
                    GLMakie.Point3f((A + vector3)...),
                    GLMakie.Point3f((A + vector2 + 1.5 .* vector3)...),
                    GLMakie.Point3f((b + 3.0 .* v2)...),
                    GLMakie.Point3f((B + 1.5 .* vector2)...)]
    ang, u = getrotation(initial, [Float64.(eyeposition - lookat)...])
    q = Quaternion(ang / 2, u)
    initial1 = vec(q * Quaternion([0; initial]) * conj(q))[2:4]
    ang1, u1 = getrotation(cross(initial1, up), [Float64.(up)...])
    q1 = Quaternion(ang1 / 2, u1)
    rotation[] = q1 * q

    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
