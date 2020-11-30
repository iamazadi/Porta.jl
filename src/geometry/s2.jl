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
    r::ℝ³
    Cartesian(r::ℝ³) = new(r)
    Cartesian(x::Real, y::Real, z::Real) = Cartesian(ℝ³(x, y, z))
    Cartesian(a::Array) = begin
        @assert(length(a) == 3, "The length of the input vector must be exactly 3.")
        Cartesian(a...)
    end
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
        @assert(-π ≤ ϕ ≤ π, "ϕ must be in [-π, π].")
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

fields: r, ϕ and θ.
"""
struct Geographic <: S²
    r::Float64
    ϕ::Float64
    θ::Float64
    Geographic(r::Real, ϕ::Real, θ::Real) = begin
        @assert(r ≥ 0, "r must be non-negative: $r")
        #@assert(-π ≤ ϕ ≤ π, "ϕ must be in [-π, π]: $ϕ")
        #@assert(-π/2 ≤ θ ≤ π/2, "θ must be in [-π/2, π/2]: $θ")
        new(float(r), float(ϕ), float(θ))
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
Base.conj(cl::ComplexLine) = ComplexLine(conj(cl.z))

Base.vec(cl::ComplexLine) = [cl.z; conj(cl).z]
Base.vec(c::Cartesian) = vec(c.r)
Base.vec(s::Spherical) = [s.r; s.ϕ; s.θ]
Base.vec(g::Geographic) = [g.r; g.ϕ; g.θ]

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

ℝ³(c::Cartesian) = c.r
ℝ³(s::S²) = Cartesian(s).r

norm(c::Cartesian) = norm(c.r)

ComplexLine(c::Cartesian) = begin
    x, y, z = vec(c)
    ComplexLine(x / (1 - z) + im * y / (1 - z))
end
ComplexLine(r::ℝ³) = ComplexLine(Cartesian(r))
ComplexLine(s::Spherical) = ComplexLine(Cartesian(s))
ComplexLine(g::Geographic) = ComplexLine(Cartesian(g))

Cartesian(cl::ComplexLine) = begin
    x, y = real(cl), imag(cl)
    d = x^2 + y^2 + 1
    Cartesian(2x / d, 2y / d, (d - 2) / d)
end
Cartesian(s::Spherical) = begin
    r, ϕ, θ = vec(s)
    x = r * sin(θ) * cos(ϕ)
    y = r * sin(θ) * sin(ϕ)
    z = r * cos(θ)
    Cartesian(x, y, z)
end
Cartesian(g::Geographic) = begin
    r, ϕ, θ = vec(g)
    x = r * cos(θ) * cos(ϕ)
    y = r * cos(θ) * sin(ϕ)
    z = r * sin(θ)
    Cartesian(x, y, z)
end

Spherical(c::Cartesian) = begin
    x, y, z = vec(c)
    r = norm(c)
    Spherical(r, atan(y, x), acos(z / r))
end
Spherical(cl::ComplexLine) = Spherical(Cartesian(cl))
Spherical(g::Geographic) = Spherical(g.r, g.ϕ, pi / 2 - g.θ)
Spherical(r::ℝ³) = Spherical(Cartesian(r))

Geographic(g::Geographic) = g
Geographic(s::Spherical) = Geographic(s.r, s.ϕ, pi / 2 - s.θ)
Geographic(c::Cartesian) = begin
    x, y, z = vec(c)
    r = norm(c)
    Geographic(r, atan(y, x), asin(z / r))
end
Geographic(r::ComplexLine) = Geographic(Cartesian(r))
Geographic(r::ℝ³) = Geographic(Cartesian(r))
