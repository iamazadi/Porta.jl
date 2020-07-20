import Base.vec
import Base.show
import Base.isapprox
import Base.length
import Base.transpose


export VectorSpace
export I
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
show(io::IO, vs::VectorSpace) = Base.show(io, vec(vs))
isapprox(vs1::VectorSpace, vs2::VectorSpace) = Base.isapprox(vec(vs1), vec(vs2))
length(vs::VectorSpace) = Base.length(vec(vs))
transpose(vs::VectorSpace) = Base.transpose(vec(vs))
I(vs::VectorSpace) = reshape([Float64(i == j) for i in 1:length(vs) for j in 1:length(vs)],
                             length(vs),
                             length(vs))
# dot product with a given metric
dot(vs1::VectorSpace, vs2::VectorSpace, M::Array{Float64}) = transpose(vs1) * M * vec(vs2)
dot(vs1::VectorSpace, vs2::VectorSpace) = dot(vs1, vs2, I(vs1))
norm(vs::VectorSpace) = sqrt(dot(vs, vs))
outer(vs1::VectorSpace, vs2::VectorSpace) = vec(vs1) * transpose(vs2)
normalize(vs::VectorSpace) = vs * (1 / norm(vs))
