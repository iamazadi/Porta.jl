export normalize


normalize(v::Vector{Float64}) = v ./ norm(v)
normalize(r::ℝ³) = 1 / norm(r) * r
normalize(h::ℍ) = 1 / norm(h) * h
