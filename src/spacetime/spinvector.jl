import Base.+
import Base.-
import Base.*
import Base.isapprox


export SpinVector
export vec
export mat


"""
    Represents a spin-vector in the spin-space G, which is a vector space over Complex numbers.

fields: a and timesign.
"""
struct SpinVector <: VectorSpace
    a::Vector{Complex}
    timesign::Int
    SpinVector(a::Vector{<:Complex}, timesign::Int) = begin
        @assert(length(a) == 2, "The spin-vector components must be two in number, but was given $(length(a)).")
        new(a, timesign)
    end
    SpinVector(ξ::Complex, η::Complex, timesign::Int) = SpinVector([ξ; η], timesign)
    SpinVector(ζ::Complex, timesign::Int) = SpinVector(ζ, Complex(1.0), timesign)
    SpinVector(ζ::Float64, timesign::Int) = begin
        @assert(isapprox(ζ, Inf), "The spatial direction of the spin vector must either be at the point Infinity or a in Argand plane.")
        SpinVector(Complex(1.0), Complex(0.0), timesign)
    end
    SpinVector(nullvector::𝕍) = begin
        @assert(isnull(nullvector, atol = 1e-3), "The spin vector must be a null vector: $nullvector.")
        t, x, y, z = vec(nullvector)
        timesign = t > 0.0 ? 1 : -1
        x, y, z = timesign > 0 ? vec(normalize(ℝ³(x, y, z))) : vec(normalize(-ℝ³(x, y, z)))
        if isapprox(z, 1.0)
            SpinVector(Inf, timesign)
        else
            X′, Y′ = x / (1.0 - z), y / (1.0 - z)
            ζ = X′ + im * Y′
            SpinVector(ζ, timesign)
        end
    end
    SpinVector(θ::Float64, ϕ::Float64, timesign::Int) = begin
        ζ = timesign > 0 ? exp(im * ϕ) * cot(θ / 2.0) : -exp(im * ϕ) * tan(θ / 2.0)
        SpinVector(ζ, timesign)
    end
    SpinVector(cartesian::ℝ³, timesign::Int) = begin
        @assert(isapprox(norm(cartesian), 1.0), "The direction must be in the unit sphere in the Euclidean 3-space.")
        @assert(!isapprox(timesign, 0), "The future/past direction can be either +1 pr -1, but was given 0.")
        x, y, z = vec(cartesian)
        if isapprox(z, 1.0)
            SpinVector(Inf, timesign)
        else
            t = timesign > 0 ? 1.0 : -1.0
            x, y, z = vec(normalize(t * ℝ³(x, y, z)))
            X′, Y′ = x / (1.0 - z), y / (1.0 - z)
            ζ = X′ + im * Y′
            ζ = timesign > 0 ? ζ : -1.0 / conj(ζ)
            SpinVector(ζ, timesign)
        end
    end
end


vec(κ::SpinVector) = κ.a


mat(κ::SpinVector) = κ.a * adjoint(κ.a)


Base.isapprox(κ::SpinVector, ω::SpinVector; atol::Float64 = TOLERANCE) = isapprox(κ.a[1], ω.a[1], atol = atol) &&
                                                                         isapprox(κ.a[2], ω.a[2], atol = atol) &&
                                                                         isapprox(κ.timesign, ω.timesign, atol = atol)


# unary operations
+(κ::SpinVector) = κ
-(κ::SpinVector) = SpinVector(-κ.a, κ.timesign)


# scalar multiplication: ℂ × G → G
*(λ::Complex, κ::SpinVector) = SpinVector(λ .* κ.a, κ.timesign)
*(λ::Real, κ::SpinVector) = Complex(λ) * κ
# addition: G × G → G
+(κ::SpinVector, ω::SpinVector) = SpinVector(κ.a + ω.a, κ.timesign)
# inner product: G × G → ℂ
dot(κ::SpinVector, ω::SpinVector) = κ.a[1] * ω.a[2] - κ.a[2] * ω.a[1]


ℝ³(κ::SpinVector) = begin
    t = κ.timesign > 0 ? 1.0 : -1.0
    ξ, η = κ.a
    x = (ξ * conj(η) + η * conj(ξ)) / (ξ * conj(ξ) + η * conj(η))
    y = (ξ * conj(η) - η * conj(ξ)) / (im * (ξ * conj(ξ) + η * conj(η)))
    z = (ξ * conj(ξ) - η * conj(η)) / (ξ * conj(ξ) + η * conj(η))
    ℝ³(real(x), real(y), real(z))
end


Complex(κ::SpinVector) = begin
    if isapprox(κ.a[2], Complex(0))
        return Inf
    else
        return κ.a[1] / κ.a[2]
    end
end


𝕍(κ::SpinVector) = begin
    t = float(κ.timesign)
    v = ℝ³(κ)
    𝕍(ℝ⁴(t, vec(t * v)...))
end