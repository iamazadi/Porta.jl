export dot
export norm
export I


I(v::Vector{Float64}) = reshape([Float64(i == j) for i in 1:length(v) for j in 1:length(v)],
                                length(v), length(v))
# dot product with a given metric
dot(a::Vector{Float64}, b::Vector{Float64}, M::Array{Float64}) = transpose(a) * M * b
dot(a::Vector{Float64}, b::Vector{Float64}) = dot(a, b, I(a))
norm(a::Vector{Float64}) = sqrt(dot(a, a))
