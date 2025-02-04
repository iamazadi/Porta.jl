import GLMakie


export convert_hsvtorgb
export updatecamera!
export gettextrotation
export resetcamera
export rotatecamera


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
    updatecamera!(lscene, eyeposition, lookat, up)

Update the camera of `lscene` with `eyeposition`, `lookat` and `up` vectors in order to change its viewport.
"""
updatecamera!(lscene::GLMakie.LScene, eyeposition::ℝ³, lookat::ℝ³, up::ℝ³) = begin
    update_cam!(lscene.scene, Vec3f(eyeposition), Vec3f(lookat), Vec3f(up))
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
    rotatecamera(step, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes)

Resets the eyeposition, look at and up vactors of cameras caused by creating objects in the scene,
with the given `step` which determines the rotation degree.
"""
function rotatecamera(step::Float64, eyeposition::ℝ³, eyepositionn::ℝ³, eyepositions::ℝ³,
    lookat::ℝ³, lookatn::ℝ³, lookats::ℝ³, up::ℝ³, lscene::GLMakie.LScene, lscenen::GLMakie.LScene, lscenes::GLMakie.LScene)
    q = ℍ(step * 2π, ℝ³(0.0, 0.0, 1.0))
    updatecamera!(lscene, rotate(eyeposition, q), lookat, up)
    updatecamera!(lscenen, rotate(eyepositionn, q), lookatn, up)
    updatecamera!(lscenes, rotate(eyepositions, q), lookats, up)
    "Rotate the camera about the ẑ axis."
end


"""
    resetcamera(lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)

Resets the eyeposition, look at and up vactors of cameras (caused by creating objects in the scene.)
"""
function resetcamera(lscene::GLMakie.LScene, lscenen::GLMakie.LScene, lscenes::GLMakie.LScene,
    eyeposition::ℝ³, eyepositionn::ℝ³, eyepositions::ℝ³, lookat::ℝ³, lookatn::ℝ³, lookats::ℝ³, up::ℝ³)
    updatecamera!(lscene, eyeposition, lookat, up)
    updatecamera!(lscenen, eyeposition, lookat, up)
    updatecamera!(lscenes, eyeposition, lookat, up)
    "Reset 'the eyeposition', 'look at' and 'up' vactors of cameras."
end