using FileIO
using LinearAlgebra
using GLMakie
using Sockets
using CSV
using DataFrames
using Porta


clientside = nothing
run = false
ipaddress = "192.168.4.1"
portnumber = 10000
figuresize = (1920, 1080)
modelname = "unicycle_tilt_estimation"
headers = ["changes", "time", "active", "AX1", "AY1", "AZ1", "AX2", "AY2", "AZ2", "roll", "pitch", "encT", "encB", "j", "k", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"]
readings = Dict()
segments = 30
fontsize = 30
chassis_colormap = :Pastel1_9
rollingwheel_colormap = :autumn
reactionwheel_colormap = :glasbey_bw_minc_20_hue_330_100_n256
markersize = 10
ballsize = 0.01
linewidth = 0.01
arrowsize = Vec3f(0.02, 0.02, 0.04)
arrowscale = 0.25
smallarrowscale = arrowscale * 0.5
chassis_stl_path = joinpath("data", "unicycle", "unicycle_chassis.STL")
rollingwheel_stl_path = joinpath("data", "unicycle", "unicycle_main_wheel.STL")
reactionwheel_stl_path = joinpath("data", "unicycle", "unicycle_reaction_wheel.STL")
chassis_scale = 0.001
rollingwheel_scale = 1.0
reactionwheel_scale = 1.0
# the robot body origin in the inertial frame Ô
origin = Point3f(-0.1, -0.1, -0.02)
# the pivot point B̂ in the inertial frame Ô
pivot = Point3f(-0.097, -0.1, -0.032)
# the position of sensors mounted on the body in the body frame of reference
p1 = Point3f(-0.14000000286102293, -0.06500000149011612, -0.06200000151991844)
p2 = Point3f(-0.04000000286102295, -0.06000000149011612, -0.06000000151991844)
rollingwheel_origin = Point3f(3.0, -12.0, 0.0)
reactionwheel_origin = Point3f(0.0, 153.0, 1.0)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
# the vectors of the standard basis for the input space ℝ³
ê = [Vec3f(vec(x̂)), Vec3f(vec(ŷ)), Vec3f(vec(ẑ))]
# The rotation of the inertial frame Ô to the body frame B̂
α = 0.0
transformation = [-sin(α) cos(α) 0.0; -cos(α) -sin(α) 0.0; 0.0 0.0 1.0]
B_O_R = convert(Matrix{Float64}, transformation * [ê[1] ê[2] ê[3]])
O_B_R = convert(Matrix{Float64}, inv(B_O_R))
# The rotation of the local frame of the sensor i to the robot frame B̂
B_A1_R = convert(Matrix{Float64}, transformation * [ê[1] ê[2] ê[3]])
A1_B_R = convert(Matrix{Float64}, inv(B_A1_R))
α = 30.0 / 180.0 * π # imu2angle
B_A2_R = convert(Matrix{Float64}, [cos(α) sin(α) 0.0; -sin(α) cos(α) 0.0; 0.0 0.0 1.0] * [ê[1] ê[2] ê[3]])
# B_A2_R = [-sin(α) cos(α) 0.0; -cos(α) -sin(α) 0.0; 0.0 0.0 1.0] # this is equal to B_O_R * B_A2_R the same as the one that is used on the device
A2_B_R = convert(Matrix{Float64}, inv(B_A2_R))
maxplotnumber = 400
timeaxiswindow= 15.0
fps = 24
minutes = 1
iterations = minutes * 60 * fps
data = Dict()
for header in headers
    data[header] = []
end

eyeposition = normalize([1.0; 1.0; 1.0]) * 0.5
up = [0.0; 0.0; 1.0]

makefigure() = Figure(size=figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
backgroundcolor = RGBf(1.0, 1.0, 1.0)
lscene = LScene(fig[1:4, 2], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
ax1 = Axis(fig[1, 1], xlabel="Time (sec)", ylabel="x-Euler angle (rad)", xlabelsize=fontsize, ylabelsize=fontsize)
ax2 = Axis(fig[2, 1], xlabel="Time (sec)", ylabel="y-Euler angle (rad)", xlabelsize=fontsize, ylabelsize=fontsize)
ax3 = Axis(fig[3, 1], xlabel="Time (sec)", ylabel="P Matrix Parameters", xlabelsize=fontsize, ylabelsize=fontsize)
buttoncolor = RGBf(0.3, 0.3, 0.3)
buttonlabels = ["Connect", "Disconnect", "Record", "Stop"]
buttons = [Button(fig, label=l, buttoncolor=buttoncolor) for l in buttonlabels]
connection_statustext = Observable("Disconnected")
connection_statuslabel = Label(fig, connection_statustext, fontsize = fontsize)
controller_statustext = Observable("Deactive")
controller_statuslabel = Label(fig, controller_statustext, fontsize = fontsize)
jindextext = Observable("j: 1")
jindexlabel = Label(fig, jindextext, fontsize = fontsize)
kindextext = Observable("k: 1")
kindexlabel = Label(fig, kindextext, fontsize = fontsize)
recordtext = Observable("Not recording")
recordlabel = Label(fig, recordtext, fontsize = fontsize)
fig[4, 2] = grid!(hcat(connection_statuslabel, controller_statuslabel, jindexlabel, kindexlabel, recordlabel), tellheight = true, tellwidth = false)
fig[4, 1] = grid!(hcat(buttons...), tellheight = true, tellwidth = false)
colsize!(fig.layout, 1, Relative(1/4))

unicycle = Unicycle(origin, pivot, p1, p2, B_O_R, B_A1_R, B_A2_R, chassis_scale, rollingwheel_scale, reactionwheel_scale,
                    rollingwheel_origin, reactionwheel_origin, chassis_stl_path, rollingwheel_stl_path, reactionwheel_stl_path,
                    lscene, ax1, ax2, ax3, arrowscale, smallarrowscale, linewidth, arrowsize, markersize, ballsize, segments,
                    chassis_colormap, rollingwheel_colormap, reactionwheel_colormap, maxplotnumber, timeaxiswindow)

lookat = deepcopy(pivot)
update_cam!(lscene.scene, Vec3f(eyeposition...), Vec3f(lookat...), Vec3f(up...))

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
        readings = parsetext(filtered, headers)
        # calculate(readings)
        allkeys = keys(readings)
        flag = all([x ∈ allkeys for x in headers]) && all([!isnothing(readings[x]) for x in headers])
        if flag
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
                recordtext[] = "frame $(length(data["time"]))"
            end
            updatemodel(unicycle, readings)
        end
    end
end


disconnect(clientside) = begin
    if !isnothing(clientside)
        close(clientside)
    end
end


connect(clientside, ipaddress::String, portnumber::Int)= begin
    if !isnothing(clientside)
        disconnect(clientside)
    end
    # execute the command nc 192.168.4.1 10000 in terminal for testing
    clientside = Sockets.connect(ipaddress, portnumber)
    return clientside
end


on(buttons[1].clicks) do n
    global clientside = connect(clientside, ipaddress, portnumber)
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
    filepath = joinpath("data", "csv", "$modelname.csv")
    CSV.write(filepath, dataframe)
    recordtext[] = "$(length(data["time"])) frames"
end