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
        @assert(length(a) == 4, "The input must be a 4-vector.")
        Quaternion(a...)
    end
    Quaternion(θ::Real, u::ℝ³) = Quaternion([cos(θ); vec(sin(θ) * normalize(u))])
end


"""
    Represents a point in SU(2)

field: a.
"""
struct SU2 <: S³
    a::Array{<:Complex,2}
end


"""
    show(b)

Print a string representation of the given SU2 `b`.
"""
Base.show(io::IO, q::SU2) = print(io, "$(round.(q.a, digits = 2)) ∈ SU(2)")
Base.show(io::IO, q::ComplexPlane) = print(io, "($(round(q.z₁, digits = 2)),$(round(q.z₂, digits = 2))) ∈ ℂ²")
Base.show(io::IO, q::Quaternion) = print(io, "$(round.(vec(q.r), digits = 2)) ∈ ℝ⁴")

Base.vec(q::Quaternion) = vec(q.r)
Base.vec(cp::ComplexPlane) = [cp.z₁; cp.z₂]

Base.adjoint(s::SU2) = SU2(adjoint(s.a))
Base.conj(q::Quaternion) = Quaternion(vec(q)[1], -vec(q)[2], -vec(q)[3], -vec(q)[4])

ComplexPlane(z::Array{<:Complex,1}) = ComplexPlane(z...)
ComplexPlane(z::ComplexPlane) = z
ComplexPlane(s::SU2) = ComplexPlane(s.a[1,1], s.a[2,1])
ComplexPlane(q::Quaternion) = ComplexPlane(vec(q)[1] + im * vec(q)[2],
                                           vec(q)[3] + im * vec(q)[4])

SU2(cp::ComplexPlane) = SU2([cp.z₁ -conj(cp.z₂); cp.z₂ conj(cp.z₁)])
SU2(q::Quaternion) = SU2(ComplexPlane(q))
Quaternion(cp::ComplexPlane) = Quaternion(real(cp.z₁),
                                          imag(cp.z₁),
                                          real(cp.z₂),
                                          imag(cp.z₂))
Quaternion(s::SU2) = Quaternion(ComplexPlane(s))
Quaternion(r::ℝ³) = Quaternion([0; vec(r)])
normalize(q::Quaternion) = Quaternion(normalize(q.r))
norm(q::Quaternion) = norm(q.r)
dot(q1::Quaternion, q2::Quaternion) = dot(q1.r, q2.r)

(*)(s1::SU2, s2::SU2) = SU2(s1.a * s2.a)
(*)(s::SU2, λ::Real) = SU2(λ .* s.a)
(*)(λ::Real, s::SU2) = SU2(s.a .* λ)
(+)(a::SU2, b::SU2) = SU2(a.a + b.a)
(*)(cp1::S³, cp2::S³) = ComplexPlane(SU2(cp1) * SU2(cp2))
(*)(q1::Quaternion, q2::Quaternion) = Quaternion(SU2(q1) * SU2(q2))
(*)(q::Quaternion, λ::Real) = Quaternion(λ * q.r)
(*)(λ::Real, q::Quaternion) = q * λ
(+)(q1::Quaternion, q2::Quaternion) = Quaternion(vec(q1) + vec(q2))
(-)(q1::Quaternion, q2::Quaternion) = Quaternion(vec(q1) - vec(q2))
+(q::Quaternion) = q
-(q::Quaternion) = Quaternion(-vec(q))

Base.isapprox(q1::Quaternion, q2::Quaternion) = isapprox(vec(q1), vec(q2))
Base.isapprox(q::Quaternion, s::S³) = isapprox(q, Quaternion(s))
Base.isapprox(s::S³, q::Quaternion) = isapprox(Quaternion(s), q)
Base.isapprox(s1::S³, s2::S³) = isapprox(Quaternion(s1), Quaternion(s2))
