import Base.show
import Base.vec
import Base.real
import Base.imag
import Base.conj
import Base.isapprox
import Base.:+
import Base.:-
import Base.:*
import LinearAlgebra.norm
import LinearAlgebra.normalize


export Dualquaternion
export getrotation
export gettranslation


"""
    Represents a Dual-Quaternion number.

fields: real and imag.
"""
struct Dualquaternion
    real::Quaternion
    imag::Quaternion
    Dualquaternion(g::Quaternion, q::Quaternion) = new(g, q)
    Dualquaternion(q::Quaternion, t::Vector{<:Real}) = new(normalize(q), 0.5 * (Quaternion(0, t...) * normalize(q)))
    Dualquaternion(q::Dualquaternion) = Dualquaternion(normalize(q.real), normalize(q.imag))
    Dualquaternion(q::Quaternion) = Dualquaternion(normalize(q), [0; 0; 0])
    Dualquaternion(t::Vector{<:Real}) = Dualquaternion(Quaternion(1, 0, 0, 0), t)
end


"""
    show(q)

Print a string representation of the given Dualquaternion `q`.
"""
Base.show(io::IO, q::Dualquaternion) = print(io, "$(round.(vec(q.real), digits = 3)) + $(round.(vec(q.imag), digits = 3))𝜺 ∈ ℍ²")


"""
    vec(q)

Reshape the number `q` as a one-dimensional column vector in ℍ². The resulting vector shares the same underlying data as `q`, so it will only be mutable if
`q` is mutable, in which case modifying one will also modify the other.
"""
Base.vec(q::Dualquaternion) = [vec(q.real); vec(q.imag)]


"""
    real(q)

Return the real part of the dual-quaternion number `q`.
"""
Base.real(q::Dualquaternion) = q.real


"""
    imag(q)

Return the imaginary/dual part of the dual-quaternion number `q`.
"""
Base.imag(q::Dualquaternion) = q.imag


"""
    conj(q)

Compute the conjugate of a dual-quaternion number `q`.
"""
Base.conj(q::Dualquaternion) = Dualquaternion(conj(q.real), conj(q.imag))


"""
    isapprox(g, q)

Inexact equality comparison: true if norm(`g`-`q`) <= max(0, rtol*max(norm(`g`), norm(`q`))).
The default rtol varies from 1.0e-4 to 1.0e-8 .
"""
Base.isapprox(g::Dualquaternion, q::Dualquaternion) = isapprox(g.real, q.real) && isapprox(g.imag, q.imag)


"""
    norm(q)

Compute the norm of `q` as a dual-quaternion number.
"""
LinearAlgebra.norm(q::Dualquaternion) = [LinearAlgebra.norm(real(q)); LinearAlgebra.dot(real(q), imag(q)) * (1 / LinearAlgebra.norm(real(q)))]


"""
    normalize(q)

Normalize the dual-quaternion number `q` so that its norm equals unity, i.e. norm(a) == 1.
"""
LinearAlgebra.normalize(q::Dualquaternion) = Dualquaternion(real(q) * (1 / LinearAlgebra.norm(real(q))), Quaternion(0, gettranslation(q)...) * real(q) * (1 /  LinearAlgebra.norm(real(q))))


"""
    getrotation(q)

Return the real part of `q` as the quaternion representing rotations in 3D space.
"""
getrotation(q::Dualquaternion) = q.real


"""
    gettranslation(q)

Return the translation part of `q` as a pure imaginary quaternion representing translations in 3D space.
"""
gettranslation(q::Dualquaternion) = imag(2(q.imag) * conj(q.real))


+(g::Dualquaternion, q::Dualquaternion) = Dualquaternion(g.real + q.real, g.imag + q.imag)
-(g::Dualquaternion, q::Dualquaternion) = Dualquaternion(g.real - q.real, g.imag - q.imag)
*(g::Dualquaternion, q::Dualquaternion) = Dualquaternion(g.real * q.real, g.real * q.imag + g.imag * q.real)
*(q::Dualquaternion, λ::Real) = Dualquaternion(λ * q.real, λ * q.imag)
*(λ::Real, q::Dualquaternion) = q * λ
