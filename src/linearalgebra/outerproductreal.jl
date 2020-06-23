export outer
export cross


outer(a::Vector{Float64}, b::Vector{Float64}) = a * transpose(b)
cross(a::Vector{Float64}, b::Vector{Float64}) = begin
    M = convert(Array{Float64}, transpose(reshape([a; a; b], :, length(a))))
    [cofactor(M, 1, i) for i in 1:length(a)]
end
