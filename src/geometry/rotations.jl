export rotate
export getrotation


rotate(g::Quaternion, q::Quaternion) = g * q
rotate(p::ℝ³, q::Quaternion) = begin
    s = adjoint(SU2(q)) * SU2(Quaternion([0; vec(p)])) * SU2(q)
    ℝ³(vec(Quaternion(s))[2:4])
end
rotate(p::Array{ℝ³}, q::Quaternion) = [rotate(point, q) for point in p]
getrotation(i::ℝ³, n::ℝ³) = begin
    u = normalize(cross(i, n))
    θ = acos(dot(normalize(i), normalize(n))) / 2
    Quaternion([cos(θ); vec(sin(θ) * u)])
end
