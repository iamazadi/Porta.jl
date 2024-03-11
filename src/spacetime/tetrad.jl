import Base.*
import Base.isapprox


export Tetrad
export mat


"""
    Represents an n-dimensional orthogonal frame.
"""
abstract type Ennuple end


"""
    Represents a basis for the Minkowski vector space 𝕍.

fields: t, x, y and z.
"""
struct Tetrad <: Ennuple
    t::ℝ⁴
    x::ℝ⁴
    y::ℝ⁴
    z::ℝ⁴
    Tetrad(t::ℝ⁴, x::ℝ⁴, y::ℝ⁴, z::ℝ⁴) = new(t, x, y, z)
    Tetrad(a::Matrix{Float64}) = new(ℝ⁴(a[1, :]), ℝ⁴(a[2, :]), ℝ⁴(a[3, :]), ℝ⁴(a[4, :]))
end


## Approximate equality ##

Base.isapprox(g::Tetrad, h::Tetrad; atol::Float64 = TOLERANCE) = begin
    isapprox(g.t, h.t, atol = atol) && isapprox(g.x, h.x, atol = atol) && isapprox(g.y, h.y, atol = atol) && isapprox(g.z, h.z, atol = atol)
end

mat(tetrad::Tetrad) = begin
    t = vec(tetrad.t)
    x = vec(tetrad.x)
    y = vec(tetrad.y)
    z = vec(tetrad.z)
    [t[1] t[2] t[3] t[4];
     x[1] x[2] x[3] x[4];
     y[1] y[2] y[3] y[4];
     z[1] z[2] z[3] z[4]]
end

*(g1::Tetrad, g2::Tetrad) = Tetrad(mat(g1) * mat(g2))