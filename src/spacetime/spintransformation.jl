import Base.:*
import Base.:-
import Base.vec
import Base.isapprox


export SpinTransformation
export mat
export mat4
export det
export inverse
export zboost
export dopplerfactor
export rapidity


"""
    Represents a spin transformation.

fields: α, β, γ and δ
"""
struct SpinTransformation
    α::Complex
    β::Complex
    γ::Complex
    δ::Complex
    SpinTransformation(a::Vector{<:Complex}) = begin
        @assert(length(a) == 4, "The input vector must contain exactly four numbers.")
        new(a...)
    end
    SpinTransformation(α::Complex, β::Complex, γ::Complex, δ::Complex) = new(α, β, γ, δ)
    SpinTransformation(m::Matrix{<:Complex}) = SpinTransformation(m[1, 1], m[1, 2], m[2, 1], m[2, 2])
    SpinTransformation(θ::Float64, ϕ::Float64, ψ::Float64) = begin # Euler angles
        if isapprox(ϕ, 0.0) && isapprox(θ, 0.0)
            return SpinTransformation(Complex.([exp(im * ψ / 2); 0.0; 0.0; exp(-im * ψ / 2)]))
        end
        if isapprox(ψ, 0.0) && isapprox(ϕ, 0.0)
            return SpinTransformation(Complex.([cos(θ / 2); -sin(θ / 2); sin(θ / 2); cos(θ / 2)]))
        end
        if isapprox(θ, 0.0) && isapprox(ψ, 0.0)
            return SpinTransformation(Complex.([cos(ϕ / 2); im * sin(ϕ / 2); im * sin(ϕ / 2); cos(ϕ / 2)]))
        end
        e11 = cos(θ / 2) * exp(im * (ϕ + ψ) / 2)
        e12 = -sin(θ / 2) * exp(im * (ϕ - ψ) / 2)
        e21 = sin(θ / 2) * exp(-im * (ϕ - ψ) / 2)
        e22 = cos(θ / 2) * exp(-im * (ϕ + ψ) / 2)
        return SpinTransformation(Complex.([e11; e12; e21; e22]))
    end
end


Base.vec(a::SpinTransformation) = [a.α; a.β; a.γ; a.δ]


"""
    mat(a)

Return the spin matrix with the given spin transformation `a`.
"""
mat(a::SpinTransformation) = [a.α a.β; a.γ a.δ]


mat4(a::SpinTransformation) = begin
    α, β, γ, δ = vec(a)
    _α, _β, _γ, _δ = conj.(vec(a))
    e11 = α * _α + β * _β  + γ * _γ  + δ * _δ
    e12 = α * _β  + β * _α + γ * _δ + δ * _γ
    e13 = im * (α * _β  - β * _α + γ * _δ - δ * _γ)
    e14 = α * _α - β * _β  + γ * _γ  - δ * _δ
    e21 = α * _γ  + γ * _α + β * _δ + δ * _β
    e22 = α * _δ + δ * _α + β * _γ  + γ * _β
    e23 = im * (α * _δ - δ * _α + γ * _β  - β * _γ)
    e24 = α * _γ  + γ * _α - β * _δ - δ * _β
    e31 = im * (γ * _α - α * _γ  + δ * _β  - β * _δ)
    e32 = im * (δ * _α - α * _δ + γ * _β  - β * _γ)
    e33 = α * _δ + δ * _α - β * _γ  - γ * _β
    e34 = im * (γ * _α - α * _γ  + β * _δ - δ * _β)
    e41 = α * _α + β * _β  - γ * _γ  - δ * _δ
    e42 = α * _β  + β * _α - γ * _δ - δ * _γ
    e43 = im * (α * _β  - β * _α + δ * _γ  - γ * _δ)
    e44 = α * _α - β * _β  - γ * _γ  + δ * _δ
    M = [e11 e12 e13 e14;
         e21 e22 e23 e24;
         e31 e32 e33 e34;
         e41 e42 e43 e44]
    real.(M)
end


det(a::SpinTransformation) = real(a.α * a.δ - a.β * a.γ)


*(a::SpinTransformation, b::SpinVector) = begin
    # if isapprox(b.a[2], Complex(0))
    #     SpinVector(a.α * b.a[1] + a.β * b.a[2], a.γ * b.a[1] + a.δ * b.a[2], b.timesign)
    # else
    #     ζ = b.a[1] / b.a[2]
    #     SpinVector((a.α * ζ + a.β) / (a.γ * ζ + a.δ), b.timesign)
    # end
    vector = mat(a) * vec(b)
    ξ, η = vector
    timesign = sign(real(ξ * conj(ξ) + η * conj(η))) > 0 ? 1 : -1
    SpinVector(vector..., timesign)
end


*(a::SpinTransformation, b::𝕄) = 𝕄(b.origin, (𝕄(b.origin, mat(a) * mat(b) * adjoint(mat(a)), b.tetrad)).point, b.tetrad)


*(M::Matrix{Float64}, a::𝕄) = 𝕄(a.origin, 𝕍(0.5 .* M * vec(a)), a.tetrad)


*(a::SpinTransformation, b::ℝ⁴) = ℝ⁴(0.5 .* mat4(a) * vec(b))


*(a::SpinTransformation, b::SpinTransformation) = SpinTransformation(mat(a) * mat(b))


-(a::SpinTransformation) = SpinTransformation(-a.α, -a.β, -a.γ, -a.δ)


inverse(a::SpinTransformation) = SpinTransformation(a.δ, -a.β, -a.γ, a.α)


Base.isapprox(a::SpinTransformation, b::SpinTransformation; atol::Float64 = TOLERANCE) = isapprox(a.α, b.α, atol = atol) &&
                                                                                         isapprox(a.β, b.β, atol = atol) &&
                                                                                         isapprox(a.γ, b.γ, atol = atol) &&
                                                                                         isapprox(a.δ, b.δ, atol = atol)


# The relativistic Doppler factor
dopplerfactor(v::Float64) = √((1 + v) / (1 - v))


rapidity(v::Float64) = atanh(v)


zboost(v::Float64) = SpinTransformation(Complex.([√dopplerfactor(v) 0; 0 1 / √dopplerfactor(v)]))


"""
    SpinTransformation(ψ, v)

Construct a spin transformation with the given rotation angle `ψ` and spin vector `v`.
"""
SpinTransformation(ψ::Float64, v::SpinVector) = SpinTransformation(mat(ℍ(ψ, ℝ³(v))))