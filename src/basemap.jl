import GLMakie


export Basemap
export update!
export make


"""
    make(q, M, segments, chart)

Make a 2-surface of the horizontal section at point `q` after transformation with `f`, and with the given `segments` number and `chart`.
"""
function make(q::Quaternion, f::Any, segments::Integer; chart::NTuple{4, Float64} = (-π / 4, π / 4, -π / 4, π / 4))
    matrix = Matrix{ℝ³}(undef, segments, segments)
    lspaceθ = collect(range(chart[1], stop = chart[2], length = segments))
    lspaceϕ = collect(range(chart[3], stop = chart[4], length = segments))
    for (i, ϕ) in enumerate(lspaceϕ)
        for (j, θ) in enumerate(lspaceθ)
            point = exp(θ * K(1) + -ϕ * K(2)) * q
            matrix[i, j] = project(f(point))
        end
    end
    matrix
end


"""
    Represents a horizontal subspace.

fields: q, f, chart, segments, color and observable.
"""
mutable struct Basemap <: Sprite
    q::Quaternion
    f::Any
    chart::NTuple{4, Float64}
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Basemap(scene::GLMakie.LScene, q::Quaternion, f::Any, chart::NTuple{4, Float64}, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(q, f, segments, chart = chart)
        observable = buildsurface(scene, matrix, color, transparency = transparency)
        new(q, f, chart, segments, color, observable)
    end
end


"""
    update!(basemap, q, M)

Switch to the right horizontal section with the given point `q` and transformation `f`.
"""
function update!(basemap::Basemap, q::Quaternion, f::Any)
    basemap.q = q
    basemap.f = f
    matrix = make(q, f, basemap.segments, chart = basemap.chart)
    updatesurface!(matrix, basemap.observable)
end


"""
    update!(basemap, chart)

Update the bundle chart in the horizontal subspace with the given 'chart.
"""
function update!(basemap::Basemap, chart::NTuple{4, Float64})
    basemap.chart = chart
    matrix = make(basemap.q, basemap.f, basemap.segments, chart = chart)
    updatesurface!(matrix, basemap.observable)
end

