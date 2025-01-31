export maketwosphere
export makesphere
export makespheretminusz
export makestereographicprojectionplane
export makeflagplane
export projectontoplane


"""
    maketwosphere(origin)

Make a 2-sphere as a matrix of 3D points with the given `origin` as the center point.
"""
function maketwosphere(origin::ℝ³; segments::Int = 30)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    [origin + convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
end


"""
    makesphere(transformation, T)

Make a cross-section of the null cone with the given spin `transformation` and temporal section `T`.
"""
function makesphere(transformation::SpinTransformation, T::Float64; compressedprojection::Bool = true, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    if isapprox(T, 0.0)
        surface = map(x -> 𝕍(T, vec(x)...), sphere)
    else
        surface = map(x -> 𝕍(T, vec(sign(T) * √abs(T) * x)...), sphere)
    end
    surface = map(x -> 𝕍(transformation * SpinVector(x)), surface)
    projectionmap = compressedprojection ? project : projectnocompression
    return map(x -> projectionmap(normalize(ℍ(vec(x)))), surface)
end


"""
    makesphere(transformation, T)

Make a cross-section of the null cone as aclosed 2-surface with the given spin `transformation` and temporal section `T`.
"""
function makesphere(transformation::Any, T::Float64; compressedprojection::Bool = true, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2 * 0.99, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    timesign = T ≥ 0 ? 1 : -1
    if isapprox(T, 0.0)
        surface = map(x -> 𝕍(T, vec(x)...), sphere)
    else
        surface = map(x -> 𝕍(T, vec(sign(T) * √abs(T) * x)...), sphere)
    end
    surface = map(x -> 𝕍(SpinVector(transformation(Complex(SpinVector(x))), timesign)), surface)
    projectionmap = compressedprojection ? project : projectnocompression
    return map(x -> projectionmap(normalize(ℍ(vec(x)))), surface)
end


"""
    makesphere(M, T)

Make a cross-section of the null cone as aclosed 2-surface with the given transformation M and temporal section `T`.
"""
function makesphere(M::ℍ, T::Float64; compressedprojection::Bool = true, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    if isapprox(T, 0.0)
        surface = map(x -> 𝕍(T, vec(x)...), sphere)
    else
        surface = map(x -> 𝕍(T, vec(sign(T) * √abs(T) * x)...), sphere)
    end
    projectionmap = compressedprojection ? project : projectnocompression
    return map(x -> projectionmap(M * normalize(ℍ(vec(x)))), surface)
end


"""
    makesphere(a, b, T)

Make a closed 2-surface in Minkowski vector space at constant time `T` (a section of the null cone),
and rotate the Minkowski tetrad with the given unit quaternions `a` and `b`, which represent an element of SO(4).
"""
function makesphere(a::ℍ, b::ℍ, T::Float64; compressedprojection::Bool = true, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    if isapprox(T, 0.0)
        surface = map(x -> 𝕍(T, vec(x)...), sphere)
    else
        surface = map(x -> 𝕍(T, vec(sign(T) * √abs(T) * x)...), sphere)
    end
    projectionmap = compressedprojection ? project : projectnocompression
    return map(x -> projectionmap(a * normalize(ℍ(vec(x))) * b), surface)
end


"""
    makesphere(M, T)

Make a closed 2-surface in Minkowski vector space at constant time `T` (a section of the null cone),
and rotate the Minkowski tetrad with the given transformation `M`, which represents an element of SO(4).
"""
function makesphere(M::Matrix{Float64}, T::Float64; compressedprojection::Bool = true, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    if isapprox(T, 0.0)
        surface = map(x -> 𝕍(T, vec(x)...), sphere)
    else
        surface = map(x -> 𝕍(T, vec(sign(T) * √abs(T) * x)...), sphere)
    end
    projectionmap = compressedprojection ? project : projectnocompression
    return map(x -> projectionmap(M * normalize(ℍ(vec(x)))), surface)
end


"""
    makesphere(transformation, T)

Make a closed 2-surface in Minkowski vector space at constant time `T` (a section of the null cone),
and rotate the Minkowski tetrad with the given spin `transformation`.
"""
function makespheretminusz(transformation::SpinTransformation; T::Float64 = 1.0, compressedprojection::Bool = true, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    surface = map(x -> 𝕍(transformation * SpinVector( 𝕍(T, vec(sign(T) * √abs(T) * x)...))), sphere)
    surface = map(x -> 𝕍(vec(x) .* (1.0 / (1.0 - vec(x)[4]))) , surface)
    projectionmap = compressedprojection ? project : projectnocompression
    return map(x -> projectionmap(ℍ(vec(x))), surface)
end


"""
    makestereographicprojectionplane(transformation)

Transform the cross-section of the null cone corresponding to T = 1 with the given spin `transformation`,
such that it is equivalent to the stereographic projection.
"""
function makestereographicprojectionplane(transformation::SpinTransformation; T::Float64 = 1.0, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = (π / 2), length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    surface = map(x -> 𝕍(transformation * SpinVector( 𝕍(T, vec(sign(T) * √abs(T) * x)...))), sphere)
    surface = map(x -> 𝕍(vec(x)[1], vec(x)[2] / (1.0 - vec(x)[4]), vec(x)[3] / (1.0 - vec(x)[4]) , 0.0), surface)
    return map(x -> ℝ³(vec(x)[2], vec(x)[3], 0.0), surface)
end


"""
    makestereographicprojectionplane(M)

Transform the cross-section of the null cone corresponding to T = 1 with the given transformation matrix `M`,
such that it is equivalent to the stereographic projection.
"""
function makestereographicprojectionplane(M::Matrix{Float64}; T::Float64 = 1.0, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = (π / 2), length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    surface = map(x -> 𝕍(M * vec(𝕍(SpinVector( 𝕍(T, vec(sign(T) * √abs(T) * x)...))))), sphere)
    surface = map(x -> 𝕍(vec(x)[1], vec(x)[2] / (1.0 - vec(x)[4]), vec(x)[3] / (1.0 - vec(x)[4]) , 0.0), surface)
    return map(x -> ℝ³(vec(x)[2], vec(x)[3], 0.0), surface)
end


"""
    makestereographicprojectionplane(M)

Transform the cross-section of the null cone corresponding to T = 1 with the given transformation number `M`,
such that it is equivalent to the stereographic projection.
"""
function makestereographicprojectionplane(M::ℍ; T::Float64 = 1.0, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = (π / 2), length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    surface = map(x -> 𝕍(vec(M * ℍ(vec(𝕍(SpinVector( 𝕍(T, vec(sign(T) * √abs(T) * x)...))))))), sphere)
    surface = map(x -> 𝕍(vec(x)[1], vec(x)[2] / (1.0 - vec(x)[4]), vec(x)[3] / (1.0 - vec(x)[4]) , 0.0), surface)
    return map(x -> ℝ³(vec(x)[2], vec(x)[3], 0.0), surface)
end


"""
    projectontoplane(x)

Project the given 4-vector `x` onto a cross-section of the null cone such that it is equivalent to the stereographic projection.
"""
function projectontoplane(x::𝕍)
    v = 𝕍(vec(x)[1], vec(x)[2] / (1.0 - vec(x)[4]), vec(x)[3] / (1.0 - vec(x)[4]) , 0.0)
    ℝ³(vec(v)[2], vec(v)[3], 0.0)
end


"""
    makeflagplane(u, v, T)

Make a half plane with the given 4-vectors `u`, `v` and temporal section `T`.
"""
function makeflagplane(u::𝕍, v::𝕍, T::Float64; compressedprojection::Bool = true, segments::Int = 60)
    lspace1 = range(min(-T, T), stop = max(-T, T), length = segments)
    lspace2 = range(0.0, stop = T, length = segments)
    matrix = [f * u + s * v for f in lspace1, s in lspace2]
    projectionmap = compressedprojection ? project : projectnocompression
    map(x -> projectionmap(normalize(ℍ(vec(x)))), matrix)
end


"""
    makeflagplane(u, v, M)

Make a half plane with the given 4-vectors `u`, `v` and the transformation of the inertial frame `M`.
"""
function makeflagplane(u::𝕍, v::𝕍, M::Matrix{Float64}; segments::Int = 60)
    lspace = range(-1.0, stop = 1.0, length = segments)
    [project(M * normalize(ℍ((f * u + s * v).a))) for f in lspace, s in lspace]
end