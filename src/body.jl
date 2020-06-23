export getsprite
export getplane


getsprite(p::ℝ³, h::ℍ; len=1.0) = begin
    map(x -> x + p, rotate(ℝ³.([[0.0; 0.0; 0.0], [len; 0.0; 0.0],
                                [0.0; 0.0; 0.0], [0.0; len; 0.0],
                                [0.0; 0.0; 0.0], [0.0; 0.0; len]]), h))
end


getplane(p::Array{Float64}, h::ℍ, s::Array{Float64}) = begin
    plane = Array{Float64,3}(undef, 2, 2, 3)
    plane[1, 1, :] = vec(rotate(ℝ³([0.0; -1.0; 1.0]), h)) .* s + p
    plane[1, 2, :] = vec(rotate(ℝ³([0.0; 1.0; 1.0]), h)) .* s + p
    plane[2, 1, :] = vec(rotate(ℝ³([0.0; -1.0; -1.0]), h)) .* s + p
    plane[2, 2, :] = vec(rotate(ℝ³([0.0; 1.0; -1.0]), h)) .* s + p
    plane
end
