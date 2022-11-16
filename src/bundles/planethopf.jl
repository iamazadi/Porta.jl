import ColorTypes
import FixedPointNumbers

export Point
export Line
export getdistance
export decimate
export getcolor
export isinside
export getbutterflycurve


"""
    Represents a point

fields: x and y.
"""
struct Point{T}
    x::T
    y::T
end
Base.show(io::IO, p::Point) = print(io, "($(p.x), $(p.y))")

const Edge = Tuple{Point{T}, Point{T}} where T
Base.show(io::IO, e::Edge) = print(io, "$(e[1]) ∘−∘ $(e[2])")


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
    height, width = size(color)
    margin = 20
    ϕ = map(x -> x.ϕ, points)
    θ = map(x -> π / 2 - (π / 2 + x.θ), points)
    number = length(points)
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
            c = color[y + i, x + j]
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
    Makie.RGBA{FixedPointNumbers.Normed{UInt8, 8}}(r, g, b, α)
end


"""
    rayintersectseg(p, edge)

Determines whther a ray cast from a point intersects an edge with the given point `p` and `edge`.
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


isinside(poly::Vector{Tuple{Point{T}, Point{T}}}, p::Point{T}) where T = isodd(count(edge -> rayintersectseg(p, edge), poly))

connect(a::Point{T}, b::Point{T}...) where T = [(a, b) for (a, b) in zip(vcat(a, b...), vcat(b..., a))]

"""
    isinside(point, boundary)

Determine whether the given `point` is inside the `boundary`.
"""
function isinside(point::Geographic, boundary::Array{Geographic,1})
    p = Point(point.ϕ, point.θ)
    N = length(boundary)
    poly = Vector{Tuple{Point{Float64}, Point{Float64}}}(undef, N)
    for i in 1:N
        a = boundary[i]
        b = i == N ? boundary[1] : boundary[i + 1]
        a = Point(a.ϕ, a.θ)
        b = Point(b.ϕ, b.θ)
        poly[i] = (a, b)
    end
    isinside(poly, p)
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