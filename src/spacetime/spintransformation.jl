import Base.:*
import Base.:-
import Base.vec
import Base.isapprox


export SpinTransformation
export mat
export det
export inverse


"""
    Represents a spin transformation.

fields: α, β, γ and δ
"""
struct SpinTransformation
    α::Complex
    β::Complex
    γ::Complex
    δ::Complex
    SpinTransformation(a::Vector{<:Complex}) = begin
        @assert(length(a) == 4, "The input vector must contain exactly four numbers.")
        new(a...)
    end
    SpinTransformation(α::Complex, β::Complex, γ::Complex, δ::Complex) = new(α, β, γ, δ)
    SpinTransformation(m::Matrix{<:Complex}) = SpinTransformation(m[1, 1], m[1, 2], m[2, 1], m[2, 2])
end


Base.vec(a::SpinTransformation) = [a.α; a.β; a.γ; a.δ]


"""
    mat(a)

Return the spin matrix with the given spin transformation `a`.
"""
mat(a::SpinTransformation) = [a.α a.β; a.γ a.δ]


det(a::SpinTransformation) = real(a.α * a.δ - a.β * a.γ)


*(a::SpinTransformation, b::SpinVector) = SpinVector((a.α * b.ζ + a.β) / (a.γ * b.ζ + a.δ), b.timesign)


*(a::SpinTransformation, b::𝕄) = 𝕄(mat(a) * mat(b) * adjoint(mat(a)))


-(a::SpinTransformation) = SpinTransformation(-a.α, -a.β, -a.γ, -a.δ)


inverse(a::SpinTransformation) = SpinTransformation(a.δ, -a.β, -a.γ, a.α)


Base.isapprox(a::SpinTransformation, b::SpinTransformation; atol::Float64 = TOLERANCE) = isapprox(a.α, b.α, atol = atol) &&
                                                                                         isapprox(a.β, b.β, atol = atol) &&
                                                                                         isapprox(a.γ, b.γ, atol = atol) &&
                                                                                         isapprox(a.δ, b.δ, atol = atol)

                    
"""
    SpinVector(q)

Transform a quaternion nuber to a spin vector.
"""
function SpinVector(q::Quaternion)
    t, x, y, z = vec(q)
    t = √(x^2 + y^2 + z^2)
    SpinVector(𝕍(t, x, y, z))
end


"""
    Quaternion(v)

Perform a trick to convert `q` to a Quaternion number.
"""
Quaternion(v::SpinVector) = Quaternion(vec(v.nullvector)[1], normalize(v.cartesian))


𝕄(v::SpinVector) = begin
    T = real(1.0 / √2 * (v.ξ * conj(v.ξ) + v.η * conj(v.η)))
    X = real(1.0 / √2 * (v.ξ * conj(v.η) + v.η * conj(v.ξ)))
    Y = real(1.0 / (im * √2) * (v.ξ * conj(v.η) - v.η * conj(v.ξ)))
    Z = real(1.0 / √2 * (v.ξ * conj(v.ξ) - v.η * conj(v.η)))
    tetrad = Tetrad(ℝ⁴(1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, -1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, -1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, -1.0))
    𝕄(𝕍(0.0, 0.0, 0.0, 0.0), 𝕍(T, X, Y, Z), tetrad)
end