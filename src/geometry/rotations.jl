export rotate
export getrotation


# second generation constructors


ℍ(θ::Number, u::ℝ³) = ℍ([cos(θ); vec(sin(θ) * u)])
ℍ(r::ℝ³) = ℍ([cos(vec(r)[1]); vec(sin(vec(r)[1]) * ℝ³(1, 0, 0))]) *
           ℍ([cos(vec(r)[2]); vec(sin(vec(r)[2]) * ℝ³(0, 1, 0))]) *
           ℍ([cos(vec(r)[3]); vec(sin(vec(r)[3]) * ℝ³(0, 0, 1))]) # Euler angles


# rotations


rotate(g::ℍ, h::ℍ) = g * h
rotate(p::ℝ³, h::ℍ) = ℝ³(vec(adjoint(h) * ℍ([0; vec(p)]) * h)[2:4])
rotate(p::Array{ℝ³}, h::ℍ) = [rotate(point, h) for point in p]
getrotation(i, n) = begin
    u = normalize(cross(i, n))
    θ = acos(dot(normalize(i), normalize(n))) / 2
    ℍ([cos(θ); sin(θ) .* u])
end
