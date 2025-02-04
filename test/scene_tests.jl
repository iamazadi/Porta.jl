using GLMakie

hue = rand() * 359.0
saturation = rand()
brightness = rand()
hsv = [hue; saturation; brightness]
rgb = convert_hsvtorgb(hsv)

@test typeof(rgb) <: Vector
@test all([0.0 ≤ x ≤ 1.0 for x in rgb])


eyeposition = ℝ³(rand(3))
lookat = ℝ³(0.0, 0.0, 0.0)
up = ℝ³(0.0, 0.0, 1.0)
fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])
updatecamera!(lscene, eyeposition, lookat, up)


q = gettextrotation(lscene)
@test typeof(q) <: Observable{Quaternion{Float64}}


## test resetcamera
fig = Figure()
lscene = LScene(fig[1:8, 1:2])
lscenen = LScene(fig[1:2, 3])
lscenes = LScene(fig[3:4, 3])
eyeposition = ℝ³(Float64.(vec(lscene.scene.camera.eyeposition[]))...)
eyepositionn = ℝ³(Float64.(vec(lscenen.scene.camera.eyeposition[]))...)
eyepositions = ℝ³(Float64.(vec(lscenes.scene.camera.eyeposition[]))...)
lookat = ℝ³(0.0, 0.0, 0.0)
lookatn = ℝ³(0.0, 0.0, 0.0)
lookats = ℝ³(0.0, 0.0, 0.0)
up = ℝ³(0.0, 0.0, 1.0)
message = resetcamera(lscene, lscenen, lscenes, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up)
@test typeof(message) <: String


## test rotatecamera
timestep = rand()
message = rotatecamera(timestep, eyeposition, eyepositionn, eyepositions, lookat, lookatn, lookats, up, lscene, lscenen, lscenes)
@test typeof(message) <: String