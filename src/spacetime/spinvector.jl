import Base.isapprox


export SpinVector
export RiemannSphere
export antipodal
export transform
export mat


"""
    Represents a spin vector represented as the intersection of the future [past] null cone with the hyperplane T = 1 [T = -1].

fields: nullvector, timesign, ξ, η, ζ, cartesian and spherical.
"""
struct SpinVector <: VectorSpace
    nullvector::𝕍
    timesign::Int
    ξ::Complex
    η::Complex
    ζ::Union{Complex, ComplexF64, Float64}
    cartesian::ℝ³
    spherical::ℝ²
    SpinVector(ζ::Complex, timesign::Int) = begin
        t = timesign > 0 ? +1.0 : -1.0
        denominator = ζ * conj(ζ) + 1.0
        x = (ζ + conj(ζ)) / denominator
        y = (ζ - conj(ζ)) / (im * denominator)
        z = (ζ * conj(ζ) - 1.0) / denominator
        cartesian = ℝ³(real(x), real(y), real(z))
        nullvector = 𝕍(t * ℝ⁴(1.0, vec(cartesian)...))
        if isapprox(z, 1.0)
            θ = 0.0
            ϕ = 0.0
        else
            r, θ, ϕ = vec(convert_to_geographic(cartesian))
            θ = π - θ - π / 2
        end
        spherical = t > 0.0 ? ℝ²(θ, ϕ) : ℝ²(θ, π + ϕ)
        ξ = ζ
        η = Complex(1.0)
        new(nullvector, timesign, ξ, η, ζ, cartesian, spherical)
    end
    SpinVector(ζ::Float64, timesign::Int) = begin
        @assert(isapprox(ζ, Inf), "The spatial direction of the spin vector must either be at the point Infinity or a in the Agrand's Complex plane.")
        t = timesign > 0 ? 1.0 : -1.0
        cartesian = ℝ³(0.0, 0.0, 1.0)
        spherical = ℝ²(0.0, 0.0)
        nullvector = 𝕍(t * ℝ⁴(1.0, vec(cartesian)...))
        ζ = Inf
        ξ = Complex(1.0)
        η = Complex(0.0)
        new(nullvector, timesign, ξ, η, ζ, cartesian, spherical)
    end
    SpinVector(ξ::Complex, η::Complex, timesign::Int) = begin
        t = timesign > 0 ? 1.0 : -1.0
        x = (ξ * conj(η) + η * conj(ξ)) / (ξ * conj(ξ) + η * conj(η))
        y = (ξ * conj(η) - η * conj(ξ)) / (im * (ξ * conj(ξ) + η * conj(η)))
        z = (ξ * conj(ξ) - η * conj(η)) / (ξ * conj(ξ) + η * conj(η))
        cartesian = ℝ³(real(x), real(y), real(z))
        nullvector = 𝕍(ℝ⁴(t, vec(t * cartesian)...))
        SpinVector(nullvector)
    end
    SpinVector(nullvector::𝕍) = begin
        @assert(isnull(nullvector), "The spin vector must be a null vector.")
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


vec(v::SpinVector) = vec(v.nullvector)


mat(v::SpinVector) = [v.ξ; v.η] * transpose([conj(v.ξ); conj(v.η)])


Base.isapprox(u::SpinVector, v::SpinVector; atol::Float64 = TOLERANCE) = isapprox(u.nullvector, v.nullvector, atol = atol) &&
                                                                         isapprox(u.timesign, v.timesign, atol = atol) &&
                                                                         isapprox(u.ζ, v.ζ, atol = atol) &&
                                                                         isapprox(u.cartesian, v.cartesian, atol = atol) &&
                                                                         isapprox(u.spherical, v.spherical, atol = atol)


antipodal(v::SpinVector) = SpinVector(-v.nullvector)
