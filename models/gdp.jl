import LinearAlgebra
import FileIO
import GeometryBasics
import Observables
import Makie
import GLMakie
import DataFrames
import CSV
import ColorTypes
import FixedPointNumbers
import LinearAlgebra
import DifferentialEquations

using Porta


startframe = 1
frames = 3600
FPS = 60
resolution = (3840, 2160)
segments = 36
speed = 1
scale = 1.0
exportmode = ["gif", "frames", "video"]
exportmode = exportmode[2]
modelname = "gdp_alpha2"

# The scene object that contains other visual objects
#Makie.reasonable_resolution() = (800, 800)
scene = Makie.Scene(backgroundcolor = :white,
                    show_axis = false,
                    resolution = resolution)


fmap(b::S²) = b


"""
λ⁻¹map(p)
Sends a point on the plane back to a point on a unit sphere with the given
point. This is the inverse stereographic projection of a 3-sphere.
"""
function λ⁻¹map(p::S²)
    r3 = ℝ³(Cartesian(p))
    p₁, p₂, p₃ = vec(r3)
    mgnitude² = norm(r3)^2
    x₁ = 2p₁ / (1 + mgnitude²)
    x₂ = 2p₂ / (1 + mgnitude²)
    x₃ = 2p₃ / (1 + mgnitude²)
    x₄ = (-1 + mgnitude²) / (1 + mgnitude²)
    Quaternion(x₁, x₂, x₃, x₄)
end


"""
    getpointonpath(t)

Get a point on a path on S² with the given parameter `t`. t ∈ [0, 1].
"""
getpointonpath(t::Real) = begin
    t = t * 12π
    d = ℯ^cos(t) - 2cos(4t) - sin(t / 12)^5
    x, y = sin(t) * d, cos(t) * d
    ComplexLine(x + im * y)
end


"""
    getbutterflycurve(points)

Get butterfly curve by Temple H. Fay (1989) with the given number of `points`.
"""
function getbutterflycurve(points::Int)
    array = Array{ComplexLine,1}(undef, points)
    # 0 ≤ t ≤ 12π
    for i in 1:points
        t = (i - 1) / points * 12π
        d = ℯ^cos(t) - 2cos(4t) - sin(t / 12)^5
        x, y = sin(t) * d, cos(t) * d
        array[i] = ComplexLine(x + im * y)
    end
    array
end



"""
    Represents a line segment.

fields: p₁ and p₂.
"""
struct Line
    p₁::ℝ³
    p₂::ℝ³
end


function getdistance(point::ℝ³, line::Line)
    p₀ = point
    p₁, p₂ = line.p₁, line.p₂
    norm(cross(p₂ - p₁, p₁ - p₀)) / norm(p₂ - p₁)
end


function decimate(points::Array{Geographic,1}, ϵ::Float64)
    # Find the point with the maximum distance
    dmax = 0
    index = 1
    number = length(points)
    for i in 2:number-1
        line = Line(ℝ³(Cartesian(points[begin])), ℝ³(Cartesian(points[end])))
        point = ℝ³(Cartesian(points[i]))
        d = getdistance(point, line)
        if d > dmax
            index = i
            dmax = d
        end
    end

    array = []

    # If max distance is greater than epsilon, recursively simplify
    if dmax > ϵ
        # Recursive call
        array1 = decimate(points[begin:index], ϵ)
        array2 = decimate(points[index:end], ϵ)

        # Build the result list
        array = [array1[begin:end-1]; array2]
    else
        array = [points[begin]; points[end]]
    end
    # Return the result
    array
end


function getcolor(points::Array{Geographic,1}, color::Array{ColorTypes.RGBA{FixedPointNumbers.Normed{UInt8, 8}}, 2}, α::Float64)
    ϕ = map(x -> x.ϕ, points)
    θ = map(x -> x.θ, points)
    number = length(points)
    ϕ = sum(ϕ) / number
    θ = sum(θ) / number
    height, width = size(color)
    x = Int(floor((ϕ + π) / 2π * width))
    y = height - Int(floor((θ + π / 2) / π * height))
    r, g, b, a = color[y, x].r, color[y, x].g, color[y, x].b, color[y, x].alpha
    Makie.RGBAf(r, g, b, α)
end


# Use QGIS to design a geo map
colorref = FileIO.load("data/gdp/map_colors.png")
color = FileIO.load("data/gdp/map_transparent2.png")
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.

# 1. Download cultural data admin 0 from natural earth data
# 2. Install this desktop
# 3. Install mmqgis plugin for exporting to CSV

# The path to the dataset
attributespath = "data/gdp/geometry-attributes.csv"
attributes = DataFrames.DataFrame(CSV.File(attributespath))
attributes = DataFrames.sort(attributes, :shapeid, rev = true)
nodespath = "data/gdp/geometry-nodes.csv"
nodes = DataFrames.DataFrame(CSV.File(nodespath))

attributesgroup = DataFrames.groupby(attributes, :NAME)
nodesgroup = DataFrames.groupby(nodes, :shapeid)
number = length(attributesgroup)
ϵ = 5e-3
countries = Dict("shapeid" => [], "name" => [], "gdpmd" => [],
                 "gdpyear" => [], "economy" => [], "partid" => [], "nodes" => [])
for i in 1:number
    shapeid = attributesgroup[i][!, :shapeid][1]
    name = attributesgroup[i][!, :NAME][1]
    gdpmd = attributesgroup[i][!, :GDP_MD][1]
    gdpyear = attributesgroup[i][!, :GDP_YEAR][1]
    economy = attributesgroup[i][!, :ECONOMY][1]
    subdataframe = nodes[nodes.shapeid .== shapeid, :]
    uniquepartid = unique(subdataframe[!, :partid])
    ϵ = name == "Antarctica" ? 1e-3 : 5e-3
    histogram = Dict()
    for id in uniquepartid
        sub = subdataframe[subdataframe.partid .== id, :]
        ϕ = sub.x ./ 180 .* π
        θ = sub.y ./ 180 .* π
        coordinates = map(x -> Geographic(1, x[1], x[2]), eachrow([ϕ θ]))[begin:end-1]
        coordinates = decimate(coordinates, ϵ)
        histogram[id] = length(coordinates)
    end
    partsnumber = max(values(histogram)...)
    index = findfirst(x -> histogram[x] == partsnumber, uniquepartid)
    partid = uniquepartid[index]
    subdataframe = subdataframe[subdataframe.partid .== partid, :]
    ϕ = subdataframe.x ./ 180 .* π
    θ = subdataframe.y ./ 180 .* π
    coordinates = map(x -> Geographic(1, x[1], x[2]), eachrow([ϕ θ]))[begin:end-1]
    println("Length of points: $name : $(length(coordinates))")
    coordinates = decimate(coordinates, ϵ)
    println("Length of points: $name : $(length(coordinates))")
    push!(countries["shapeid"], shapeid)
    push!(countries["name"], name)
    push!(countries["gdpmd"], gdpmd)
    push!(countries["gdpyear"], gdpyear)
    push!(countries["economy"], economy)
    push!(countries["partid"], partid)
    push!(countries["nodes"], coordinates)
end

for i in 1:length(countries["nodes"])
    println(length(countries["nodes"][i]))
end

countries["gdpmd"] = countries["gdpmd"] ./ (max(countries["gdpmd"]...) - min(countries["gdpmd"]...))

s3rotation = Quaternion(1, 0, 0, 0)
config = Biquaternion(ℝ³(0, 0, 0))
solidwhirls = []
ghostwhirls = []
phases = Array{U1,2}(undef, number, 4)
for i in 1:number
    name = countries["name"][i]
    points = countries["nodes"][i]
    gdpmd = countries["gdpmd"][i]
    α₁ = name == "Antarctica" ? 0.1 : 1.0
    α₂ = name == "Antarctica" ? 0.05 : 0.1
    solidcolor = getcolor(points, colorref, α₁)
    ghostcolor = getcolor(points, colorref, α₂)
    solidtop = U1(0)
    solidbottom = U1(gdpmd * 2π)
    ghosttop = solidbottom
    ghostbottom = solidbottom
    phases[i, 1] = solidtop
    phases[i, 2] = solidbottom
    phases[i, 3] = ghosttop
    phases[i, 4] = ghostbottom
    #segments2 = name == "Antarctica" ? 2segments : segments
    solidwhirl = Whirl(scene,
                       points,
                       σmap,
                       fmap,
                       top = solidtop,
                       bottom = solidbottom,
                       s3rotation = s3rotation,
                       config = config,
                       segments = segments,
                       color = solidcolor,
                       transparency = false)
    push!(solidwhirls, solidwhirl)
    ghostwhirl = Whirl(scene,
                       points,
                       σmap,
                       fmap,
                       top = ghosttop,
                       bottom = ghostbottom,
                       s3rotation = s3rotation,
                       config = config,
                       segments = segments,
                       color = ghostcolor,
                       transparency = true)
    push!(ghostwhirls, ghostwhirl)
end

framesprites = []
framesprite1 = Frame(scene,
                     U1(0),
                     σmap,
                     fmap,
                     color,
                     s3rotation = s3rotation,
                     config = config,
                     segments = 2segments,
                     transparency = true)
framesprite2 = Frame(scene,
                     U1(0),
                     σmap,
                     fmap,
                     color,
                     s3rotation = s3rotation,
                     config = config,
                     segments = 2segments,
                     transparency = true)
push!(framesprites, framesprite1)
push!(framesprites, framesprite2)

a, b = ComplexLine(1 + im), ComplexLine(0.5 - 1.5 * im)
c, d = ComplexLine(-0.5 + 1 * im), ComplexLine(-1 + 0.3 * im)
f(z, a, b, c, d) = (a * z + b) / (c * z + d)


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i::Int)
    factor = 0.666
    step = (i - 1) / frames
    u = getpointonpath(step)
    if isnan(vec(u)[1]) || isnan(vec(u)[2])
        u = Geographic(1, 0, π/2)
    end
    τ = step * speed * 2pi
    ω = 2τ
    u = ℝ³(Cartesian(u))
    q = Quaternion(τ, u)
    a′, b′, c′, d′ = [ComplexLine(Cartesian(rotate(ℝ³(Cartesian(point)), q))).z for point in (a, b, c, d)]
    newmap(x::S²) = begin
        z = ComplexLine(x).z
        z = ComplexLine(f(z, a′, b′, c′, d′))
        if isnan(vec(z)[1]) || isnan(vec(z)[2])
            z = ComplexLine(Geographic(1, 0, -π / 2))
        end
        r, ϕ, θ = vec(Geographic(z))
        if isnan(r)
            z = ComplexLine(Geographic(1, ϕ, θ * 0.99))
        end
        z
    end
    newmap2(x::S²) = begin
        g = Geographic(x)
        r, ϕ, θ = vec(g)
        Geographic(r, ϕ + ω, θ)
    end
    for index in 1:number
        gdpmd = countries["gdpmd"][index] * (factor * 2π)
        solidtop = U1(0)
        solidbottom = U1(min(τ, gdpmd))
        ghosttop = solidbottom
        ghostbottom = τ > gdpmd ? U1(min(τ, 2π * factor)) : ghosttop
        phases[index, 1] = solidtop
        phases[index, 2] = solidbottom
        phases[index, 3] = ghosttop
        phases[index, 4] = ghostbottom
    end
    for (index, item) in enumerate(solidwhirls)
        item.s2tos2map = newmap2
        solidtop = phases[index, 1]
        solidbottom = phases[index, 2]
        points = countries["nodes"][index]
        update(item, points, s3rotation, solidtop, solidbottom)
    end
    for (index, item) in enumerate(ghostwhirls)
        item.s2tos2map = newmap2
        ghosttop = phases[index, 3]
        ghostbottom = phases[index, 4]
        points = countries["nodes"][index]
        update(item, points, s3rotation, ghosttop, ghostbottom)
    end
    update(framesprite1, σmap, newmap2)
    framesprite2.s2tos2map = newmap2
    update(framesprite2, U1(min(factor * 2π, τ)))

    n = ℝ³(0, 0, 1)
    v = ℝ³(-1, -1, sin(τ)^2) * (π / 2)
    v = rotate(v, Quaternion(π / 8 + π / 8 * sin(-τ), ℝ³(0, 0, 1)))
    # v = rotate(v, Quaternion(-π / 8, ℝ³(0, 0, 1)))
    # update eye position
    # scene.camera.eyeposition.val
    upvector = GeometryBasics.Vec3f0(vec(n)...)
    eyeposition = GeometryBasics.Vec3f0(vec(v)...)
    lookat = GeometryBasics.Vec3f0(0, 0, 0)
    #camera = Makie.Camera3D(scene)
    # Makie.update_cam!(scene, camera, eyeposition, lookat, upvector)
    Makie.update_cam!(scene, eyeposition, lookat, upvector)
    scene.center = false # prevent scene from recentering on display
end


function saveframe(filepath, scene, resolution)
    FileIO.save(filepath,
                scene;
                resolution = resolution,
                pt_per_unit = 400.0,
                px_per_unit = 400.0)
end


n = ℝ³(0, 0, 1)
v = ℝ³(-1, -1, 0) * 2.0
v = rotate(v, Quaternion(π / 8, ℝ³(0, 0, 1)))
# v = rotate(v, Quaternion(-π / 8, ℝ³(0, 0, 1)))
# update eye position
# scene.camera.eyeposition.val
upvector = GeometryBasics.Vec3f0(vec(n)...)
eyeposition = GeometryBasics.Vec3f0(vec(v)...)
lookat = GeometryBasics.Vec3f0(0, 0, 0)
#camera = Makie.Camera3D(scene)
# Makie.update_cam!(scene, camera, eyeposition, lookat, upvector)
Makie.update_cam!(scene, eyeposition, lookat, upvector)
scene.center = false # prevent scene from recentering on display
if exportmode ∈ ["gif", "video"]
    outputextension = exportmode == "gif" ? "gif" : "mkv"
    Makie.record(scene, "gallery/$modelname.$outputextension",
                            framerate = FPS) do io
        for i in startframe:frames
            animate(i) # animate the scene
            Makie.recordframe!(io) # record a new frame
            step = (i - 1) / frames
            println("Completed step $(100step).\n")
        end
    end
elseif exportmode == "frames"
    directory = joinpath("gallery", modelname)
    !isdir(directory) && mkdir(directory)
    for i in startframe:frames
        start = time()
        animate(i) # animate the scene
        elapsed = time() - start
        println("Generating frame $i took $elapsed (s).")

        start = time()

        paddingnumber = length(digits(frames))
        imageid = lpad(i, paddingnumber, "0")
        imagename = "$(modelname)_$(resolution[2])p_$(FPS)fps_$imageid.jpeg"
        filepath = joinpath(directory, imagename)
        saveframe(filepath, scene, resolution)
        elapsed = time() - start
        println("Saving file $filepath took $elapsed (s).")

        step = (i - 1) / frames
        println("Completed step $(100step).\n")
        sleep(5)

        stitch() = begin
            part = i ÷ (frames / 5)
            exportdir = joinpath(directory, "export")
            !isdir(exportdir) && mkdir(exportdir)
            WxH = "$(resolution[1])x$(resolution[2])"
            #WxH = "1920x1080"
            commonpart = "$(modelname)_$(resolution[2])p_$(FPS)fps"
            inputname = "$(commonpart)_%0$(paddingnumber)d.jpeg"
            inputpath = joinpath(directory, inputname)
            outputname = "$(commonpart)_$(part).mp4"
            outputpath = joinpath(exportdir, outputname)
            command1 = `ffmpeg -y -f image2 -framerate $FPS -i $inputpath -s $WxH -pix_fmt yuvj420p $outputpath`
            run(command1)
        end

        if isapprox(i % (frames / 5), 0)
            sleep(5)
            stitch()
            sleep(5)
        end
        # break
    end
end
