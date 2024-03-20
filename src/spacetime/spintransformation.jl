import Base.:*
import Base.:-
import Base.vec
import Base.isapprox


export SpinTransformation
export mat
export mat4
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


mat4(a::SpinTransformation) = begin
    α, β, γ, δ = vec(a)
    _α, _β, _γ, _δ = conj.(vec(a))
    e11 = α * _α + β * _β  + γ * _γ  + δ * _δ
    e12 = α * _β  + β * _α + γ * _δ + δ * _γ
    e13 = im * (α * _β  - β * _α + γ * _δ - δ * _γ)
    e14 = α * _α - β * _β  + γ * _γ  - δ * _δ
    e21 = α * _γ  + γ * _α + β * _δ + δ * _β
    e22 = α * _δ + δ * _α + β * _γ  + γ * _β
    e23 = im * (α * _δ - δ * _α + γ * _β  - β * _γ)
    e24 = α * _γ  + γ * _α - β * _δ - δ * _β
    e31 = im * (γ * _α - α * _γ  + δ * _β  - β * _δ)
    e32 = im * (δ * _α - α * _δ + γ * _β  - β * _γ)
    e33 = α * _δ + δ * _α - β * _γ  - γ * _β
    e34 = im * (γ * _α - α * _γ  + β * _δ - δ * _β)
    e41 = α * _α + β * _β  - γ * _γ  - δ * _δ
    e42 = α * _β  + β * _α - γ * _δ - δ * _γ
    e43 = im * (α * _β  - β * _α + δ * _γ  - γ * _δ)
    e44 = α * _α - β * _β  - γ * _γ  + δ * _δ
    M = [e11 e12 e13 e14;
         e21 e22 e23 e24;
         e31 e32 e33 e34;
         e41 e42 e43 e44]
    real.(M)
end


det(a::SpinTransformation) = real(a.α * a.δ - a.β * a.γ)


*(a::SpinTransformation, b::SpinVector) = SpinVector((a.α * b.ζ + a.β) / (a.γ * b.ζ + a.δ), b.timesign)


*(a::SpinTransformation, b::𝕄) = 𝕄(b. origin, 𝕍(0.5 .* mat4(a) * vec(b)), b.tetrad)


*(M::Matrix{Float64}, a::𝕄) = 𝕄(a.origin, 𝕍(0.5 .* M * vec(a)), a.tetrad)


*(a::SpinTransformation, b::ℝ⁴) = ℝ⁴(0.5 .* mat4(a) * vec(b))


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

