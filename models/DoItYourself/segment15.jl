import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using Porta

# GLMakie.activate!(ssao=true)
# GLMakie.closeall() # close any open screen
# ssao = GLMakie.SSAO(radius=5.0, blur=3)

resolution = (1920, 1080)
segments = 60
basemapsegments = 150
frames_number = 1440

modelname = "segment15"
makefigure() = GLMakie.Figure(resolution=resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(0.0, 0.1019, 0.1019)
# lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw=(resolution=resolution, lights=[pl, al], backgroundcolor=backgroundcolor, clear=true, ssao=ssao))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw=(resolution=resolution, lights=[pl, al], backgroundcolor=backgroundcolor, clear=true))
# SSAO attributes are per scene
#lscene.scene.ssao.bias[] = 0.025

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

α = 0.2
_color1 = getcolor(country_nodes1, colorref, 1.0)
__color1 = getcolor(country_nodes1, colorref, α)
α2 = 1.0
color1 = getcolor(country_nodes1, colorref, α2)
w1 = [τmap(country_nodes1[i]) for i in eachindex(country_nodes1)]
θ = 3π / 2
elementsnumber = 30
gauge2 = convert(Vector{Float64}, [θ for i in 1:length(w1)])
whirl1 = Whirl(lscene, w1, [0.0 for i in 1:length(w1)], gauge2, segments, color1, transparency=false)
_whirl1 = Whirl(lscene, w1, gauge2, [2π for i in 1:length(w1)], segments, __color1, transparency=true)
frame1 = Basemap(lscene, x -> G(0, τmap(x)), basemapsegments, basemap_color, transparency=false)
frame2 = Basemap(lscene, x -> G(θ, τmap(x)), basemapsegments, basemap_color, transparency=false)

spheresvisible = GLMakie.Observable(false)
basisarrowsvisible = GLMakie.Observable(false)
textvisible = GLMakie.Observable(false)
linesvisible = GLMakie.Observable(false)
bandvisible = GLMakie.Observable(false)

ps = [GLMakie.Point3f(0, 0, 0) for i in 1:3]
ns = map(p -> 0.1 * GLMakie.Point3f(p[2], p[3], p[1]), ps)
tails = GLMakie.Observable(ps)
heads = GLMakie.Observable(ns)
lengths = norm.(ns)
GLMakie.arrows!(lscene,
    tails, heads, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = 0.005, arrowsize = GLMakie.Vec3f(0.01, 0.01, 0.01),
    align = :center,
    visible = basisarrowsvisible
)

vertical_points1 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:elementsnumber])
vertical_points2 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:elementsnumber])
vertical_points3 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:elementsnumber])
GLMakie.lines!(lscene, vertical_points1, color=:red, linewidth=10, fxaa=false, visible = linesvisible)
GLMakie.lines!(lscene, vertical_points2, color=:green, linewidth=10, fxaa=false, visible = linesvisible)
GLMakie.lines!(lscene, vertical_points3, color=:blue, linewidth=10, fxaa=false, visible = linesvisible)
bandcolor = GLMakie.RGBAf(1.0, 0.8431, 0.0, 0.3)
bandsection1 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:length(country_nodes1)])
bandsection2 = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:length(country_nodes1)])
GLMakie.band!(lscene, bandsection1, bandsection2, color=bandcolor, transparency = true, visible = bandvisible)

initial = [0.0; 0.0; 1.0]
rotation = GLMakie.Observable(Quaternion(1.0, 0.0, 0.0, 0.0))
textotation = GLMakie.@lift(GLMakie.Quaternion(vec($rotation)[2], vec($rotation)[3], vec($rotation)[4], vec($rotation)[1]))
text = ["x", "x1", "x2", "x3"]
text_point = GLMakie.Observable([GLMakie.Point3f(0, 0, 0) for _ in 1:length(text)])
fontsize = 0.05
GLMakie.text!(lscene.scene,
    text_point,
    text = text,
    rotation = textotation,
    color = [:white,:red, :green, :blue],
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data,
    visible = textvisible
)

frame = 1
eyeposition = [0.72; 0.73; -0.21]
τ(x, ϕ) = begin
    g = convert_to_geographic(x)
    r, _ϕ, _θ = g
    _ϕ += ϕ
    z₁ = ℯ^(im * 0) * √((1 + sin(_θ)) / 2)
    z₂ = ℯ^(im * _ϕ) * √((1 - sin(_θ)) / 2)
    Quaternion([z₁; z₂])
end
τ(x, ϕ, progress) = begin
    g = convert_to_geographic(x)
    r, _ϕ, _θ = g
    z₁ = ℯ^(im * 0.0) * √((1 + sin(_θ)) / 2)
    z₂ = ℯ^(im * _ϕ) * √((1 - sin(_θ)) / 2)
    q = normalize(Quaternion(sin(progress * 2π) * π / 4, [0.0; 0.0; 1.0]))
    normalize(Quaternion([z₁; z₂]) * q)
end
τ1(x, ϕ, progress) = begin
    g = convert_to_geographic(x)
    r, _ϕ, _θ = g
    z₁ = ℯ^(im * 0.0) * √((1 + sin(_θ)) / 2)
    z₂ = ℯ^(im * _ϕ) * √((1 - sin(_θ)) / 2)
    q = normalize(Quaternion(sin(progress * 2π) * π / 4, [0.0; 1.0; 0.0]))
    normalize(Quaternion([z₁; z₂]) * q)
end
τ2(x, ϕ, progress) = begin
    g = convert_to_geographic(x)
    r, _ϕ, _θ = g
    z₁ = ℯ^(im * 0.0) * √((1 + sin(_θ)) / 2)
    z₂ = ℯ^(im * _ϕ) * √((1 - sin(_θ)) / 2)
    q = normalize(Quaternion(sin(progress * 2π) * π / 4, [0.1; 0.0; 0.0]))
    normalize(Quaternion([z₁; z₂]) * q)
end
center = [0.0; 0.0; 0.0]
for i in eachindex(country_nodes1)
    geographic = convert_to_geographic(country_nodes1[i])
    global center = center + geographic
end
center[2] = center[2] ./ length(country_nodes1)
center[3] = center[3] ./ length(country_nodes1)
center = convert_to_cartesian(center)
index1 = 1
index2 = max(1, Int(floor(length(country_nodes1) / 2.0)))
point1 = country_nodes1[index1]
point2 = country_nodes1[index2]

function animate(stage, stageprogress)
    if stage == 1
        ϕ = π / 4 * sin(stageprogress * 2π)
        update!(frame1, x -> τ(x, ϕ))
        update!(frame2, x -> G(θ, τ(x, ϕ)))
        update!(whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
        update!(_whirl1, τ.(country_nodes1, ϕ), [θ for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])

        tail = project(τ(center, ϕ))
        head1 = normalize(project(G(-0.1, τ(center, ϕ))) - tail)

        lookat = GLMakie.Vec3f(tail...)
        up = GLMakie.Vec3f(head1...)
    end

    if stage == 2
        if basisarrowsvisible[] == false
            basisarrowsvisible[] = true
        end
        if textvisible[] == false
            textvisible[] = true
        end

        ϕ = π * sin(stageprogress * 2π)
        update!(frame1, x -> τ(x, ϕ))
        update!(frame2, x -> G(θ, τ(x, ϕ)))
        update!(whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
        update!(_whirl1, τ.(country_nodes1, ϕ), [θ for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])

        tail = project(τ(center, ϕ))
        length1 = stageprogress * 0.1
        length2 = stageprogress * norm(project(τ(point1, ϕ))- tail)
        length3 = stageprogress * norm(project(τ(point2, ϕ)) - tail)
        head1 = length1 .* normalize(project(G(-0.1, τ(center, ϕ))) - tail)
        head2 = length2 .* normalize(project(τ(point1, ϕ)) - tail)
        head3 = length3 .* normalize(project(τ(point2, ϕ)) - tail)

        tails[] = [GLMakie.Point3f(tail + head1...), GLMakie.Point3f(tail + head2...), GLMakie.Point3f(tail + head3...)]
        heads[] = [GLMakie.Point3f(head1...), GLMakie.Point3f(head2...), GLMakie.Point3f(head3...)]

        text_point[] = [GLMakie.Point3f(tail...),
                        GLMakie.Point3f((tail + head1)...),
                        GLMakie.Point3f((tail + head2)...),
                        GLMakie.Point3f((tail + head3)...)]
        lookat = GLMakie.Vec3f(tail...)
        up = GLMakie.Vec3f(normalize(head1)...)
        ang, u = getrotation(initial, [Float64.(eyeposition - lookat)...])
        q = Quaternion(ang / 2, u)
        initial1 = vec(q * Quaternion([0; initial]) * conj(q))[2:4]
        ang1, u1 = getrotation(cross(initial1, up), [Float64.(up)...])
        q1 = Quaternion(ang1 / 2, u1)
        rotation[] = q1 * q
    end

    if stage == 3
        ϕ = 0.0
        if linesvisible[] == false
            linesvisible[] = true
            update!(frame1, x -> τ(x, ϕ))
            update!(frame2, x -> G(θ, τ(x, ϕ)))
            update!(whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
            update!(_whirl1, τ.(country_nodes1, ϕ), [θ for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])
        end

        tail = project(τ(center, ϕ))
        length1 = stageprogress * 0.1
        length2 = norm(project(τ(point1, ϕ))- tail)
        length3 = norm(project(τ(point2, ϕ)) - tail)
        head1 = length1 .* normalize(project(G(-0.1, τ(center, ϕ))) - tail)
        head2 = length2 .* normalize(project(τ(point1, ϕ)) - tail)
        head3 = length3 .* normalize(project(τ(point2, ϕ)) - tail)

        tails[] = [GLMakie.Point3f(tail + head1...), GLMakie.Point3f(tail + head2...), GLMakie.Point3f(tail + head3...)]
        heads[] = [GLMakie.Point3f(head1...), GLMakie.Point3f(head2...), GLMakie.Point3f(head3...)]

        text_point[] = [GLMakie.Point3f(tail...),
                        GLMakie.Point3f((tail + head1)...),
                        GLMakie.Point3f((tail + head2)...),
                        GLMakie.Point3f((tail + head3)...)]
        lookat = GLMakie.Vec3f(tail...)
        up = GLMakie.Vec3f(normalize(head1)...)
        ang, u = getrotation(initial, [Float64.(eyeposition - lookat)...])
        q = Quaternion(ang / 2, u)
        initial1 = vec(q * Quaternion([0; initial]) * conj(q))[2:4]
        ang1, u1 = getrotation(cross(initial1, up), [Float64.(up)...])
        q1 = Quaternion(ang1 / 2, u1)
        rotation[] = q1 * q

        vertical_points1[] = [tail + head1 + stageprogress * j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points2[] = [tail + head2 + stageprogress * j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points3[] = [tail + head3 + stageprogress * j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
    end

    if stage == 4
        if bandvisible[] == false
            bandvisible[] = true
        end

        ϕ = 0.0
        tail = project(τ(center, ϕ))
        length1 = stageprogress * 0.1
        length2 = norm(project(τ(point1, ϕ))- tail)
        length3 = norm(project(τ(point2, ϕ)) - tail)
        head1 = length1 .* normalize(project(G(-0.1, τ(center, ϕ))) - tail)
        head2 = length2 .* normalize(project(τ(point1, ϕ)) - tail)
        head3 = length3 .* normalize(project(τ(point2, ϕ)) - tail)

        tails[] = [GLMakie.Point3f(tail + head1...), GLMakie.Point3f(tail + head2...), GLMakie.Point3f(tail + head3...)]
        heads[] = [GLMakie.Point3f(head1...), GLMakie.Point3f(head2...), GLMakie.Point3f(head3...)]

        text_point[] = [GLMakie.Point3f(tail...),
                        GLMakie.Point3f((tail + head1)...),
                        GLMakie.Point3f((tail + head2)...),
                        GLMakie.Point3f((tail + head3)...)]
        lookat = GLMakie.Vec3f(tail...)
        up = GLMakie.Vec3f(normalize(head1)...)
        ang, u = getrotation(initial, [Float64.(eyeposition - lookat)...])
        q = Quaternion(ang / 2, u)
        initial1 = vec(q * Quaternion([0; initial]) * conj(q))[2:4]
        ang1, u1 = getrotation(cross(initial1, up), [Float64.(up)...])
        q1 = Quaternion(ang1 / 2, u1)
        rotation[] = q1 * q

        vertical_points1[] = [tail + head1 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points2[] = [tail + head2 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points3[] = [tail + head3 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]

        bandsection1[] = map(x -> project(τ(x, ϕ)), country_nodes1)
        bandsection2[] = map(x -> project(τ(x, ϕ)) + stageprogress * 0.2 .* normalize(project(G(-0.01, τ(x, ϕ))) - project(τ(x, ϕ))), country_nodes1)
        # global eyeposition = eyeposition .* (1.0 - (stageprogress * 0.1))
    end

    if stage == 5
        ϕ = 0.0
        update!(frame1, x -> τ(x, ϕ, stageprogress))
        update!(frame2, x -> G(θ, τ(x, ϕ, stageprogress)))
        update!(whirl1, τ.(country_nodes1, ϕ, stageprogress), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
        update!(_whirl1, τ.(country_nodes1, ϕ, stageprogress), [θ for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])
        tail = project(τ(center, ϕ, stageprogress))
        length1 = stageprogress * 0.1
        length2 = norm(project(τ(point1, ϕ, stageprogress))- tail)
        length3 = norm(project(τ(point2, ϕ, stageprogress)) - tail)
        head1 = length1 .* normalize(project(G(-0.1, τ(center, ϕ, stageprogress))) - tail)
        head2 = length2 .* normalize(project(τ(point1, ϕ, stageprogress)) - tail)
        head3 = length3 .* normalize(project(τ(point2, ϕ, stageprogress)) - tail)

        tails[] = [GLMakie.Point3f(tail + head1...), GLMakie.Point3f(tail + head2...), GLMakie.Point3f(tail + head3...)]
        heads[] = [GLMakie.Point3f(head1...), GLMakie.Point3f(head2...), GLMakie.Point3f(head3...)]

        text_point[] = [GLMakie.Point3f(tail...),
                        GLMakie.Point3f((tail + head1)...),
                        GLMakie.Point3f((tail + head2)...),
                        GLMakie.Point3f((tail + head3)...)]
        lookat = GLMakie.Vec3f(tail...)
        up = GLMakie.Vec3f(normalize(head1)...)
        ang, u = getrotation(initial, [Float64.(eyeposition - lookat)...])
        q = Quaternion(ang / 2, u)
        initial1 = vec(q * Quaternion([0; initial]) * conj(q))[2:4]
        ang1, u1 = getrotation(cross(initial1, up), [Float64.(up)...])
        q1 = Quaternion(ang1 / 2, u1)
        rotation[] = q1 * q

        vertical_points1[] = [tail + head1 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points2[] = [tail + head2 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points3[] = [tail + head3 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]

        bandsection1[] = map(x -> project(τ(x, ϕ, stageprogress)), country_nodes1)
        bandsection2[] = map(x -> project(τ(x, ϕ, stageprogress)) + 0.2 .* normalize(project(G(-0.01, τ(x, ϕ, stageprogress))) - project(τ(x, ϕ, stageprogress))), country_nodes1)
    end

    if stage == 6
        ϕ = 0.0
        update!(frame1, x -> τ1(x, ϕ, stageprogress))
        update!(frame2, x -> G(θ, τ(x, ϕ, stageprogress)))
        update!(whirl1, τ1.(country_nodes1, ϕ, stageprogress), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
        update!(_whirl1, τ1.(country_nodes1, ϕ, stageprogress), [θ for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])
        tail = project(τ1(center, ϕ, stageprogress))
        length1 = stageprogress * 0.1
        length2 = norm(project(τ1(point1, ϕ, stageprogress))- tail)
        length3 = norm(project(τ1(point2, ϕ, stageprogress)) - tail)
        head1 = length1 .* normalize(project(G(-0.1, τ1(center, ϕ, stageprogress))) - tail)
        head2 = length2 .* normalize(project(τ1(point1, ϕ, stageprogress)) - tail)
        head3 = length3 .* normalize(project(τ1(point2, ϕ, stageprogress)) - tail)

        tails[] = [GLMakie.Point3f(tail + head1...), GLMakie.Point3f(tail + head2...), GLMakie.Point3f(tail + head3...)]
        heads[] = [GLMakie.Point3f(head1...), GLMakie.Point3f(head2...), GLMakie.Point3f(head3...)]

        text_point[] = [GLMakie.Point3f(tail...),
                        GLMakie.Point3f((tail + head1)...),
                        GLMakie.Point3f((tail + head2)...),
                        GLMakie.Point3f((tail + head3)...)]
        lookat = GLMakie.Vec3f(tail...)
        up = GLMakie.Vec3f(normalize(head1)...)
        ang, u = getrotation(initial, [Float64.(eyeposition - lookat)...])
        q = Quaternion(ang / 2, u)
        initial1 = vec(q * Quaternion([0; initial]) * conj(q))[2:4]
        ang1, u1 = getrotation(cross(initial1, up), [Float64.(up)...])
        q1 = Quaternion(ang1 / 2, u1)
        rotation[] = q1 * q

        vertical_points1[] = [tail + head1 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points2[] = [tail + head2 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points3[] = [tail + head3 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]

        bandsection1[] = map(x -> project(τ1(x, ϕ, stageprogress)), country_nodes1)
        bandsection2[] = map(x -> project(τ1(x, ϕ, stageprogress)) + 0.2 .* normalize(project(G(-0.01, τ1(x, ϕ, stageprogress))) - project(τ1(x, ϕ, stageprogress))), country_nodes1)
    end
    
    if stage == 7
        ϕ = 0.0
        update!(frame1, x -> τ2(x, ϕ, stageprogress))
        update!(frame2, x -> G(θ, τ(x, ϕ, stageprogress)))
        update!(whirl1, τ2.(country_nodes1, ϕ, stageprogress), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
        update!(_whirl1, τ2.(country_nodes1, ϕ, stageprogress), [θ for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])
        tail = project(τ2(center, ϕ, stageprogress))
        length1 = stageprogress * 0.1
        length2 = norm(project(τ2(point1, ϕ, stageprogress))- tail)
        length3 = norm(project(τ2(point2, ϕ, stageprogress)) - tail)
        head1 = length1 .* normalize(project(G(-0.1, τ2(center, ϕ, stageprogress))) - tail)
        head2 = length2 .* normalize(project(τ2(point1, ϕ, stageprogress)) - tail)
        head3 = length3 .* normalize(project(τ2(point2, ϕ, stageprogress)) - tail)

        tails[] = [GLMakie.Point3f(tail + head1...), GLMakie.Point3f(tail + head2...), GLMakie.Point3f(tail + head3...)]
        heads[] = [GLMakie.Point3f(head1...), GLMakie.Point3f(head2...), GLMakie.Point3f(head3...)]

        text_point[] = [GLMakie.Point3f(tail...),
                        GLMakie.Point3f((tail + head1)...),
                        GLMakie.Point3f((tail + head2)...),
                        GLMakie.Point3f((tail + head3)...)]
        lookat = GLMakie.Vec3f(tail...)
        up = GLMakie.Vec3f(normalize(head1)...)
        ang, u = getrotation(initial, [Float64.(eyeposition - lookat)...])
        q = Quaternion(ang / 2, u)
        initial1 = vec(q * Quaternion([0; initial]) * conj(q))[2:4]
        ang1, u1 = getrotation(cross(initial1, up), [Float64.(up)...])
        q1 = Quaternion(ang1 / 2, u1)
        rotation[] = q1 * q

        vertical_points1[] = [tail + head1 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points2[] = [tail + head2 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]
        vertical_points3[] = [tail + head3 + j .* GLMakie.Point3f(head1...) for j in range(0.0, stop = 5.0, length = elementsnumber)]

        bandsection1[] = map(x -> project(τ2(x, ϕ, stageprogress)), country_nodes1)
        bandsection2[] = map(x -> project(τ2(x, ϕ, stageprogress)) + 0.2 .* normalize(project(G(-0.01, τ2(x, ϕ, stageprogress))) - project(τ2(x, ϕ, stageprogress))), country_nodes1)
    end

    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end

GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    progress = frame / frames_number
    stage = min(6, Int(floor(7progress))) + 1
    stageprogress = 7(progress - (stage - 1) * 1.0 / 7.0)
    println("Frame: $frame, Stage: $stage, Progress: $stageprogress")
    animate(stage, stageprogress)
end
