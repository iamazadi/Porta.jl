outer(a::ℝ³, b::ℝ³) = outer(vec(a), vec(b))
cross(a::ℝ³, b::ℝ³) = ℝ³(cross(vec(a), vec(b)))
