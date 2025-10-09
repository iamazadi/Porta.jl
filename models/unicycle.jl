using FileIO
using LinearAlgebra
using GLMakie
using Sockets
using Porta


figuresize = (1920, 1080)
modelname = "unicycle"
maxplotnumber = 50
headers = ["AX1", "AY1", "AZ1", "AX2", "AY2", "AZ2", "roll", "pitch", "encT", "encB", "k", "j", "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9", "x10", "x11", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"]
clientside = nothing
run = false
readings = Dict()

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

eyeposition = normalize([0.0, 1.0, 1.0]) .* 0.5
lookat = [-0.1, -0.1, 0.1]
up = [0.0; 0.0; 1.0]
arrowsize = Observable(Vec3f(0.03, 0.03, 0.06))
linewidth = Observable(0.01)
arrowscale = 0.1

# the robot body origin in the inertial frame Ô
origin = Point3f(-0.1, -0.1, -0.02)
# the pivot point B̂ in the inertial frame Ô
pivot = Point3f(-0.097, -0.1, -0.032)
# the position of sensors mounted on the body in the body frame of reference
# p1 = Point3f(-0.035, -0.19, -0.04)
# p2 = Point3f(0.025, -0.144, -0.07)
p1 = Point3f(-0.14000000286102293, -0.06500000149011612, -0.06200000151991844)
p2 = Point3f(-0.04000000286102295, -0.06000000149011612, -0.06000000151991844)
# the vectors of the standard basis for the input space ℝ³
ê = [Vec3f(1, 0, 0), Vec3f(0, 1, 0), Vec3f(0, 0, 1)]
# The rotation of the inertial frame Ô to the body frame B̂
O_B_R = [ê[1] ê[2] ê[3]]
B_O_R = inv(O_B_R)
# The rotation of the local frame of the sensor i to the robot frame B̂
imu2angle = -30.0 / 180.0 * π
A1_B_R = [ê[1] ê[2] ê[3]]
A2_B_R = [ê[1] ê[2] ê[3]]
# A2_B_R = [(cos(imu2angle) * ê[1] - sin(imu2angle) * ê[2]) (sin(imu2angle) * ê[1] + cos(imu2angle) * ê[2]) ê[3]]
B_A1_R = inv(A1_B_R)
B_A2_R = inv(A2_B_R)

P = [[1.0; vec(p1 - pivot)] [1.0; vec(p2 - pivot)]]
X = transpose(P) * inv(P * transpose(P))

r_w = 75.0 # +-0.1mm
chassis_scale = 0.001
rollingwheel_scale = 1.0
reactionwheel_scale = 1.0

chassis_origin = deepcopy(origin)
rollingwheel_origin = Point3f(3.0, -12.0, 0.0)
reactionwheel_origin = Point3f(0.0, 153.0, 1.0)

chassis_qx = ℍ(π / 2, x̂)
chassis_qy = ℍ(0.0, ŷ)
chassis_qz = ℍ(0.0, ẑ)
chassis_q0 = chassis_qx * chassis_qy * chassis_qz
chassis_rotation = chassis_q0
rollingwheel_qx = ℍ(0.0, x̂)
rollingwheel_qy = ℍ(0.0, ŷ)
rollingwheel_qz = ℍ(0.0, ẑ) # the axis of rotation
rollingwheel_q0 = rollingwheel_qx * rollingwheel_qy * rollingwheel_qz
rollingwheel_rotation = rollingwheel_q0
reactionwheel_qx = ℍ(0.0, x̂)
reactionwheel_qy = ℍ(0.0, ŷ)
reactionwheel_qz = ℍ(0.0, ẑ) # the axis of rotation
reactionwheel_q0 = reactionwheel_qx * reactionwheel_qy * reactionwheel_qz
reactionwheel_rotation = reactionwheel_q0

chassis_stl_path = joinpath("data", "unicycle", "unicycle_chassis.STL")
rollingwheel_stl_path = joinpath("data", "unicycle", "unicycle_main_wheel.STL")
reactionwheel_stl_path = joinpath("data", "unicycle", "unicycle_reaction_wheel.STL")

chassis_colormap = :Pastel2_8
rollingwheel_colormap = :diverging_rainbow_bgymr_45_85_c67_n256
reactionwheel_colormap = :Set3_12

pivot_observable = Observable(pivot)
point1_observable = Observable(p1)
point2_observable = Observable(p2)

makefigure() = Figure(size=figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
backgroundcolor = RGBf(1.0, 1.0, 1.0)
lscene = LScene(fig[1, 1], show_axis=false, scenekw=(lights=[pl, al], clear=true, backgroundcolor=:black))
ax1 = Axis(fig[2, 1], xlabel="Time (s)", ylabel="System States")
ax2 = Axis(fig[2, 2], xlabel="Time (s)", ylabel="P Matrix Parameters")
buttoncolor = RGBf(0.3, 0.3, 0.3)
buttonlabels = ["Run", "Stop", "Connect", "Disconnect"]
buttons = [Button(fig, label=l, buttoncolor=buttoncolor) for l in buttonlabels]
statustext = Observable("Not connected.")
statuslabel = Label(fig, statustext, fontsize = 15)
kindextext = Observable("k: 1")
jindextext = Observable("j: 1")
kindexlabel = Label(fig, kindextext, fontsize = 30)
jindexlabel = Label(fig, jindextext, fontsize = 30)
fig[1, 2] = grid!(hcat(kindexlabel, jindexlabel, statuslabel, buttons...), tellheight=false, tellwidth=false)

graphpoints = Observable([Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)]])
graphpoints2 = Observable([Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)]])

P0_lineobject = scatter!(ax2, @lift(($graphpoints2)[1]), color=:red)
P1_lineobject = scatter!(ax2, @lift(($graphpoints2)[2]), color=:green)
P2_lineobject = scatter!(ax2, @lift(($graphpoints2)[3]), color=:blue)
P3_lineobject = scatter!(ax2, @lift(($graphpoints2)[4]), color=:yellow)
P4_lineobject = scatter!(ax2, @lift(($graphpoints2)[5]), color=:orange)
P5_lineobject = scatter!(ax2, @lift(($graphpoints2)[6]), color=:gold)
P6_lineobject = scatter!(ax2, @lift(($graphpoints2)[7]), color=:purple)
P7_lineobject = scatter!(ax2, @lift(($graphpoints2)[8]), color=:pink)
P8_lineobject = scatter!(ax2, @lift(($graphpoints2)[9]), color=:white)
P9_lineobject = scatter!(ax2, @lift(($graphpoints2)[10]), color=:lime)
P10_lineobject = scatter!(ax2, @lift(($graphpoints2)[11]), color=:brown)
P11_lineobject = scatter!(ax2, @lift(($graphpoints2)[12]), color=:navyblue)
x0_lineobject = scatter!(ax1, @lift(($graphpoints)[1]), color=:red)
x1_lineobject = scatter!(ax1, @lift(($graphpoints)[2]), color=:green)
x2_lineobject = scatter!(ax1, @lift(($graphpoints)[3]), color=:orange)
x3_lineobject = scatter!(ax1, @lift(($graphpoints)[4]), color=:pink)
x4_lineobject = scatter!(ax1, @lift(($graphpoints)[5]), color=:blue)
x5_lineobject = scatter!(ax1, @lift(($graphpoints)[6]), color=:yellow)
x6_lineobject = scatter!(ax1, @lift(($graphpoints)[7]), color=:purple)
x7_lineobject = scatter!(ax1, @lift(($graphpoints)[8]), color=:brown)
x8_lineobject = scatter!(ax1, @lift(($graphpoints)[9]), color=:white)
x9_lineobject = scatter!(ax1, @lift(($graphpoints)[10]), color=:grey)
x10_lineobject = scatter!(ax1, @lift(($graphpoints)[11]), color=:gold)
x11_lineobject = scatter!(ax1, @lift(($graphpoints)[12]), color=:silver)

chassis_stl = load(chassis_stl_path)
reactionwheel_stl = load(reactionwheel_stl_path)
rollingwheel_stl = load(rollingwheel_stl_path)

pivot_observable = Observable(pivot)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap)

pivotball = meshscatter!(lscene, pivot_observable, markersize=0.01, color=:gold)

arrowscale = 0.2
smallarrowscale = arrowscale * 0.5
R1_tail = vec(p1)
R2_tail = vec(p2)
R1 = [0.0; 0.0; -1.0] .* arrowscale
R2 = [0.0; 0.0; -1.0] .* arrowscale

ps = Observable([Point3f(R1_tail...), Point3f(R2_tail...)])
ns = Observable([Vec3f(R1...), Vec3f(R2...)])
arrowsize = Observable(Vec3f(0.02, 0.02, 0.04))
linewidth = Observable(0.015)
arrows!(lscene,
    ps, ns, fxaa=true, # turn on anti-aliasing
    color=[:orange, :lime, :pink, :purple],
    linewidth=linewidth, arrowsize=arrowsize,
    align=:origin
)

pivotball = meshscatter!(lscene, pivot_observable, markersize=0.01, color=:gold)
ball1 = meshscatter!(lscene, point1_observable, markersize=0.01, color=:orange)
ball2 = meshscatter!(lscene, point2_observable, markersize=0.01, color=:lime)

pivot_ps = Observable([pivot_observable[], pivot_observable[], pivot_observable[]])
pivot_ns = Observable(map(x -> x .* smallarrowscale, ê))
ps1 = Observable([point1_observable[], point1_observable[], point1_observable[]])
ps2 = Observable([point2_observable[], point2_observable[], point2_observable[]])
ns1 = Observable(map(x -> smallarrowscale .* B_O_R * x, [B_A1_R * ê[1], B_A1_R * ê[2], B_A1_R * ê[3]]))
ns2 = Observable(map(x -> smallarrowscale .* B_O_R * x, [B_A2_R * ê[1], B_A2_R * ê[2], B_A2_R * ê[3]]))
arrowsize1 = Observable(Vec3f(0.02, 0.02, 0.04))
linewidth1 = Observable(0.01)
arrows!(lscene,
    pivot_ps, pivot_ns, fxaa=true, # turn on anti-aliasing
    color=[:red, :green, :blue],
    linewidth=linewidth1, arrowsize=arrowsize1,
    align=:origin
)
arrows!(lscene,
    ps1, ns1, fxaa=true, # turn on anti-aliasing
    color=[:red, :green, :blue],
    linewidth=linewidth1, arrowsize=arrowsize1,
    align=:origin
)
arrows!(lscene,
    ps2, ns2, fxaa=true, # turn on anti-aliasing
    color=[:red, :green, :blue],
    linewidth=linewidth1, arrowsize=arrowsize1,
    align=:origin
)

lookat = deepcopy(pivot)
update_cam!(lscene.scene, Vec3f(eyeposition...), Vec3f(lookat...), Vec3f(up...))
reaction_angle = 0.0
rolling_angle = 0.0
ylims!(ax1, -1.0, 1.0)
ylims!(ax2, -1e3, 1e3)


disconnect(clientside) = begin
    if !isnothing(clientside)
        close(clientside)
    end
end


mat33(q::ℍ) = begin
    qw, qx, qy, qz = vec(q)
    [1.0-2(qy^2)-2(qz^2) 2qx*qy-2qz*qw 2qx*qz+2qy*qw;
        2qx*qy+2qz*qw 1.0-2(qx^2)-2(qz^2) 2qy*qz-2qx*qw;
        2qx*qz-2qy*qw 2qy*qz+2qx*qw 1.0-2(qx^2)-2(qy^2)]
end


on(buttons[1].clicks) do n
    global run = true
    errormonitor(@async while (isopen(clientside) && run)
        text = readline(clientside, keep=true)
        println(text)
        # x1k: -13.76, x2k: 1.60, u1k: -40.00, u2k: 43.36, x1k+: -13.76, x2k+: 1.60, u1k+: -40.00, u2k+: 43.36, dt: 0.000006
        filtered = replace(text, "\0" => "")
        filtered = replace(filtered, "\r\n" => "")
        global readings = parsetext(filtered, headers)
        # calculate(readings)
        allkeys = keys(readings)
        flag = all([x ∈ allkeys for x in headers]) && all([!isnothing(readings[x]) for x in headers])
        if flag
            acc1 = [readings["AX1"]; readings["AY1"]; readings["AZ1"]]          # acc2 = [-(cos(imu2angle) * readings["aY2"] - sin(imu2angle) * readings["aX2"]); -(sin(imu2angle) * readings["aX2"] + cos(imu2angle) * readings["aY2"]); -readings["aZ2"]] .* (1.0 / 8092.0)
            acc2 = [readings["AX2"], readings["AY2"], readings["AZ2"]]

            # acc2 = [-(cos(imu2angle) * readings["aY2"] - sin(imu2angle) * readings["aX2"]); -(sin(imu2angle) * readings["aX2"] + cos(imu2angle) * readings["aY2"]); -readings["aZ2"]] .* (1.0 / 8092.0)
            # gyr1 = [readings["gX1"]; readings["gY1"]; readings["gZ1"]]
            # gyr2 = [readings["gX2"]; readings["gY2"]; readings["gZ2"]]
            roll = readings["roll"]
            pitch = readings["pitch"]
            rolling_angle = readings["encB"]
            reaction_angle = -readings["encT"]
            x0 = readings["x0"]
            x1 = readings["x1"]
            x2 = readings["x2"]
            x3 = readings["x3"]
            x4 = readings["x4"]
            x5 = readings["x5"]
            x6 = readings["x6"]
            x7 = readings["x7"]
            x8 = readings["x8"]
            x9 = readings["x9"]
            x10 = readings["x10"]
            x11 = readings["x11"]
            P0 = readings["P0"]
            P1 = readings["P1"]
            P2 = readings["P2"]
            P3 = readings["P3"]
            P4 = readings["P4"]
            P5 = readings["P5"]
            P6 = readings["P6"]
            P7 = readings["P7"]
            P8 = readings["P8"]
            P9 = readings["P9"]
            P10 = readings["P10"]
            P11 = readings["P11"]
            kindextext[] = "k: $(readings["k"])"
            jindextext[] = "j: $(readings["j"])"
            # delta_time = readings["dt"]

            global R1 = acc1
            global R2 = acc2

            M = [B_A1_R * R1 B_A2_R * R2]
            ĝ = (M*X)[:, 1]
            β = atan(-ĝ[1], √(ĝ[2]^2 + ĝ[3]^2))
            γ = atan(ĝ[2], ĝ[3])
            println("β: $β, γ: $γ.")
            # roll = β
            # pitch = -γ
            q = ℍ(roll, x̂) * ℍ(pitch, ŷ)
            O_B_R = mat33(q)
            B_O_R = mat33(-q)

            # g = q * chassis_q0
            # rotate!(robot, Quaternion(g))
            pivot_observable[] = Point3f(O_B_R * (pivot - origin) + origin)
            point1_observable[] = Point3f(O_B_R * (p1 - origin) + origin)
            point2_observable[] = Point3f(O_B_R * (p2 - origin) + origin)

            ps[] = [Point3f(point1_observable[]...), Point3f(point2_observable[]...)]
            ns[] = map(x -> x .* arrowscale, [Vec3f(O_B_R * [R1[2]; -R1[1]; R1[3]]...), Vec3f(O_B_R * [R2[2]; -R2[1]; R2[3]]...)])

            pivot_ps[] = [Point3f(pivot_observable[]...), Point3f(pivot_observable[]...), Point3f(pivot_observable[]...)]
            ps1[] = [Point3f(point1_observable[]...), Point3f(point1_observable[]...), Point3f(point1_observable[]...)]
            ps2[] = [Point3f(point2_observable[]...), Point3f(point2_observable[]...), Point3f(point2_observable[]...)]

            ns1[] = map(x -> x .* norm(R1) .* smallarrowscale, [B_O_R * B_A1_R * ê[1], B_O_R * B_A1_R * ê[2], B_O_R * B_A1_R * ê[3]])
            ns2[] = map(x -> x .* norm(R2) .* smallarrowscale, [B_O_R * B_A2_R * ê[1], B_O_R * B_A2_R * ê[2], B_O_R * B_A2_R * ê[3]])

            # plot the system state graph
            _graphpoints = graphpoints[]
            _x0points = _graphpoints[1]
            _x1points = _graphpoints[2]
            _x2points = _graphpoints[3]
            _x3points = _graphpoints[4]
            _x4points = _graphpoints[5]
            _x5points = _graphpoints[6]
            _x6points = _graphpoints[7]
            _x7points = _graphpoints[8]
            _x8points = _graphpoints[9]
            _x9points = _graphpoints[10]
            _x10points = _graphpoints[11]
            _x11points = _graphpoints[12]
            timestamp = vec(_x0points[end])[1] + 1.0
            push!(_x0points, Point2f(timestamp, x0))
            push!(_x1points, Point2f(timestamp, x1))
            push!(_x2points, Point2f(timestamp, x2))
            push!(_x3points, Point2f(timestamp, x3))
            push!(_x4points, Point2f(timestamp, x4))
            push!(_x5points, Point2f(timestamp, x5))
            push!(_x6points, Point2f(timestamp, x6))
            push!(_x7points, Point2f(timestamp, x7))
            push!(_x8points, Point2f(timestamp, x8))
            push!(_x9points, Point2f(timestamp, x9))
            push!(_x10points, Point2f(timestamp, x10))
            push!(_x11points, Point2f(timestamp, x11))
            # plot the P Matrix
            _graphpoints2 = graphpoints2[]
            _P0points = _graphpoints2[1]
            _P1points = _graphpoints2[2]
            _P2points = _graphpoints2[3]
            _P3points = _graphpoints2[4]
            _P4points = _graphpoints2[5]
            _P5points = _graphpoints2[6]
            _P6points = _graphpoints2[7]
            _P7points = _graphpoints2[8]
            _P8points = _graphpoints2[9]
            _P9points = _graphpoints2[10]
            _P10points = _graphpoints2[11]
            _P11points = _graphpoints2[12]
            push!(_P0points, Point2f(timestamp, P0))
            push!(_P1points, Point2f(timestamp, P1))
            push!(_P2points, Point2f(timestamp, P2))
            push!(_P3points, Point2f(timestamp, P3))
            push!(_P4points, Point2f(timestamp, P4))
            push!(_P5points, Point2f(timestamp, P5))
            push!(_P6points, Point2f(timestamp, P6))
            push!(_P7points, Point2f(timestamp, P7))
            push!(_P8points, Point2f(timestamp, P8))
            push!(_P9points, Point2f(timestamp, P9))
            push!(_P10points, Point2f(timestamp, P10))
            push!(_P11points, Point2f(timestamp, P11))
            number = length(_x0points)
            if number > maxplotnumber
                _x0points = _x0points[number-maxplotnumber+1:end]
                _x1points = _x1points[number-maxplotnumber+1:end]
                _x2points = _x2points[number-maxplotnumber+1:end]
                _x3points = _x3points[number-maxplotnumber+1:end]
                _x4points = _x4points[number-maxplotnumber+1:end]
                _x5points = _x5points[number-maxplotnumber+1:end]
                _x6points = _x6points[number-maxplotnumber+1:end]
                _x7points = _x7points[number-maxplotnumber+1:end]
                _x8points = _x8points[number-maxplotnumber+1:end]
                _x9points = _x9points[number-maxplotnumber+1:end]
                _x10points = _x10points[number-maxplotnumber+1:end]
                _x11points = _x11points[number-maxplotnumber+1:end]
                # P matrix graph
                _P0points = _P0points[number-maxplotnumber+1:end]
                _P1points = _P1points[number-maxplotnumber+1:end]
                _P2points = _P2points[number-maxplotnumber+1:end]
                _P3points = _P3points[number-maxplotnumber+1:end]
                _P4points = _P4points[number-maxplotnumber+1:end]
                _P5points = _P5points[number-maxplotnumber+1:end]
                _P6points = _P6points[number-maxplotnumber+1:end]
                _P7points = _P7points[number-maxplotnumber+1:end]
                _P8points = _P8points[number-maxplotnumber+1:end]
                _P9points = _P9points[number-maxplotnumber+1:end]
                _P10points = _P10points[number-maxplotnumber+1:end]
                _P11points = _P11points[number-maxplotnumber+1:end]
                @assert(length(_x0points) == maxplotnumber)
                graphpoints[] = [_x0points, _x1points, _x2points, _x3points, _x4points, _x5points, _x6points, _x7points, _x8points, _x9points, _x10points, _x11points]
                graphpoints2[] = [_P0points, _P1points, _P2points, _P3points, _P4points, _P5points, _P6points, _P7points, _P8points, _P9points, _P10points, _P11points]
            else
                graphpoints[] = [_x0points, _x1points, _x2points, _x3points, _x4points, _x5points, _x6points, _x7points, _x8points, _x9points, _x10points, _x11points]
                graphpoints2[] = [_P0points, _P1points, _P2points, _P3points, _P4points, _P5points, _P6points, _P7points, _P8points, _P9points, _P10points, _P11points]
            end
            xlims!(ax1, timestamp - maxplotnumber, timestamp)
            xlims!(ax2, timestamp - maxplotnumber, timestamp)
            
            #######

            # q = ℍ(roll, x̂) * ℍ(pitch, ŷ)
            O_B_R = mat3(q)

            g = q * chassis_q0
            GLMakie.rotate!(robot, Quaternion(g))
            pivot_observable[] = Point3f(O_B_R * (pivot - origin) + origin)

            pivot_ps[] = [Point3f(pivot_observable[]...), Point3f(pivot_observable[]...), Point3f(pivot_observable[]...)]
            rq = Quaternion(ℍ(reaction_angle, x̂))
            mq = Quaternion(ℍ(rolling_angle, ẑ))
            GLMakie.rotate!(rollingwheel, mq)
            GLMakie.rotate!(reactionwheel, rq)
        end
    end)
end

on(buttons[2].clicks) do n
    global run = false
end

on(buttons[3].clicks) do n
    disconnect(clientside)
    # execute the command nc 192.168.4.1 10000 in terminal for testing
    global clientside = connect("192.168.4.1", 10000)
    if isopen(clientside)
        statustext[] = "Connected."
    else
        statustext[] = "Disconnected."
    end
end

on(buttons[4].clicks) do n
    disconnect(clientside)
    if !isnothing(clientside) && isopen(clientside)
        statustext[] = "Connected."
    else
        statustext[] = "Disconnected."
    end
end