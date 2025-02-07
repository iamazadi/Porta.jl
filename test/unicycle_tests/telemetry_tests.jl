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

roll = string(round(rand(), digits = 2))
pitch = string(round(rand(), digits = 2))
rolling_ctrl_output = string(round(rand(), digits = 2))
reaction_ctrl_output = string(round(rand(), digits = 2))
dt = string(round(rand(), digits = 6))
keywords = ["roll", "pitch", "v1", "v2"]
message = "roll: $roll, pitch: $pitch, v1: $reaction_ctrl_output, v2: $rolling_ctrl_output, dt: $dt\r\n"

beginninglabel = "roll: "
endinglabel = ", "
type = Float64
scalar = parsescalar(message, beginninglabel, endinglabel, type = type)
@test typeof(scalar) <: Float64

_beginninglabel = "nothing"
scalar = parsescalar(message, _beginninglabel, endinglabel; type = type)
@test isnothing(scalar)

readings = parsetext(message)
@test typeof(readings) <: Dict

@test all([x in keys(readings) for x in keywords])
@test all([!isnothing(readings[x]) for x in keywords])