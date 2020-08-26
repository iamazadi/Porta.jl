import Base.:+
import Base.:-
import Base.:*


export ℝ³
export cross


"""
    Represents a point in ℝ³.

field: a.
"""
struct ℝ³ <: VectorSpace
    a::Array{Float64}
    ℝ³(x₁::Real, x₂::Real, x₃::Real) = new(float.([x₁; x₂; x₃]))
    ℝ³(a::Array) = begin
        @assert(length(a) == 3, "The input vector must contain exactly three elements.")
        ℝ³(a...)
    end
end



## Unary Operators ##


+(r::ℝ³) = r
-(r::ℝ³) = ℝ³(-vec(r))


## Binary Operators ##


+(r1::ℝ³, r2::ℝ³) = ℝ³(vec(r1) + vec(r2))
-(r1::ℝ³, r2::ℝ³) = ℝ³(vec(r1) - vec(r2))
*(r::ℝ³, λ::Real) = ℝ³(λ .* vec(r))
*(λ::Real, r::ℝ³) = r * λ


"""
    cross(r1, r2)

Perform a cross product with the given vectors `r1` and `r2`.
"""
cross(r1::ℝ³, r2::ℝ³) = begin
    M = transpose(reshape([vec(r1); vec(r1); vec(r2)], :, length(r1)))
    M = convert(Array{Float64}, M)
    ℝ³(map(x -> cofactor(M, 1, x), 1:length(r1)))
end


Base.isapprox(a::Array{ℝ³},
              b::Array{ℝ³};
              atol::Float64 = TOLERANCE) = begin
    for (elementa, elementb) in zip(a, b)
        if isapprox(elementa, elementb, atol = atol) == false
            return false
        end
    end
    return true
end
