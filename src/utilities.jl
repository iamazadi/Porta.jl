import GeometryBasics
import GLMakie.Quaternion
import GLMakie.Point3f
import GLMakie.Vec3f
export convert_hsvtorgb
export project
export projectnocompression
export updatecamera!
export gettextrotation
export maketwosphere
export makesphere
export makespheretminusz
export makestereographicprojectionplane
export makeflagplane
export makeplane
export projectontoplane
export constructtorus
export constructsphere
export calculatebasisvectors
export calculatetransformation
export make_sprite
export parsetext


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
    projectnocompression(q)

Take the given point `q` ∈ S³ ⊂ ℂ² into the Euclidean space E³ ⊂ ℝ³ using stereographic projection.
"""
function projectnocompression(q::ℍ)
    if isapprox(norm(q), 0.0)
        return ℝ³(0.0, 0.0, 0.0)
    elseif isapprox(q, ℍ(1.0, 0.0, 0.0, 0.0))
        return ℝ³(0.0, 0.0, 1.0)
    else
        ℝ³(vec(q)[2], vec(q)[3], vec(q)[4]) * (1.0 / (1.0 - vec(q)[1]))
    end
end


"""
    project(q)

Take the given point `q` ∈ S³ ⊂ ℂ² into the Euclidean space E³ ⊂ ℝ³ using stereographic projection,
and then compress it into a closed 3-ball.
"""
function project(q::ℍ)
    v = projectnocompression(q)
    return normalize(v) * tanh(norm(v))
end


project(q::ℝ⁴) = project(ℍ(q))


projectnocompression(q::ℝ⁴) = projectnocompression(ℍ(q))


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
    updatecamera!(lscene, eyeposition, lookat, up)

Update the camera of `lscene` with `eyeposition`, `lookat` and `up` vectors in order to change its viewport.
"""
updatecamera!(lscene::GLMakie.LScene, eyeposition::ℝ³, lookat::ℝ³, up::ℝ³) = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition), GLMakie.Vec3f(lookat), GLMakie.Vec3f(up))
end


"""
    gettextrotation(scene)

Calculate the orientation of the camera of the given `scene` for rotating text in an automatic way.
"""
gettextrotation(scene::GLMakie.LScene) = begin
    eyeposition_observable = scene.scene.camera.eyeposition
    lookat_observable = scene.scene.camera.lookat
    rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.(vec($eyeposition_observable - $lookat_observable))...)))
    rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
    GLMakie.@lift(GLMakie.Quaternion(ℍ($rotationangle, $rotationaxis) * ℍ(getrotation(ℝ³(0.0, 0.0, 1.0), $rotationaxis)...)))
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


function makestereographicprojectionplane(M::Matrix{Float64}; T::Float64 = 1.0, segments::Int = 60)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = (π / 2), length = segments)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    surface = map(x -> 𝕍(M * vec(𝕍(SpinVector( 𝕍(T, vec(sign(T) * √abs(T) * x)...))))), sphere)
    surface = map(x -> 𝕍(vec(x)[1], vec(x)[2] / (1.0 - vec(x)[4]), vec(x)[3] / (1.0 - vec(x)[4]) , 0.0), surface)
    return map(x -> ℝ³(vec(x)[2], vec(x)[3], 0.0), surface)
end


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


"""
    find_centerofmass(stl)

Calculate the center of mass of a three-dimensional object with the given `stl` data.
"""
find_centerofmass(stl) = begin
    center_of_mass = [0.0; 0.0; 0.0]
    points_number = 0
    for tri in stl
        for point in tri
            center_of_mass = center_of_mass + point
            points_number += 1
        end
    end
    center_of_mass .* (1.0 / points_number)
end


"""
    make_sprite(scene, parent, origin, rotation, scale, stl, colormap)

Instantiate a visual object in the `scene` with the given `parent` object,
`origin` position, `rotation`, `scale`, `stl` object 3D file and `colormap`.
"""
make_sprite(scene, parent, origin, rotation, scale, stl, colormap) = begin
    center_of_mass = find_centerofmass(stl)
    # Create a child transformation from the parent
    child = GLMakie.Transformation(parent)
    # get the transformation of the parent
    ptrans = Makie.transformation(parent)

    # center the mesh to its origin, if we have one
    if !isnothing(origin)
        GLMakie.rotate!(child, rotation)
        GLMakie.scale!(child, scale, scale, scale)
        centered = stl.position .- GLMakie.Point3f(center_of_mass...)
        stl = GeometryBasics.Mesh(GeometryBasics.meta(centered; normals=stl.normals), GeometryBasics.faces(stl))
        GLMakie.translate!(child, origin) # translates the visual mesh in the viewport
    else
        # if we don't have an origin, we need to correct for the parents translation
        GLMakie.translate!(child, -ptrans.translation[])
    end
    # plot the part with transformation & color
    GLMakie.mesh!(scene, stl; color = [tri[1][2] for tri in stl for i in 1:3], colormap = colormap, transformation = child)
end


"""
    parsescalar(text, beginninglabel, endinglabel)

Parse a scalar value that begins with `beginninglabel` and ends with `endinglabel`, with the given `text` string.
"""
parsescalar(text::String, beginninglabel::String, endinglabel::String; type::DataType = Int) = begin
    scalar = Nothing
    index = findfirst(beginninglabel, text)
    if !isnothing(index)
        _text = replace(text, text[begin:index[end]] => "")
        if length(_text) > 1
            index = findfirst(endinglabel, _text)
            if !isnothing(index)
                _text = replace(_text, _text[index[begin]:end] => "")
                if length(_text) > 0
                    _text = strip(_text)
                    try
                        scalar = parse(type, _text)
                    catch e
                        println("Not parsed: $_text. $e")
                    end
                end
            end
        end
    end
    scalar
end


"""
    parse3vector(text, beginninglabel, endinglabel, delimiter)

Parse a vector of real numbers with the given `text`, which begins with `beginninglabel` and ends with `endinglabel`,
and the three elements of the vector are separated with `delimiter`.
"""
parse3vector(text::String, beginninglabel::String, endinglabel::String, delimiter::String) = begin
    vector = []
    index = findfirst(beginninglabel, text)
    if !isnothing(index)
        _text = replace(text, text[begin:index[end]] => "")
        if length(_text) > 3
            index = findfirst(endinglabel, _text)
            if !isnothing(index)
                _text = replace(_text, _text[index[begin]:end] => "")
                if length(_text) > 3
                    _text = strip(_text)
                    items = split(_text, delimiter)
                    try
                        push!(vector, parse(Float64, items[1]))
                        push!(vector, parse(Float64, items[2]))
                        push!(vector, parse(Float64, items[3]))
                    catch e
                        println("Not parsed: $_text. $e")
                    end
                end
            end
        end
    end
    vector
end


"""
    parsetext(text)

Parse the values of robot telemetry with the given `text`.
"""
parsetext(text::String) = begin
    readings = Dict()
    if length(text) > 30
        scalar = parsescalar(text, "roll: ", ", ", type = Float64)
        if !isnothing(scalar)
            readings["roll"] = scalar
        end
        scalar = parsescalar(text, "pitch: ", ", ", type = Float64)
        if !isnothing(scalar)
            readings["pitch"] = scalar
        end
        scalar = parsescalar(text, "v1: ", ", ", type = Float64)
        if !isnothing(scalar)
            readings["v1"] = scalar
        end
        scalar = parsescalar(text, "v2: ", ", ", type = Float64)
        if !isnothing(scalar)
            readings["v2"] = scalar
        end
    end
    readings
end