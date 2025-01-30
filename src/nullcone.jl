export maketwosphere
export makesphere
export makespheretminusz
export makestereographicprojectionplane
export makeflagplane
export makeplane
export projectontoplane
export constructtorus
export constructsphere


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
function makeplane(u::𝕍, v::𝕍, M::Matrix{Float64}; segments::Int = 60)
    lspace = range(-1.0, stop = 1.0, length = segments)
    [project(M * normalize(ℍ((f * u + s * v).a))) for f in lspace, s in lspace]
end


"""
    constructtorus(q, r, R)

Construct a torus of revolution with the given configuration `q`, the smaller radius `r`
and the bigger radius `R`.
"""
function constructtorus(q::Dualquaternion,
                        r::Real,
                        R::Real;
                        segments::Int = 36)
    array = Array{ℝ³,2}(undef, segments, segments)
    for i in 1:segments
        for j in 1:segments
            ϕ = i * 2pi / (segments - 1)
            θ = j * 2pi / (segments - 1)
            x₁ = (R + r * cos(ϕ)) * cos(θ)
            x₂ = (R + r * cos(ϕ)) * sin(θ)
            x₃ = r * sin(ϕ)
            array[i, j] = ℝ³(x₁, x₂, x₃)
        end
    end
    map(x -> x + gettranslation(q), rotate(array, getrotation(q)))
end


"""
    constructsphere(q, radius)

Construct a sphere with the given configuration `q` and `radius`.
"""
function constructsphere(q::Dualquaternion,
                         radius::Real;
                         segments::Int = 36)
    array = Array{ℝ³,2}(undef, segments, segments)
    lspace = collect(range(float(-pi), stop = float(pi), length = segments))
    lspace1 = collect(range(float(π / 2), stop = float(-π / 2), length = segments))
    for i in 1:segments
        for j in 1:segments
            ϕ = lspace[i]
            θ = lspace1[j]
            array[j, i] = convert_to_cartesian([radius; θ; ϕ])
        end
    end
    map(x -> x + gettranslation(q), rotate(array, getrotation(q)))
end


"""
    calculatebasisvectors(κ, ω)

Calculate an orthonormal set of basis vectors with the given spin-vectors `κ` and `ω`.
"""
function calculatebasisvectors(κ::SpinVector, ω::SpinVector)
    κv = 𝕍( κ)
    ωv = 𝕍( ω)
    zero = 𝕍( 0.0, 0.0, 0.0, 0.0)
    B = stack([vec(κv), vec(ωv), vec(zero), vec(zero)])
    N = LinearAlgebra.nullspace(B)
    a = 𝕍(N[begin:end, 1])
    b = 𝕍(N[begin:end, 2])
    a = 𝕍(LinearAlgebra.normalize(vec(a - κv - ωv)))
    b = 𝕍(LinearAlgebra.normalize(vec(b - κv - ωv)))
    v₁ = ℝ⁴(κv)
    v₂ = ℝ⁴(ωv)
    v₃ = ℝ⁴(a)
    v₄ = ℝ⁴(b)
    e₁ = v₁
    ê₁ = normalize(e₁)
    e₂ = v₂ - dot(ê₁, v₂) * ê₁
    ê₂ = normalize(e₂)
    e₃ = v₃ - dot(ê₁, v₃) * ê₁ - dot(ê₂, v₃) * ê₂
    ê₃ = normalize(e₃)
    e₄ = v₄ - dot(ê₁, v₄) * ê₁ - dot(ê₂, v₄) * ê₂ - dot(ê₃, v₄) * ê₃
    ê₄ = normalize(e₄)
    ê₁, ê₂, ê₃, ê₄
end


"""
    calculatetransformation(z₁, z₂, z₃, w₁, w₂, w₃)

Calculate the bilinear transformation that takes the given three points `z₁`, `z₂` and `z₃` to three points `w₁`, `w₂` and `w₃`.
"""
function calculatetransformation(z₁::Complex, z₂::Complex, z₃::Complex, w₁::Complex, w₂::Complex, w₃::Complex)
    f(z::Complex) = begin
        A = (w₁ - w₂) * (z - z₂) * (z₁ - z₃)
        B = (w₁ - w₃) * (z₁ - z₂) * (z - z₃)
        (w₃ * A - w₂ * B) / (A - B)
    end
end