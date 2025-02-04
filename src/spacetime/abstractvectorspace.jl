import Base.vec
import Base.show
import Base.isapprox
import Base.length
import Base.transpose
import LinearAlgebra.normalize


export VectorSpace
export Identity
export dot
export norm
export outer
export normalize


"""
    Represents an abstract vector space.
"""
abstract type VectorSpace end


## Generic Functions ##


vec(vs::VectorSpace) = Base.vec(vs.a)
show(io::IO, vs::VectorSpace) = Base.show(io, "$(round.(vec(vs), digits = 4)) ∈ $(typeof(vs))")
length(vs::VectorSpace) = Base.length(vec(vs))
transpose(vs::VectorSpace) = Base.transpose(vec(vs))
Identity(vs::VectorSpace) = reshape([Float64(i == j) for i in 1:length(vs) for j in 1:length(vs)], length(vs), length(vs))
# dot product with a given metric
dot(vs1::VectorSpace, vs2::VectorSpace, M::Array{Float64}) = transpose(vs1) * M * vec(vs2)
dot(vs1::VectorSpace, vs2::VectorSpace) = dot(vs1, vs2, Identity(vs1))
norm(vs::VectorSpace) = sqrt(dot(vs, vs))
outer(vs1::VectorSpace, vs2::VectorSpace) = vec(vs1) * transpose(vs2)
normalize(vs::VectorSpace) = vs * (1.0 / norm(vs))

Base.isapprox(vs1::VectorSpace, vs2::VectorSpace; atol::Float64 = TOLERANCE) = isapprox(vec(vs1), vec(vs2), atol = atol)
isapprox(a₁::Array{<:VectorSpace}, a₂::Array{<:VectorSpace}; atol::Real = TOLERANCE) = all(map((i, j) -> isapprox(i, j, atol = atol), zip(a₁, a₂)))