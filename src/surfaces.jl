ϵ = 1e-2
Φ(p) = f(p[1], p[2])
struct dΦ
    u::Float64
    v::Float64
end
struct ξ
    a::Float64
    b::Float64
end
vect(dΦ) = [dΦ.u; dΦ.v]
vect(ξ) = [ξ.a; ξ.b]
dΦ(p::Array{Float64,1}) = dΦ(Φ([p[1] + ϵ, p[2]]) - Φ(p)) / ϵ,
                            (Φ([p[1], p[2] + ϵ]) - Φ(p)) / ϵ)
ξ(Φ, p) = vect(dΦ(p)) * vect(ξ(p))
