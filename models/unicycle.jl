using FileIO
using LinearAlgebra
using GLMakie
using Sockets
using CSV
using DataFrames
using Porta


figuresize = (1920, 1080)
modelname = "unicycle_tilt_estimation"
maxplotnumber = 200
timeaxiswindow = 15
headers = ["changes", "time", "active", "AX1", "AY1", "AZ1", "AX2", "AY2", "AZ2", "roll", "pitch", "encT", "encB", "j", "k", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"]
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
chassis_colormap = :roma
rollingwheel_colormap = :cyclic_mrybm_35_75_c68_n256_s25
reactionwheel_colormap = :diverging_rainbow_bgymr_45_85_c67_n256
recordedtime = 0.0
markersize = 15
data = Dict()
for header in headers
    data[header] = []
end

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

reorder(x) = [x[2]; -x[1]; x[3]]

eyeposition = normalize([0.04; -0.45; -0.17]) * 0.5
view_direction = normalize([-0.28; 0.81; 0.50])
lookat = eyeposition + view_direction
up = [0.0; 0.0; 1.0]
arrowsize = Observable(Vec3f(0.03, 0.03, 0.06))
linewidth = Observable(0.02)
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
jindextext = Observable("j: 1")
jindexlabel = Label(fig, jindextext, fontsize = fontsize)
kindextext = Observable("k: 1")
kindexlabel = Label(fig, kindextext, fontsize = fontsize)
recordtext = Observable("Not recording.")
recordlabel = Label(fig, recordtext, fontsize = fontsize)
fig[3, 1] = grid!(hcat(connection_statuslabel, controller_statuslabel, jindexlabel, kindexlabel, recordlabel), tellheight=true, tellwidth=false)
fig[3, 2] = grid!(hcat(buttons...), tellheight=true, tellwidth=false)

graphpoints1 = Observable([Point2f[(0, 0)], Point2f[(0, 0)]])
graphpoints2 = Observable([Point2f[(0, 0)], Point2f[(0, 0)]])
graphpoints3 = Observable([Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)]])

x_euler_angle_raw_lineobject = scatter!(ax1, @lift(($graphpoints1)[1]), color=:green, markersize = markersize)
y_euler_angle_raw_lineobject = scatter!(ax2, @lift(($graphpoints2)[1]), color=:blue, markersize = markersize)
x_euler_angle_estimate_lineobject = scatter!(ax1, @lift(($graphpoints1)[2]), color=:lightgreen, markersize = markersize)
y_euler_angle_estimate_lineobject = scatter!(ax2, @lift(($graphpoints2)[2]), color=:lightblue, markersize = markersize)
P0_lineobject = scatter!(ax3, @lift(($graphpoints3)[1]), color=:lavenderblush, markersize = markersize)
P1_lineobject = scatter!(ax3, @lift(($graphpoints3)[2]), color=:plum1, markersize = markersize)
P2_lineobject = scatter!(ax3, @lift(($graphpoints3)[3]), color=:thistle, markersize = markersize)
P3_lineobject = scatter!(ax3, @lift(($graphpoints3)[4]), color=:orchid2, markersize = markersize)
P4_lineobject = scatter!(ax3, @lift(($graphpoints3)[5]), color=:mediumorchid1, markersize = markersize)
P5_lineobject = scatter!(ax3, @lift(($graphpoints3)[6]), color=:magenta2, markersize = markersize)
P6_lineobject = scatter!(ax3, @lift(($graphpoints3)[7]), color=:lavenderblush4, markersize = markersize)
P7_lineobject = scatter!(ax3, @lift(($graphpoints3)[8]), color=:magenta3, markersize = markersize)
P8_lineobject = scatter!(ax3, @lift(($graphpoints3)[9]), color=:plum4, markersize = markersize)
P9_lineobject = scatter!(ax3, @lift(($graphpoints3)[10]), color=:mediumorchid4, markersize = markersize)
P10_lineobject = scatter!(ax3, @lift(($graphpoints3)[11]), color=:mediumpurple4, markersize = markersize)
P11_lineobject = scatter!(ax3, @lift(($graphpoints3)[12]), color=:purple4, markersize = markersize)

chassis_stl = load(chassis_stl_path)
reactionwheel_stl = load(reactionwheel_stl_path)
rollingwheel_stl = load(rollingwheel_stl_path)

pivot_observable = Observable(pivot)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap, transparency = true)
rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap, transparency = true)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap, transparency = true)

pivotball = meshscatter!(lscene, pivot_observable, markersize=0.01, color=:gold)

arrowscale = 0.4
smallarrowscale = arrowscale * 0.7
R1_tail = vec(p1)
R2_tail = vec(p2)
R1 = [0.0; 0.0; -1.0] .* arrowscale
R2 = [0.0; 0.0; -1.0] .* arrowscale

acceleration_vector_tails = Observable([Point3f(R1_tail...), Point3f(R2_tail...)])
acceleration_vector_heads = Observable([Vec3f(R1...), Vec3f(R2...)])
arrowsize = Observable(Vec3f(0.02, 0.02, 0.04))
linewidth = Observable(0.02)
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
linewidth1 = Observable(0.02)
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
sphere_color_p1 = [RGBAf(1.0, 1.0, 0.0, 0.8) for ϕ in lspaceϕ, θ in lspaceθ]
sphere_color_p2 = [RGBAf(0.0, 1.0, 0.0, 0.8) for ϕ in lspaceϕ, θ in lspaceθ]
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


on(events(fig).tick) do tick
    if !isnothing(clientside) && isopen(clientside)
        previoustext = []
        try
            if !isnothing(clientside) && isopen(clientside)
                push!(previoustext, readline(clientside, keep=true))
            end
        catch e
            println(e)
        end
        # check to see if there are changes
        text = ""
        if length(previoustext) == 0
            return
        elseif length(previoustext) == 1
            text = previoustext[1]
        end
        filtered = replace(text, "\0" => "")
        filtered = replace(filtered, "\r\n" => "")
        global readings = parsetext(filtered, headers)
        # calculate(readings)
        allkeys = keys(readings)
        flag = all([x ∈ allkeys for x in headers]) && all([!isnothing(readings[x]) for x in headers])
        if flag
            for header in headers
                readings[header] = text[Symbol(header)]
            end
            if run == true
                for header in headers
                    push!(data[header], readings[header])
                end
            end
            iscontrolleractive = readings["active"]
            controller_statustext[] = isapprox(iscontrolleractive, 1.0) ? "Active" : "Deactive"
            jindextext[] = "j: $(readings["j"])"
            kindextext[] = "k: $(readings["k"])"
            if run == true
                recordtext[] = "Recorded frame $(length(data["time"]))."
            end
            stepforward(readings)
        end
    end
end


connect(clientside, ipaddress::String, portnumber::Int)= begin
    if !isnothing(clientside)
        disconnect(clientside)
    end
    # execute the command nc 192.168.4.1 10000 in terminal for testing
    clientside = Sockets.connect(ipaddress, portnumber)
    return
end

disconnect(clientside) = begin
    if !isnothing(clientside)
        close(clientside)
    end
end

on(buttons[1].clicks) do n
    clientside = connect(clientside, ipaddress, portnumber)
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

on(buttons[3].clicks) do n
    global run = true
end

on(buttons[4].clicks) do n
    global run = false
    dataframe = DataFrame(data)
    filepath = joinpath("data", "$modelname.csv")
    CSV.write(filepath, dataframe)
    recordtext[] = "Recorded $(length(data["time"])) frames."
end