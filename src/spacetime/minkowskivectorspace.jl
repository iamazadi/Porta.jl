import Base.+
import Base.-
import Base.*
import Base.isapprox


export 𝕍
export lorentznorm
export istimelike
export isspacelike
export isnull
export iscausal


tetrad = Tetrad(ℝ⁴(1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, -1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, -1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, -1.0))


"""
    Represents a point in the Minkowski vector space 𝕍 with signature (+---).

fields: a and tetrad.
"""
struct 𝕍 <: VectorSpace
    a::ℝ⁴
    tetrad::Tetrad
    𝕍(x₁::Float64, x₂::Float64, x₃::Float64, x₄::Float64; tetrad::Tetrad = tetrad) = new(ℝ⁴([x₁; x₂; x₃; x₄]), tetrad)
    𝕍(v::ℝ⁴; tetrad::Tetrad = tetrad) = new(v, tetrad)
    𝕍(v::Vector{Float64}; tetrad::Tetrad = tetrad) = begin
        @assert(length(v) == 4, "The input vector must contain exactly four elements.")
        new(ℝ⁴(v), tetrad)
    end
end


## Unary Operators ##

+(r::𝕍) = r
-(r::𝕍) = 𝕍(-vec(r))


## Binary Operators ##

+(r1::𝕍, r2::𝕍) = 𝕍(vec(r1) + vec(r2))
-(r1::𝕍, r2::𝕍) = 𝕍(vec(r1) - vec(r2))
*(r::𝕍, λ::Real) = 𝕍(λ .* vec(r))
*(λ::Real, r::𝕍) = r * λ


## Approximate equality ##

Base.isapprox(u::𝕍, v::𝕍; atol::Float64 = TOLERANCE) = begin
    isapprox(vec(u), vec(v), atol = atol) && isapprox(u.tetrad, v.tetrad, atol = atol)
end

dot(u::𝕍, v::𝕍) = dot(u, v, mat(u.tetrad))
lorentznorm(u::𝕍) = dot(u, u, mat(tetrad))

istimelike(u::𝕍) = lorentznorm(u) > 0.0
isspacelike(u::𝕍) = lorentznorm(u) < 0.0
isnull(u::𝕍; atol::Float64 = TOLERANCE) = isapprox(lorentznorm(u), 0.0, atol = atol)
iscausal(u::𝕍) = istimelike(u) || isnull(u)