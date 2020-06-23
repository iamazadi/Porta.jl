export det
export minor
export cofactor


sub(M::Array{Float64}, i, j) = M[1:end .!= i, 1:end .!= j]
det(a::Array{Float64}) = begin
    if size(a) == (2, 2)
        a[1, 1] * a[2, 2] - a[1, 2] * a[2, 1]
    else
        sum([(-1)^(i+1) * a[i, 1] * det(sub(a, i, 1)) for i in 1:size(a, 1)])
        # performance tip, look for the best row/column choice for expansion.
    end
end
minor(M::Array{Float64}, i, j) = det(sub(M, i, j))
cofactor(M::Array{Float64}, i, j) = minor(M, i, j) * (-1)^(i+j)
