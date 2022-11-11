import ColorTypes
import FixedPointNumbers

export Line
export getdistance
export decimate
export getcolor


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
    margin = 25
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