import GLMakie.Quaternion
import GLMakie.Point3f
import GLMakie.Vec3f
export convert_hsvtorgb
export project
export updatecamera
export maketwosphere
export makesphere


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

Make a 2-sphere as a matrix of 3D points.
"""
function maketwosphere(origin::ℝ³)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    [origin + convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
end


"""
    makesphere(M, T)

Make a 2-surface as a section of the null cone with the given transformation `M` and temporal section `T`.
"""
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