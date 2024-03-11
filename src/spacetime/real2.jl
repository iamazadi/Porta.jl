import Base.:+
import Base.:-
import Base.:*


export ℝ²


"""
    Represents a point in ℝ².

field: a.
"""
struct ℝ² <: VectorSpace
    a::Vector{Float64}
    ℝ²(x₁::Float64, x₂::Float64) = new(float.([x₁; x₂]))
    ℝ²(a::Vector{Float64}) = begin
        @assert(length(a) == 2, "The input vector must contain exactly three elements.")
        ℝ²(a...)
    end
end



## Unary Operators ##


+(r::ℝ²) = r
-(r::ℝ²) = ℝ²(-vec(r))


## Binary Operators ##


+(r1::ℝ², r2::ℝ²) = ℝ²(vec(r1) + vec(r2))
-(r1::ℝ², r2::ℝ²) = ℝ²(vec(r1) - vec(r2))
*(r::ℝ², λ::Real) = ℝ²(λ .* vec(r))
*(λ::Real, r::ℝ²) = r * λ


Base.isapprox(a::Array{ℝ²},
              b::Array{ℝ²};
              atol::Float64 = TOLERANCE) = begin
    for (elementa, elementb) in zip(a, b)
        if isapprox(elementa, elementb, atol = atol) == false
            return false
        end
    end
    return true
end