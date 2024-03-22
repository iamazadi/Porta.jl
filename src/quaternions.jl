import Base.show
import Base.vec
import Base.real
import Base.imag
import Base.conj
import Base.isapprox
import Base.:+
import Base.:-
import Base.:*

export Quaternion
export elI
export eli
export elj
export elk
export mat
export det
export K
export J
export R


# The global constants defining elementary Quaternions
const elI = Complex.([1 0; 0 1])
const eli = Complex.([0 im; im 0])
const elj = Complex.([0 -1; 1 0])
const elk = Complex.([im 0; 0 -im])


"""
    Represents a quaternion number.

fields: a, b, c and d.
"""
struct Quaternion
    a::Float64
    b::Float64
    c::Float64
    d::Float64
    Quaternion(a::Float64, b::Float64, c::Float64, d::Float64) = new(a, b, c, d)
    Quaternion(a::ℝ⁴) = Quaternion(vec(a)...)
    Quaternion(v::Vector{Float64}) = Quaternion(v...)
    Quaternion(z::Vector{<:Complex}) = Quaternion(real(z[1]), real(z[2]), imag(z[1]), imag(z[2]))
    Quaternion(m::Matrix{Float64}) = Quaternion(m[1,1], m[1,2], m[1,3], m[1,4])
    Quaternion(M::Matrix{<:Complex}) = begin
        if isapprox(M, elI)
            return Quaternion(1.0, 0.0, 0.0, 0.0)
        elseif isapprox(M, eli)
            return Quaternion(0.0, 1.0, 0.0, 0.0)
        elseif isapprox(M, elj)
            return Quaternion(0.0, 0.0, 1.0, 0.0)
        elseif isapprox(M, elk)
            return Quaternion(0.0, 0.0, 0.0, 1.0)
        else
            @assert(false, "The direct construction for the given matrix has not been implemented, try other constructors instead.")
        end
    end
    Quaternion(ψ::Float64, u::ℝ³) = begin
        @assert(isapprox(norm(u), 1.0), "The input vector must have unit norm, but the norm is $(norm(u)).")
        Quaternion(ℝ⁴(cos(ψ / 2), vec(sin(ψ / 2) * u)...))
    end
end


"""
    vec(q)
 
 Reshape the number `q` as a column 4-vector.
 """
Base.vec(q::Quaternion) = [q.a; q.b; q.c; q.d]


"""
    show(q)

Print a string representation of the given quaternion `q`.
"""
Base.show(io::IO, q::Quaternion) = print(io, "($(q.a) + $(q.b) i + $(q.c) j + $(q.d) k) ∈ ℍ")


"""
    mat(q)

Represent the number `q` by a complex 2x2 matrix in terms a basis of elementary Quaternions: I, i, j and k.
"""
mat(q::Quaternion) = [q.a + im * q.d -q.c + im * q.b; q.c + im * q.b q.a - im * q.d]


"""
    mat4(q)

Represent the number `q` by a quaternionic 4x4 matrix in terms a basis for so(4), the Lie algebra of the Lie group of rotations about a fixed point in ℝ⁴.
"""
mat4(q::Quaternion) = q.a .* I(4) + q.b .* K(2) + q.c .* K(3) + q.d .* K(1)


"""
    real(q)

Return the real part of the quaternion number `q`.
"""
Base.real(q::Quaternion) = q.a


"""
    imag(q)

Return the imaginary (vectorial) part of the quaternion number `q`.
"""
Base.imag(q::Quaternion) = ℝ³(q.b, q.c, q.d)


"""
    conj(q)

Compute the conjugate of a quaternion number `q`.
"""
Base.conj(q::Quaternion) = Quaternion(real(q), vec(-imag(q))...)


"""
    det(q)

Compute the determinant of a quaternion number `q`.
"""
det(q::Quaternion) = det(mat(q))
det(M::Matrix{<:Complex}) = begin
    @assert(size(M) == (2, 2), "The size of the matrix must be a square 2 by 2, but was given the size: $(size(M)).")
    real(M[1, 1] * M[2, 2] - M[1, 2] * M[2, 1])
end


"""
    isapprox(g, q)

Inexact equality comparison.
"""
Base.isapprox(g::Quaternion, q::Quaternion; atol::Float64 = TOLERANCE) = isapprox(g.a, q.a, atol = atol) &&
                                                                         isapprox(g.b, q.b, atol = atol) &&
                                                                         isapprox(g.c, q.c, atol = atol) &&
                                                                         isapprox(g.d, q.d, atol = atol)


"""
    norm(q)

Compute the 2-norm as if `q` were a vector of the corresponding length.
"""
norm(q::Quaternion) = norm(ℝ⁴(vec(q)))


"""
    normalize(q)

Normalize the number `q` so that its 2-norm equals unity, i.e. norm(a) == 1.
"""
normalize(q::Quaternion) = Quaternion(normalize(ℝ⁴(vec(q))))


"""
    dot(g, q)

Compute the dot product between two vector representations of `g` and `q`.
"""
dot(g::Quaternion, q::Quaternion) = dot(ℝ⁴(vec(g)), ℝ⁴(vec(q)))
dot(g::ℝ⁴, q::Quaternion) = dot(g, ℝ⁴(vec(q)))
dot(g::Quaternion, q::ℝ⁴) = dot(ℝ⁴(vec(g)), q)


+(q::Quaternion) = q
-(q::Quaternion) = Quaternion(-vec(q))
(+)(g::Quaternion, q::Quaternion) = Quaternion(mat4(g) + mat4(q))
(-)(g::Quaternion, q::Quaternion) = Quaternion(mat4(g) - mat4(q))
(*)(q::Quaternion, λ::Real) = Quaternion(mat4(q) .* λ)
(*)(λ::Real, q::Quaternion) = q * λ
(*)(g::Quaternion, q::Quaternion) = Quaternion(mat4(g) * mat4(q))
(*)(m::Matrix{<:Real}, q::Quaternion) = Quaternion(m * vec(q))
(*)(m::Matrix{<:Complex}, q::Quaternion) = m * mat(q)


"""
    I(n)

Construct a 4x4 identity matrix with Real elements as a basis for so(4), with the given identifier `n`.
"""
I(n::Integer) = begin
    if n == 2
        return [1.0 0.0;
                0.0 1.0]
    end
    if n == 4
        return [1.0 0.0 0.0 0.0;
                0.0 1.0 0.0 0.0;
                0.0 0.0 1.0 0.0;
                0.0 0.0 0.0 1.0]
    end
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
