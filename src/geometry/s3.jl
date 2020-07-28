import Base.*
import Base.vec
import Base.adjoint
import Base.isapprox


export S³
export ComplexPlane
export SU2
export Quaternion


"""
    Represents a point in a 3-sphere.
"""
abstract type S³ end


"""
    Represents a point in the complex plane.

fields: z₁ and z₂.
"""
struct ComplexPlane <: S³
    z₁::Complex
    z₂::Complex
end


"""
    Represents a Quaternion.

field: q.
"""
struct Quaternion <: S³
    r::ℝ⁴
    Quaternion(r4::ℝ⁴) = new(r4)
    Quaternion(a::Real, b::Real, c::Real, d::Real) = new(ℝ⁴(a, b, c, d))
    Quaternion(a::Array) = begin
        @assert(length(a) == 4, "The input vector must contain exactly four elements.")
        Quaternion(a...)
    end
    Quaternion(θ::Real, u::ℝ³) = Quaternion([cos(θ); vec(sin(θ) * u)])
end


"""
    Represents a point in SU(2)

field: a.
"""
struct SU2 <: S³
    a::Array{Complex,2}
end


vec(q::Quaternion) = vec(q.r)
vec(cp::ComplexPlane) = [cp.z₁; cp.z₂]

adjoint(s::SU2) = SU2(convert(Array{Complex,2}, Base.adjoint(s.a)))

Base.conj(q::Quaternion) = Quaternion(vec(q)[1], -vec(q)[2], -vec(q)[3], -vec(q)[4])

ComplexPlane(s::SU2) = ComplexPlane(s.a[1,1], -s.a[2,1])
ComplexPlane(q::Quaternion) = ComplexPlane(vec(q)[1] + im * vec(q)[2],
                                           vec(q)[3] + im * vec(q)[4])
SU2(cp::ComplexPlane) = SU2([cp.z₁ Base.conj(cp.z₂); -cp.z₂ Base.conj(cp.z₁)])
SU2(q::Quaternion) = SU2(ComplexPlane(q))
Quaternion(cp::ComplexPlane) = Quaternion(real(cp.z₁),
                                          imag(cp.z₁),
                                          real(cp.z₂),
                                          imag(cp.z₂))
Quaternion(s::SU2) = Quaternion(ComplexPlane(s))

(*)(s1::SU2, s2::SU2) = SU2(s1.a * s2.a)
(*)(cp1::S³, cp2::S³) = ComplexPlane(SU2(cp1) * SU2(cp2))
(*)(q1::Quaternion, q2::Quaternion) = Quaternion(SU2(q1) * SU2(q2))

isapprox(q1::Quaternion, q2::Quaternion) = Base.isapprox(vec(q1), vec(q2))
isapprox(q::Quaternion, s::S³) = isapprox(q, Quaternion(s))
isapprox(s::S³, q::Quaternion) = isapprox(Quaternion(s), q)
isapprox(s1::S³, s2::S³) = isapprox(Quaternion(s1), Quaternion(s2))
