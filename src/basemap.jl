import GLMakie


export Basemap
export update!


"""
    convert_to_cartesian(g)

Convert a point `g` from geographic coordinates into cartesian coordinates.
"""
function convert_to_cartesian(g::Vector{<:Real})
    r, ϕ, θ = vec(g)
    x = r * cos(θ) * cos(ϕ)
    y = r * cos(θ) * sin(ϕ)
    z = r * sin(θ)
    [x; y; z]
end


"""
    make(σ, sgments)

Make the shape of a frame as a 2-surface in ℝ³.
"""
function make(σ::Any, segments::Integer)
    matrix = Matrix{Vector{Float64}}(undef, segments, segments)
    factor = 0.99 # use a limiting factor to avoid the poles
    lspace_ϕ = collect(range(-π, stop = float(π), length = segments))
    lspace_θ = collect(range(π / 2 * factor, stop = -π / 2 * factor, length = segments))
    for (i, θ) in enumerate(lspace_θ)
        for (j, ϕ) in enumerate(lspace_ϕ)
            matrix[i, j] = project(σ(convert_to_cartesian([1; ϕ; θ])))
        end
    end
    matrix
end


"""
    Represents a base map.

fields: σ, segments, color and observable.
σ: S² → S³
"""
mutable struct Basemap <: Sprite
    σ::Any
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Basemap(scene::GLMakie.LScene, σ::Any, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(σ, segments)
        observable = buildsurface(scene, matrix, color, transparency = transparency)
        new(σ, segments, color, observable)
    end
end


"""
    update!(basemap, σ)

Update a Basemap's section `σ`.
"""
function update!(basemap::Basemap, σ::Any)
    basemap.σ = σ
    matrix = make(σ, basemap.segments)
    updatesurface!(matrix, basemap.observable)
end
