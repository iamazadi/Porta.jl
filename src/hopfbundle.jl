export Φ
export G
export hopfmap
export π✳
export ver
export σmap
export τmap
export πmap


"""
    Φ(θ, z)

Perform the standard S¹ free group action in complex coordinates z ∈ S³ ⊂ ℂ².
Φ: S¹ × S³ → S³
(ℯⁱᶿ,z) ↦ ℯⁱᶿz
"""
Φ(θ::Real, v::ℝ⁴) = ℍ(exp(im * θ) .* [vec(v)[1] + im * vec(v)[3]; vec(v)[2] + im * vec(v)[4]])
Φ(θ::Real, q::ℍ) = Φ(θ, ℝ⁴(vec(q)))


"""
    G(θ, v)

The S¹ group action in real coordinates.
G_θ: S¹ × S³ → S³
"""
G(θ::Real, v::ℝ⁴) = ℍ([Identity(2) .* cos(θ) Identity(2) .* -sin(θ);
                                Identity(2) .* sin(θ) Identity(2) .* cos(θ)] * vec(v))
G(θ::Real, q::ℍ) = G(θ, ℝ⁴(vec(q)))


"""
    hopfmap(q)

Apply the Hopf map as a projection.
π: ℂ² → ℝ³
(x₁, x₂, x₃, x₄) ↦ (2(x₁x₂ + y₁y₂), 2(x₂y₁ + x₁y₂), x₁² + y₁² - x₂² - y₂²)
z = (z₁, z₂) ↦ (2Re(z₁z̅₂), 2Im(z₁z̅₂), |z₁|² - |z₂|²) = (z̅₁z₂ + z₁z̅₂, i(z̅₁z₂ + z₁z̅₂), |z₁|² - |z₂|²)
"""
hopfmap(v::ℝ⁴) = [2(vec(v)[1] * vec(v)[2] + vec(v)[3] * vec(v)[4]); 2(vec(v)[2] * vec(v)[3] - vec(v)[1] * vec(v)[4]); vec(v)[1]^2 + vec(v)[3]^2 - vec(v)[2]^2 - vec(v)[4]^2]
hopfmap(q::ℍ) = hopfmap(ℝ⁴(vec(q)))


"""
    π✳(q)

Push forward a tangent vector of S³ at `v` into the tangent space of S² at the Hopf map of `v`, p = π(v).
π✳: TᵥS³ → TₚS²
z = (z₁, z₂) = (x₁ + iy₂, x₂ + iy₂) = (x₁, x₂) + i(y₁, y₂) ⊂ ℂ²
v = (x₁, x₂, y₁, y₂) = (Re(z₁), Re(z₂), Im(z₁), Im(z₂)) ∈ S³ ⊂ ℝ⁴
π✳ = 2(x₂ x₁ y₂ y₁
       -y₂ y₁ x₂ -x₁
       x₁ -x₂ y₁ -y₂)
"""
π✳(q::Dualquaternion) = begin
    x₁, x₂, y₁, y₂ = vec(real(q))
    M = [x₂ x₁ y₂ y₁;
         -y₂ y₁ x₂ -x₁;
         x₁ -x₂ y₁ -y₂]
    ℝ³(2 .* M * vec(imag(q)))
end


"""
    ver(v, α)

create a vector in the vertical subspace of the Hopf bundle with the given point `v` and constant `α`, which spans K₃v.
"""
ver(v::ℍ, α::Real) = α * (K(3) * v)


"""
    σmap(p)

Take a point from S² into S³ as a section of the Hopf bundle.
σ: S² → S³
"""
function σmap(p::ℝ³)
    @assert(isapprox(norm(p), 1), "The given point must be in the unit 2-sphere, but has norm $(norm(p)).")
    g = convert_to_geographic(p)
    r, θ, ϕ = g
    z₂ = ℯ^(im * 0) * √((1 + sin(θ)) / 2)
    z₁ = ℯ^(im * ϕ) * √((1 - sin(θ)) / 2)
    -ℍ([z₁; z₂])
end


"""
    τmap(p)

Take a point from S² into S³ as a section of the Hopf bundle.
τ: S² → S³
"""
function τmap(p::ℝ³)
    @assert(isapprox(norm(p), 1), "The given point must be in the unit 2-sphere, but has norm $(norm(p)).")
    g = convert_to_geographic(p)
    r, θ, ϕ = g
    z₂ = ℯ^(im * 0) * √((1 + sin(θ)) / 2)
    z₁ = ℯ^(im * ϕ) * √((1 - sin(θ)) / 2)
    -ℍ([z₂; z₁])
end


"""
    πmap(q)

Apply the Hopf map to the given point `q`.
π: S³ → S²
"""
πmap(v::ℍ) = begin
    z₁, z₂ = vec(v)[1] + vec(v)[3] * im, vec(v)[2] + vec(v)[4] * im
    w₃ = conj(z₁) * z₂ + z₁ * conj(z₂)
    w₂ = im * (conj(z₁) * z₂ - z₁ * conj(z₂))
    w₁ = abs(z₁)^2 - abs(z₂)^2
    ℝ³(real.([w₁; w₂; w₃]))
end