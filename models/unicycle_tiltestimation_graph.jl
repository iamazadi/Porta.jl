using FileIO
using LinearAlgebra
using GLMakie
using CSV
using Porta


figuresize = (1920, 1080)
datafilename = "take004_unicycle_tilt_estimation"
modelname = "$(datafilename)_graph"
headers = ["changes", "time", "active", "AX1", "AY1", "AZ1", "AX2", "AY2", "AZ2", "roll", "pitch", "encT", "encB", "j", "k", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"]
readings = Dict()
fontsize = 30
markersize = 10
xminorticksize = 20.0
labelsize = 20
titlesize = 25
singleacc_linecolor = :green
doubleacc_linecolor = :blue
gyrofused_linecolor = :orange
singleacc_marker = :rect
doubleacc_marker = :circle
gyrofused_marker = :utriangle
data = Dict()
for header in headers
    data[header] = []
    readings[header] = []
end
filepath = joinpath("data", "csv", "$datafilename.csv")
file = CSV.File(filepath)
number = length(file)
begintime = file[begin][:time]
endtime = file[end][:time]
period = endtime - begintime
beginsecond = Int(floor(begintime))
endsecond = Int(floor(endtime))
sequence = beginsecond:5:endsecond
xticks = (sequence, ["$(round(x))" for x in sequence])

makefigure() = Figure(size=figuresize)
fig = with_theme(makefigure, theme_black())
axis1 = Axis(fig[1, 1], title = "The x-Euler angle", xlabel = "Time (sec)", ylabel = "roll",
             xlabelsize = fontsize, ylabelsize=fontsize, xminorticksvisible = true, xminorgridvisible = true,
             xminorticksize = xminorticksize, xticks = xticks, titlesize = titlesize)
axis2 = Axis(fig[1, 2], title = "The y-Euler angle", xlabel = "Time (sec)", ylabel = "pitch",
             xlabelsize = fontsize, ylabelsize=fontsize, xminorticksvisible = true, xminorgridvisible = true,
             xminorticksize = xminorticksize, xticks = xticks, titlesize = titlesize)

roll_graphpoints = [Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)]]
pitch_graphpoints = [Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)]]

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
# the vectors of the standard basis for the input space ℝ³
ê = [Vec3f(vec(x̂)), Vec3f(vec(ŷ)), Vec3f(vec(ẑ))]
# The rotation of the inertial frame Ô to the body frame B̂
α = 0.0
transformation = [-sin(α) cos(α) 0.0; -cos(α) -sin(α) 0.0; 0.0 0.0 1.0]
# The rotation of the local frame of the sensor i to the robot frame B̂
B_A1_R = convert(Matrix{Float64}, transformation * [ê[1] ê[2] ê[3]])
α = 30.0 / 180.0 * π # imu2angle
B_A2_R = convert(Matrix{Float64}, [cos(α) sin(α) 0.0; -sin(α) cos(α) 0.0; 0.0 0.0 1.0] * [ê[1] ê[2] ê[3]])

# the pivot point B̂ in the inertial frame Ô
pivot = Point3f(-0.097, -0.1, -0.032)
# the position of sensors mounted on the body in the body frame of reference
p1 = Point3f(-0.14000000286102293, -0.06500000149011612, -0.06200000151991844)
p2 = Point3f(-0.04000000286102295, -0.06000000149011612, -0.06000000151991844)
P = [[1.0; vec(p1 - pivot)] [1.0; vec(p2 - pivot)]]
X = transpose(P) * inv(P * transpose(P))

for i in 1:number
    text = file[i]
    for header in headers
        readings[header] = text[Symbol(header)]
    end
    timestamp = readings["time"]
    roll = readings["roll"]
    pitch = readings["pitch"]
    push!(roll_graphpoints[3], Point2f(timestamp, roll))
    push!(pitch_graphpoints[3], Point2f(timestamp, pitch))
    
    R1 = [readings["AX1"]; readings["AY1"]; readings["AZ1"]]
    R2 = [readings["AX2"]; readings["AY2"]; readings["AZ2"]]
    ĝ = deepcopy(R1)
    β = atan(-ĝ[1], √(ĝ[2]^2 + ĝ[3]^2))
    γ = atan(ĝ[2], ĝ[3])
    push!(roll_graphpoints[1], Point2f(timestamp, β))
    push!(pitch_graphpoints[1], Point2f(timestamp, -γ))

    M = [B_A1_R * R1 B_A2_R * R2]
    ĝ = (M * X)[:, 1]
    β = atan(-ĝ[1], √(ĝ[2]^2 + ĝ[3]^2))
    γ = atan(ĝ[2], ĝ[3])
    push!(roll_graphpoints[2], Point2f(timestamp, β))
    push!(pitch_graphpoints[2], Point2f(timestamp, -γ))
end

singleacc_roll_line = scatter!(axis1, roll_graphpoints[1], color = singleacc_linecolor, markersize = markersize, marker = singleacc_marker)
doubleacc_roll_line = scatter!(axis1, roll_graphpoints[2], color = doubleacc_linecolor, markersize = markersize, marker = doubleacc_marker)
gyrofused_roll_line = scatter!(axis1, roll_graphpoints[3], color = gyrofused_linecolor, markersize = markersize, marker = gyrofused_marker)
singleacc_pitch_line = scatter!(axis2, pitch_graphpoints[1], color = singleacc_linecolor, markersize = markersize, marker = singleacc_marker)
doubleacc_pitch_line = scatter!(axis2, pitch_graphpoints[2], color = doubleacc_linecolor, markersize = markersize, marker = doubleacc_marker)
gyrofused_pitch_line = scatter!(axis2, pitch_graphpoints[3], color = gyrofused_linecolor, markersize = markersize, marker = gyrofused_marker)

axislegend(axis1, [singleacc_roll_line, doubleacc_roll_line, gyrofused_roll_line],
           ["the x-Euler angle estimate if only a single tri-axis accelerometer is used", "the accelerometric estimate of x-Euler angle",
            "the accelerometric estimate fused with rate gyro data"],
            "The x-Euler angle estimate", position = :rb, orientation = :vertical, framevisible = false, labelsize = labelsize,
            titlesize = titlesize)
axislegend(axis2, [singleacc_pitch_line, doubleacc_pitch_line, gyrofused_pitch_line],
           ["the y-Euler angle estimate if only a single tri-axis accelerometer is used", "the accelerometric estimate of y-Euler angle",
            "the accelerometric estimate fused with rate gyro data"],
           "The y-Euler angle estimate", position = :rb, orientation = :vertical, framevisible = false, labelsize = labelsize,
           titlesize = titlesize)

# to find the upper and lower bounds of data distribution
xlims!(axis1, begintime, endtime)
xlims!(axis2, begintime, endtime)
ylims1 = [min(map(x -> x[2], roll_graphpoints[1])...) - 0.01; max(map(x -> x[2], roll_graphpoints[1])...) + 0.01]
ylims2 = [min(map(x -> x[2], pitch_graphpoints[1])...) - 0.01; max(map(x -> x[2], pitch_graphpoints[1])...) + 0.01]
ylims!(axis1, ylims1[1], ylims1[2])
ylims!(axis2, ylims2[1], ylims2[2])

save(joinpath("gallery", "$modelname.png"), fig)