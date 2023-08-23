using LinearAlgebra


export getrotation


"""
    getrotation(i, n)

Calculate the rotation axis and angle required to rotate vector `i` such that it becomes 'n' after the rotation.
"""
getrotation(i::Vector{Float64}, n::Vector{Float64}) = begin
    if isapprox(normalize(i), normalize(n))
        return 0, normalize(i)
    end
    u = normalize(cross(i, n))
    ang = acos(dot(normalize(i), normalize(n)))
    ang, u
end