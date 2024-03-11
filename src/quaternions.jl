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
export mat
export K
export J
export R


"""
    Represents a quaternion number.

field: a.
"""
struct Quaternion
    a::ℝ⁴
    Quaternion(a::ℝ⁴) = new(a)
    Quaternion(a::Float64, b::Float64, c::Float64, d::Float64) = new(ℝ⁴(a, b, c, d))
    Quaternion(v::Vector{Float64}) = new(ℝ⁴(v))
    Quaternion(z::Vector{<:Complex}) = new(ℝ⁴(real(z[1]), real(z[2]), imag(z[1]), imag(z[2])))
    Quaternion(m::Matrix{Float64}) = Quaternion(ℝ⁴(m[1,1], m[1,2], m[1,3], m[1,4]))
    Quaternion(θ::Float64, u::ℝ³) = Quaternion(ℝ⁴(cos(θ), vec(sin(θ) * u)...))
end


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


"""
    vec(q)
 
 Reshape the number `q` as a one-dimensional column vector in ℝ⁴. The resulting vector shares the same underlying data as `q`, so it will only be mutable if
 `q` is mutable, in which case modifying one will also modify the other.
 """
 Base.vec(q::Quaternion) = vec(q.a)


"""
    show(q)

Print a string representation of the given quaternion `q`.
"""
Base.show(io::IO, q::Quaternion) = print(io, "($(vec(q)[1]) + $(vec(q)[2]) i + $(vec(q)[3]) j + $(vec(q)[4]) k) ∈ ℍ")


"""
    mat(q)

Represent the number `q` by a quaternionic 4x4 matrix in terms a basis for so(4), the Lie algebra of the Lie group of rotations about a fixed point in ℝ⁴.
"""
mat(q::Quaternion) = vec(q)[1] .* I(4) + vec(q)[2] .* K(2) + vec(q)[3] .* K(3) + vec(q)[4] .* K(1)


"""
    real(q)

Return the real part of the quaternion number `q`.
"""
Base.real(q::Quaternion) = vec(q)[1]


"""
    imag(q)

Return the imaginary part of the quaternion number `q`.
"""
Base.imag(q::Quaternion) = ℝ³(vec(q)[2:4])


"""
    conj(q)

Compute the conjugate of a quaternion number `q`.
"""
Base.conj(q::Quaternion) = Quaternion(transpose(R) * mat(q) * R)


"""
    isapprox(g, q)

Inexact equality comparison.
"""
Base.isapprox(g::Quaternion, q::Quaternion; atol::Float64 = TOLERANCE) = isapprox(g.a, q.a, atol = atol)


"""
    norm(q)

Compute the 2-norm as if `q` were a vector of the corresponding length.
"""
norm(q::Quaternion) = norm(q.a)


"""
    normalize(q)

Normalize the number `q` so that its 2-norm equals unity, i.e. norm(a) == 1.
"""
normalize(q::Quaternion) = Quaternion(normalize(q.a))


"""
    dot(g, q)

Compute the dot product between two vector representations of `g` and `q`.
"""
dot(g::Quaternion, q::Quaternion) = dot(g.a, q.a)
dot(g::ℝ⁴, q::Quaternion) = dot(g, q.a)
dot(g::Quaternion, q::ℝ⁴) = dot(g.a, q)


+(q::Quaternion) = q
-(q::Quaternion) = Quaternion(-q.a)
(+)(g::Quaternion, q::Quaternion) = Quaternion(mat(g) + mat(q))
(-)(g::Quaternion, q::Quaternion) = Quaternion(mat(g) - mat(q))
(*)(q::Quaternion, λ::Real) = Quaternion(mat(q) .* λ)
(*)(λ::Real, q::Quaternion) = q * λ
(*)(g::Quaternion, q::Quaternion) = Quaternion(mat(g) * mat(q))
(*)(m::Matrix{<:Real}, q::Quaternion) = Quaternion(m * vec(q))
