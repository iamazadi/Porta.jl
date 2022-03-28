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


startframe = 85
frames = 3600
FPS = 60
resolution = (3840, 2160)
segments = 36
exportmode = ["gif", "frames", "video"]
exportmode = exportmode[2]
modelname = "spin3_alpha1"

# The scene object that contains other visual objects
#Makie.reasonable_resolution() = (800, 800)
scene = Makie.Scene(backgroundcolor = :white,
                    show_axis = false,
                    resolution = resolution)

geocoordinates = Dict()
geocoordinates["Antarctica"] = deg2rad.([135.00; 82.86])
geocoordinates["Japan"] = deg2rad.([138.25; -36.20])
geocoordinates["Italy"] = deg2rad.([12.56; -41.87])
geocoordinates["Germany"] = deg2rad.([10.45; -51.16])
geocoordinates["Canada"] = deg2rad.([-106.34; -56.13])
geocoordinates["United States of America"] = deg2rad.([-95.71; -37.09])
geocoordinates["United Kingdom"] = deg2rad.([-3.43; -55.37])
geocoordinates["France"] = deg2rad.([2.21; -46.22])


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


A(p::ComplexPlane) = begin
    z₀, z₁ = vec(p)
    r = vec(Quaternion(p)) # radial
    f = [-r[2]; r[1]; -r[4]; r[3]] # fiber tangent
    X₀, X₁ = vec(ComplexPlane(Quaternion(f)))
    U1(1 / 2 * (conj(z₀) * X₀ - z₀ * conj(X₀) + conj(z₁) * X₁ - z₁ * conj(X₁)))
end


# Use QGIS to design a geo map
colorref = FileIO.load("data/gdp/map_color_reference.png")
color = FileIO.load("data/gdp/map_transparent.png")
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.

# 1. Download cultural data admin 0 from natural earth data
# 2. Install qgis desktop
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
ϵ = 1e-3
countries = Dict("shapeid" => [], "name" => [], "gdpmd" => [],
                 "gdpyear" => [], "economy" => [], "partid" => [], "nodes" => [])
selection = collect(keys(geocoordinates))
for i in 1:number
    shapeid = attributesgroup[i][!, :shapeid][1]
    name = attributesgroup[i][!, :NAME][1]
    if !(name in selection) continue end
    gdpmd = attributesgroup[i][!, :GDP_MD][1]
    gdpyear = attributesgroup[i][!, :GDP_YEAR][1]
    economy = attributesgroup[i][!, :ECONOMY][1]
    subdataframe = nodes[nodes.shapeid .== shapeid, :]
    uniquepartid = unique(subdataframe[!, :partid])
    # if economy == "1. Developed region: G7"
    #     push!(selection, name)
    # end
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

configuration = Biquaternion(ℝ³(0, 0, 0))
solidwhirls = []
ghostwhirls = []
number = length(selection)
for i in 1:number
    name = countries["name"][i]
    points = countries["nodes"][i]
    gdpmd = countries["gdpmd"][i]
    α₁ = name == "Antarctica" ? 0.1 : 0.7
    α₂ = name == "Antarctica" ? 0.05 : 0.3
    solidcolor = getcolor(name, points, colorref, α₁)
    ghostcolor = getcolor(name, points, colorref, α₂)
    points = map(x -> σmap(x), points)
    solidgauge1 = [U1(0) for j in 1:length(points)]
    solidgauge2 = [U1(gdpmd * 2π) for j in 1:length(points)]
    solidgauge1 = convert(Array{U1,1}, solidgauge1)
    solidgauge2 = convert(Array{U1,1}, solidgauge2)
    ghostgauge1 = solidgauge2
    ghostgauge2 = solidgauge2
    solidwhirl = Whirl(scene,
                       points,
                       solidgauge1,
                       solidgauge2,
                       configuration = configuration,
                       segments = segments,
                       color = solidcolor,
                       transparency = true)
    push!(solidwhirls, solidwhirl)
    ghostwhirl = Whirl(scene,
                       points,
                       ghostgauge1,
                       ghostgauge2,
                       configuration = configuration,
                       segments = segments,
                       color = ghostcolor,
                       transparency = true)
    push!(ghostwhirls, ghostwhirl)
end

framesprites = []
framesprite1 = Frame(scene,
                     σmap,
                     color,
                     configuration = configuration,
                     segments = 3segments,
                     transparency = true)
framesprite2 = Frame(scene,
                     σmap,
                     color,
                     configuration = configuration,
                     segments = 3segments,
                     transparency = true)
push!(framesprites, framesprite1)
push!(framesprites, framesprite2)


group2algebra(A::SU2, r::Float64) = begin
    τ₃ = -0.5 .* [im 0; 0 -im]
    (-2 * r) .* (A.a * τ₃ * LinearAlgebra.inv(A.a))
end


exponentiate(M::Array{<:Complex,2}, t::Float64) = begin
    eigenvalues = LinearAlgebra.eigvals(M)
    eigenvectors = LinearAlgebra.eigvecs(M)
    S = eigenvectors
    S⁻¹ = LinearAlgebra.inv(S)
    e = LinearAlgebra.Diagonal(eigenvalues) .* t
    S = convert.(Complex{BigFloat}, S)
    S⁻¹ = convert.(Complex{BigFloat}, S⁻¹)
    e = convert.(Complex{BigFloat}, e)
    G = S * ℯ.^e * S⁻¹
    z₁, z₂ = G[1,1], G[1,2]
    v = LinearAlgebra.normalize([real(z₁); imag(z₁); real(z₂); imag(z₂)])
    z₁, z₂ = Complex{Float64}(v[1] + im * v[2]), Complex{Float64}(v[3] + im * v[4])
    G = [z₁ -conj(z₂); z₂ conj(z₁)]
    SU2(G)
end


L₁ = [Complex(0) Complex(1); Complex(1) Complex(0)]
L₂ = [Complex(0) Complex(-im); Complex(im) Complex(0)]
L₃ = [Complex(1) Complex(0); Complex(0) Complex(-1)]
rotation = 4π
operator = exponentiate(L₃, 0.0)
ϵ = float(π / 2)


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i::Int)
    step = i / frames
    τ = step * rotation
    ψ = Int(τ ÷ ϵ)
    θ = τ % ϵ

    q₁ = [exponentiate(group2algebra(operator, 1.0), ϵ) for x in 1:ψ]
    q = exponentiate(group2algebra(operator, 1.0), θ)
    for item in q₁
        q = SU2(normalize(Quaternion(item * q)))
    end

    for index in 1:number
        # gdpmd = countries["gdpmd"][index]
        points = countries["nodes"][index]
        p = map(x -> ComplexPlane(normalize(Quaternion(SU2(σmap(x)) * q))), points)
        # α = gdpmd * 2π
        g₁ = map(x -> U1(0), p)
        g₂ = A.(p)
        g₃ = map(x -> U1(2π), p)
        update(solidwhirls[index], p, g₁, g₂)
        update(ghostwhirls[index], p, g₂, g₃)
    end

    σ₁(x) = begin
        p = σmap(x)
        p = ComplexPlane(normalize(Quaternion(SU2(p) * q)))
        α = A(p)
        _g = transformg(p, U1(0), α, 3segments)[end]
        S¹action(p, _g)
    end
    σ₂(x) = begin
        p = σmap(x)
        p = ComplexPlane(normalize(Quaternion(SU2(p) * q)))
        α = A(p)
        S¹action(p, α)
    end
    update(framesprite1, σ₁)
    update(framesprite2, σ₂)
end


function saveframe(filepath, scene, resolution)
    FileIO.save(filepath,
                scene;
                resolution = resolution,
                pt_per_unit = 400.0,
                px_per_unit = 400.0)
end


n = ℝ³(0, 0, 1)
v = ℝ³(-1, -1, 0) * (pi / 2)
#v = rotate(v, Quaternion(π / 8, ℝ³(0, 0, 1)))
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
        sleep(0.1)
        println("Generating frame $i took $elapsed (s).")

        start = time()

        paddingnumber = length(digits(frames))
        imageid = lpad(i, paddingnumber, "0")
        imagename = "$(modelname)_$(resolution[2])p_$(FPS)fps_$imageid.jpeg"
        filepath = joinpath(directory, imagename)
        saveframe(filepath, scene, resolution)
        elapsed = time() - start
        sleep(0.1)
        println("Saving file $filepath took $elapsed (s).")

        step = (i - 1) / frames
        println("Completed step $(100step).\n")
        sleep(1)

        stitch() = begin
            part = i ÷ (frames / 3)
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

        if isapprox(i % (frames / 3), 0)
            sleep(1)
            stitch()
            sleep(1)
        end
        # break
    end
end
