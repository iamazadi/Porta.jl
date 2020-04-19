using Porta
using Base.Test

S²() = [rand() * 2pi - pi, rand() * pi - pi/2)]
S³() = begin
    s = anS²()
    ϕ = lon(s)
    θ = lat(s)
    ψ = rand() * 2pi
    z = Complex(cos(ψ), sin(ψ) * cos(θ) * cos(ϕ))
    w = Complex(sin(ψ) * cos(θ) * sin(ϕ), sin(ψ) * sin(θ))
    [z conj(w); -w conj(z)]
end
Hopf() = Hopf(S²(), rand() ≥ 0.5 ? true : false)

for k in 1:samples
end
