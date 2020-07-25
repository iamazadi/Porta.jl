export getsprite
export getplane
export getdisk


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


"""
   getdisk(position, orientation, radialoffset, angularoffset, scale, segments)

Calculate a disk shape in ℝ³ space with the given `position`, `orientation`, `scale`,
`radialoffset`, `angularoffset` and `segments`.
"""
getdisk(radius::Real,
        position::ℝ³,
        orientation::ℍ,
        radialoffset::Real=0,
        angularoffset::Real=0,
        scale::Real=1,
        segments::Int=30) = begin
    disk = Array{ℝ³}(undef, segments, segments)
    ϕ = collect(range(-float(pi), stop = float(pi), length = segments))
    θ = collect(range(-float(pi/2), stop = float(pi/2), length = segments))
    x = radialoffset * cos(angularoffset)
    y = radialoffset * sin(angularoffset)
    for i in 1:segments
        for j in 1:segments
            r = sqrt((1 - sin(θ[j])) / 2)
            y₁ = r * cos(ϕ[i] + angularoffset)
            y₂ = r * sin(ϕ[i] + angularoffset)
            y₃ = sqrt((1 + sin(θ[j])) / 2)
            initialposition = ℝ³([y₁; y₂; y₃])
            disk[i, j] = rotate(initialposition, orientation)
        end
    end
    disk
end
