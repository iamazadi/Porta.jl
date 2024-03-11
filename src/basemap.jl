import GLMakie


export Basemap
export update!
export make


function make(q::Quaternion, segments::Integer)
    matrix = Matrix{ℝ³}(undef, segments, segments)
    lspaceϕ = collect(range(-π / 4, stop = π / 4, length = segments))
    lspaceθ = collect(range(-π / 4, stop = π / 4, length = segments))
    f = 0.9
    for (i, ϕ) in enumerate(lspaceϕ)
        for (j, θ) in enumerate(lspaceθ)
            matrix[i, j] = project(exp(f * θ * K(1) + f * -ϕ * K(2)) * q)
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
    segments::Integer
    color::Any
    observable::Tuple{GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}, GLMakie.Observable{Matrix{Float64}}}
    Basemap(scene::GLMakie.LScene, q::Quaternion, segments::Integer, color::Any; transparency::Bool = false) = begin
        matrix = make(q, segments)
        observable = buildsurface(scene, matrix, color, transparency = transparency)
        new(q, segments, color, observable)
    end
end


"""
    update!(basemap, q)

Switch to the right horizontal subsapce with the given point `q`.
"""
function update!(basemap::Basemap, q::Quaternion)
    basemap.q = q
    matrix = make(q, basemap.segments)
    updatesurface!(matrix, basemap.observable)
end
