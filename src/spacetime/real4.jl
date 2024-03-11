import Base.+
import Base.-
import Base.*


export ℝ⁴


"""
    Represents a point in ℝ⁴.

field: a.
"""
struct ℝ⁴ <: VectorSpace
    a::Vector{Float64}
    ℝ⁴(x₁::Float64, x₂::Float64, x₃::Float64, x₄::Float64) = new(float.([x₁; x₂; x₃; x₄]))
    ℝ⁴(a::Vector{Float64}) = begin
        @assert(length(a) == 4, "The input vector must contain exactly four elements.")
        ℝ⁴(a...)
    end
end


## Unary Operators ##


+(r::ℝ⁴) = r
-(r::ℝ⁴) = ℝ⁴(-vec(r))


## Binary Operators ##


+(r1::ℝ⁴, r2::ℝ⁴) = ℝ⁴(vec(r1) + vec(r2))
-(r1::ℝ⁴, r2::ℝ⁴) = ℝ⁴(vec(r1) - vec(r2))
*(r::ℝ⁴, λ::Real) = ℝ⁴(λ .* vec(r))
*(λ::Real, r::ℝ⁴) = r * λ