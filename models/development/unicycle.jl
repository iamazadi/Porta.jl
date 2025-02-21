using FileIO
using LinearAlgebra
using GLMakie
using Sockets
using Porta


figuresize = (1920, 1080)
segments = 30
frames_number = 360
modelname = "unicycle"
maxplotnumber = 500
plotsampleratio = 0.9

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

eyeposition = LinearAlgebra.normalize([0.9, 0.3, 1.0]) .* 0.55
lookat = [-0.1, -0.1, 0.1]
up = [0.0; 0.0; 1.0]
arrowsize = Observable(Vec3f(0.02, 0.02, 0.03))
linewidth = Observable(0.01)
arrowscale = 0.1

# the robot body origin in the inertial frame Ô
origin = Point3f(-0.1, -0.1, -0.02)
# the pivot point B̂ in the inertial frame Ô
pivot = Point3f(-0.097, -0.1, -0.032)
# the vectors of the standard basis for the input space ℝ³
ê = [Vec3f(1, 0, 0), Vec3f(0, 1, 0), Vec3f(0, 0, 1)]
# The rotation of the inertial frame Ô to the body frame B̂
O_B_R = [ê[1] ê[2] ê[3]]
B_O_R = inv(O_B_R)

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

chassis_colormap = :inferno
rollingwheel_colormap = :rainbow
reactionwheel_colormap = :plasma

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
backgroundcolor = RGBf(1.0, 1.0, 1.0)
lscene = LScene(fig[1, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :white))
ax1 = Axis(fig[2, 1], xlabel = "Time (s)", ylabel = "System States")
ax2 = Axis(fig[2, 2], xlabel = "Time (s)", ylabel = "P Matrix Parameters")
buttoncolor = RGBf(0.3, 0.3, 0.3)
buttonlabels = ["Run", "Stop", "Connect", "Disconnect"]
buttons = [Button(fig, label = l, buttoncolor = buttoncolor) for l in buttonlabels]
statustext = Observable("Not connected.")
statuslabel = Label(fig, statustext)
fig[1, 2] = grid!(hcat(statuslabel, buttons...), tellheight = false, tellwidth = false)


rollpoints = Observable(Point2f[(0, 0)])
pitchpoints = Observable(Point2f[(0, 0)])

linegraphx2 = Observable(0..10)
linegraphy2 = Observable(cos)
roll_lineobject = scatter!(ax1, rollpoints, color = :red)
pitch_lineobject = scatter!(ax1, pitchpoints, color = :green)
lineobject2 = lines!(ax2, linegraphx2, linegraphy2, color = :blue)

chassis_stl = load(chassis_stl_path)
reactionwheel_stl = load(reactionwheel_stl_path)
rollingwheel_stl = load(rollingwheel_stl_path)

pivot_observable = Observable(pivot)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap)

pivotball = meshscatter!(lscene, pivot_observable, markersize = 0.01, color = :gold)

pivot_ps = Observable([pivot_observable[], pivot_observable[], pivot_observable[]])
pivot_ns = Observable(map(x -> x .* arrowscale, ê))
arrows!(lscene,
    pivot_ps, pivot_ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)

lookat = deepcopy(pivot)
update_cam!(lscene.scene, Vec3f(eyeposition...), Vec3f(lookat...), Vec3f(up...))
reaction_angle = 0.0
rolling_angle = 0.0


clientside = nothing
run = false


disconnect(clientside) = begin
    if !isnothing(clientside)
        close(clientside)
    end
end


on(buttons[1].clicks) do n
    global run = true
    errormonitor(@async while (isopen(clientside) && run)
        text = readline(clientside, keep = true)
        println(text)
        readings = parsetext(text)
        flag = "roll" in keys(readings) && "pitch" in keys(readings) && "v1" in keys(readings) && "v2" in keys(readings) &&
            !isnothing(readings["roll"]) && !isnothing(readings["pitch"]) && !isnothing(readings["v1"]) && !isnothing(readings["v2"])
        if flag
            roll = readings["roll"] / 180.0 * π
            pitch = -readings["pitch"] / 180.0 * π
            if rand() > plotsampleratio # skip samples in order to make the plotter interface closer to real time
                timestamp = length(rollpoints[]) + 1
                roll_point = Point2f(timestamp, roll)
                pitch_point = Point2f(timestamp, pitch)
                rollpoints[] = push!(rollpoints[], roll_point)
                pitchpoints[] = push!(pitchpoints[], pitch_point)
                number = length(rollpoints[])
                xlims!(ax1, number - maxplotnumber, number)
            end
            v1 = readings["v1"]
            v2 = readings["v2"]
            q = ℍ(roll, x̂) * ℍ(pitch, ŷ)
            O_B_R = mat3(q)
    
            g = q * chassis_q0
            GLMakie.rotate!(robot, Quaternion(g))
            pivot_observable[] = Point3f(O_B_R * (pivot - origin) + origin)
    
            pivot_ps[] = [Point3f(pivot_observable[]...), Point3f(pivot_observable[]...), Point3f(pivot_observable[]...)]
    
            global reaction_angle = reaction_angle + float(v1) / 45.0 * 0.1
            global rolling_angle = rolling_angle + float(v2) / 255.0 * 0.01
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