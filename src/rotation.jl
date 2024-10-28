export getrotation
export rotate


"""
    getrotation(i, n)

Calculate the rotation axis and angle required to rotate vector `i` such that it becomes 'n' after the rotation.
"""
getrotation(i::ℝ³, n::ℝ³) = begin
    if isapprox(normalize(i), normalize(n))
        return 0, normalize(i)
    end
    u = normalize(cross(i, n))
    ang = acos(dot(normalize(i), normalize(n)))
    ang, u
end


rotate(g::ℍ, q::ℍ) = g * q
rotate(M::Matrix{<:Complex}, q::ℍ) = ℍ(M * mat(q))
rotate(p::ℝ³, q::ℍ) = ℝ³(vec(q * ℍ([0; vec(p)]) * conj(q))[2:4])
rotate(p::Matrix{ℝ³}, q::ℍ) = map(x -> rotate(x, q), p)