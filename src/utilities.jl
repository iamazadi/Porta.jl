import GLMakie.Quaternion
import GLMakie.Point3f
import GLMakie.Vec3f
export convert_hsvtorgb
export project
export updatecamera
export maketwosphere
export makesphere
export makespheretminusz
export makestereographicprojectionplane
export makeflagplane
export projectontoplane


"""
   hsvtorgb(color)

Convert a `color` from HSV space to RGB.
"""
convert_hsvtorgb(color) = begin
    H, S, V = color
    C = V * S
    X = C * (1 - Base.abs((H / 60) % 2 - 1))
    m = V - C
    if 0 ≤ H < 60
        R′, G′, B′ = C, X, 0
    elseif 60 ≤ H < 120
        R′, G′, B′ = X, C, 0
    elseif 120 ≤ H < 180
        R′, G′, B′ = 0, C, X
    elseif 180 ≤ H < 240
        R′, G′, B′ = 0, X, C
    elseif 240 ≤ H < 300
        R′, G′, B′ = X, 0, C
    elseif 300 ≤ H < 360
        R′, G′, B′ = C, 0, X
    else
        R′, G′, B′ = rand(3)
    end
    R, G, B = R′ + m, G′ + m, B′ + m
    [R; G; B]
end


"""
    project(q)

Take the given point `q` ∈ S³ ⊂ ℂ² into the Euclidean space E³ ⊂ ℝ³ using stereographic projection.
"""
function project(q::ℍ)
    v = ℝ³(vec(q)[2], vec(q)[3], vec(q)[4]) * (1.0 / (1.0 - vec(q)[1]))
    normalize(v) * tanh(norm(v))
end


"""
    project(p)

Project the given point `p` in the 2-sphere onto the Argand plane in a stereographic way.
"""
project(p::ℝ³) = ℝ³(vec(p)[1], vec(p)[2], 0.0) * (1.0 / (1.0 - vec(p)[3]))


"""
    Quaternion(q)

Converts the quaternion number `q` to a quaternion type in Makie for interoperability.
"""
GLMakie.Quaternion(q::ℍ) = GLMakie.Quaternion(vec(q)[2:4]..., vec(q)[1])


ℝ³(p::GLMakie.Point3f) = ℝ³(Float64.(vec(p))...)


"""
    Point3f(v)

Converts a vector in ℝ³ to a three-dimansional point in Makie for interoperability.
"""
GLMakie.Point3f(v::ℝ³) = GLMakie.Point3f(vec(v)...)


"""
    Vec3f(v)

Converts a vector in ℝ³ to a floating point 3-vector in Makie for interoperability.
"""
GLMakie.Vec3f(v::ℝ³) = GLMakie.Vec3f(vec(v)...)


"""
    updatecamera(lscene, eyeposition, lookat, up)

Update the camera of `lscene` with `eyeposition`, `lookat` and `up` vectors in order to change its viewport.
"""
updatecamera(lscene::GLMakie.LScene, eyeposition::ℝ³, lookat::ℝ³, up::ℝ³) = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition), GLMakie.Vec3f(lookat), GLMakie.Vec3f(up))
end


"""
    maketwosphere(origin)

Make a 2-sphere as a matrix of 3D points with the given `origin` as the center point.
"""
function maketwosphere(origin::ℝ³)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    [origin + convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
end


"""
    makesphere(transformation, T)

Make a cross-section of the null cone with the given spin `transformation`` and temporal section `T`.
"""
function makesphere(transformation::SpinTransformation, T::Float64; segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    if isapprox(T, 0.0)
        surface = map(x -> 𝕍(T, vec(x)...), sphere)
    else
        surface = map(x -> 𝕍(T, vec(sign(T) * √abs(T) * x)...), sphere)
    end
    surface = map(x -> 𝕍(transformation * SpinVector(x)), surface)
    return map(x -> project(normalize(ℍ(vec(x)))), surface)
end


function makesphere(M::ℍ, T::Float64; segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    if isapprox(T, 0.0)
        surface = map(x -> 𝕍(T, vec(x)...), sphere)
    else
        surface = map(x -> 𝕍(T, vec(sign(T) * √abs(T) * x)...), sphere)
    end
    return map(x -> project(M * normalize(ℍ(vec(x)))), surface)
end


function makesphere(M::Matrix{Float64}, T::Float64; segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    if isapprox(T, 0.0)
        surface = map(x -> 𝕍(T, vec(x)...), sphere)
    else
        surface = map(x -> 𝕍(T, vec(sign(T) * √abs(T) * x)...), sphere)
    end
    return map(x -> project(M * normalize(ℍ(vec(x)))), surface)
end


function makespheretminusz(transformation::SpinTransformation; T::Float64 = 1.0, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    surface = map(x -> 𝕍(transformation * SpinVector( 𝕍(T, vec(sign(T) * √abs(T) * x)...))), sphere)
    surface = map(x -> 𝕍(vec(x) .* (1.0 / (1.0 - vec(x)[4]))) , surface)
    return map(x -> project(ℍ(vec(x))), surface)
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


function makestereographicprojectionplane(M::Matrix{Float64}; T::Float64 = 1.0, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = (π / 2), length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    surface = map(x -> 𝕍(M * vec(𝕍(SpinVector( 𝕍(T, vec(sign(T) * √abs(T) * x)...))))), sphere)
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
    makeflagplane(u, v)

Make a half plane with the given 4-vectors `u` and `v`.
"""
function makeflagplane(u::𝕍, v::𝕍; segments::Int = 60)
    lspace1 = range(-1.0, stop = 1.0, length = segments)
    lspace2 = range(0.0, stop = 1.0, length = segments)
    matrix = [f * u + s * v for f in lspace1, s in lspace2]
    map(x -> project(normalize(ℍ(vec(x)))), matrix)
end