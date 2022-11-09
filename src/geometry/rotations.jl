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
    u = normalize(cross(i, n))
    θ = acos(dot(normalize(i), normalize(n))) / 2
    Quaternion(-θ, u)
end
getrotation(q::Quaternion, h::Quaternion) = begin
    @assert(isapprox(norm(q), 1), "The first point must be in S². $q")
    @assert(isapprox(norm(h), 1), "The second point also must be in S². $h")
    if isapprox(q, h)
        return Quaternion(1, 0, 0, 0)
    end
    s = conj(q) * h
    Quaternion(-acos(vec(s)[1]) / 2, normalize(ℝ³(vec(s)[2:4])))
end


"""
    applyconfig(p, q)

Apply a rigid body transformation in 3-space with the given array of points `p` and
configuration `q`.
"""
function applyconfig(p::Array{ℝ³}, q::Biquaternion)
    map(x -> x + gettranslation(q), rotate(p, getrotation(q)))
end
