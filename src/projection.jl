export project
export projectnocompression


"""
    project(q)

Take the given point `q` ∈ S³ ⊂ ℂ² into the Euclidean space E³ ⊂ ℝ³ using the stereographic projection,
and then compress it into a closed 3-ball.
"""
function project(q::ℍ)
    v = projectnocompression(q)
    return normalize(v) * tanh(norm(v))
end


project(q::ℝ⁴) = project(ℍ(q))


"""
    projectnocompression(q)

Take the given point `q` ∈ S³ ⊂ ℂ² into the Euclidean space E³ ⊂ ℝ³ using the stereographic projection.
"""
function projectnocompression(q::ℍ)
    if isapprox(norm(q), 0.0)
        return ℝ³(0.0, 0.0, 0.0)
    elseif isapprox(q, ℍ(1.0, 0.0, 0.0, 0.0))
        return ℝ³(0.0, 0.0, 1.0)
    else
        ℝ³(vec(q)[2], vec(q)[3], vec(q)[4]) * (1.0 / (1.0 - vec(q)[1]))
    end
end


projectnocompression(q::ℝ⁴) = projectnocompression(ℍ(q))


"""
    project(p)

Project the given point `p` ∈ S² onto the Argand plane using the stereographic projection.
"""
project(p::ℝ³) = ℝ³(vec(p)[1], vec(p)[2], 0.0) * (1.0 / (1.0 - vec(p)[3]))