import Base.show
import Base.vec
import Base.real
import Base.imag
import Base.conj
import Base.isapprox
import Base.:+
import Base.:-
import Base.:*
import LinearAlgebra
import LinearAlgebra.norm
import LinearAlgebra.normalize
import LinearAlgebra.dot

export Quaternion
export mat
export K
export J
export R


"""
    Represents a quaternion number.

field: a, b, c and d.
"""
struct Quaternion
    a::Real
    b::Real
    c::Real
    d::Real
    Quaternion(a::Real, b::Real, c::Real, d::Real) = new(a, b, c, d)
    Quaternion(v::Vector{<:Real}) = new(v...)
    Quaternion(z::Vector{<:Complex}) = new(real(z[1]), real(z[2]), imag(z[1]), imag(z[2]))
    Quaternion(m::Matrix{<:Real}) = Quaternion(m[1,1], m[1,2], m[1,3], m[1,4])
    Quaternion(θ::Real, u::Vector{<:Real}) = Quaternion(cos(θ), (sin(θ) .* u)...)
end


"""
    J(n)

Construct a 4x4 matrix with Real elements as a basis for so(4), with the given identifier `n`.
"""
J(n::Integer) = begin
    if n == 1
        J₁ = [0 -1 0 0;
              1 0 0 0;
              0 0 0 -1;
              0 0 1 0]
        return J₁
    end
    if n == 2
        J₂ = [0 0 -1 0;
              0 0 0 1;
              1 0 0 0;
              0 -1 0 0]
        return J₂
    end
    if n == 3
        J₃ = [0 0 0 -1;
              0 0 -1 0;
              0 1 0 0;
              1 0 0 0]
        return J₃
    end
end


"""
    K(n)

Construct a 4x4 matrix with Real elements as a basis for so(4), with the given identifier `n`.
"""
K(n::Integer) = begin
    if n == 1
        K₁ = [0 0 0 1;
              0 0 -1 0;
              0 1 0 0;
              -1 0 0 0]
        return K₁
    end
    if n == 2
        K₂ = [0 1 0 0;
              -1 0 0 0;
              0 0 0 -1;
              0 0 1 0]
        return K₂
    end
    if n == 3
        K₃ = [0 0 1 0;
              0 0 0 1;
              -1 0 0 0;
              0 -1 0 0]
        return K₃
    end
end


# The quaternionic matrix conjugate operator
R = [1 0 0 0;
     0 -1 0 0;
     0 0 -1 0;
     0 0 0 -1]


"""
    show(q)

Print a string representation of the given quaternion `q`.
"""
Base.show(io::IO, q::Quaternion) = print(io, "($(q.a) + $(q.b) i + $(q.c) j + $(q.d) k) ∈ ℍ")


"""
    vec(q)

Reshape the number `q` as a one-dimensional column vector in ℝ⁴. The resulting vector shares the same underlying data as `q`, so it will only be mutable if
`q` is mutable, in which case modifying one will also modify the other.
"""
Base.vec(q::Quaternion) = [q.a; q.b; q.c; q.d]


"""
    mat(q)

Represent the number `q` by a quaternionic 4x4 matrix in terms a basis for so(4), the Lie algebra of the Lie group of rotations about a fixed point in ℝ⁴.
"""
mat(q::Quaternion) = q.a .* LinearAlgebra.I(4) + q.b .* K(2) + q.c .* K(3) + q.d .* K(1)


"""
    real(q)

Return the real part of the quaternion number `q`.
"""
Base.real(q::Quaternion) = q.a


"""
    imag(q)

Return the imaginary part of the quaternion number `q`.
"""
Base.imag(q::Quaternion) = [q.b; q.c; q.d]


"""
    conj(q)

Compute the conjugate of a quaternion number `q`.
"""
Base.conj(q::Quaternion) = Quaternion(LinearAlgebra.transpose(R) * mat(q) * R)


"""
    isapprox(g, q)

Inexact equality comparison.
"""
Base.isapprox(g::Quaternion, q::Quaternion; atol::Float64 = 1e-8) = isapprox(g.a, q.a, atol = atol) &&
                                                                    isapprox(g.b, q.b, atol = atol) &&
                                                                    isapprox(g.c, q.c, atol = atol) &&
                                                                    isapprox(g.d, q.d, atol = atol)


"""
    norm(q)

Compute the 2-norm as if `q` were a vector of the corresponding length.
"""
LinearAlgebra.norm(q::Quaternion) = LinearAlgebra.norm(vec(q))


"""
    normalize(q)

Normalize the number `q` so that its 2-norm equals unity, i.e. norm(a) == 1.
"""
LinearAlgebra.normalize(q::Quaternion) = Quaternion(LinearAlgebra.normalize(vec(q))...)


"""
    dot(g, q)

Compute the dot product between two vector representations of `g` and `q`.
"""
LinearAlgebra.dot(g::Quaternion, q::Quaternion) = LinearAlgebra.dot(vec(g), vec(q))
LinearAlgebra.dot(g::Vector{<:Real}, q::Quaternion) = LinearAlgebra.dot(g, vec(q))
LinearAlgebra.dot(g::Quaternion, q::Vector{<:Real}) = LinearAlgebra.dot(vec(g), q)


+(q::Quaternion) = q
-(q::Quaternion) = Quaternion(-vec(q)...)
(+)(g::Quaternion, q::Quaternion) = Quaternion(mat(g) + mat(q))
(-)(g::Quaternion, q::Quaternion) = Quaternion(mat(g) - mat(q))
(*)(q::Quaternion, λ::Real) = Quaternion(mat(q) .* λ)
(*)(λ::Real, q::Quaternion) = q * λ
(*)(g::Quaternion, q::Quaternion) = Quaternion(mat(g) * mat(q))
(*)(m::Matrix{<:Real}, q::Quaternion) = Quaternion(m * vec(q))
