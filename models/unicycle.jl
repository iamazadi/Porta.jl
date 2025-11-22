using FileIO
using LinearAlgebra
using GLMakie
using Sockets
using Porta


figuresize = (1920, 1080)
modelname = "unicycle_tilt_estimation"
maxplotnumber = 100
timeaxiswindow = 7.5
headers = ["AX1", "AY1", "AZ1", "AX2", "AY2", "AZ2", "roll", "pitch", "encT", "encB", "j", "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9", "x10", "x11", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11", "changes", "time", "active"]
clientside = nothing
run = false
readings = Dict()
segments = 30
fps = 24
minutes = 1
iterations = minutes * 60 * fps
ipaddress = "192.168.4.1"
portnumber = 10000
fontsize = 30
chassis_colormap = :sun
rollingwheel_colormap = :redgreensplit
reactionwheel_colormap = :vangogh
recordedtime = 0.0

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

reorder(x) = [x[2]; -x[1]; x[3]]

eyeposition = [0.24; -0.27; 0.12]
view_direction = normalize([-0.867103; 0.4348146; -0.24304059])
lookat = eyeposition + view_direction
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
α = -30.0 / 180.0 * π # imu2angle
A1_B_R = [ê[1] ê[2] ê[3]]
# A2_B_R = [ê[1] ê[2] ê[3]]
# A2_B_R = [(cos(α) * ê[1] - sin(α) * ê[2]) (sin(α) * ê[1] + cos(α) * ê[2]) ê[3]]
B_A1_R = inv(A1_B_R)
# B_A2_R = inv(A2_B_R)
B_A2_R = [-sin(α) -cos(α) 0.0; cos(α) -sin(α) 0.0; 0.0 0.0 1.0]
A2_B_R = inv(B_A2_R)
# _B_A2_R = inv(B_A_R)


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

pivot_observable = Observable(pivot)
point1_observable = Observable(p1)
point2_observable = Observable(p2)

makefigure() = Figure(size=figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
backgroundcolor = RGBf(1.0, 1.0, 1.0)
lscene = LScene(fig[1, 1], show_axis=false, scenekw=(lights=[pl, al], clear=true, backgroundcolor=:black))
ax1 = Axis(fig[2, 1], xlabel="Time (sec)", ylabel="x-Euler angle (rad)", xlabelsize=fontsize, ylabelsize=fontsize)
ax2 = Axis(fig[2, 2], xlabel="Time (sec)", ylabel="y-Euler angle (rad)", xlabelsize=fontsize, ylabelsize=fontsize)
ax3 = Axis(fig[1, 2], xlabel="Time (sec)", ylabel="P Matrix Parameters", xlabelsize=fontsize, ylabelsize=fontsize)
buttoncolor = RGBf(0.3, 0.3, 0.3)
buttonlabels = ["Connect", "Disconnect", "Record", "Stop"]
buttons = [Button(fig, label=l, buttoncolor=buttoncolor) for l in buttonlabels]
connection_statustext = Observable("Disconnected.")
connection_statuslabel = Label(fig, connection_statustext, fontsize = fontsize)
controller_statustext = Observable("Deactive.")
controller_statuslabel = Label(fig, controller_statustext, fontsize = fontsize)
jindextext = Observable("time j: 1")
jindexlabel = Label(fig, jindextext, fontsize = fontsize)
recordtext = Observable("Not recording.")
recordlabel = Label(fig, recordtext, fontsize = fontsize)
fig[3, 1] = grid!(hcat(connection_statuslabel, controller_statuslabel, jindexlabel, recordlabel), tellheight=true, tellwidth=false)
fig[3, 2] = grid!(hcat(buttons...), tellheight=true, tellwidth=false)

graphpoints1 = Observable([Point2f[(0, 0)], Point2f[(0, 0)]])
graphpoints2 = Observable([Point2f[(0, 0)], Point2f[(0, 0)]])
graphpoints3 = Observable([Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)]])

x_euler_angle_raw_lineobject = scatter!(ax1, @lift(($graphpoints1)[1]), color=:green)
y_euler_angle_raw_lineobject = scatter!(ax2, @lift(($graphpoints2)[1]), color=:blue)
x_euler_angle_estimate_lineobject = scatter!(ax1, @lift(($graphpoints1)[2]), color=:lightgreen)
y_euler_angle_estimate_lineobject = scatter!(ax2, @lift(($graphpoints2)[2]), color=:lightblue)
P0_lineobject = scatter!(ax3, @lift(($graphpoints3)[1]), color=:lavenderblush)
P1_lineobject = scatter!(ax3, @lift(($graphpoints3)[2]), color=:plum1)
P2_lineobject = scatter!(ax3, @lift(($graphpoints3)[3]), color=:thistle)
P3_lineobject = scatter!(ax3, @lift(($graphpoints3)[4]), color=:orchid2)
P4_lineobject = scatter!(ax3, @lift(($graphpoints3)[5]), color=:mediumorchid1)
P5_lineobject = scatter!(ax3, @lift(($graphpoints3)[6]), color=:magenta2)
P6_lineobject = scatter!(ax3, @lift(($graphpoints3)[7]), color=:lavenderblush4)
P7_lineobject = scatter!(ax3, @lift(($graphpoints3)[8]), color=:magenta3)
P8_lineobject = scatter!(ax3, @lift(($graphpoints3)[9]), color=:plum4)
P9_lineobject = scatter!(ax3, @lift(($graphpoints3)[10]), color=:mediumorchid4)
P10_lineobject = scatter!(ax3, @lift(($graphpoints3)[11]), color=:mediumpurple4)
P11_lineobject = scatter!(ax3, @lift(($graphpoints3)[12]), color=:purple4)

chassis_stl = load(chassis_stl_path)
reactionwheel_stl = load(reactionwheel_stl_path)
rollingwheel_stl = load(rollingwheel_stl_path)

pivot_observable = Observable(pivot)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap, transparency = true)
rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap, transparency = true)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap, transparency = true)

pivotball = meshscatter!(lscene, pivot_observable, markersize=0.01, color=:gold)

arrowscale = 0.2
smallarrowscale = arrowscale * 0.5
R1_tail = vec(p1)
R2_tail = vec(p2)
R1 = [0.0; 0.0; -1.0] .* arrowscale
R2 = [0.0; 0.0; -1.0] .* arrowscale

acceleration_vector_tails = Observable([Point3f(R1_tail...), Point3f(R2_tail...)])
acceleration_vector_heads = Observable([Vec3f(R1...), Vec3f(R2...)])
arrowsize = Observable(Vec3f(0.02, 0.02, 0.04))
linewidth = Observable(0.015)
arrows!(lscene,
    acceleration_vector_tails, acceleration_vector_heads, fxaa=true, # turn on anti-aliasing
    color=[:orange, :lime, :pink, :purple],
    linewidth=linewidth, arrowsize=arrowsize,
    align=:origin
)

pivotball = meshscatter!(lscene, pivot_observable, markersize=0.01, color=:gold)
ball1 = meshscatter!(lscene, point1_observable, markersize=0.01, color=:orange)
ball2 = meshscatter!(lscene, point2_observable, markersize=0.01, color=:lime)

pivot_ps = Observable([pivot_observable[], pivot_observable[], pivot_observable[]])
pivot_ns = Observable(map(x -> x .* smallarrowscale, ê))
sensor1frame_tails = Observable([point1_observable[], point1_observable[], point1_observable[]])
sensor2frame_tails = Observable([point2_observable[], point2_observable[], point2_observable[]])
sensor1frame_heads = Observable(map(x -> smallarrowscale .* B_O_R * x, [reorder(B_A1_R * ê[1]), reorder(B_A1_R * ê[2]), reorder(B_A1_R * ê[3])]))
sensor2frame_heads = Observable(map(x -> smallarrowscale .* B_O_R * x, [reorder(B_A2_R * ê[1]), reorder(B_A2_R * ê[2]), reorder(B_A2_R * ê[3])]))
arrowsize1 = Observable(Vec3f(0.02, 0.02, 0.04))
linewidth1 = Observable(0.01)
arrows!(lscene,
    pivot_ps, pivot_ns, fxaa=true, # turn on anti-aliasing
    color=[:red, :green, :blue],
    linewidth=linewidth1, arrowsize=arrowsize1,
    align=:origin
)
arrows!(lscene,
    sensor1frame_tails, sensor1frame_heads, fxaa=true, # turn on anti-aliasing
    color=[:red, :green, :blue],
    linewidth=linewidth1, arrowsize=arrowsize1,
    align=:origin
)
arrows!(lscene,
    sensor2frame_tails, sensor2frame_heads, fxaa=true, # turn on anti-aliasing
    color=[:red, :green, :blue],
    linewidth=linewidth1, arrowsize=arrowsize1,
    align=:origin
)

lspaceθ = range(π / 2, stop = -π / 2, length = segments)
lspaceϕ = range(-π, stop = float(π), length = segments)
sphere_radius_p1 = norm(p1 - pivot)
sphere_radius_p2 = norm(p2 - pivot)
spherematrix_p1 = Observable([ℝ³(p1) + convert_to_cartesian([sphere_radius_p1; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ])
spherematrix_p2 = Observable([ℝ³(p2) + convert_to_cartesian([sphere_radius_p2; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ])
sphere_color_p1 = [RGBAf(abs(θ / (π / 2)), abs(ϕ / π), 0.0, 0.75) for ϕ in lspaceϕ, θ in lspaceθ]
sphere_color_p2 = [RGBAf(0.0, abs(θ / (π / 2)), 0.0, 0.75) for ϕ in lspaceϕ, θ in lspaceθ]
sphereobservable_p1 = buildsurface(lscene, spherematrix_p1, sphere_color_p1, transparency = true)
sphereobservable_p2 = buildsurface(lscene, spherematrix_p2, sphere_color_p2, transparency = true)

lookat = deepcopy(pivot)
update_cam!(lscene.scene, Vec3f(eyeposition...), Vec3f(lookat...), Vec3f(up...))
reaction_angle = 0.0
rolling_angle = 0.0
default_ylims = [-π / 8; π / 8]
ylims!(ax1, default_ylims[1], default_ylims[2])
ylims!(ax2, default_ylims[1], default_ylims[2])
ylims!(ax3, -1e2, 1e2)


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


on(buttons[4].clicks) do n
    global run = false
end

on(buttons[1].clicks) do n
    if !isnothing(clientside)
        disconnect(clientside)
    end
    # execute the command nc 192.168.4.1 10000 in terminal for testing
    global clientside = connect(ipaddress, portnumber)
    if isopen(clientside)
        connection_statustext[] = "Connected."
    else
        connection_statustext[] = "Disconnected."
    end
end

on(buttons[2].clicks) do n
    disconnect(clientside)
    if !isnothing(clientside) && isopen(clientside)
        connection_statustext[] = "Connected."
    else
        connection_statustext[] = "Disconnected."
    end
end

function stepforward()
    text = []
    try
        if !isnothing(clientside) && isopen(clientside)
            push!(text, readline(clientside, keep=true))
        end
    catch e
        println(e)
    end
    text = length(text) > 0 ? text[1] : ""
    # println(text)
    # x1k: -13.76, x2k: 1.60, u1k: -40.00, u2k: 43.36, x1k+: -13.76, x2k+: 1.60, u1k+: -40.00, u2k+: 43.36, dt: 0.000006
    filtered = replace(text, "\0" => "")
    filtered = replace(filtered, "\r\n" => "")
    global readings = parsetext(filtered, headers)
    # calculate(readings)
    allkeys = keys(readings)
    flag = all([x ∈ allkeys for x in headers]) && all([!isnothing(readings[x]) for x in headers])
    if flag
        global recordedtime = readings["time"] 
        iscontrolleractive = readings["active"]
        acc1 = [readings["AX1"]; readings["AY1"]; readings["AZ1"]]          # acc2 = [-(cos(imu2angle) * readings["aY2"] - sin(imu2angle) * readings["aX2"]); -(sin(imu2angle) * readings["aX2"] + cos(imu2angle) * readings["aY2"]); -readings["aZ2"]] .* (1.0 / 8092.0)
        acc2 = [readings["AX2"], readings["AY2"], readings["AZ2"]]
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

        # acc2 = [-(cos(imu2angle) * readings["aY2"] - sin(imu2angle) * readings["aX2"]); -(sin(imu2angle) * readings["aX2"] + cos(imu2angle) * readings["aY2"]); -readings["aZ2"]] .* (1.0 / 8092.0)
        # gyr1 = [readings["gX1"]; readings["gY1"]; readings["gZ1"]]
        # gyr2 = [readings["gX2"]; readings["gY2"]; readings["gZ2"]]
        roll = readings["roll"]
        pitch = readings["pitch"]
        rolling_angle = readings["encB"]
        reaction_angle = -readings["encT"]
        jindextext[] = "j: $(readings["j"])"
        # delta_time = readings["dt"]

        controller_statustext[] = isapprox(iscontrolleractive, 1.0) ? "Active" : "Deactive"

        global R1 = acc1
        global R2 = acc2

        M = [B_A1_R * R1 B_A2_R * R2]
        # ĝ = (M*X)[:, 1]
        ĝ = deepcopy(R1)
        β = atan(-ĝ[1], √(ĝ[2]^2 + ĝ[3]^2))
        γ = atan(ĝ[2], ĝ[3])

        x_euler_angle_raw = β
        x_euler_angle_estimate = roll
        y_euler_angle_raw = -γ
        y_euler_angle_estimate = pitch
        # @assert(isapprox(β, roll, atol = 1e-2), "The roll angle $roll is not equal to beta $β.")
        # @assert(isapprox(-γ, pitch, atol = 1e-2), "The pitch angle $pitch is not equal to minus gamma -$γ.")
        # println("roll: $roll, γ: $γ, pitch: $pitch, β: $β.")
        # println("x_euler_angle_raw: $x_euler_angle_raw, x_euler_angle_estimate: $x_euler_angle_estimate, y_euler_angle_raw: $y_euler_angle_raw, y_euler_angle_estimate: $y_euler_angle_estimate.")
        q = ℍ(roll, x̂) * ℍ(pitch, ŷ)
        O_B_R = mat33(q)
        B_O_R = mat33(-q)

        # g = q * chassis_q0
        # rotate!(robot, Quaternion(g))
        pivot_observable[] = Point3f(O_B_R * (pivot - origin) + origin)
        point1_observable[] = Point3f(O_B_R * (p1 - origin) + origin)
        point2_observable[] = Point3f(O_B_R * (p2 - origin) + origin)

        spherematrix_p1[] = [ℝ³(to_value(point1_observable)) + convert_to_cartesian([sphere_radius_p1; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ]
        spherematrix_p2[] = [ℝ³(to_value(point2_observable)) + convert_to_cartesian([sphere_radius_p2; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ]

        acceleration_vector_tails[] = [Point3f(point1_observable[]...), Point3f(point2_observable[]...)]
        acceleration_vector_heads[] = map(x -> x .* arrowscale, [Vec3f(O_B_R * reorder(B_A1_R * R1)...), Vec3f(O_B_R * reorder(B_A2_R * R2)...)])

        pivot_ps[] = [Point3f(pivot_observable[]...), Point3f(pivot_observable[]...), Point3f(pivot_observable[]...)]
        sensor1frame_tails[] = [Point3f(point1_observable[]...), Point3f(point1_observable[]...), Point3f(point1_observable[]...)]
        sensor2frame_tails[] = [Point3f(point2_observable[]...), Point3f(point2_observable[]...), Point3f(point2_observable[]...)]

        sensor1frame_heads[] = map(x -> x .* norm(R1) .* smallarrowscale, [B_O_R * reorder(B_A1_R * ê[1]), B_O_R * reorder(B_A1_R * ê[2]), B_O_R * reorder(B_A1_R * ê[3])])
        sensor2frame_heads[] = map(x -> x .* norm(R2) .* smallarrowscale, [B_O_R * reorder(B_A2_R * ê[1]), B_O_R * reorder(B_A2_R * ê[2]), B_O_R * reorder(B_A2_R * ê[3])])

        # plot the x-Euler and y-Euler angles
        _graphpoints1 = graphpoints1[]
        _graphpoints2 = graphpoints2[]
        _x_euler_angle_raw_points = _graphpoints1[1]
        _y_euler_angle_raw_points = _graphpoints2[1]
        _x_euler_angle_estimate_points = _graphpoints1[2]
        _y_euler_angle_estimate_points = _graphpoints2[2]
        timestamp = recordedtime
        push!(_x_euler_angle_raw_points, Point2f(timestamp, x_euler_angle_raw))
        push!(_y_euler_angle_raw_points, Point2f(timestamp, y_euler_angle_raw))
        push!(_x_euler_angle_estimate_points, Point2f(timestamp, x_euler_angle_estimate))
        push!(_y_euler_angle_estimate_points, Point2f(timestamp, y_euler_angle_estimate))
        # plot the P Matrix
        _graphpoints3 = graphpoints3[]
        _P0points = _graphpoints3[1]
        _P1points = _graphpoints3[2]
        _P2points = _graphpoints3[3]
        _P3points = _graphpoints3[4]
        _P4points = _graphpoints3[5]
        _P5points = _graphpoints3[6]
        _P6points = _graphpoints3[7]
        _P7points = _graphpoints3[8]
        _P8points = _graphpoints3[9]
        _P9points = _graphpoints3[10]
        _P10points = _graphpoints3[11]
        _P11points = _graphpoints3[12]
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
        number = length(_x_euler_angle_raw_points)
        if number > maxplotnumber
            _x_euler_angle_raw_points = _x_euler_angle_raw_points[number-maxplotnumber+1:end]
            _y_euler_angle_raw_points = _y_euler_angle_raw_points[number-maxplotnumber+1:end]
            _x_euler_angle_estimate_points = _x_euler_angle_estimate_points[number-maxplotnumber+1:end]
            _y_euler_angle_estimate_points = _y_euler_angle_estimate_points[number-maxplotnumber+1:end]
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
            @assert(length(_x_euler_angle_raw_points) == maxplotnumber)
            graphpoints1[] = [_x_euler_angle_raw_points, _x_euler_angle_estimate_points]
            graphpoints2[] = [_y_euler_angle_raw_points, _y_euler_angle_estimate_points]
            graphpoints3[] = [_P0points, _P1points, _P2points, _P3points, _P4points, _P5points, _P6points, _P7points, _P8points, _P9points, _P10points, _P11points]
        else
            graphpoints1[] = [_x_euler_angle_raw_points, _x_euler_angle_estimate_points]
            graphpoints2[] = [_y_euler_angle_raw_points, _y_euler_angle_estimate_points]
            graphpoints3[] = [_P0points, _P1points, _P2points, _P3points, _P4points, _P5points, _P6points, _P7points, _P8points, _P9points, _P10points, _P11points]
        end
        P_parameters = []
        for x in to_value(graphpoints3[])
            for y in x
                push!(P_parameters, y[2])
            end
        end
        xlims!(ax1, timestamp - timeaxiswindow, timestamp)
        xlims!(ax2, timestamp - timeaxiswindow, timestamp)
        xlims!(ax3, timestamp - timeaxiswindow, timestamp)
        ylims1 = [min(map(x -> x[2], _x_euler_angle_estimate_points)...) - 0.01; max(map(x -> x[2], _x_euler_angle_estimate_points)...) + 0.01]
        ylims2 = [min(map(x -> x[2], _y_euler_angle_estimate_points)...) - 0.01; max(map(x -> x[2], _y_euler_angle_estimate_points)...) + 0.01]
        ylims3 = [min(P_parameters...) - 0.01; max(P_parameters...) + 0.01]
        ylims!(ax1, ylims1[1], ylims1[2])
        ylims!(ax2, ylims2[1], ylims2[2])
        ylims!(ax3, ylims3[1], ylims3[2])
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
end

on(buttons[3].clicks) do n
    global run = true
    record(lscene.scene, joinpath("gallery", "$modelname.mp4"); framerate=fps) do io
        for i = 1:iterations
            if run == false
                recordtext[] = "Not recording."
                break
            end
            sleep(1 / fps * 0.7)
            # stepforward()
            recordframe!(io)
            # println("Recorded frame $i out of $iterations frames.")
            recordtext[] = "Recorded frame $i / $iterations."
        end
        global run = false
    end
end

on(events(fig).tick) do tick
    if !isnothing(clientside) && isopen(clientside)
        stepforward()
    end
end