export S²
export ComplexLine
export Cartesian
export Spherical
export Geographic


"""
    Represents a point in 2-sphere.
"""
abstract type S² end


"""
    Represents a point in the complex line.

field: z.
"""
struct ComplexLine <: S²
    z::Complex
end


"""
    Represents a point in the Cartesian coordinate system.

fields: x, y and z.
"""
struct Cartesian <: S²
    x::Float64
    y::Float64
    z::Float64
    Cartesian(x::Real, y::Real, z::Real) = new(float(x), float(y), float(z))
    Cartesian(a::Array) = begin
        @assert(length(a) == 3, "The length of the input vector must be exactly 3.")
        Cartesian(a...)
    end
    Cartesian(r::ℝ³) = Cartesian(vec(r))
end


"""
    Represents a point in the spherical coordinate system.

fields: r, ϕ and θ.
"""
struct Spherical <: S²
    r::Float64
    ϕ::Float64
    θ::Float64
    Spherical(r::Real, ϕ::Real, θ::Real) = begin
        @assert(r ≥ 0, "r must be non-negative.")
        @assert(0 ≤ ϕ ≤ 2π, "ϕ must be in [0, 2π].")
        @assert(0 ≤ θ ≤ π, "θ must be in [0, π].")
        new(float(r), float(ϕ), float(θ))
    end
    Spherical(a::Array) = begin
        @assert(length(a) == 3, "The length of the input vector must be exactly 3.")
        Spherical(a...)
    end
end


"""
    Represents a point in the geographic coordinate system.

fields: ϕ and θ.
"""
struct Geographic <: S²
    ϕ::Float64
    θ::Float64
    Geographic(ϕ::Real, θ::Real) = begin
        @assert(-π ≤ ϕ ≤ π, "ϕ must be in [-π, π].")
        @assert(-π/2 ≤ θ ≤ π/2, "θ must be in [-π/2, π/2].")
        new(float(ϕ), float(θ))
    end
    Geographic(a::Array) = begin
        @assert(length(a) == 2, "The length of the input vector must be exactly 2.")
        Geographic(a...)
    end
end


Base.real(cl::ComplexLine) = real(cl.z)
Base.imag(cl::ComplexLine) = imag(cl.z)
Base.abs(cl::ComplexLine) = abs(cl.z)
Base.angle(cl::ComplexLine) = angle(cl.z)
Base.conj(cl::ComplexLine) = conj(cl.z)

Base.vec(cl::ComplexLine) = [cl.z; conj(cl)]
Base.vec(c::Cartesian) = [c.x; c.y; c.z]
Base.vec(s::Spherical) = [s.r; s.ϕ; s.θ]
Base.vec(g::Geographic) = [g.ϕ; g.θ]

Base.isapprox(c1::Cartesian, c2::Cartesian) = isapprox(vec(c1), vec(c2))
Base.isapprox(s1::S², s2::S²) = isapprox(Cartesian(s1), Cartesian(s2))
Base.isapprox(a::Array{<:S²,N} where N,
              b::Array{<:S²,N} where N;
              atol::Float64 = TOLERANCE) = begin
    for (elementa, elementb) in zip(a, b)
        if isapprox(vec(elementa), vec(elementb), atol = atol) == false
            return false
        end
    end
    return true
end

ℝ³(c::Cartesian) = ℝ³(vec(c))
ℝ³(s::S²) = ℝ³(Cartesian(s))

norm(c::Cartesian) = norm(ℝ³(c))

ComplexLine(r3::ℝ³) = ComplexLine(Cartesian(r3))
ComplexLine(s::Spherical) = ComplexLine(cot(s.θ / 2) * exp(im * s.ϕ))
ComplexLine(c::Cartesian) = ComplexLine((c.x + im * c.y) / (1 - c.z))
ComplexLine(g::Geographic) = ComplexLine(Spherical(g))

Cartesian(cl::ComplexLine) = begin
    x, y = real(cl), imag(cl)
    d = x^2 + y^2 + 1
    Cartesian(2x / d, 2y / d, (d - 2) / d)
end
Cartesian(s::Spherical) = begin
    r, ϕ, θ = s.r, s.ϕ, s.θ
    Cartesian(r * sin(θ) * cos(ϕ), r * sin(θ) * sin(ϕ), r * cos(θ))
end
Cartesian(g::Geographic) = Cartesian(Spherical(g))

Spherical(cl::ComplexLine) = Spherical([1; angle(cl); 2acot(abs(cl))])
Spherical(c::Cartesian) = begin
    x, y, z = vec(c)
    if x > 0
        ϕ = atan(y / x)
    elseif y > 0
        ϕ = atan(y / x) + pi
    else
        ϕ = atan(y / x) - pi
    end
    r = norm(c)
    θ = asin(z / r)
    Spherical(r, ϕ, pi/2 - θ)
end
Spherical(g::Geographic) = Spherical(1, g.ϕ + pi, pi/2 - g.θ)
Spherical(r::ℝ³) = Spherical(Cartesian(r))

Geographic(g::Geographic) = g
Geographic(s::Spherical) = Geographic(s.ϕ - pi, pi/2 - s.θ)
Geographic(r::ComplexLine) = Geographic(Spherical(r))
Geographic(c::Cartesian) = Geographic(ComplexLine(c))
Geographic(r::ℝ³) = Geographic(Cartesian(r))
