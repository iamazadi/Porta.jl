import Base.isapprox
import Base.length


export RiemannSphere
export ComplexPlane
export Spherical
export Cartesian
export Geographic


"""
    Represents a point in the Riemann sphere.
"""
abstract type RiemannSphere end


struct ComplexPlane <: RiemannSphere
    a::Array{Complex} # basis [z; z̄]
end


struct Spherical <: RiemannSphere
    a::Array{Float64} # basis [r; ϕ; θ]
end


struct Cartesian <: RiemannSphere
    a::Array{Float64} # basis [x; y; z]
end


struct Geographic <: RiemannSphere
    a::Array{Float64} # basis [ϕ; θ]
end


ζ(y₁, y₂, y₃) = (y₁ + im * y₂) / (1 - y₃)
ζ(ϕ, θ) = cot(θ / 2) * exp(im * ϕ)
ComplexPlane(s::Spherical) = ComplexPlane([ζ(s.a[2], s.a[3]); conj(ζ(s.a[2], s.a[3]))])
ComplexPlane(c::Cartesian) = ComplexPlane([ζ(c.a...); conj(ζ(c.a...))])
ComplexPlane(g::Geographic) = ComplexPlane(Spherical([1.0; g.a[1] + pi; pi / 2 - g.a[2]]))


ζ⁻¹(z) = [angle(z); 2acot(abs(z))]
Spherical(r::ComplexPlane) = Spherical([1.0; ζ⁻¹(r.a[1])])
Spherical(c::Cartesian) = begin
    r = sqrt(c.a[1]^2 + c.a[2]^2 + c.a[3]^2)
    if c.a[1] > 0
        ϕ = atan(c.a[2] / c.a[1])
    elseif c.a[2] > 0
        ϕ = atan(c.a[2] / c.a[1]) + pi
    else
        ϕ = atan(c.a[2] / c.a[1]) - pi
    end
    θ = asin(c.a[3] / r)
    Spherical([r; ϕ; pi / 2 - θ])
end
Spherical(g::Geographic) = Spherical([1.0; g.a[1] + pi; pi / 2 - g.a[2]])


Cartesian(r::ComplexPlane) = begin
    z, z̄ = r.a
    x, y = real(z), imag(z)
    d = x ^ 2 + y ^ 2 + 1
    y₁ = 2x / d
    y₂ = 2y / d
    y₃ = (d - 2) / d
    Cartesian([y₁; y₂; y₃])
end
Cartesian(s::Spherical) = begin
    r, ϕ, θ = s.a
    y₁ = r * sin(θ) * cos(ϕ)
    y₂ = r * sin(θ) * sin(ϕ)
    y₃ = r * cos(θ)
    Cartesian([y₁; y₂; y₃])
end
Cartesian(g::Geographic) = Cartesian(Spherical(g))


Geographic(r::ComplexPlane) = Geographic(Spherical(r))
Geographic(s::Spherical) = Geographic([s.a[2] - pi; pi / 2 - s.a[3]])
Geographic(c::Cartesian) = Geographic(ComplexPlane(c))


vec(r::RiemannSphere) = Base.vec(r.a)
length(r::RiemannSphere) = length(vec(a))


isapprox(z1::ComplexPlane, z2::ComplexPlane) = begin
    Base.isapprox(Cartesian(z1).a, Cartesian(z2).a) end
isapprox(r1::RiemannSphere, r2::RiemannSphere) = Base.isapprox(vec(r1), vec(r2))


Cartesian(r::ℝ³) = Cartesian(vec(r))
ComplexPlane(r::ℝ³) = ComplexPlane(Cartesian(r))
Spherical(r::ℝ³) = Spherical(Cartesian(r))
Geographic(r::ℝ³) = Geographic(Cartesian(r))


ℝ³(r::Cartesian) = ℝ³(vec(r))
ℝ³(r::RiemannSphere) = ℝ³(Cartesian(r))
