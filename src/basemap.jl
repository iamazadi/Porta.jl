import GLMakie


export Basemap
export update!
export make


function make(q::Quaternion, segments::Integer; chart::NTuple{4, Float64} = (-π / 4, π / 4, -π / 4, π / 4))
    matrix = Matrix{ℝ³}(undef, segments, segments)
    lspaceθ = collect(range(chart[1], stop = chart[2], length = segments))
    lspaceϕ = collect(range(chart[3], stop = chart[4], length = segments))
    for (i, ϕ) in enumerate(lspaceϕ)
        for (j, θ) in enumerate(lspaceθ)
            matrix[i, j] = project(exp(θ * K(1) + -ϕ * K(2)) * q)
        end
    end
    matrix
end


"""
    Represents a horizontal subspace.

fields: q, segments, color and observable.
"""
mutable struct Basemap <: Sprite
    q::Quaternion
    chart::NTuple{4, Float64}
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Basemap(scene::GLMakie.LScene, q::Quaternion, chart::NTuple{4, Float64}, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(q, segments, chart = chart)
        observable = buildsurface(scene, matrix, color, transparency = transparency)
        new(q, chart, segments, color, observable)
    end
end


"""
    update!(basemap, q)

Switch to the right horizontal subsapce with the given point `q`.
"""
function update!(basemap::Basemap, q::Quaternion)
    basemap.q = q
    matrix = make(q, basemap.segments, chart = basemap.chart)
    updatesurface!(matrix, basemap.observable)
end

"""
    update!(basemap, chart)

Update the bundle chart in the horizontal subspace with the given 'chart.
"""
function update!(basemap::Basemap, chart::NTuple{4, Float64})
    basemap.chart = chart
    matrix = make(basemap.q, basemap.segments, chart = chart)
    updatesurface!(matrix, basemap.observable)
end

