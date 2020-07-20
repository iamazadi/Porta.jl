export outer
export cross


outer(a::Vector{Float64}, b::Vector{Float64}) = a * transpose(b)
cross(a::Vector{Float64}, b::Vector{Float64}) = begin
    M = convert(Array{Float64}, transpose(reshape([a; a; b], :, length(a))))
    map(x -> cofactor(M, 1, x), 1:length(a))
end
