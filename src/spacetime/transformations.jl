import LinearAlgebra


export compute_fourscrew
export compute_nullrotation
export calculatetransformation
export calculatebasisvectors


"""
    compute_fourscrew(progress, status)

Compute a matrix that takes a Minkowski tetrad to another in the form of a four-screw,
with the given `progress` for interpolation and `status` for choosing between rotation, boost and four-screw.
"""
function compute_fourscrew(progress::Float64, status::Int)
    if status == 1 # roation
        w = 1.0
        ϕ = log(w) # rapidity
        ψ = progress * 2π
    end
    if status == 2 # boost
        w = max(1e-4, abs(cos(progress * 2π)))
        ϕ = log(w) # rapidity
        ψ = 0.0
    end
    if status == 3 # four-screw
        w = max(1e-4, abs(cos(progress * 2π)))
        ϕ = log(w) # rapidity
        ψ = progress * 2π
    end
    transform(x::ℍ) = begin
        T, X, Y, Z = vec(x)
        X̃ = X * cos(ψ) - Y * sin(ψ)
        Ỹ = X * sin(ψ) + Y * cos(ψ)
        Z̃ = Z * cosh(ϕ) + T * sinh(ϕ)
        T̃ = Z * sinh(ϕ) + T * cosh(ϕ)
        ℍ(T̃, X̃, Ỹ, Z̃)
    end
    r₁ = transform(ℍ(1.0, 0.0, 0.0, 0.0))
    r₂ = transform(ℍ(0.0, 1.0, 0.0, 0.0))
    r₃ = transform(ℍ(0.0, 0.0, 1.0, 0.0))
    r₄ = transform(ℍ(0.0, 0.0, 0.0, 1.0))
    r = r₁ * r₂ * r₃ * r₄
    _M = reshape([vec(r₁); vec(r₂); vec(r₃); vec(r₄)], (4, 4))
    decomposition = LinearAlgebra.eigen(_M)
    λ = LinearAlgebra.normalize(decomposition.values) .* 2.0
    Λ = [λ[1] 0.0 0.0 0.0; 0.0 λ[2] 0.0 0.0; 0.0 0.0 λ[3] 0.0; 0.0 0.0 0.0 λ[4]]
    M = real.(decomposition.vectors * Λ * LinearAlgebra.inv(decomposition.vectors))

    u₁ = 𝕍(1.0, 1.0, 0.0, 0.0)
    u₂ = 𝕍(1.0, 0.0, 1.0, 0.0)
    u₃ = 𝕍(1.0, 0.0, 0.0, 1.0)
    tolerance = 1e-3
    for u in [u₁, u₂, u₃]
        v = 𝕍(vec(M * ℍ(u.a)))
        @assert(isnull(v, atol = tolerance), "v ∈ 𝕍 in not null, $v.")
        s = SpinVector(u)
        s′ = SpinVector(v)
        if Complex(s) == Inf # A Float64 number (the point at infinity)
            ζ = Complex(s)
        else # A Complex number
            ζ = w * exp(im * ψ) * Complex(s)
        end
        ζ′ = Complex(s′)
        if ζ′ == Inf
            ζ = real(ζ)
        end
        @assert(isapprox(ζ, ζ′, atol = tolerance), "The transformation induced on Argand plane is not correct, $ζ != $ζ′.")
    end
    
    M
end


"""
    compute_nullrotation(progress)

Compute a matrix that takes a Minkowski tetrad to another in the form of a null rotation,
with the given `progress` for a smooth interpolation.
"""
function compute_nullrotation(progress::Float64)
    a = sin(progress * 2π)
    transform(x::ℍ) = begin
        T, X, Y, Z = vec(x)
        X̃ = X 
        Ỹ = Y + a * (T - Z)
        Z̃ = Z + a * Y + 0.5 * a^2 * (T - Z)
        T̃ = T + a * Y + 0.5 * a^2 * (T - Z)
        ℍ(T̃, X̃, Ỹ, Z̃)
    end
    r₁ = transform(ℍ(1.0, 0.0, 0.0, 0.0))
    r₂ = transform(ℍ(0.0, 1.0, 0.0, 0.0))
    r₃ = transform(ℍ(0.0, 0.0, 1.0, 0.0))
    r₄ = transform(ℍ(0.0, 0.0, 0.0, 1.0))
    _M = reshape([vec(r₁); vec(r₂); vec(r₃); vec(r₄)], (4, 4))
    decomposition = LinearAlgebra.eigen(_M)
    λ = decomposition.values
    Λ = [λ[1] 0.0 0.0 0.0; 0.0 λ[2] 0.0 0.0; 0.0 0.0 λ[3] 0.0; 0.0 0.0 0.0 λ[4]]
    M = real.(decomposition.vectors * Λ * LinearAlgebra.inv(decomposition.vectors))

    u₁ = 𝕍(1.0, 1.0, 0.0, 0.0)
    u₂ = 𝕍(1.0, 0.0, 1.0, 0.0)
    u₃ = 𝕍(1.0, 0.0, 0.0, 1.0)
    tolerance = 1e-3
    for u in [u₁, u₂, u₃]
        v = 𝕍(vec(M * ℍ(u.a)))
        @assert(isnull(v, atol = tolerance), "v ∈ 𝕍 in not a null vector, $v.")
        s = SpinVector(u) # TODO: visualize the spin-vectors as frames on S⁺
        s′ = SpinVector(v)
        β = Complex(im * a)
        α = 1.0
        ζ = α * Complex(s) + β
        ζ′ = Complex(s′)
        if ζ′ == Inf
            ζ = real(ζ)
        end
        @assert(isapprox(ζ, ζ′, atol = tolerance), "The transformation induced on Argand plane is not correct, $ζ != $ζ′.")
    end

    v₁ = 𝕍(normalize(ℝ⁴(1.0, 0.0, 0.0, 1.0)))
    v₂ = 𝕍(vec(M * ℍ(vec(v₁))))
    @assert(isnull(v₁, atol = tolerance), "vector t + z in not null, $v₁.")
    @assert(isapprox(v₁, v₂, atol = tolerance), "The null vector t + z is not invariant under the null rotation, $v₁ != $v₂.")

    M
end


"""
    calculatetransformation(z₁, z₂, z₃, w₁, w₂, w₃)

Calculate the bilinear transformation that takes the given three points `z₁`, `z₂` and `z₃` to three points `w₁`, `w₂` and `w₃`.
"""
function calculatetransformation(z₁::Complex, z₂::Complex, z₃::Complex, w₁::Complex, w₂::Complex, w₃::Complex)
    f(z::Complex) = begin
        A = (w₁ - w₂) * (z - z₂) * (z₁ - z₃)
        B = (w₁ - w₃) * (z₁ - z₂) * (z - z₃)
        (w₃ * A - w₂ * B) / (A - B)
    end
end


"""
    calculatebasisvectors(κ, ω)

Calculate an orthonormal set of basis vectors with the given spin-vectors `κ` and `ω`.
"""
function calculatebasisvectors(κ::SpinVector, ω::SpinVector)
    κv = 𝕍( κ)
    ωv = 𝕍( ω)
    zero = 𝕍( 0.0, 0.0, 0.0, 0.0)
    B = stack([vec(κv), vec(ωv), vec(zero), vec(zero)])
    N = LinearAlgebra.nullspace(B)
    a = 𝕍(N[begin:end, 1])
    b = 𝕍(N[begin:end, 2])
    a = 𝕍(LinearAlgebra.normalize(vec(a - κv - ωv)))
    b = 𝕍(LinearAlgebra.normalize(vec(b - κv - ωv)))
    v₁ = ℝ⁴(κv)
    v₂ = ℝ⁴(ωv)
    v₃ = ℝ⁴(a)
    v₄ = ℝ⁴(b)
    e₁ = v₁
    ê₁ = normalize(e₁)
    e₂ = v₂ - dot(ê₁, v₂) * ê₁
    ê₂ = normalize(e₂)
    e₃ = v₃ - dot(ê₁, v₃) * ê₁ - dot(ê₂, v₃) * ê₂
    ê₃ = normalize(e₃)
    e₄ = v₄ - dot(ê₁, v₄) * ê₁ - dot(ê₂, v₄) * ê₂ - dot(ê₃, v₄) * ê₃
    ê₄ = normalize(e₄)
    ê₁, ê₂, ê₃, ê₄
end