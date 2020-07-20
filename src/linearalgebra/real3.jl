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
    a::Array{Float64} # basis [x; y; z]
    ℝ³(a::Array{Float64,1}) = begin
        @assert(length(a) == 3, "The input vector must contain exactly three elements.")
        new(Float64.(a))
    end
    ℝ³(a::Array{Int64,1}) = ℝ³(Float64.(a))
    ℝ³(a::Real, b::Real, c::Real) = ℝ³([a; b; c])
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
