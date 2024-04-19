import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (3840, 2160)
segments = 60
totalstages = 6
frames_number = totalstages * 720
modelname = "hypersphere"
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
eyeposition = normalize(ℝ³(-2.0, 0.0, 2.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))

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
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.1)
    color2 = getcolor(boundary_nodes[i], reference, 0.2)
    color3 = getcolor(boundary_nodes[i], reference, 0.3)
    color4 = getcolor(boundary_nodes[i], reference, 0.4)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end


updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


animate(frame::Int) = begin
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    if stage == 1 || stage == 2
        θ₀ = sin(stageprogress * 2π) * 2π
        q₀ = Quaternion(exp(θ₀ * K(1)))
        T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
        q = isodd(stage) ? Quaternion(T, X, Y, Z) * q₀ : q₀ * Quaternion(T, X, Y, Z)
        gauge1 = 0.0
        gauge2 = π / 2
        gauge3 = float(π)
        gauge4 = 3π / 2
        gauge5 = 2π
        M = I(4)
        global points = Vector{Quaternion}[]
        for i in eachindex(boundary_nodes)
            _points = Quaternion[]
            for node in boundary_nodes[i]
                r, θ, ϕ = convert_to_geographic(node)
                push!(_points, q * Quaternion(exp(ϕ / 4 * K(1) + θ / 2 * K(2))))
            end
            push!(points, _points)
        end
        update!(basemap1, q, gauge1, M)
        update!(basemap2, q, gauge2, M)
        update!(basemap3, q, gauge3, M)
        update!(basemap4, q, gauge4, M)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1, gauge2, M)
            update!(whirls2[i], points[i], gauge2, gauge3, M)
            update!(whirls3[i], points[i], gauge3, gauge4, M)
            update!(whirls4[i], points[i], gauge4, gauge5, M)
        end
    elseif stage == 3 || stage == 4
        ϕ₀ = sin(stageprogress * 2π) * 2π
        q₀ = Quaternion(exp(ϕ₀ * K(2)))
        T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
        q = isodd(stage) ? Quaternion(T, X, Y, Z) * q₀ : q₀ * Quaternion(T, X, Y, Z)
        global points = Vector{Quaternion}[]
        for i in eachindex(boundary_nodes)
            _points = Quaternion[]
            for node in boundary_nodes[i]
                r, θ, ϕ = convert_to_geographic(node)
                push!(_points, q * Quaternion(exp(ϕ / 4 * K(1) + θ / 2 * K(2))))
            end
            push!(points, _points)
        end
        gauge1 = 0.0
        gauge2 = π / 2
        gauge3 = float(π)
        gauge4 = 3π / 2
        gauge5 = 2π
        M = I(4)
        update!(basemap1, q, gauge1, M)
        update!(basemap2, q, gauge2, M)
        update!(basemap3, q, gauge3, M)
        update!(basemap4, q, gauge4, M)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1, gauge2, M)
            update!(whirls2[i], points[i], gauge2, gauge3, M)
            update!(whirls3[i], points[i], gauge3, gauge4, M)
            update!(whirls4[i], points[i], gauge4, gauge5, M)
        end
    elseif stage == 5 || stage == 6
        g₀ = sin(stageprogress * 2π) * 2π
        q₀ = Quaternion(exp(g₀ * K(3)))
        T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
        q = isodd(stage) ? Quaternion(T, X, Y, Z) * q₀ : q₀ * Quaternion(T, X, Y, Z)
        global points = Vector{Quaternion}[]
        for i in eachindex(boundary_nodes)
            _points = Quaternion[]
            for node in boundary_nodes[i]
                r, θ, ϕ = convert_to_geographic(node)
                push!(_points, q * Quaternion(exp(ϕ / 4 * K(1) + θ / 2 * K(2))))
            end
            push!(points, _points)
        end
        gauge1 = 0.0
        gauge2 = π / 2
        gauge3 = float(π)
        gauge4 = 3π / 2
        gauge5 = 2π
        M = I(4)
        update!(basemap1, q, gauge1, M)
        update!(basemap2, q, gauge2, M)
        update!(basemap3, q, gauge3, M)
        update!(basemap4, q, gauge4, M)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1, gauge2, M)
            update!(whirls2[i], points[i], gauge2, gauge3, M)
            update!(whirls3[i], points[i], gauge3, gauge4, M)
            update!(whirls4[i], points[i], gauge4, gauge5, M)
        end
    end
    # elseif stage == 7
    #     scale = cos(stageprogress * 2π) + sin(stageprogress * 2π) * π
    #     T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
    #     q = Quaternion(T, X, Y, Z)
    #     M = I(4)
    #     gauge1 = 0.0
    #     gauge2 = π / 2
    #     gauge3 = float(π)
    #     gauge4 = 3π / 2
    #     gauge5 = 2π
    #     chart = (-π / 4, π / 4, -π / 4, π / 4) .* scale
    #     global points = Vector{Quaternion}[]
    #     for i in eachindex(boundary_nodes)
    #         _points = Quaternion[]
    #         for node in boundary_nodes[i]
    #             r, θ, ϕ = convert_to_geographic(node)
    #             push!(_points, q * Quaternion(exp(scale * ϕ / 4 * K(1) + scale * θ / 2 * K(2))))
    #         end
    #         push!(points, _points)
    #     end
    #     update!(basemap1, chart)
    #     update!(basemap2, chart)
    #     update!(basemap3, chart)
    #     update!(basemap4, chart)
    #     update!(basemap1, q, gauge1, M)
    #     update!(basemap2, q, gauge2, M)
    #     update!(basemap3, q, gauge3, M)
    #     update!(basemap4, q, gauge4, M)
    #     for i in eachindex(whirls1)
    #         update!(whirls1[i], points[i], gauge1, gauge2, M)
    #         update!(whirls2[i], points[i], gauge2, gauge3, M)
    #         update!(whirls3[i], points[i], gauge3, gauge4, M)
    #         update!(whirls4[i], points[i], gauge4, gauge5, M)
    #     end
    # end
    updatecamera()
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end