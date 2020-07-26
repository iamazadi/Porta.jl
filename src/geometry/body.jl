export getsprite
export getplane
export getdisk


getsprite(p::ℝ³, q::Quaternion; len=1.0) = begin
    map(x -> x + p, rotate(ℝ³.([[0.0; 0.0; 0.0], [len; 0.0; 0.0],
                                [0.0; 0.0; 0.0], [0.0; len; 0.0],
                                [0.0; 0.0; 0.0], [0.0; 0.0; len]]), q))
end


getplane(p::Array{Float64}, q::Quaternion, s::Array{Float64}) = begin
    plane = Array{Float64,3}(undef, 2, 2, 3)
    plane[1, 1, :] = vec(rotate(ℝ³([0.0; -1.0; 1.0]), q)) .* s + p
    plane[1, 2, :] = vec(rotate(ℝ³([0.0; 1.0; 1.0]), q)) .* s + p
    plane[2, 1, :] = vec(rotate(ℝ³([0.0; -1.0; -1.0]), q)) .* s + p
    plane[2, 2, :] = vec(rotate(ℝ³([0.0; 1.0; -1.0]), q)) .* s + p
    plane
end
