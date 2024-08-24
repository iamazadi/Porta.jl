import GLMakie
import FileIO
import Makie
import MeshIO
import GeometryBasics
import LinearAlgebra
import GLMakie.Quaternion
using Sockets
using Porta

include(joinpath("models", "utilities.jl"))

figuresize = (1080, 1920)
segments = 30
frames_number = 360

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

eyeposition = LinearAlgebra.normalize([-0.9, 0.3, 0.5]) .* 0.6
lookat = [-0.1, -0.1, 0.1]
up = [0.0; 0.0; 1.0]

# the robot body origin in the inertial frame Ô
origin = GLMakie.Point3f(-0.1, -0.1, -0.02)
# the pivot point B̂ in the inertial frame Ô
pivot = GLMakie.Point3f(-0.097, -0.1, -0.032)
# the position of sensors mounted on the body in the body frame of reference
p1 = GLMakie.Point3f(-0.035, -0.19, -0.04)
p2 = GLMakie.Point3f(0.025, -0.144, -0.07)
p3 = GLMakie.Point3f(-0.11, -0.01, 0.13)
p4 = GLMakie.Point3f(-0.11, -0.19, 0.13)
# the vectors of the standard basis for the input space ℝ³
ê = [GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)]
# The rotation of the inertial frame Ô to the body frame B̂
O_B_R = [ê[1] ê[2] ê[3]]
B_O_R = LinearAlgebra.inv(O_B_R)
# The rotation of the local frame of the sensor i to the robot frame B̂
A1_B_R = [-ê[2] -ê[1] -ê[3]]
A2_B_R = [ê[1] ê[2] ê[3]]
A3_B_R = [-ê[3] ê[1] -ê[2]]
A4_B_R = [-ê[3] -ê[1] ê[2]]
B_A1_R = LinearAlgebra.inv(A1_B_R)
B_A2_R = LinearAlgebra.inv(A2_B_R)
B_A3_R = LinearAlgebra.inv(A3_B_R)
B_A4_R = LinearAlgebra.inv(A4_B_R)

P = [[1.0; vec(p1 - pivot)] [1.0; vec(p2 - pivot)] [1.0; vec(p3 - pivot)] [1.0; vec(p4 - pivot)]]
X = transpose(P) * LinearAlgebra.inv(P * transpose(P))

chassis_scale = 0.001
rollingwheel_scale = 1.0
reactionwheel_scale = 1.0

chassis_origin = deepcopy(origin)
rollingwheel_origin = GLMakie.Point3f(3.0, -12.0, 0.0)
reactionwheel_origin = GLMakie.Point3f(0.0, 153.0, 1.0)

chassis_qx = Porta.Quaternion(π / 2, x̂)
chassis_qy = Porta.Quaternion(0.0, ŷ)
chassis_qz = Porta.Quaternion(0.0, ẑ)
chassis_q0 = chassis_qx * chassis_qy * chassis_qz
chassis_rotation = GLMakie.Quaternion(chassis_q0)
rollingwheel_qx = Porta.Quaternion(0.0, x̂)
rollingwheel_qy = Porta.Quaternion(0.0, ŷ)
rollingwheel_qz = Porta.Quaternion(0.0, ẑ) # the axis of rotation
rollingwheel_q0 = rollingwheel_qx * rollingwheel_qy * rollingwheel_qz
rollingwheel_rotation = GLMakie.Quaternion(rollingwheel_q0)
reactionwheel_qx = Porta.Quaternion(0.0, x̂)
reactionwheel_qy = Porta.Quaternion(0.0, ŷ)
reactionwheel_qz = Porta.Quaternion(0.0, ẑ) # the axis of rotation
reactionwheel_q0 = reactionwheel_qx * reactionwheel_qy * reactionwheel_qz
reactionwheel_rotation = GLMakie.Quaternion(reactionwheel_q0)

chassis_stl_path = joinpath("data", "unicycle", "unicycle_chassis.STL")
rollingwheel_stl_path = joinpath("data", "unicycle", "unicycle_main_wheel.STL")
reactionwheel_stl_path = joinpath("data", "unicycle", "unicycle_reaction_wheel.STL")

chassis_colormap = :Blues
rollingwheel_colormap = :rose
reactionwheel_colormap = :gold

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(1.0, 1.0, 1.0)
lscene = GLMakie.LScene(fig[1, 1], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = backgroundcolor))

chassis_stl = FileIO.load(chassis_stl_path)
reactionwheel_stl = FileIO.load(reactionwheel_stl_path)
rollingwheel_stl = FileIO.load(rollingwheel_stl_path)

pivot_observable = GLMakie.Observable(pivot)
point1_observable = GLMakie.Observable(p1)
point2_observable = GLMakie.Observable(p2)
point3_observable = GLMakie.Observable(p3)
point4_observable = GLMakie.Observable(p4)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap)

arrowscale = 0.1
smallarrowscale = arrowscale * 0.5
R1_tail = vec(p1)
R2_tail = vec(p2)
R3_tail = vec(p3)
R4_tail = vec(p4)
R1 = [0.0; 0.0; -1.0] .* arrowscale
R2 = [0.0; 0.0; -1.0] .* arrowscale
R3 = [0.0; 0.0; -1.0] .* arrowscale
R4 = [0.0; 0.0; -1.0] .* arrowscale

ps = GLMakie.Observable([GLMakie.Point3f(R1_tail...), GLMakie.Point3f(R2_tail...), GLMakie.Point3f(R3_tail...), GLMakie.Point3f(R4_tail...)])
ns = GLMakie.Observable([GLMakie.Vec3f(R1...), GLMakie.Vec3f(R2...), GLMakie.Vec3f(R3...),  GLMakie.Vec3f(R4...)])
arrowsize = GLMakie.Observable(GLMakie.Vec3f(0.01, 0.02, 0.03))
linewidth = GLMakie.Observable(0.01)
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:orange, :lime, :pink, :purple],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :center
)

pivotball = GLMakie.meshscatter!(lscene, pivot_observable, markersize = 0.01, color = :gold)
ball1 = GLMakie.meshscatter!(lscene, point1_observable, markersize = 0.01, color = :orange)
ball2 = GLMakie.meshscatter!(lscene, point2_observable, markersize = 0.01, color = :lime)
ball3 = GLMakie.meshscatter!(lscene, point3_observable, markersize = 0.01, color = :pink)
ball4 = GLMakie.meshscatter!(lscene, point4_observable, markersize = 0.01, color = :purple)

pivot_ps = GLMakie.Observable([pivot_observable[], pivot_observable[], pivot_observable[]])
pivot_ns = GLMakie.Observable(map(x -> x .* smallarrowscale, ê))
ps1 = GLMakie.Observable([point1_observable[], point1_observable[], point1_observable[]])
ps2 = GLMakie.Observable([point2_observable[], point2_observable[], point2_observable[]])
ps3 = GLMakie.Observable([point3_observable[], point3_observable[], point3_observable[]])
ps4 = GLMakie.Observable([point4_observable[], point4_observable[], point4_observable[]])
ns1 = GLMakie.Observable(map(x -> smallarrowscale .* B_O_R * x, [B_A1_R * ê[1], B_A1_R * ê[2], B_A1_R * ê[3]]))
ns2 = GLMakie.Observable(map(x -> smallarrowscale .* B_O_R * x, [B_A2_R * ê[1], B_A2_R * ê[2], B_A2_R * ê[3]]))
ns3 = GLMakie.Observable(map(x -> smallarrowscale .* B_O_R * x, [B_A3_R * ê[1], B_A3_R * ê[2], B_A3_R * ê[3]]))
ns4 = GLMakie.Observable(map(x -> smallarrowscale .* B_O_R * x, [B_A4_R * ê[1], B_A4_R * ê[2], B_A4_R * ê[3]]))
arrowsize1 = GLMakie.Observable(GLMakie.Vec3f(0.01, 0.02, 0.03))
linewidth1 = GLMakie.Observable(0.005)
GLMakie.arrows!(lscene,
    pivot_ps, pivot_ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
    ps1, ns1, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
    ps2, ns2, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
ps3, ns3, fxaa = true, # turn on anti-aliasing
color = [:red, :green, :blue],
linewidth = linewidth1, arrowsize = arrowsize1,
align = :center
)
GLMakie.arrows!(lscene,
ps4, ns4, fxaa = true, # turn on anti-aliasing
color = [:red, :green, :blue],
linewidth = linewidth1, arrowsize = arrowsize1,
align = :center
)

lookat = deepcopy(pivot)
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(up...))


clientside  = connect("192.168.4.1", 10000)

run = true
errormonitor(@async while (isopen(clientside) && run)
    text = readline(clientside, keep = true)
    println(text)
    readings = parsetext(text)
    flag = "R1" in keys(readings) && "R2" in keys(readings) &&
           "R3" in keys(readings) && "R4" in keys(readings) &&
           "v1" in keys(readings) && "v2" in keys(readings)
    if flag
        R1 = readings["R1"]
        R2 = readings["R2"]
        R3 = readings["R3"]
        R4 = readings["R4"]
        v1 = readings["v1"]
        v2 = readings["v2"]

        _R1 = B_A1_R * R1
        _R2 = B_A2_R * R2
        _R3 = B_A3_R * R3
        _R4 = B_A4_R * R4
        M = [_R1 _R2 _R3 _R4]
        ĝ = (M * X)[:, 1]
        β = atan(-ĝ[1], √(ĝ[2]^2 + ĝ[3]^2))
        γ = atan(ĝ[2], ĝ[3])
        println("β: $β, γ: $γ.")
        pitch = β
        roll = γ
        q = Porta.Quaternion(roll, x̂) * Porta.Quaternion(pitch, ŷ)
        O_B_R = mat33(q)
        B_O_R = mat33(-q)

        g = q * chassis_q0
        GLMakie.rotate!(robot, GLMakie.Quaternion(g))
        pivot_observable[] = GLMakie.Point3f(O_B_R * (pivot - origin) + origin)
        point1_observable[] = GLMakie.Point3f(O_B_R * (p1 - origin) + origin)
        point2_observable[] = GLMakie.Point3f(O_B_R * (p2 - origin) + origin)
        point3_observable[] = GLMakie.Point3f(O_B_R * (p3 - origin) + origin)
        point4_observable[] = GLMakie.Point3f(O_B_R * (p4 - origin) + origin)

        ps[] = [GLMakie.Point3f(point1_observable[]...), GLMakie.Point3f(point2_observable[]...),
                GLMakie.Point3f(point3_observable[]...), GLMakie.Point3f(point4_observable[]...)]
        ns[] = map(x -> x .* arrowscale, [GLMakie.Vec3f(O_B_R * _R1...), GLMakie.Vec3f(O_B_R * _R2...),
                                          GLMakie.Vec3f(O_B_R * _R3...), GLMakie.Vec3f(O_B_R * _R4...)])

        pivot_ps[] = [GLMakie.Point3f(pivot_observable[]...), GLMakie.Point3f(pivot_observable[]...), GLMakie.Point3f(pivot_observable[]...)]
        ps1[] = [GLMakie.Point3f(point1_observable[]...), GLMakie.Point3f(point1_observable[]...), GLMakie.Point3f(point1_observable[]...)]
        ps2[] = [GLMakie.Point3f(point2_observable[]...), GLMakie.Point3f(point2_observable[]...), GLMakie.Point3f(point2_observable[]...)]
        ps3[] = [GLMakie.Point3f(point3_observable[]...), GLMakie.Point3f(point3_observable[]...), GLMakie.Point3f(point3_observable[]...)]
        ps4[] = [GLMakie.Point3f(point4_observable[]...), GLMakie.Point3f(point4_observable[]...), GLMakie.Point3f(point4_observable[]...)]

        ns1[] = map(x -> x .* LinearAlgebra.norm(R1) .* smallarrowscale, [B_O_R * B_A1_R * ê[1], B_O_R * B_A1_R * ê[2], B_O_R * B_A1_R * ê[3]])
        ns2[] = map(x -> x .* LinearAlgebra.norm(R2) .* smallarrowscale, [B_O_R * B_A2_R * ê[1], B_O_R * B_A2_R * ê[2], B_O_R * B_A2_R * ê[3]])
        ns3[] = map(x -> x .* LinearAlgebra.norm(R3) .* smallarrowscale, [B_O_R * B_A3_R * ê[1], B_O_R * B_A3_R * ê[2], B_O_R * B_A3_R * ê[3]])
        ns4[] = map(x -> x .* LinearAlgebra.norm(R4) .* smallarrowscale, [B_O_R * B_A4_R * ê[1], B_O_R * B_A4_R * ê[2], B_O_R * B_A4_R * ê[3]])

        mq = GLMakie.Quaternion(Porta.Quaternion(float(-v1) / 600.0 * 2pi, ẑ))
        rq = GLMakie.Quaternion(Porta.Quaternion(float(-v2) / 1800.0 * 2pi, x̂))
        GLMakie.rotate!(rollingwheel, mq)
        GLMakie.rotate!(reactionwheel, rq)
    end
end)

# close(clientside)