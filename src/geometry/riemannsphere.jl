import Base.real
import Base.imag
import Base.abs
import Base.angle
import Base.isapprox


export RiemannSphere
export ComplexLine
export Cartesian
export Spherical
export Geographic


"""
    Represents a point in the Riemann sphere.
"""
abstract type RiemannSphere end


"""
    Represents a point in a complex line.

field: z.
"""
struct ComplexLine <: RiemannSphere
    z::Complex
    ComplexLine(z::Complex) = new(z)
end


"""
    Represents a point in the Cartesian coordinate system.

fields: x, y and z.
"""
struct Cartesian <: RiemannSphere
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
struct Spherical <: RiemannSphere
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
struct Geographic <: RiemannSphere
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


real(cl::ComplexLine) = Base.real(cl.z)
imag(cl::ComplexLine) = Base.imag(cl.z)
abs(cl::ComplexLine) = Base.abs(cl.z)
angle(cl::ComplexLine) = Base.angle(cl.z)
conj(cl::ComplexLine) = Base.conj(cl.z)

vec(cl::ComplexLine) = [cl.z; conj(cl)]
vec(c::Cartesian) = [c.x; c.y; c.z]

isapprox(c1::Cartesian, c2::Cartesian) = Base.isapprox(vec(c1), vec(c2))
isapprox(r1::RiemannSphere, r2::RiemannSphere) = isapprox(Cartesian(r1), Cartesian(r2))

ℝ³(c::Cartesian) = ℝ³(vec(c))
ℝ³(r::RiemannSphere) = ℝ³(Cartesian(r))

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

Geographic(s::Spherical) = Geographic(s.ϕ - pi, pi/2 - s.θ)
Geographic(r::ComplexLine) = Geographic(Spherical(r))
Geographic(c::Cartesian) = Geographic(ComplexLine(c))
Geographic(r::ℝ³) = Geographic(Cartesian(r))
