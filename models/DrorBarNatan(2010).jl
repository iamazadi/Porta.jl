"""
    π(p)

Map the point `p` from S³ into the Riemann sphere.
"""
function π(p::ℍ)
    z₁ = Cpmplex(p.a[1], p.a[2])
    z₂ = Cpmplex(p.a[3], p.a[4])
    z = z₂ / z₁
    z̅ = conj(z)
    RiemannSphere(z, z̅)
end


"""
    f(p)

Map from S² into the upper hemisphere of S² with the given point `p`.
"""
function f(p::RiemannSphere)
    ϕ, θ = Geographic(p).a
    r = sqrt((1 + sin(θ)) / 2)
    z = r * exp(im * ϕ)
    Cartesian(real(z), imag(z), sqrt((1 + sin(θ)) / 2))
end


"""
    g(p, α)

Map from the upper hemisphere of S² into S³ with the given point `p`.
"""
function g(p::Cartesian, α::Real)
    z₁ = exp(im * α) * Complex(p.a[1], p.a[2])
    z₂ = exp(im * α) * p.a[3]
    ℍ(real(z₁), imag(z₁), real(z₂), imag(z₂))
end



"""
    f✳(p)

Calculate the pullback to S³ with the given point `p`.
"""
function f✳(p::ℍ)
    f(π(p))
end
