using GLMakie
using FileIO


fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])

chassis_stl_path = joinpath("../data", "unicycle", "unicycle_chassis.STL")
chassis_stl = load(chassis_stl_path)

centerofmass = Porta.find_centerofmass(chassis_stl)
@test length(centerofmass) == 3

chassis_colormap = :rainbow
chassis_rotation = ℍ(π / 2, ℝ³([1.0; 0.0; 0.0]))
chassis_origin = Point3f(-0.1, -0.1, -0.02)
chassis_scale = 0.001
parent = lscene.scene
robot = make_sprite(lscene.scene, parent, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
@test typeof(robot) <: GLMakie.Mesh

parent = chassis_stl
robot = make_sprite(lscene.scene, parent, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
@test typeof(robot) <: GLMakie.Mesh

x1k = string(round(rand(), digits = 2))
x2k = string(round(rand(), digits = 2))
u1k = string(round(rand(), digits = 2))
u2k = string(round(rand(), digits = 2))
headers = ["x1k", "x2k", "u1k", "u2k", "x1k+", "x2k+", "u1k+", "u2k+"]
message = "x1k: $x1k, x2k: $x2k, u1k: $u1k, u2k: $u2k, x1k+: 14.40, x2k+: 0.25, u1k+: 40.00, u2k+: 31.23, dt: 0.000007"

beginninglabel = "x1k: "
endinglabel = ", "
type = Float64
scalar = parsescalar(message, beginninglabel, endinglabel, type = type)
@test typeof(scalar) <: Float64

_beginninglabel = "nothing"
scalar = parsescalar(message, _beginninglabel, endinglabel; type = type)
@test isnothing(scalar)

readings = parsetext(message, headers)
@test typeof(readings) <: Dict

@test all([x in keys(readings) for x in headers])
@test all([!isnothing(readings[x]) for x in headers])