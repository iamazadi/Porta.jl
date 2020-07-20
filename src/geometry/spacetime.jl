import Base.:+
import Base.:-
import Base.:*
import Base.vec
import Base.show
import Base.isapprox
import Base.length


export Spacetime


"""
    Represents Spacetime.

field: a.
"""
struct Spacetime
    a::Array{Float64} # Basis [t; x; y; z]
    Spacetime(a::Array{Float64,1}) = begin
        @assert(length(a) == 4, "The input vector must contain exactly four elements.")
        new(Float64.(a))
    end
    Spacetime(a::Array{Int64,1}) = Spacetime(Float64.(a))
end


## Generic Functions ##


vec(st::Spacetime) = Base.vec(st.a)
show(io::IO, p::Spacetime) = Base.show(io, vec(p))
isapprox(st1::Spacetime, st2::Spacetime) = Base.isapprox(vec(st1), vec(st2))
length(st::Spacetime) = Base.length(vec(st))


## Unary Operators ##


+(st::Spacetime) = st
-(st::Spacetime) = Spacetime(-vec(st))


## Binary Operators ##


+(st1::Spacetime, st2::Spacetime) = Spacetime(vec(st1) + vec(st2))
-(st1::Spacetime, st2::Spacetime) = Spacetime(vec(st1) - vec(st2))
*(st::Spacetime, λ::Real) = Spacetime(λ .* vec(st))
*(λ::Real, st::Spacetime) = st * λ


## Product Space ##


dot(st1::Spacetime, st2::Spacetime) = dot(vec(st1), vec(st2))
norm(st::Spacetime) = norm(vec(st))
outer(st1::Spacetime, st2::Spacetime) = outer(vec(st1), vec(st2))
