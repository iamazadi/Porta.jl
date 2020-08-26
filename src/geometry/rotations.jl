export rotate
export getrotation


rotate(g::Quaternion, q::Quaternion) = g * q
rotate(p::ℝ³, q::Quaternion) = ℝ³(vec(q * Quaternion([0; vec(p)]) * conj(q))[2:4])
rotate(p::Array{ℝ³}, q::Quaternion) = map(x -> rotate(x, q), p)
getrotation(i::ℝ³, n::ℝ³) = begin
    if isapprox(i, n)
        return Quaternion(0, normalize(i))
    end
    u = normalize(cross(i, n))
    θ = acos(dot(normalize(i), normalize(n)))
    Quaternion(θ, u)
end
