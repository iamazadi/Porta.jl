import Base.show
import Base.vec
import Base.real
import Base.imag
import Base.conj
import Base.isapprox
import Base.:+
import Base.:-
import Base.:*
import GLMakie.Quaternion

export ℍ
export elI
export eli
export elj
export elk
export mat
export mat3
export mat4
export det
export K
export J
export R


# The global constants defining elementary ℍs
const elI = Complex.([1 0; 0 1])
const eli = Complex.([0 im; im 0])
const elj = Complex.([0 -1; 1 0])
const elk = Complex.([im 0; 0 -im])


"""
    Represents a quaternion number.

fields: a, b, c and d.
"""
struct ℍ
    a::Float64
    b::Float64
    c::Float64
    d::Float64
    ℍ(a::Float64, b::Float64, c::Float64, d::Float64) = new(a, b, c, d)
    ℍ(a::ℝ⁴) = ℍ(vec(a)...)
    ℍ(v::Vector{Float64}) = ℍ(v...)
    ℍ(z::Vector{<:Complex}) = ℍ(real(z[1]), imag(z[1]), real(z[2]), imag(z[2]))
    ℍ(m::Matrix{Float64}) = ℍ(m[1,1], m[1,2], m[1,3], m[1,4])
    ℍ(M::Matrix{<:Complex}) = begin
        if isapprox(M, elI)
            return ℍ(1.0, 0.0, 0.0, 0.0)
        elseif isapprox(M, eli)
            return ℍ(0.0, 1.0, 0.0, 0.0)
        elseif isapprox(M, elj)
            return ℍ(0.0, 0.0, 1.0, 0.0)
        elseif isapprox(M, elk)
            return ℍ(0.0, 0.0, 0.0, 1.0)
        else
            @assert(false, "The direct construction for the given matrix has not been implemented, try other constructors instead.")
        end
    end
    ℍ(ψ::Float64, u::ℝ³) = begin
        @assert(isapprox(norm(u), 1.0), "The input vector must have unit norm, but the norm is $(norm(u)).")
        ℍ(ℝ⁴(cos(ψ / 2), vec(sin(ψ / 2) * u)...))
    end
    ℍ(ψ::Int64, u::ℝ³) = begin
        @assert(isapprox(norm(u), 1.0), "The input vector must have unit norm, but the norm is $(norm(u)).")
        ℍ(ℝ⁴(cos(float(ψ) / 2), vec(sin(float(ψ) / 2) * u)...))
    end
end


"""
    vec(q)
 
 Reshape the number `q` as a column 4-vector.
 """
Base.vec(q::ℍ) = [q.a; q.b; q.c; q.d]


"""
    show(q)

Print a string representation of the given quaternion `q`.
"""
Base.show(io::IO, q::ℍ) = print(io, "($(round(q.a, digits = 4)) + $(round(q.b, digits = 4)) i + $(round(q.c, digits = 4)) j + $(round(q.d, digits = 4)) k) ∈ ℍ")


"""
    mat(q)

Represent the number `q` by a complex 2x2 matrix in terms a basis of elementary ℍs: I, i, j and k.
"""
mat(q::ℍ) = [q.a + im * q.d -q.c + im * q.b; q.c + im * q.b q.a - im * q.d]


"""
    mat4(q)

Represent the number `q` by a quaternionic 4x4 matrix in terms a basis for so(4), the Lie algebra of the Lie group of rotations about a fixed point in ℝ⁴.
"""
mat4(q::ℍ) = q.a .* Identity(4) + q.b .* K(2) + q.c .* K(3) + q.d .* K(1)


"""
    mat3(q)

Convert the given quaternion number `q` to a 3 by 3 square matrix of real numbers.
"""
mat3(q::ℍ) = begin
    qw, qx, qy, qz = vec(q)
    [1.0 - 2(qy^2) - 2(qz^2) 	2qx * qy - 2qz * qw 	2qx * qz + 2qy * qw;
     2qx * qy + 2qz * qw 	1.0 - 2(qx^2) - 2(qz^2) 	2qy * qz - 2qx * qw;
     2qx * qz - 2qy * qw 	2qy * qz + 2qx * qw 	1.0 - 2(qx^2) - 2(qy^2)]
end


"""
    real(q)

Return the real part of the quaternion number `q`.
"""
Base.real(q::ℍ) = q.a


"""
    imag(q)

Return the imaginary (vectorial) part of the quaternion number `q`.
"""
Base.imag(q::ℍ) = ℝ³(q.b, q.c, q.d)


"""
    conj(q)

Compute the conjugate of a quaternion number `q`.
"""
Base.conj(q::ℍ) = ℍ(real(q), vec(-imag(q))...)


"""
    det(q)

Compute the determinant of a quaternion number `q`.
"""
det(q::ℍ) = det(mat(q))
det(M::Matrix{<:Complex}) = begin
    @assert(size(M) == (2, 2), "The size of the matrix must be a square 2 by 2, but was given the size: $(size(M)).")
    real(M[1, 1] * M[2, 2] - M[1, 2] * M[2, 1])
end


"""
    isapprox(g, q)

Inexact equality comparison.
"""
Base.isapprox(g::ℍ, q::ℍ; atol::Float64 = TOLERANCE) = isapprox(g.a, q.a, atol = atol) &&
                                                                         isapprox(g.b, q.b, atol = atol) &&
                                                                         isapprox(g.c, q.c, atol = atol) &&
                                                                         isapprox(g.d, q.d, atol = atol)


"""
    norm(q)

Compute the 2-norm as if `q` were a vector of the corresponding length.
"""
norm(q::ℍ) = norm(ℝ⁴(vec(q)))


"""
    normalize(q)

Normalize the number `q` so that its 2-norm equals unity, i.e. norm(a) == 1.
"""
normalize(q::ℍ) = ℍ(normalize(ℝ⁴(vec(q))))


"""
    dot(g, q)

Compute the dot product between two vector representations of `g` and `q`.
"""
dot(g::ℍ, q::ℍ) = dot(ℝ⁴(vec(g)), ℝ⁴(vec(q)))
dot(g::ℝ⁴, q::ℍ) = dot(g, ℝ⁴(vec(q)))
dot(g::ℍ, q::ℝ⁴) = dot(ℝ⁴(vec(g)), q)


+(q::ℍ) = q
-(q::ℍ) = ℍ(-vec(q))
(+)(g::ℍ, q::ℍ) = ℍ(mat4(g) + mat4(q))
(-)(g::ℍ, q::ℍ) = ℍ(mat4(g) - mat4(q))
(*)(q::ℍ, λ::Real) = ℍ(mat4(q) .* λ)
(*)(λ::Real, q::ℍ) = q * λ
(*)(g::ℍ, q::ℍ) = ℍ(mat4(g) * mat4(q))
(*)(m::Matrix{<:Real}, q::ℍ) = ℍ(m * vec(q))
(*)(m::Matrix{<:Complex}, q::ℍ) = m * mat(q)


"""
    I(n)

Construct a 4x4 identity matrix with Real elements as a basis for so(4), with the given identifier `n`.
"""
Identity(n::Integer) = begin
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
    ℍ(v)

Transform a four-vector into a 'vectorial' quaternion.
"""
function ℍ(v::𝕍)
    T, X, Y, Z = vec(v)
    @assert(isapprox(T, 0), "The coordinate of the given four-vector must have the first element equal to zero, but was given T = $T.")
    ℍ(0.0, X, Y, Z)
end


"""
    ℍ(s)

Transform a spin-vector into a 'vectorial' quaternion.
"""
ℍ(v::SpinVector) = ℍ(0.0, vec(ℝ³(v))...)


"""
    Quaternion(q)

Converts the quaternion number `q` to a Quaternion type in Makie for interoperability.
"""
Quaternion(q::ℍ) = Quaternion(vec(q)[2:4]..., vec(q)[1])