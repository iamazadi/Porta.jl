import Base.:+
import Base.:-
import Base.:*
import GLMakie.Point3f
import GLMakie.Vec3f
import LinearAlgebra.cross


export ℝ³
export cross


"""
    Represents a point in ℝ³.

field: a.
"""
struct ℝ³ <: VectorSpace
    a::Vector{Float64}
    ℝ³(x₁::Float64, x₂::Float64, x₃::Float64) = new(float.([x₁; x₂; x₃]))
    ℝ³(a::Vector{Float64}) = begin
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


"""
    ℝ³(p)

Convert a point from type Point3f in Makie to ℝ³ for interoperability, with the given point `p`.
"""
ℝ³(p::Point3f) = ℝ³(Float64.(vec(p))...)


"""
    Point3f(v)

Convert a vector of type ℝ³ to a 3-dimansional point in Makie for interoperability.
"""
Point3f(v::ℝ³) = Point3f(vec(v)...)


"""
    ℝ³(v)

Convert a vector of type Vec3f in Makie to ℝ³ for interoperability.
"""
ℝ³(v::Vec3f) = ℝ³(Float64.(vec(v))...)


"""
    Vec3f(v)

Convert a vector of type ℝ³ to a floating point 3-vector in Makie for interoperability.
"""
Vec3f(v::ℝ³) = Vec3f(Float64.(vec(v))...)