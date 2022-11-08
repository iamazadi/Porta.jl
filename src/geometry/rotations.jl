export rotate
export getrotation
export applyconfig


rotate(g::Quaternion, q::Quaternion) = g * q
rotate(M::Array{<:Complex,2}, q::ComplexPlane) = ComplexPlane(M * vec(q))
rotate(p::ℝ³, q::Quaternion) = ℝ³(vec(q * Quaternion([0; vec(p)]) * conj(q))[2:4])
rotate(p::Array{ℝ³}, q::Quaternion) = map(x -> rotate(x, q), p)
getrotation(i::ℝ³, n::ℝ³) = begin
    if isapprox(normalize(i), normalize(n))
        return Quaternion(0, normalize(i))
    end
    u = normalize(cross(n, i))
    θ = acos(dot(normalize(i), normalize(n))) / 2
    Quaternion(θ, u)
end


"""
    applyconfig(p, q)

Apply a rigid body transformation in 3-space with the given array of points `p` and
configuration `q`.
"""
function applyconfig(p::Array{ℝ³}, q::Biquaternion)
    map(x -> x + gettranslation(q), rotate(p, getrotation(q)))
end
