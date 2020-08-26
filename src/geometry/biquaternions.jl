import Base.:+
import Base.:*


export Biquaternion
export getrotation
export gettranslation


"""
    Represents a bi-quaternion for describing rotation and translation in a unified way.

fields: real and dual.
"""
struct Biquaternion
    real::Quaternion
    dual::Quaternion
    Biquaternion(qr::Quaternion, qd::Quaternion) = new(qr, qd)
    Biquaternion(q::Quaternion, t::ℝ³) = begin
        qr = normalize(q)
        qd = 0.5 * Quaternion([0; vec(t)]) * qr
        new(qr, qd)
    end
end


"""
    show(b)

Print a string representation of the given Biquaternion `b`.
"""
Base.show(io::IO, q::Biquaternion) = print(io, "$(q.real) + $(q.dual)𝜺")


"""
    Biquaternion(q)

Construct a Biquaternion with the given Biquaternion `q` and also normalize.
"""
Biquaternion(q::Biquaternion) = begin
    q̂ = normalize(q)
    Biquaternion(q̂.real, q̂.dual)
end


"""
    Biquaternion(rotation)

Construct a Biquaternion with the given Quaternion `rotation` and also normalize.
"""
Biquaternion(rotation::Quaternion) = Biquaternion(normalize(rotation), ℝ³(0, 0, 0))


"""
    Biquaternion(translation)

Construct a Biquaternion with the given ℝ³ `translation`.
"""
Biquaternion(translation::ℝ³) = Biquaternion(Quaternion(1, 0, 0, 0), translation)


vec(q::Biquaternion) = [vec(q.real); vec(q.dual)]


+(q₁::Biquaternion, q₂::Biquaternion) = Biquaternion(q₁.real + q₂.real, q₁.dual + q₂.dual)
-(q₁::Biquaternion, q₂::Biquaternion) = Biquaternion(q₁.real - q₂.real, q₁.dual - q₂.dual)
*(q₁::Biquaternion, q₂::Biquaternion) = Biquaternion(q₁.real * q₂.real,
                                                     q₁.real * q₂.dual + q₁.dual * q₂.real)
*(q::Biquaternion, λ::Real) = Biquaternion(λ * q.real, λ * q.dual)
*(λ::Real, q::Biquaternion) = q * λ
Base.conj(q::Biquaternion) = Biquaternion(conj(q.real), conj(q.dual))
norm(q::Biquaternion) = begin
    qrnorm = norm(q.real)
    Q = (conj(q.real) * q.dual + q.real * conj(q.dual)) * (1 / 2qrnorm)
    scalar = vec(Q)[1]
    sqrt(qrnorm^2 + scalar^2)
end
normalize(q::Biquaternion) = begin
    magnitude = norm(q)
    @assert(magnitude > 1e-5, "The magnitude is almost equal to zero, too small.")
    q * (1 / magnitude)
end
getrotation(q::Biquaternion) = q.real
gettranslation(q::Biquaternion) = ℝ³(vec(2q.dual * conj(q.real))[2:4])

Base.isapprox(q1::Biquaternion, q2::Biquaternion) = isapprox(q1.real, q2.real) &&
                                                    isapprox(q1.dual, q2.dual)
