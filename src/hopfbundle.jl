import LinearAlgebra


export Φ
export G
export hopfmap
export π✳
export ver
export σmap
export τmap


"""
    Φ(θ, z)

Perform the standard S¹ free group action in complex coordinates z ∈ S³ ⊂ ℂ².
Φ: S¹ × S³ → S³
(ℯⁱᶿ,z) ↦ ℯⁱᶿz
"""
Φ(θ::Real, v::Vector{<:Real}) = Quaternion(exp(im * θ) .* [v[1] + im * v[3]; v[2] + im * v[4]])
Φ(θ::Real, q::Quaternion) = Quaternion(exp(im * θ) .* [q.a + im * q.c; q.b + im * q.d])


"""
    G(θ, v)

The S¹ group action in real coordinates.
G_θ: S¹ × S³ → S³
"""
G(θ::Real, v::Vector{<:Real}) = Quaternion([LinearAlgebra.I(2) .* cos(θ) LinearAlgebra.I(2) .* -sin(θ);
                                            LinearAlgebra.I(2) .* sin(θ) LinearAlgebra.I(2) .* cos(θ)] * v)
G(θ::Real, q::Quaternion) = Quaternion([LinearAlgebra.I(2) .* cos(θ) LinearAlgebra.I(2) .* -sin(θ);
                                        LinearAlgebra.I(2) .* sin(θ) LinearAlgebra.I(2) .* cos(θ)] * vec(q))


"""
    hopfmap(q)

Apply the Hopf map as a projection.
π: ℂ² → ℝ³
(x₁, x₂, x₃, x₄) ↦ (2(x₁x₂ + y₁y₂), 2(x₂y₁ + x₁y₂), x₁² + y₁² - x₂² - y₂²)
z = (z₁, z₂) ↦ (2Re(z₁z̅₂), 2Im(z₁z̅₂), |z₁|² - |z₂|²) = (z̅₁z₂ + z₁z̅₂, i(z̅₁z₂ + z₁z̅₂), |z₁|² - |z₂|²)
"""
hopfmap(v::Vector{<:Real}) = [2(v[1] * v[2] + v[3] * v[4]); 2(v[2] * v[3] - v[1] * v[4]); v[1]^2 + v[3]^2 - v[2]^2 - v[4]^2]
hopfmap(q::Quaternion) = [2(q.a * q.b + q.c * q.d); 2(q.b * q.c - q.a * q.d); q.a^2 + q.c^2 - q.b^2 - q.d^2]


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
    g = real(q)
    M = 2 .* [g.b g.a g.d g.c;
              -g.d g.c g.b -g.a;
              g.a -g.b g.c -g.d]
    M * vec(imag(q))
end


"""
    ver(v, α)

create a vector in the vertical subspace of the Hopf bundle with the given point `v` and constant `α`, which spans K₃v.
"""
ver(v::Quaternion, α::Real) = α * (K(3) * v)


"""
    σmap(p)

Take a point from S² into S³ as a section of the Hopf bundle.
σ: S² → S³
"""
function σmap(p::Vector{Float64})
    g = convert_to_geographic(p)
    r, ϕ, θ = g
    z₁ = ℯ^(im * 0) * √((1 + sin(θ)) / 2)
    z₂ = ℯ^(im * ϕ) * √((1 - sin(θ)) / 2)
    Quaternion([z₁; z₂])
end


"""
    τmap(p)

Take a point from S² into S³ as a section of the Hopf bundle.
τ: S² → S³
"""
function τmap(p::Vector{Float64})
    g = convert_to_geographic(p)
    r, ϕ, θ = g
    z₁ = ℯ^(im * 0) * √((1 + sin(θ)) / 2)
    z₂ = ℯ^(im * ϕ) * √((1 - sin(θ)) / 2)
    Quaternion([z₂; z₁])
end