import Base.vec


export 𝕄
export vec
export Φ


tetrad = Tetrad(ℝ⁴(1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, -1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, -1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, -1.0))


"""
    Represents a point in the Minkowski space-time 𝕄 with respect to a given origin.

fields: origin, point and tetrad.
"""
struct 𝕄 <: VectorSpace
    origin::𝕍
    point::𝕍
    tetrad::Tetrad
    𝕄(origin::𝕍, point::𝕍, tetrad::Tetrad) = new(origin, point, tetrad)
    𝕄(m::Matrix{<:Complex}) = begin
        @assert(size(m) == (2, 2), "The matrix representation must be a square 2 by 2 matrix, but was given $(size(m)).")
        T = 0.5 * real(m[1, 1] + m[2, 2])
        X = 0.5 * real(m[1, 2] + m[2, 1])
        Y = imag(m[1, 2])
        Z = 0.5 * real(m[1, 1] - m[2, 2])
        𝕄(𝕍(0., 0.0, 0.0, 0.0), 𝕍(T, X, Y, Z), tetrad)
    end
end


Base.vec(p::𝕄) = vec(p.point) - vec(p.origin)


mat(p::𝕄) = begin
    T, X, Y, Z = vec(p)
    [T + Z X + im * Y;
     X - im * Y T - Z] .* (1.0 / √2.0)
end


"""
    vec(p, q)

Get the position vector p⃖q⃖ ∈ 𝕍 of `q` relative to `p` where p,q ∈ 𝕄.
vec: 𝕄 × 𝕄 → 𝕍
"""
function Base.vec(p::𝕄, q::𝕄)
    q.point - p.point
end


"""
    Φ(p, q)

The squared interval is the norm that 𝕍 induces on the Minkowski space-time 𝕄 by the generic function vec.
"""
function Φ(p::𝕄, q::𝕄)
    lorentznorm(vec(p, q))
end