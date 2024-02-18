import CSV
import DataFrames
import GLMakie
using LinearAlgebra

export Point
export Line
export Edge
export getdistance
export decimate
export convert_to_geographic
export convert_to_cartesian
export rayintersectseg
export isinside
export getcolor
export getbutterflycurve
export loadcountries


"""
    Represents a point

fields: x and y.
"""
struct Point{T}
    x::T
    y::T
end


"""
    show(p)

Print a string representation of the point `p`.
"""
Base.show(io::IO, p::Point) = print(io, "($(p.x), $(p.y))")


"""
    Represents an edge between two endpoints of a line segment.
"""
const Edge = Tuple{Point{T}, Point{T}} where T


"""
    show(e)

Print a string representation of the edge `e`.
"""
Base.show(io::IO, e::Edge) = print(io, "$(e[1]) ∘−∘ $(e[2])")


"""
    Represents a line segment.

fields: p₁ and p₂.
"""
struct Line
    p₁::Vector{Float64}
    p₂::Vector{Float64}
end


"""
    getdistance(point, line)

Calculate the length of a line segment perpendicular to `line` and passing through the given `point`.
"""
function getdistance(point::Vector{Float64}, line::Line)
    p₀ = point
    p₁, p₂ = line.p₁, line.p₂
    norm(cross(p₂ - p₁, p₁ - p₀)) / norm(p₂ - p₁)
end


"""
    decimate(points, ϵ)

Decimate a curve containing a sequence of `points` by adding points to the curve that are farther ferom each other than the given threshold `ϵ`.
"""
function decimate(points::Vector{Vector{Float64}}, ϵ::Float64)
    # Find the point with the maximum distance
    dmax = 0
    index = 1
    number = length(points)
    for i in 2:number-1
        line = Line(points[begin], points[end])
        point = points[i]
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
        array = [[points[begin]]; [points[end]]]
    end
    # Return the result
    array
end


"""
    convert_to_geographic(p)

Convert a point from cartesian coordinate to geographic coordinates.
"""
convert_to_geographic(p::Vector{Float64}) = begin
    x, y, z = p
    r = norm(p)
    [r; atan(y, x); asin(z / r)]
end


"""
   getcolor(points, basemap, α)

Get the color of the given `basemap` at the center of the boundary specified by `points`, and set the alpha channel to `α`.

Use QGIS to design a geo map.
"""
function getcolor(points::Vector{Vector{Float64}}, basemap::Any, α::Float64)
    number = length(points)
    if (number == 0)
        return GLMakie.RGBA(1.0, 1.0, 1.0, α)
    end
    height, width = size(basemap)
    margin = 20
    ϕ = map(x -> convert_to_geographic(x)[2], points)
    θ = map(x -> π / 2 - (π / 2 + convert_to_geographic(x)[3]), points)
    ϕ = sum(ϕ) / number
    θ = sum(θ) / number
    ϕ, θ = (ϕ + π) / 2π, (θ + π / 2) / π
    x = Int(floor(ϕ * (width - 1))) + 1
    y = Int(floor(θ * (height - 1))) + 1
    colors = Dict()
    for i in -margin:margin
        for j in -margin:margin
            if x + j > width || y + i > height
                continue
            end
            if x + j < 1 || y + i < 1
                continue
            end
            c = basemap[y + i, x + j]
            # if isapprox(c.r, 0) && isapprox(c.g, 0) && isapprox(c.b, 0) continue end
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
    GLMakie.RGBA(r, g, b, α)
end


"""
    rayintersectseg(p, edge)

Determine whther a ray cast from a point intersects an edge with the given point `p` and `edge`.
"""
function rayintersectseg(p::Point{T}, edge::Edge{T}) where T
    a, b = edge
    if a.y > b.y
        a, b = b, a
    end
    if p.y ∈ (a.y, b.y)
        p = Point(p.x, p.y + eps(p.y))
    end

    rst = false
    if (p.y > b.y || p.y < a.y) || (p.x < max(a.x, b.x))
        return false
    end

    if p.x < min(a.x, b.x)
        rst = true
    else
        mred = (b.y - a.y) / (b.x - a.x)
        mblu = (p.y - a.y) / (p.x - a.x)
        rst = mblu ≥ mred
    end

    return rst
end


"""
    isinside(poly, p)

Determine whether the given point `p` is inside the shape `poly`.
"""
isinside(poly::Vector{Tuple{Point{T}, Point{T}}}, p::Point{T}) where T = isodd(count(edge -> rayintersectseg(p, edge), poly))


"""
    isinside(point, boundary)

Determine whether the given `point` is inside the `boundary`.
"""
function isinside(point::Vector{Float64}, boundary::Vector{<:Vector{<:Real}})
    _point = convert_to_geographic(point)
    p = Point(_point[2], _point[3])
    N = length(boundary)
    _boundary = map(x -> convert_to_geographic(x), boundary)
    poly = Vector{Tuple{Point{Float64}, Point{Float64}}}(undef, N)
    for i in 1:N
        a = _boundary[i]
        b = i == N ? _boundary[1] : _boundary[i + 1]
        a = Point(a[2], a[3])
        b = Point(b[2], b[3])
        poly[i] = (a, b)
    end
    isinside(poly, p)
end


"""
    convert_to_cartesian(z)

Convert the given point `z` in the Riemann sphere to cartesian coordinates.
"""
convert_to_cartesian(z::Complex) = begin
    x, y = real(z), imag(z)
    d = x^2 + y^2 + 1
    [2x / d; 2y / d; (d - 2) / d]
end


"""
    getbutterflycurve(points)

Get the butterfly curve with the given number of `points`.
Temple H. Fay (1989)
"""
function getbutterflycurve(points::Integer)
    array = Vector{ComplexF64}(undef, points)
    # 0 ≤ t ≤ 12π
    for i in 1:points
        t = (i - 1) / points * 12π
        d = ℯ^cos(t) - 2cos(4t) - sin(t / 12)^5
        x, y = sin(t) * d, cos(t) * d
        array[i] = x + im * y
    end
    array
end


"""
    loadcountries(attributes_path, nodes_path)

Load the natural earth data, including boundaries, with the given path for geometry `attributes` and `nodes`.

Made with Natural Earth.
Free vector and raster map data @ naturalearthdata.com.
1. Download cultural data admin 0 from natural earth data
2. Install qgis desktop
3. Install mmqgis plugin for exporting to CSV
"""
function loadcountries(attributes_path::String, nodes_path::String)
    attributes = DataFrames.DataFrame(CSV.File(attributes_path))
    attributes = DataFrames.sort(attributes, :shapeid, rev = true)
    nodes = DataFrames.DataFrame(CSV.File(nodes_path))

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
        # ϵ = name == "Antarctica" ? 5e-3 : 1e-3
        ϵ = 1e-3
        histogram = Dict()
        for id in uniquepartid
            sub = subdataframe[subdataframe.partid .== id, :]
            ϕ = sub.x ./ 180 .* π
            θ = sub.y ./ 180 .* π
            coordinates = map(x -> convert_to_cartesian([1; x[1]; x[2]]), eachrow([ϕ θ]))[begin:end-1]
            coordinates = decimate(coordinates, ϵ)
            histogram[id] = length(coordinates)
        end
        partsnumber = max(values(histogram)...)
        index = findfirst(x -> histogram[x] == partsnumber, uniquepartid)
        partid = uniquepartid[index]
        subdataframe = subdataframe[subdataframe.partid .== partid, :]
        ϕ = subdataframe.x ./ 180 .* π
        θ = subdataframe.y ./ 180 .* π
        coordinates = map(x -> convert_to_cartesian([1; x[1]; x[2]]), eachrow([ϕ θ]))[begin:end-1]
        # println("Length of points: $name : $(length(coordinates))")
        coordinates = decimate(coordinates, ϵ)
        # println("Length of points: $name : $(length(coordinates))")
        push!(countries["shapeid"], shapeid)
        push!(countries["name"], name)
        push!(countries["gdpmd"], gdpmd)
        push!(countries["gdpyear"], gdpyear)
        push!(countries["economy"], economy)
        push!(countries["partid"], partid)
        push!(countries["nodes"], coordinates)
    end

    # for i in 1:length(countries["nodes"])
    #     println(length(countries["nodes"][i]))
    # end

    countries["gdpmd"] = countries["gdpmd"] ./ (max(countries["gdpmd"]...) - min(countries["gdpmd"]...))
    countries
end