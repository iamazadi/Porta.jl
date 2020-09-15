"""
    f₁(r, θ, ϕ, ψ)

Define a coordinate chart from 3-hyperspherical coordinates into Cartesian coordinates in ℝ⁴
with the given radius `r`, and angles: `θ`, `ϕ` and `ψ`. f₁: S³ ⟼ ℝ⁴.
"""
function f₁(r::Real, θ::Real, ϕ::Real, ψ::Real)
    x₁ = r * cos(θ)
    x₂ = r * sin(θ) * cos(ϕ)
    x₃ = r * sin(θ) * sin(ϕ) * cos(ψ)
    x₄ = r * sin(θ) * sin(ϕ) * sin(ψ)
    ℝ⁴(x₁, x₂, x₃, x₄)
end


"""
    f₂(α, ϕ₁, ϕ₂)

Define a coordinate chart from Hopf coordinates on 3-sphere into Cartesian coordinates in ℝ⁴
with the given angles `α`, `ϕ₁` and `ϕ₂`. f₂: S³ ⟼ ℝ⁴.
"""
function f₂(α::Real, ϕ₁::Real, ϕ₂::Real)
    @assert(0 < α < π / 2, "α ∈ (0, π/2)")
    @assert(0 ≤ ϕ₁ ≤ 2π, "ϕ₁ ∈ [0, 2π]")
    @assert(0 ≤ ϕ₂ ≤ 2π, "ϕ₂ ∈ [0, 2π]")
    x₁ = cos(ϕ₁) * sin(α)
    x₂ = sin(ϕ₁) * sin(α)
    x₃ = cos(ϕ₂) * cos(α)
    x₄ = sin(ϕ₂) * cos(α)
    ℝ⁴(x₁, x₂, x₃, x₄)
end


"""
    f₃(α, ϕ₁, ϕ₂)

Define a coordinate chart from Hopf coordinates on 3-sphere into Cartesian coordinates in ℝ⁴
with the given angles `α`, `ϕ₁` and `ϕ₂`. f₃: S³ ⟼ ℝ⁴.
"""
function f₃(α::Real, ϕ₁::Real, ϕ₂::Real)
    @assert(0 < α < π / 2, "α ∈ (0, π/2)")
    @assert(0 ≤ ϕ₁ ≤ 2π, "ϕ₁ ∈ [0, 2π]")
    @assert(0 ≤ ϕ₂ ≤ 4π, "ϕ₂ ∈ [0, 4π]")
    x₁ = cos((ϕ₁ + ϕ₂) / 2) * sin(α)
    x₂ = sin((ϕ₁ + ϕ₂) / 2) * sin(α)
    x₃ = cos((ϕ₂ - ϕ₁) / 2) * cos(α)
    x₄ = sin((ϕ₂ - ϕ₁) / 2) * cos(α)
    ℝ⁴(x₁, x₂, x₃, x₄)
end
