import GLMakie


export Basemap
export update!
export make


"""
    make(x, gauge, M, segments, chart)

Make a 2-surface of the horizontal section at point `x` after transformation with `M`, and with the given `segments` number and `chart`.
"""
function make(x::Quaternion, gauge::Float64, M::Matrix{Float64}, segments::Integer; chart::NTuple{4, Float64} = (-π / 4, π / 4, -π / 4, π / 4))
    lspaceθ = range(chart[1], stop = chart[2], length = segments)
    lspaceϕ = range(chart[3], stop = chart[4], length = segments)
    [project(normalize(M * (x * Quaternion(exp(θ * K(1) + -ϕ * K(2)) * exp(gauge * K(3)))))) for ϕ in lspaceϕ, θ in lspaceθ]
end


"""
    Represents a horizontal subspace.

fields: x, M, chart, segments, color and observable.
"""
mutable struct Basemap <: Sprite
    x::Quaternion
    gauge::Float64
    M::Matrix{Float64}
    chart::NTuple{4, Float64}
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Basemap(scene::GLMakie.LScene, x::Quaternion, gauge::Float64, M::Matrix{Float64}, chart::NTuple{4, Float64}, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(x, gauge, M, segments, chart = chart)
        observable = buildsurface(scene, matrix, color, transparency = transparency)
        new(x, gauge, M, chart, segments, color, observable)
    end
end


"""
    update!(basemap, x, gauge, M)

Switch to the right horizontal section with the given point `x`, `gauge` and transformation `M`.
"""
function update!(basemap::Basemap, x::Quaternion, gauge::Float64, M::Matrix{Float64})
    basemap.x = x
    basemap.gauge = gauge
    basemap.M = M
    matrix = make(x, gauge, M, basemap.segments, chart = basemap.chart)
    updatesurface!(matrix, basemap.observable)
end


"""
    update!(basemap, chart)

Update the bundle chart in the horizontal subspace with the given 'chart.
"""
function update!(basemap::Basemap, chart::NTuple{4, Float64})
    basemap.chart = chart
    matrix = make(basemap.x, basemap.gauge, basemap.M, basemap.segments, chart = chart)
    updatesurface!(matrix, basemap.observable)
end

