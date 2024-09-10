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

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

eyeposition = LinearAlgebra.normalize([-0.9, 0.3, 0.5]) .* 0.6
lookat = [-0.1, -0.1, 0.1]
up = [0.0; 0.0; 1.0]

# the robot body origin in the inertial frame Ô
origin = GLMakie.Point3f(0.0, 0.0, 0.0)
# the vectors of the standard basis for the input space ℝ³
ê = [GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)]

# Parameters
m_w = 0.1 # kg # Wheel mass
m_c = 0.2 # kg # Chassis mass
m_r = 0.1 # kg # Pendulum mass
I_w1 = 0.01 # kg . m² # Wheel x-dir. moment of inertia
I_w2 = 0.02 # kg . m² # Wheel y-dir. moment of inertia
I_w3 = 0.01 # kg . m² # Wheel z-dir. moment of inertia
I_c1 = 0.17 # kg . m² # Chassis x-dir. moment of inertia
I_c2 = 0.11 # kg . m² # Chassis y-dir. moment of inertia
I_c3 = 0.08 # kg . m² # Chassis z-dir. moment of inertia
I_r1 = 0.03 # kg . m² # Reaction wheel x-dir. moment of inertia
I_r2 = 0.03 # kg . m² # Reaction wheel y-dir. moment of inertia
I_r3 = 0.0003 # kg . m² # Reaction wheel z-dir. moment of inertia
r_w = 0.0750 # +-0.0001m # Wheel radius
l_c = 0.1 # m # Distance between wheel center of mass and chassis center of mass
l_cr = 0.1 # m # Distance between chassis center of mass and pendulum pivot
l_r = 0.1 # m # Distance between pendulum pivot and center of mass

g = 9.81 # m/s² # Gravitational acceleration
I_w = [I_w1; I_w2; I_w3; 0.0] # Wheel moment of inertia
I_c = [I_c1; I_c2; I_c3; 0.0] # Chassis moment of inertia
I_r = [I_r1; I_r2; I_r3; 0.0] # Reaction wheel moment of inertia


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

chassis_colormap = :inferno
rollingwheel_colormap = :gold
reactionwheel_colormap = :plasma

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(1.0, 1.0, 1.0)
lscene = GLMakie.LScene(fig[1:3, 1], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :navyblue))

sg = GLMakie.SliderGrid(
    fig[1, 2],
    (label = "x", range = -1:0.01:1, format = "{:.2f}mm", startvalue = 0.0),
    (label = "y", range = -1:0.01:1, format = "{:.2f}mm", startvalue = 0.0),
    (label = "θ", range = -π:0.01:π, format = "{:.2f}°", startvalue = 0.0),
    (label = "α", range = -π:0.01:π, format = "{:.2f}°", startvalue = 0.0),
    (label = "β", range = -π:0.01:π, format = "{:.2f}°", startvalue = 0.0),
    (label = "γ", range = -π:0.01:π, format = "{:.2f}°", startvalue = 0.0),
    (label = "δ", range = -π:0.01:π, format = "{:.2f}°", startvalue = 0.0),
    width = 350,
    tellheight = false)

tw = GLMakie.Textbox(fig[2, 2], placeholder = "τ_w", validator = Float64, tellwidth = false, textcolor = :white)
tb = GLMakie.Textbox(fig[3, 2], placeholder = "τ_p", validator = Float64, tellwidth = false, textcolor = :white)

sliderobservables = [s.value for s in sg.sliders]
x = sliderobservables[1]
y = sliderobservables[2]
θ = sliderobservables[3]
α = sliderobservables[4]
β = sliderobservables[5]
γ = sliderobservables[6]
δ = sliderobservables[7]

chassis_stl = FileIO.load(chassis_stl_path)
reactionwheel_stl = FileIO.load(reactionwheel_stl_path)
rollingwheel_stl = FileIO.load(rollingwheel_stl_path)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap)

arrowscale = 0.1
observablepointG = GLMakie.@lift(GLMakie.Point3f($x, $y, 0.0))
observablepointCP = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, -0.085))
observablepointW1 = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, -0.011))
observablepointW2 = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, -0.011))
observablepointW3 = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, -0.011))
observablepointC = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
observablepointR = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.154))
observablepoints = [observablepointG, observablepointCP, observablepointW1, observablepointW2, observablepointW3, observablepointC, observablepointR]
corrdinateframetitles = ["ΣG", "ΣCP", "ΣW1", "ΣW2", "ΣW3", "ΣC", "ΣR"]

psG = GLMakie.lift(x -> [x, x, x], observablepointG)
psCP = GLMakie.lift(x -> [x, x, x], observablepointCP)
psW1 = GLMakie.lift(x -> [x, x, x], observablepointW1)
psW2 = GLMakie.lift(x -> [x, x, x], observablepointW2)
psW3 = GLMakie.lift(x -> [x, x, x], observablepointW3)
psC = GLMakie.lift(x -> [x, x, x], observablepointC)
psR = GLMakie.lift(x -> [x, x, x], observablepointR)
nsG = GLMakie.Observable(ê .* arrowscale)
nsCP = GLMakie.Observable(ê .* arrowscale)
nsW1 = GLMakie.Observable(ê .* arrowscale)
nsW2 = GLMakie.Observable(ê .* arrowscale)
nsW3 = GLMakie.Observable([ê[1], ê[3], ê[2]] .* arrowscale)
nsC = GLMakie.Observable(ê .* arrowscale)
nsR = GLMakie.Observable(ê .* arrowscale)
coordinateframes_ps = [psG, psCP, psW1, psW2, psW3, psC, psR]
coordinateframes_ns = [nsG, nsCP, nsW1, nsW2, nsW3, nsC, nsR]

arrowsize = GLMakie.Vec3f(0.01, 0.02, 0.03)
linewidth = 0.01
for (i, ps) in enumerate(coordinateframes_ps)
    GLMakie.arrows!(lscene,
        ps, coordinateframes_ns[i], fxaa = true, # turn on anti-aliasing
        color = [:red, :green, :blue],
        linewidth = linewidth, arrowsize = arrowsize,
        align = :center
    )
end

rotations = GLMakie.@lift(map(x -> GLMakie.Quaternion(Porta.Quaternion(getrotation(ẑ, ℝ³([vec(x)...] - eyeposition))...)), $observablepoints))
eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation1 = GLMakie.@lift(Porta.Quaternion(getrotation(ẑ, $rotationaxis)...))
rotation2 = GLMakie.@lift(Porta.Quaternion($rotationangle, $rotationaxis))
rotation = GLMakie.@lift(GLMakie.Quaternion($rotation2 * $rotation1))
GLMakie.text!(lscene,
    GLMakie.@lift([$observablepointG, $observablepointCP, $observablepointW1, $observablepointW2, $observablepointW3, $observablepointC, $observablepointR]),
    text = corrdinateframetitles,
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.04,
    markerspace = :data
)


GLMakie.on(θ) do θ
    mq = GLMakie.Quaternion(Porta.Quaternion(Float64(θ), ẑ))
    GLMakie.rotate!(rollingwheel, mq)
end

GLMakie.on(γ) do γ
    rq = GLMakie.Quaternion(Porta.Quaternion(Float64(γ), x̂))
    GLMakie.rotate!(reactionwheel, rq)
end

GLMakie.on(α) do α
    q = Porta.Quaternion(α, x̂) * Porta.Quaternion(β[], ŷ) * Porta.Quaternion(δ[], ẑ)
    GLMakie.rotate!(robot, GLMakie.Quaternion(q * chassis_q0))
end

GLMakie.on(β) do β
    q = Porta.Quaternion(α[], x̂) * Porta.Quaternion(β, ŷ) * Porta.Quaternion(δ[], ẑ)
    GLMakie.rotate!(robot, GLMakie.Quaternion(q * chassis_q0))
end

GLMakie.on(δ) do δ
    q = Porta.Quaternion(α[], x̂) * Porta.Quaternion(β[], ŷ) * Porta.Quaternion(δ, ẑ)
    GLMakie.rotate!(robot, GLMakie.Quaternion(q * chassis_q0))
end

eyeposition_observable[] = eyeposition
lookat_observable[] = deepcopy([vec(origin)...])
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition_observable[]...), GLMakie.Vec3f(lookat_observable[]...), GLMakie.Vec3f(up...))

w2_cp_T = GLMakie.@lift([[1.0; 0.0; 0.0; 0.0] [0.0; cos($α); sin($α); 0.0] [0.0; -sin($α); cos($α); 0.0] [0.0; 0.0; 0.0; 1.0]] *
                        [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; r_w; 1.0]])
cp_g_T = GLMakie.@lift([[cos($δ); sin($δ); 0.0; 0.0] [-sin($δ); cos($δ); 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [$x; $y; 0.0; 1.0]])
w2_g_T = GLMakie.@lift($cp_g_T * $w2_cp_T)

w2_P_w = [0.0; 0.0; 0.0; 1.0]
g_P_w = GLMakie.@lift($w2_g_T * w2_P_w)

c_w2_T = GLMakie.@lift([[cos($β); 0.0; -sin($β); 0.0] [0.0; 1.0; 0.0; 0.0] [sin($β); 0.0; cos($β); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_c; 1.0]])

c_g_T = GLMakie.@lift($w2_g_T * $c_w2_T)

c_P_c = [0.0; 0.0; 0.0; 1.0]
g_P_c = GLMakie.@lift($c_g_T * c_P_c)

r_c_T = GLMakie.@lift([[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_cr; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; cos($γ); sin($γ); 0.0] [0.0; -sin($γ); cos($γ); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_r; 1.0]])

r_g_T = GLMakie.@lift($c_g_T * $r_c_T)

r_P_r = [0.0; 0.0; 0.0; 1.0]
g_P_r = GLMakie.@lift($r_g_T * r_P_r)

w2_cp_Transform = [[1.0; 0.0; 0.0; 0.0] [0.0; cos(α[]); sin(α[]); 0.0] [0.0; -sin(α[]); cos(α[]); 0.0] [0.0; -r_w * sin(α[]); r_w * cos(α[]); 1.0]]
@assert(isapprox(w2_cp_T[], w2_cp_Transform))
w2_g_Transform = [[cos(δ[]); sin(δ[]); 0.0; 0.0] [-sin(δ[]) * cos(α[]); cos(δ[]) * cos(α[]); sin(α[]); 0.0] [sin(δ[]) * sin(α[]); -cos(δ[]) * sin(α[]); cos(α[]); 0.0] [x[] + r_w * sin(δ[]) * sin(α[]); y[] - r_w * cos(δ[]) * sin(α[]); r_w * cos(α[]); 1.0]]
@assert(isapprox(w2_g_T[], w2_g_Transform))
g_Position_w = [x[] + r_w * sin(α[]) * sin(δ[]); y[] - r_w * sin(α[]) * cos(δ[]); r_w * cos(α[]); 1.0]
@assert(isapprox(g_P_w[], g_Position_w))
c_w2_Transform = [[cos(β[]); 0.0; -sin(β[]); 0.0] [0.0; 1.0; 0.0; 0.0] [sin(β[]); 0.0; cos(β[]); 0.0] [l_c * sin(β[]); 0.0; l_c * cos(β[]); 1.0]]
@assert(isapprox(c_w2_T[], c_w2_Transform))
c_g_Transform = [[cos(β[]) * cos(δ[]) - sin(α[]) * sin(β[]) * sin(δ[]); cos(β[]) * sin(δ[]) + sin(α[]) * sin(β[]) * cos(δ[]); -cos(α[]) * sin(β[]); 0.0] [-sin(δ[]) * cos(α[]); cos(δ[]) * cos(α[]); sin(α[]); 0.0] [sin(β[]) * cos(δ[]) + sin(α[]) * cos(β[]) * sin(δ[]); sin(β[]) * sin(δ[]) - sin(α[]) * cos(β[]) * cos(δ[]); cos(α[]) * cos(β[]); 0.0] [x[] + r_w * sin(δ[]) * sin(α[]) + l_c * sin(β[]) * cos(δ[]) + l_c * sin(α[]) * cos(β[]) * sin(δ[]); y[] - r_w * cos(δ[]) * sin(α[]) + l_c * sin(β[]) * sin(δ[]) - l_c * sin(α[]) * cos(β[]) * cos(δ[]); r_w * cos(α[]) + l_c * cos(α[]) * cos(β[]); 1.0]]
@assert(isapprox(c_g_T[], c_g_Transform))
g_Position_c = [x[] + r_w * sin(α[]) * sin(δ[]) + l_c * cos(β[]) * sin(α[]) * sin(δ[]) + l_c * sin(β[]) * cos(δ[]); y[] - r_w * sin(α[]) * cos(δ[]) - l_c * cos(β[]) * sin(α[]) * cos(δ[]) + l_c * sin(β[]) * sin(δ[]); r_w * cos(α[]) + l_c * cos(β[]) * cos(α[]); 1.0]
@assert(isapprox(g_P_c[], g_Position_c))
r_c_Transform = [[1.0; 0.0; 0.0; 0.0] [0.0; cos(γ[]); sin(γ[]); 0.0] [0.0; -sin(γ[]); cos(γ[]); 0.0] [0.0; -l_r * sin(γ[]); l_cr + l_r * cos(γ[]); 1.0]]
@assert(isapprox(r_c_T[], r_c_Transform))
r_g_Transform = [[cos(β[]) * cos(δ[]) - sin(α[]) * sin(β[]) * sin(δ[]); cos(β[]) * sin(δ[]) + sin(α[]) * sin(β[]) * cos(δ[]); -cos(α[]) * sin(β[]); 0.0] [-sin(δ[]) * cos(α[]) * cos(γ[]) + cos(δ[]) * sin(β[]) * sin(γ[]) + sin(δ[]) * sin(α[]) * cos(β[]) * sin(γ[]); cos(δ[]) * cos(α[]) * cos(γ[]) + sin(δ[]) * sin(β[]) * sin(γ[]) - cos(δ[]) * sin(α[]) * cos(β[]) * sin(γ[]); sin(α[]) * cos(γ[]) + cos(α[]) * cos(β[]) * sin(γ[]); 0.0] [sin(δ[]) * cos(α[]) * sin(γ[]) + cos(δ[]) * sin(β[]) * cos(γ[]) + sin(δ[]) * sin(α[]) * cos(β[]) * cos(γ[]); -cos(δ[]) * cos(α[]) * sin(γ[]) + sin(δ[]) * sin(β[]) * cos(γ[]) - cos(δ[]) * sin(α[]) * cos(β[]) * cos(γ[]); -sin(α[]) * sin(γ[]) + cos(α[]) * cos(β[]) * cos(γ[]); 0.0] [l_r * sin(δ[]) * cos(α[]) * sin(γ[]) + (l_cr + l_r * cos(γ[])) * (cos(δ[]) * sin(β[]) + sin(δ[]) * sin(α[]) * cos(β[])) + l_c * sin(β[]) * cos(δ[]) + l_c * cos(β[]) * sin(δ[]) * sin(α[]) + x[] + r_w * sin(δ[]) * sin(α[]); -l_r * cos(δ[]) * cos(α[]) * sin(γ[]) + (l_cr + l_r * cos(γ[])) * (sin(δ[]) * sin(β[]) - cos(δ[]) * sin(α[]) * cos(β[])) + l_c * sin(β[]) * sin(δ[]) - l_c * cos(β[]) * cos(δ[]) * sin(α[]) + y[] - r_w * cos(δ[]) * sin(α[]); -l_r * sin(α[]) * sin(γ[]) + (l_cr + l_r * cos(γ[])) * cos(α[]) * cos(β[]) + l_c * cos(β[]) * cos(α[]) + r_w * cos(α[]); 1.0]]
@assert(isapprox(r_g_T[], r_g_Transform))
g_Position_r = [x[] + r_w * sin(α[]) * sin(δ[]) + (l_c + l_cr) * cos(β[]) * sin(α[]) * sin(δ[]) + (l_c + l_cr) * sin(β[]) * cos(δ[]) + l_r * cos(γ[]) * cos(β[]) * sin(α[]) * sin(δ[]) + l_r * cos(γ[]) * sin(β[]) * cos(δ[]) + l_r * sin(γ[]) * cos(α[]) * sin(δ[]); y[] - r_w * sin(α[]) * cos(δ[]) - (l_c + l_cr) * cos(β[]) * sin(α[]) * cos(δ[]) + (l_c + l_cr) * sin(β[]) * sin(δ[]) - l_r * cos(γ[]) * cos(β[]) * sin(α[]) * cos(δ[]) + l_r * cos(γ[]) * sin(β[]) * sin(δ[]) - l_r * sin(γ[]) * cos(α[]) * cos(δ[]); r_w * cos(α[]) + (l_c + l_cr) * cos(β[]) * cos(α[]) + l_r * cos(γ[]) * cos(β[]) * cos(α[]) - l_r * sin(γ[]) * sin(α[]); 1.0]
@assert(isapprox(g_P_r[], g_Position_r))


g_P_w1 = GLMakie.Observable(g_P_w[])
g_P_w2 = GLMakie.Observable(g_P_w[])
g_P_c1 = GLMakie.Observable(g_P_c[])
g_P_c2 = GLMakie.Observable(g_P_c[])
g_P_r1 = GLMakie.Observable(g_P_r[])
g_P_r2 = GLMakie.Observable(g_P_r[])
V_w = GLMakie.lift(g_P_w) do g_P_w
    g_P_w2[] = g_P_w1[]
    g_P_w1[] = g_P_w
    g_P_w1[] - g_P_w2[]
end
V_c = GLMakie.lift(g_P_c) do g_P_c
    g_P_c2[] = g_P_c1[]
    g_P_c1[] = g_P_c
    g_P_c1[] - g_P_c2[]
end
V_r = GLMakie.lift(g_P_r) do g_P_r
    g_P_r2[] = g_P_r1[]
    g_P_r1[] = g_P_r
    g_P_r1[] - g_P_r2[]
end

α1 = GLMakie.Observable(α[])
α2 = GLMakie.Observable(α[])
β1 = GLMakie.Observable(β[])
β2 = GLMakie.Observable(β[])
θ1 = GLMakie.Observable(θ[])
θ2 = GLMakie.Observable(θ[])
γ1 = GLMakie.Observable(γ[])
γ2 = GLMakie.Observable(γ[])
δ1 = GLMakie.Observable(δ[])
δ2 = GLMakie.Observable(δ[])
dα = GLMakie.lift(α) do α
    α2[] = α1[]
    α1[] = α
    α1[] - α2[]
end
dβ = GLMakie.lift(β) do β
    β2[] = β1[]
    β1[] = β
    β1[] - β2[]
end
dθ = GLMakie.lift(θ) do θ
    θ2[] = θ1[]
    θ1[] = θ
    θ1[] - θ2[]
end
dγ = GLMakie.lift(γ) do γ
    γ2[] = γ1[]
    γ1[] = γ
    γ1[] - γ2[]
end
dδ = GLMakie.lift(δ) do δ
    δ2[] = δ1[]
    δ1[] = δ
    δ1[] - δ2[]
end

# kinematic constraints
dx = GLMakie.@lift(r_w * $dθ * cos($δ))
dy = GLMakie.@lift(r_w * $dθ * sin($δ))

r_w2_T = GLMakie.@lift(LinearAlgebra.inv($w2_g_T) * $r_g_T)
Ω_w = GLMakie.@lift([0.0; $dθ; 0.0; 0.0] + [$dα; 0.0; 0.0; 0.0] + LinearAlgebra.inv($w2_g_T) * [0.0; 0.0; $dδ; 0.0])
Ω_c = GLMakie.@lift([0.0; $dβ; 0.0; 0.0] + LinearAlgebra.inv($c_w2_T) * [$dα; 0.0; 0.0; 0.0] + LinearAlgebra.inv($c_g_T) * [0.0; 0.0; $dδ; 0.0])
Ω_r = GLMakie.@lift([$dγ; 0.0; 0.0; 0.0] + LinearAlgebra.inv($r_c_T) * [0.0; $dβ; 0.0; 0.0] + LinearAlgebra.inv($r_w2_T) * [$dα; 0.0; 0.0; 0.0] + LinearAlgebra.inv($r_g_T) * [0.0; 0.0; $dδ; 0.0])

Ω_wheel = [dα[]; dθ[] + dδ[] * sin(α[]); dδ[] * cos(α[]); 0.0]
Ω_chassis = [dα[] * cos(β[]) - dδ[] * cos(α[]) * sin(β[]); dβ[] + dδ[] * sin(α[]); dα[] * sin(β[]) + dδ[] * cos(α[]) * cos(β[]); 0.0]
Ω_reactionwheel = [dγ[] + dα[] * cos(β[]) - dδ[] * cos(α[]) * sin(β[]); dβ[] * cos(γ[]) + dα[] * sin(β[]) * sin(γ[]) + dδ[] * sin(α[]) * cos(γ[]) + dδ[] * cos(α[]) * cos(β[]) * sin(γ[]); -dβ[] * sin(γ[]) + dα[] * sin(β[]) * cos(γ[]) - dδ[] * sin(α[]) * sin(γ[]) + dδ[] * cos(α[]) * cos(β[]) * cos(γ[]); 0.0]
@assert(isapprox(Ω_w[], Ω_wheel))
@assert(isapprox(Ω_c[], Ω_chassis))
@assert(isapprox(Ω_r[], Ω_reactionwheel))

T_w = GLMakie.@lift(0.5 * m_w * transpose($V_w) * $V_w .+ 0.5 * transpose($Ω_w) * I_w * $Ω_w)
P_w = GLMakie.@lift(m_w * g * $g_P_w[3])
T_c = GLMakie.@lift(0.5 * m_c * transpose($V_c) * $V_c .+ 0.5 * transpose($Ω_c) * I_c * $Ω_c)
P_c = GLMakie.@lift(m_c * g * $g_P_c[3])
T_r = GLMakie.@lift(0.5 * m_r * transpose($V_r) * $V_r .+ 0.5 * transpose($Ω_r) * I_r * $Ω_r)
P_r = GLMakie.@lift(m_r * g * $g_P_r[3])

T_total = GLMakie.@lift($T_w + $T_c + $T_r)
P_total = GLMakie.@lift($P_w + $P_c + $P_r)
L = GLMakie.@lift($T_total .- $P_total)
m = 7 # the number of generalized coordinates
n = 2 # the number of kinematic constraints
