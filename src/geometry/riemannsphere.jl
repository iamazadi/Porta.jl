import Base.isapprox
import Base.length


export RiemannSphere
export Spherical
export Cartesian
export Geographic


struct RiemannSphere
    a::Array{Complex} # basis [z; z̄]
end


struct Spherical
    a::Array{Float64} # basis [r; ϕ; θ]
end


struct Cartesian
    a::Array{Float64} # basis [x; y; z]
end


struct Geographic
    a::Array{Float64} # basis [ϕ; θ]
end


ζ(y₁, y₂, y₃) = (y₁ + im * y₂) / (1 - y₃)
ζ(ϕ, θ) = cot(θ / 2) * exp(im * ϕ)
RiemannSphere(s::Spherical) = RiemannSphere([ζ(s.a[2], s.a[3]); conj(ζ(s.a[2], s.a[3]))])
RiemannSphere(c::Cartesian) = RiemannSphere([ζ(c.a...); conj(ζ(c.a...))])
RiemannSphere(g::Geographic) = RiemannSphere(Spherical([1.0; g.a[1] + pi; pi / 2 - g.a[2]]))


ζ⁻¹(z) = [angle(z); 2acot(abs(z))]
Spherical(r::RiemannSphere) = Spherical([1.0; ζ⁻¹(r.a[1])])
Spherical(c::Cartesian) = begin
    r = abs(norm(c.a))
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


Cartesian(r::RiemannSphere) = begin
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


Geographic(r::RiemannSphere) = Geographic(Spherical(r))
Geographic(s::Spherical) = Geographic([s.a[2] - pi; pi / 2 - s.a[3]])
Geographic(c::Cartesian) = Geographic(RiemannSphere(c))


length(r::RiemannSphere) = length(r.a)
length(s::Spherical) = length(s.a)
length(c::Cartesian) = length(c.a)
length(g::Geographic) = length(g.a)


Base.isapprox(r₁::RiemannSphere, r₂::RiemannSphere) = begin
    isapprox(Cartesian(r₁).a, Cartesian(r₂).a) end
Base.isapprox(s₁::Spherical, s₂::Spherical) = isapprox(s₁.a, s₂.a)
Base.isapprox(c₁::Cartesian, c₂::Cartesian) = isapprox(c₁.a, c₂.a)
Base.isapprox(g₁::Geographic, g₂::Geographic) = isapprox(g₁.a, g₂.a)
