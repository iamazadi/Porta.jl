import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using Porta

resolution = (1920, 1080)
segments = 60
basemapsegments = 120
frames_number = 1440

modelname = "segment21"
makefigure() = GLMakie.Figure(resolution=resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20 / 255, 20 / 255, 20 / 255))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(0.0196, 0.0, 0.1019)
observable = GLMakie.Observable(false)
lscene = GLMakie.LScene(fig[1, 1], show_axis=observable, scenekw=(resolution=resolution, lights=[pl, al], backgroundcolor=backgroundcolor, clear=true))

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
country_name2 = "Antarctica"
country_nodes1 = Vector{Vector{Float64}}()
country_nodes2 = Vector{Vector{Float64}}()
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
end

α = 0.1
_color1 = getcolor(country_nodes1, colorref, α)
_color2 = getcolor(country_nodes2, colorref, α)
α2 = 1.0
color1 = getcolor(country_nodes1, colorref, α2)
color2 = getcolor(country_nodes2, colorref, α2)
w1 = [τmap(country_nodes1[i]) for i in eachindex(country_nodes1)]
w2 = [τmap(country_nodes2[i]) for i in eachindex(country_nodes2)]
θ = 3π / 2
elementsnumber = 30
gauge2 = convert(Vector{Float64}, [θ for i in 1:length(w1)])
whirl1 = Whirl(lscene, w1, [0.0 for i in 1:length(w1)], gauge2, segments, color1, transparency=false)
_whirl1 = Whirl(lscene, w1, gauge2, [2π for i in 1:length(w1)], segments, _color1, transparency=true)
_whirl2 = Whirl(lscene, w2, [2π for i in 1:length(w2)], [2π for i in 1:length(w2)], segments, _color2, transparency=true)
frame1 = Basemap(lscene, x -> G(0, τmap(x)), basemapsegments, basemap_color, transparency=false)
frame2 = Basemap(lscene, x -> G(θ, τmap(x)), basemapsegments, basemap_color, transparency=false)

frame = 1
eyeposition = [0.44; -1.52; -0.79]
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
    normalize(progress * Quaternion([z₂; z₁]) + (1.0 - progress) * Quaternion([z₁; z₂]))
end

totalstages = 6 # ℝ → ℂ → ℂ² → S³ → S² → ℝ³
initialized = Dict()
for i in 1:totalstages
    initialized[i] = false
end


function animate(stage, stageprogress)
    if stage == 1
        ϕ = 0.0
        θ = stageprogress * 2π
        center = [0.0; 0.0; 0.0]
        for i in eachindex(country_nodes1)
            geographic = convert_to_geographic(country_nodes1[i])
            center = center + geographic
        end
        center[1] = 1.0
        center[2] = center[2] ./ length(country_nodes1)
        center[3] = center[3] ./ length(country_nodes1)
        center = convert_to_cartesian(center)
        update!(frame1, x -> τ(x, ϕ))
        update!(frame2, x -> G(θ, τ(x, ϕ)))
        update!(whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
        update!(_whirl1, τ.(country_nodes1, ϕ), [θ for _ in 1:length(country_nodes1)], [2π for _ in 1:length(country_nodes1)])

        tail = project(G(θ, τ(center, ϕ)))
        head = normalize(project(G(-0.01 + θ, τ(center, ϕ))) - tail)

        global lookat = 0.95 .* lookat + 0.05 .* GLMakie.Vec3f(tail...)
        global up = 0.95 .* up + 0.05 .* GLMakie.Vec3f(head...)
    end

    if stage == 2
        ϕ = stageprogress * 2π
        θ = (1.0 - stageprogress) * 2π
        if initialized[2] == false
            update!(whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [0.0 for _ in 1:length(country_nodes1)])
            initialized[2] = true
        end
        update!(_whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [θ for _ in 1:length(country_nodes1)])
        
        update!(frame1, x -> τ(x, ϕ))
        update!(frame2, x -> G(θ, τ(x, ϕ)))

        center = convert_to_cartesian([1.0; 0.0; π / 2 * 0.99])
        tail = project(G(θ, τ(center, ϕ)))
        head = normalize(project(G(-0.01 + θ, τ(center, ϕ))) - tail)

        global lookat = 0.99 .* lookat + 0.01 .* GLMakie.Vec3f(tail...)
        global up = 0.99 .* up + 0.01 .* GLMakie.Vec3f(head...)
    end

    if stage == 3
        ϕ = (1.0 - stageprogress) * 2π
        θ = stageprogress * 2π
        update!(_whirl2, τ.(country_nodes2, ϕ, stageprogress), [0.0 for _ in 1:length(country_nodes2)], [θ for _ in 1:length(country_nodes2)])
        update!(frame1, x -> G(0.0, τ(x, ϕ, stageprogress)))
        update!(frame2, x -> G(θ, τ(x, ϕ, stageprogress)))

        if initialized[3] == false
            update!(whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [0.0 for _ in 1:length(country_nodes1)])
            update!(_whirl1, τ.(country_nodes1, ϕ), [0.0 for _ in 1:length(country_nodes1)], [0.0 for _ in 1:length(country_nodes1)])
            initialized[3] = true
        end
       
        global lookat = 0.99 .* lookat + 0.01 .* GLMakie.Vec3f(0.0, 0.0, 0.0)
        global up = 0.99 .* up + 0.01 .* GLMakie.Vec3f(0.0, 0.0, 1.0)
    end

    if stage == 4
        ϕ = 0.0
        θ = (1.0 - stageprogress) * 2π
        update!(_whirl2, τ.(country_nodes2, ϕ, (1.0 - stageprogress)), [0.0 for _ in 1:length(country_nodes2)], [θ for _ in 1:length(country_nodes2)])
        update!(frame1, x -> G(θ, τ(x, ϕ, (1.0 - stageprogress))))
        update!(frame2, x -> G(0.0, τ(x, ϕ, (1.0 - stageprogress))))
    end

    if stage == 5
        ϕ = 0.0
        θ = 0.0
        if initialized[5] == false
            update!(_whirl2, τ.(country_nodes2, ϕ), [0.0 for _ in 1:length(country_nodes2)], [0.0 for _ in 1:length(country_nodes2)])
            initialized[5] = true
        end
        
        matrix = make(x -> G(0.0, τ(x, ϕ, 0.0)), frame1.segments)
        sphere = Matrix{Vector{Float64}}(undef, frame1.segments, frame1.segments)
        factor = 0.999 # use a limiting factor to avoid the poles
        lspace_ϕ = collect(range(-π, stop = float(π), length = frame1.segments))
        lspace_θ = collect(range(π / 2 * factor, stop = -π / 2 * factor, length = frame1.segments))
        for (i, θ) in enumerate(lspace_θ)
            for (j, ϕ) in enumerate(lspace_ϕ)
                sphere[i, j] = convert_to_cartesian([1; ϕ; θ])
            end
        end
        interpolation = stageprogress .* sphere + (1.0 - stageprogress) .* matrix
        updatesurface!(interpolation, frame1.observable)

        _sphere = deepcopy(interpolation)
        for i in eachindex(_sphere)
            _sphere[i] = interpolation[i] + [0.0; 0.0; 3.0] .* stageprogress
        end
        updatesurface!(_sphere, frame2.observable)
        global eyeposition = 0.99 .* eyeposition + 0.01 .* [1.5; 1.5; 1.5]
    end

    if stage == 6
        ϕ = stageprogress * 2π
        θ = 0.0
        if initialized[6] == false
            observable[] = true
            initialized[6] = true
        end
        
        sphere = Matrix{Vector{Float64}}(undef, frame1.segments, frame1.segments)
        factor = 0.999 # use a limiting factor to avoid the poles
        lspace_ϕ = collect(range(-π, stop = float(π), length = frame1.segments)) .+ ϕ
        lspace_θ = collect(range(π / 2 * factor, stop = -π / 2 * factor, length = frame1.segments))
        for (i, θ) in enumerate(lspace_θ)
            for (j, ϕ) in enumerate(lspace_ϕ)
                sphere[i, j] = convert_to_cartesian([1; ϕ; θ])
            end
        end
        updatesurface!(sphere, frame1.observable)
        global eyeposition = 0.99 .* eyeposition + 0.01 .* [2.0; 2.0; 2.0]
    end
    
    GLMakie.update_cam!(lscene.scene, GLMakie.Point3f(eyeposition...), lookat, up)
end

GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    animate(stage, stageprogress)
end
