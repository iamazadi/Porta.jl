import Base.vec
import Base.isapprox


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
    𝕄(origin::𝕍, m::Matrix{<:Complex}, tetrad::Tetrad) = begin
        @assert(size(m) == (2, 2), "The matrix representation must be a square 2 by 2 matrix, but was given $(size(m)).")
        T = 0.5 * real(m[1, 1] + m[2, 2])
        X = 0.5 * real(m[1, 2] + m[2, 1])
        Y = imag(m[1, 2])
        Z = 0.5 * real(m[1, 1] - m[2, 2])
        𝕄(origin, 𝕍(T, X, Y, Z), tetrad)
    end
    𝕄(ξ::Complex, η::Complex) = begin
        T = real(1.0 / √2 * (ξ * conj(ξ) + η * conj(η)))
        X = real(1.0 / √2 * (ξ * conj(η) + η * conj(ξ)))
        Y = real(1.0 / (im * √2) * (ξ * conj(η) - η * conj(ξ)))
        Z = real(1.0 / √2 * (ξ * conj(ξ) - η * conj(η)))
        tetrad = Tetrad(ℝ⁴(1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, -1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, -1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, -1.0))
        𝕄(𝕍(0.0, 0.0, 0.0, 0.0), 𝕍(T, X, Y, Z), tetrad)
    end
end


Base.vec(p::𝕄) = vec(p.point) - vec(p.origin)


mat(p::𝕄) = begin
    T, X, Y, Z = vec(p)
    [Complex(T + Z) X + im * Y;
     X - im * Y Complex(T - Z)]
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



Base.isapprox(a::𝕄, b::𝕄; atol::Float64 = TOLERANCE) = isapprox(a.origin, b.origin, atol = atol) &&
                                                        isapprox(a.point, b.point, atol = atol) &&
                                                        isapprox(a.tetrad, b.tetrad, atol = atol)