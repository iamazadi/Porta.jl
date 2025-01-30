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