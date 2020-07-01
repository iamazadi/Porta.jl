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
    all([isapprox(r₁.a[i], r₂.a[i]) for i in 1:length(r₁)]) end
Base.isapprox(s₁::Spherical, s₂::Spherical) = begin
    all([isapprox(s₁.a[i], s₂.a[i]) for i in 1:length(s₁)]) end
Base.isapprox(c₁::Cartesian, c₂::Cartesian) = begin
    all([isapprox(c₁.a[i], c₂.a[i]) for i in 1:length(c₁)]) end
Base.isapprox(g₁::Geographic, g₂::Geographic) = begin
    all([isapprox(g₁.a[i], g₂.a[i]) for i in 1:length(g₁)]) end
