import Base.+
import Base.-
import Base.*


export Spacetime


"""
    Represents Spacetime.

field: a.
"""
struct Spacetime <: VectorSpace
    a::Array{Float64} # Basis [t; x; y; z]
    Spacetime(a::Array{Float64,1}) = begin
        @assert(length(a) == 4, "The input vector must contain exactly four elements.")
        new(Float64.(a))
    end
    Spacetime(a::Array{Int64,1}) = Spacetime(Float64.(a))
    Spacetime(t::Real, x::Real, y::Real, z::Real) = Spacetime([t; x; y; z])
end



## Unary Operators ##


+(st::Spacetime) = st
-(st::Spacetime) = Spacetime(-vec(st))


## Binary Operators ##


+(st1::Spacetime, st2::Spacetime) = Spacetime(vec(st1) + vec(st2))
-(st1::Spacetime, st2::Spacetime) = Spacetime(vec(st1) - vec(st2))
*(st::Spacetime, λ::Real) = Spacetime(λ .* vec(st))
*(λ::Real, st::Spacetime) = st * λ
