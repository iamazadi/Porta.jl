export dΦ
export dΦξ


const ϵ = 1e-7


dΦ(Φ, p) = Φ(p .+ ϵ) - Φ(p)
dΦξ(Φ, v, p) = dot(dΦ(Φ, p), v)
