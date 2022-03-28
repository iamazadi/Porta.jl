export Bundle
export Clifford
export σmap
export τmap
export πmap
export λ⁻¹map
export S¹action


abstract type Bundle end


"""
    Represents a Clifford bundle, AKA the Hopf fibration of S³.

fields: total and base.
"""
struct Clifford <: Bundle
    total::S³
    base::S²
end


"""
    Clifford(w, z, A, B)

Construct a Clifford bundle with the given Complex numbers: `w`, `z`, `A` and `B`. The ratio
A:B distinguishes the fibers from one another.
"""
Clifford(w::Complex, z::Complex, A::Complex, B::Complex) = begin
    @assert(isapprox(abs(w)^2 + abs(z)^2, 1),
            "The equation |w|² + |z|² = 1 must hold for the given w and z.")
    @assert(!isapprox(abs(A), 0) || !isapprox(abs(B), 0),
            "Aw + Bz = 0, either of A or B can be zero, but not both.")
    Clifford(ComplexPlane(w, z), ComplexLine(A / B))
end


"""
    Clifford(w, z, B)

Construct a Clifford bundle with the given Complex numbers: `w`, `z` and `B`. Here, `B`
on its own identifies a point in the base space and we compute A on the fly.
"""
Clifford(w::Complex, z::Complex, B::Complex) = begin
    # Aw + Bz = 0
    # Aw = -Bz
    # A = -Bz/w
    Clifford(w, z, -B * z / w, B)
end


"""
    σmap(b)

A map that takes the base space to the total space. σ: S² → S³, σ ⊂ [|z₀| ≤ 1, z₁ > 0].
"""
function σmap(b::S²)
    p = Geographic(b)
    z₀ = exp(im * 0) * sqrt((1 + sin(p.θ)) / 2)
    z₁ = exp(im * p.ϕ) * sqrt((1 - sin(p.θ)) / 2)
    ComplexPlane(z₀, z₁)
end


"""
    τmap(b)

A map that takes the base space to the total space. σ: S² → S³, τ ⊂ [z₀ > 0, |z₁| ≤ 1].
"""
function τmap(b::S²)
    z₀, z₁ = vec(ComplexPlane(σmap(b)))
    ComplexPlane(z₁, z₀)
end


"""
    πmap(q)

Sends a point on a unit 3-sphere to a point on a unit 2-sphere with the given
point. S³ ↦ S²
"""
function πmap(q::Quaternion)
    z₁, z₂ = vec(ComplexPlane(q))
    ComplexLine(z₂ / z₁)
end


"""
λ⁻¹map(p)
Sends a point on the plane back to a point on a unit sphere with the given
point. This is the inverse stereographic projection of a 3-sphere.
"""
function λ⁻¹map(p::S²)
    r3 = ℝ³(Cartesian(p))
    p₁, p₂, p₃ = vec(r3)
    mgnitude² = norm(r3)^2
    x₁ = 2p₁ / (1 + mgnitude²)
    x₂ = 2p₂ / (1 + mgnitude²)
    x₃ = 2p₃ / (1 + mgnitude²)
    x₄ = (-1 + mgnitude²) / (1 + mgnitude²)
    Quaternion(x₁, x₂, x₃, x₄)
end


"""
    S¹action(z, s)

Aply the S¹ action on the S³ with the given point in the total space, `z`, and the circle
`s` as in the structure group of the Cliffor bundle, `s` ∈ U(1).
"""
S¹action(z::S³, s::S¹) = begin
    Quaternion(ComplexPlane(exp(im * angle(s)) .* vec(ComplexPlane(z))))
end

S¹action(z::ComplexPlane, s::U1) = ComplexPlane(exp(im * angle(s)) .* vec(z))