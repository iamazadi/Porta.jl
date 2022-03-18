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
import DifferentialEquations
import Images

using Porta


startframe = 1
frames = 3600
FPS = 60
resolution = (3840, 2160)
segments = 72
basepointsegments = 6
basepointradius = 0.005
speed = 1
scale = 1.0
g₀ = U1(0)
exportmode = ["gif", "frames", "video"]
exportmode = exportmode[2]
modelname = "curvaturetwoform"

# The scene object that contains other visual objects
#Makie.reasonable_resolution() = (800, 800)
scene = Makie.Scene(backgroundcolor = :black,
                    show_axis = false,
                    resolution = resolution)

geocoordinates = Dict()
geocoordinates["Japan"] = deg2rad.([138.25; -36.20])
geocoordinates["Italy"] = deg2rad.([12.56; -41.87])
geocoordinates["Germany"] = deg2rad.([10.45; -51.16])
geocoordinates["Canada"] = deg2rad.([-106.34; -56.13])
geocoordinates["United States of America"] = deg2rad.([-95.71; -37.09])
geocoordinates["United Kingdom"] = deg2rad.([-3.43; -55.37])
geocoordinates["France"] = deg2rad.([2.21; -46.22])
geocoordinates["Antarctica"] = deg2rad.([135.00; 82.86])


fmap(b::S²) = begin
    # r, ϕ, θ = vec(Geographic(b))
    # r₀ = √((1 - sin(θ)) / 2) * (π / 2)
    # ϕ, θ = r₀ .* (cos(ϕ), sin(ϕ))
    # Geographic(r, ϕ, θ)
    b
end


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


function getcolor(name::String, points::Array{Geographic,1}, color::Array{ColorTypes.RGBA{FixedPointNumbers.Normed{UInt8, 8}}, 2}, α::Float64)
    height, width = size(color)
    margin = 25
    if name in keys(geocoordinates)
        ϕ, θ = geocoordinates[name]
    else
        ϕ = map(x -> x.ϕ, points)
        θ = map(x -> x.θ, points)
        number = length(points)
        ϕ = sum(ϕ) / number
        θ = sum(θ) / number
    end
    ϕ, θ = (ϕ + π) / 2π, (θ + π / 2) / π
    x = Int(floor(ϕ * (width - 1))) + 1
    y = Int(floor(θ * (height - 1))) + 1
    colors = Dict()
    for i in -margin:margin
        for j in -margin:margin
            c = color[y + i, x + j]
            if isapprox(c.r, 0) && isapprox(c.g, 0) && isapprox(c.b, 0) continue end
            colors[c] = get(colors, c, 0) + 1
        end
    end
    array = []
    for (key, value) in colors
        push!(array, (value, key))
    end
    lt(x, y) = x[1] < y[1]
    array = sort(array, lt = lt, rev = true)
    c = array[begin][end]
    r, g, b, a = c.r, c.g, c.b, c.alpha
    Makie.RGBAf(r, g, b, α)
end


# Use QGIS to design a geo map
colorref = FileIO.load("data/gdp/map_transparent.png")
# mg_channel_view = Images.channelview(color)
# for i in 1:size(mg_channel_view)[1]
#     for j in 1:size(mg_channel_view)[2]
#         mg_channel_view[i, j, 4] = mg_channel_view[i, j, 4] * 0.1
#     end
# end
# color_transparent = Images.colorview(Images.RGBA, mg_channel_view)
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.

# The path to the dataset
attributespath = "data/gdp/geometry-attributes.csv"
attributes = DataFrames.DataFrame(CSV.File(attributespath))
attributes = DataFrames.sort(attributes, :shapeid, rev = true)
nodespath = "data/gdp/geometry-nodes.csv"
nodes = DataFrames.DataFrame(CSV.File(nodespath))

selection = []

attributesgroup = DataFrames.groupby(attributes, :NAME)
nodesgroup = DataFrames.groupby(nodes, :shapeid)
number = length(attributesgroup)
ϵ = 1e-3
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
    if economy == "1. Developed region: G7"
        push!(selection, name)
    end
    # ϵ = name == "Antarctica" ? 5e-3 : 1e-3
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

selection = [selection; "Antarctica"]
selection = ["United States of America"]
println("Selected countries:")
println(selection)

s3rotation = Quaternion(1, 0, 0, 0)
config = Biquaternion(ℝ³(0, 0, 0))
solidwhirls = Dict()
ghostwhirls = Dict()
phases = Array{U1,2}(undef, number, 4)
for i in 1:number
    name = countries["name"][i]
    if !(name in selection) continue end
    points = countries["nodes"][i]
    gdpmd = countries["gdpmd"][i]
    α₁ = 0.5
    α₂ = 0.1
    solidcolor = getcolor(name, points, colorref, α₁)
    ghostcolor = getcolor(name, points, colorref, α₂)
    solidtop = U1(0)
    solidbottom = U1(0)
    ghosttop = solidbottom
    ghostbottom = U1(2π)
    phases[i, 1] = solidtop
    phases[i, 2] = solidbottom
    phases[i, 3] = ghosttop
    phases[i, 4] = ghostbottom
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
                       transparency = true)
    solidwhirls[name] = solidwhirl
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
    ghostwhirls[name] = ghostwhirl
end

framesprite2 = Frame(scene,
                     U1(0),
                     σmap,
                     fmap,
                     colorref,
                     s3rotation = s3rotation,
                     config = config,
                     segments = 5segments,
                     transparency = true)


rectifyaction(point::S², gauge::S¹, section, s2tos2map, s3rotation::S³; scale = 1.0) = begin
    actions = getactions(point, section, s2tos2map, top = U1(0), bottom = U1(2π), s3rotation = s3rotation, segments = 1000, scale = scale)
    index = max(1, Int(floor((angle(gauge) / 2π) * length(actions))))
    U1(actions[index])
end


getpoint(point::S², gauge::S¹, section, s2tos2map, s3rotation::S³; scale = 1.0) = begin
    # action = rectifyaction(point, gauge, section, s2tos2map, s3rotation, scale = 1.0)
    compressedλmap(rotate(S¹action(section(s2tos2map(point)), gauge), s3rotation)) * scale
end


points = Dict()
for key in keys(ghostwhirls)
    points[key] = [getpoint(p, g₀, σmap, fmap, s3rotation) for p in ghostwhirls[key].points]
end

numbers = Dict()
for key in selection
    numbers[key] = length(points[key])
end

N = 7
frames = N * (max([numbers[key] for key in selection]...) + 3)
println("Frames number: $frames")

basepoints = Dict()
uppoints = Dict()
for key in selection
    basepoints[key] = Array{Sphere,1}(undef, numbers[key])
    uppoints[key] = similar(basepoints[key])
    for i in 1:numbers[key]
        config2 = Biquaternion(ℝ³(Cartesian(points[key][1])))
        hue = (i - 1) / numbers[key] * 360
        color2 = Makie.RGBAf(hsvtorgb([hue, 0.7, 0.7])..., 0)
        sphere = Sphere(config2,
                        scene,
                        radius = basepointradius,
                        segments = basepointsegments,
                        color = color2,
                        transparency = true)
        basepoints[key][i] = sphere
        color2 = Makie.RGBAf(hsvtorgb([hue, 1.0, 1.0])..., 0)
        sphere = Sphere(config2,
                        scene,
                        radius = basepointradius,
                        segments = basepointsegments,
                        color = color2,
                        transparency = false)
        uppoints[key][i] = sphere
    end
end


"""
    γ: [0,1] → M

A curve inside an open set U ⊆ M over which Pᵤ is trivial.
"""
γ(t::Float64, points::Vector{<:S²}) = begin
    if t < 0 || t > 1
        println("Bad parameter: t ∈ [0,1].")
        return
    end
    number = length(points)

    i₁ = Int(floor(number * t))
    if i₁ == 0
        i₁ = 1
        i₂ = 2
        remainder = t
        p₁ = vec(Geographic(points[i₁]))
        p₂ = vec(Geographic(points[i₂]))
        p = p₁ + (p₂ - p₁) .* remainder
    elseif i₁ == number
        remainder = 1e-7
        p₁ = vec(Geographic(points[i₁]))
        p = p₁ + p₁ .* remainder
    else
        i₂ = i₁ + 1
        t₁ = i₁ / number
        remainder = t - t₁
        remainder = isapprox(remainder, 0) ? 1e-7 : remainder
        p₁ = vec(Geographic(points[i₁]))
        p₂ = vec(Geographic(points[i₂]))
        p = p₁ + (p₂ - p₁) .* remainder
    end
    Geographic(p...)
end


A(s, p::S²) = begin
    z = s(p)
    z₀, z₁ = vec(ComplexPlane(z))
    r = vec(z) # radial
    f = [-r[2]; r[1]; -r[4]; r[3]] # fiber tangent
    X₀, X₁ = vec(ComplexPlane(Quaternion(f)))
    1/2 * (conj(z₀) * X₀ - z₀ * conj(X₀) + conj(z₁) * X₁ - z₁ * conj(X₁))
end


function getg(initial::S¹, curve, section, points::Vector{<:S²})
    angle2(z) = angle(z) ≥ 0 ? angle(z) : 2π + angle(z)
    model!(dg, g, p, t) = begin
        f(t) = begin
            h = 1e-7
            t₁ = t + h > 1 ? t - h : t
            t₂ = t + h > 1 ? t : t + h
            p₁, p₂ = p(t₁), p(t₂)
            z₁, z₂ = A(section, p₁), A(section, p₂)
            # println("A₁: $z₁, A₂: $z₂")
            θ = angle2(z₂) - angle2(z₁)
            θ = θ / h
            ψ = angle2(z₁) + θ
            ℯ^(im * ψ)
        end
    
        result = -(f(t) * Complex(g...))
        result = ℯ^(im * angle2(result))
        dg[1] = real(result)
        dg[2] = imag(result)
    end
    
    
    z = ℯ^(im * angle(initial))
    g₀ = [real(z); imag(z)]
    tspan = (0.0, 1.0)
    saveat = range(0, stop = 1, length = length(points))

    p(t::Float64) = curve(t, points)
    
    prob = DifferentialEquations.ODEProblem(model!, g₀, tspan, p)
    sol = DifferentialEquations.solve(prob, saveat = saveat)
    map(x -> U1(angle2(Complex(x...))), sol.u)
end

g = Dict()
gstate = Dict()
for key in keys(ghostwhirls)
    g[key] = getg(g₀, γ, σmap, fmap.(ghostwhirls[key].points))
    gstate[key] = g₀
end

arrows = Dict()
for key in selection
    len = 0.01
    width = 0.01
    hue = (1 - 1) / numbers[key] * 360
    color2 = Makie.RGBAf(hsvtorgb([hue, 1.0, 1.0])..., 0.0)
    tail, head = points[key][1], points[key][2]
    head = normalize(head - tail) * len
    arrows[key] = Arrow(tail, head, scene, width = width, color = color2)
end

xarrows = Dict()
for key in selection
    len = 0.01
    width = 0.01
    hue = (1 - 1) / numbers[key] * 360
    color2 = Makie.RGBAf(hsvtorgb([hue, 1.0, 1.0])..., 0.0)
    tail, head = points[key][1], points[key][2]
    head = normalize(head - tail) * len
    xarrows[key] = Arrow(tail, head, scene, width = width, color = color2)
end

yarrows = Dict()
for key in selection
    len = 0.01
    width = 0.01
    hue = (1 - 1) / numbers[key] * 360
    color2 = Makie.RGBAf(hsvtorgb([hue, 1.0, 1.0])..., 0.0)
    tail, head = points[key][1], points[key][2]
    head = normalize(head - tail) * len
    yarrows[key] = Arrow(tail, head, scene, width = width, color = color2)
end

n = ℝ³(1, 0, 0);
v = ℝ³(-1, -1, 1) * (π / 2);


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i::Int)
    step = ((i - 1) % (frames / N)) / (frames / N)
    
    step = ((i - 1) % (frames / N)) / (frames / N)
    indices = Dict()
    p = Dict()

    for key in keys(ghostwhirls)
        index = Int(floor(step * numbers[key])) + 1
        indices[key] = index
        
        σ(x) = rotate(S¹action(σmap(fmap(x)), gstate[key]), s3rotation)

        x = ghostwhirls[key].points[index]
        r, ϕ, θ = vec(x)
        h = 1e-7
        x₁ = Geographic(r, ϕ + h, θ)
        x₂ = Geographic(r, ϕ, θ + h)
        X₁ = σ(x₁)
        X₂ = σ(x₂)
        X = (X₂ - X₁) / h
        Y = ghostwhirls[key].points[index]

        basepoint = getpoint(ghostwhirls[key].points[index], gstate[key], σmap, fmap, s3rotation)
        uppoint = getpoint(ghostwhirls[key].points[index], gstate[key] * g[key][index], σmap, fmap, s3rotation)
        update(basepoints[key][index], Biquaternion(basepoint))
        update(uppoints[key][index], Biquaternion(uppoint))
        update(arrows[key], basepoint, uppoint - basepoint)

        hue = (index - 1) / numbers[key] * 360
        c₁ = Makie.RGBAf(hsvtorgb([hue, 1.0, 1.0])..., 1.0)
        c₂ = Makie.RGBAf(hsvtorgb([hue, 0.7, 0.7])..., 0.7)
        c₃ = Makie.RGBAf(hsvtorgb([hue, 1.0, 1.0])..., 0.5)
        update(uppoints[key][index], c₁)
        update(basepoints[key][index], c₂)
        update(arrows[key], c₃)

        p[key] = (basepoint, uppoint)
    end

    action = U1(max([angle(g[key][indices[key]]) for key in selection]...))
    update(framesprite1, gstate["United States of America"] * action)

    for key in keys(ghostwhirls)
        update(solidwhirls[key], gstate["United States of America"], gstate["United States of America"] * action)
    end

    if isapprox(i % (frames / N), 0)
        for key in selection
            gstate[key] = gstate[key] * g[key][end]
            s(x) = S¹action(σmap(x), gstate[key])
            g[key] = getg(g₀, γ, s, fmap.(ghostwhirls[key].points))
        end
        action = U1(max([angle(gstate[key]) for key in selection]...))
        update(framesprite2, action)
        println("g: $action")
    end

    η = i == 1 ? 1.0 : 0.05
    p₁ = p["United States of America"][1]
    p₂ = p["United States of America"][2]
    p₃ = isapprox(norm(p₂ - p₁), 0) ? n * 0.01 : p₂ - p₁
    n₀ = normalize(p₃)
    global n = (1 - η) * n + η * n₀
    v₀ = normalize(p₁ + 0.5 * p₃) * (π / 2) * √2
    global v = (1 - η) * v + η * v₀
    upvector = GeometryBasics.Vec3f0(vec(n)...);
    eyeposition = GeometryBasics.Vec3f0(vec(v)...);
    lookat = GeometryBasics.Vec3f0(0, 0, 0);
    Makie.update_cam!(scene, eyeposition, lookat, upvector);
    scene.center = false; # prevent scene from recentering on display
end


function saveframe(filepath, scene, resolution)
    FileIO.save(filepath,
                scene;
                resolution = resolution,
                pt_per_unit = 400.0,
                px_per_unit = 400.0)
end


n = ℝ³(1, 0, 0);
v = ℝ³(-1, -1, 1) * (π / 2) * √2;
# v = rotate(v, Quaternion(-π / 10, ℝ³(0, 0, 1)));
#v = ℝ³(Cartesian(points[1]))
#v = ℝ³(0.03, 0.5, 1.04) * 0.3
#l = ℝ³(Cartesian(points[1]))
# v = rotate(v, Quaternion(-π / 8, ℝ³(0, 0, 1)))
# update eye position
# scene.camera.eyeposition.val
upvector = GeometryBasics.Vec3f0(vec(n)...);
eyeposition = GeometryBasics.Vec3f0(vec(v)...);
lookat = GeometryBasics.Vec3f0(0, 0, 0);
#camera = Makie.Camera3D(scene)
# Makie.update_cam!(scene, camera, eyeposition, lookat, upvector)
Makie.update_cam!(scene, eyeposition, lookat, upvector);
scene.center = false; # prevent scene from recentering on display

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
        elapsed = round(time() - start, digits = 4)
        sleep(0.1)
        println("Generating frame $i took $elapsed (s).")

        start = time()

        paddingnumber = length(digits(frames))
        imageid = lpad(i, paddingnumber, "0")
        imagename = "$(modelname)_$(resolution[2])p_$(FPS)fps_$imageid.jpeg"
        filepath = joinpath(directory, imagename)
        saveframe(filepath, scene, resolution)
        elapsed = round(time() - start, digits = 4)
        sleep(0.1)
        println("Saving file $filepath took $elapsed (s).")

        step = round((i - 1) / frames, digits = 4)
        println("Completed step $(100step).\n")

        stitch() = begin
            part = i
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

        if i == frames
            sleep(1)
            stitch()
            sleep(1)
        end
        break
    end
end
