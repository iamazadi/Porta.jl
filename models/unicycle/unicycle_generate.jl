using FileIO
using LinearAlgebra
using GLMakie
using Sockets
using CSV
using DataFrames
using Porta


figuresize = (1920, 1080)
modelname = "sample2_dec8_unicycle_tiltestimation"
headers = ["changes", "time", "active", "AX1", "AY1", "AZ1", "AX2", "AY2", "AZ2", "roll", "pitch", "encT", "encB", "j", "k", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"]
readings = Dict()
segments = 360
fontsize = 30
textfontsize = 0.05
chassis_colormap = :matter
rollingwheel_colormap = :oxy
reactionwheel_colormap = :delta
markersize = 10
ballsize = 0.01
linewidth = 0.01
arrowsize = Vec3f(0.03, 0.03, 0.06)
arrowscale = 0.3
smallarrowscale = arrowscale * 0.5
chassis_stl_path = joinpath("data", "unicycle", "unicycle_chassis.STL")
rollingwheel_stl_path = joinpath("data", "unicycle", "unicycle_main_wheel.STL")
reactionwheel_stl_path = joinpath("data", "unicycle", "unicycle_reaction_wheel.STL")
chassis_scale = 0.001
rollingwheel_scale = 1.0
reactionwheel_scale = 1.0
wheelradius = 0.075
offset = 0.012 + wheelradius
# the robot body origin in the inertial frame Ô
chassis_origin = Point3f(-0.1, -0.1, -0.02)
# the pivot point B̂ in the inertial frame Ô
center = Point3f(-0.097, -0.1, -0.032)
pivot = center - Point3f(0.0, 0.0, wheelradius)
# the position of sensors mounted on the body in the body frame of reference
p1 = Point3f(-0.14000000286102293, -0.06500000149011612, -0.06200000151991844)
p2 = Point3f(-0.205, -0.055, -0.06)
rollingwheel_origin = Point3f(3.0, -12.0 + (1.0 / chassis_scale) * offset, 0.0)
reactionwheel_origin = Point3f(0.0, 153.0 + (1.0 / chassis_scale) * offset, 1.0)
x̂ = ℝ³(1.0, 0.0, 0.0)
ŷ = ℝ³(0.0, 1.0, 0.0)
ẑ = ℝ³(0.0, 0.0, 1.0)
# the vectors of the standard basis for the input space ℝ³
ê = [Vec3f(vec(x̂)), Vec3f(vec(ŷ)), Vec3f(vec(ẑ))]
transformation = [0.0 1.0 0.0; -1.0 0.0 0.0; 0.0 0.0 1.0]
B_O_R = convert(Matrix{Float64}, transformation * [ê[1] ê[2] ê[3]])
O_B_R = convert(Matrix{Float64}, inv(B_O_R))
# The rotation of the local frame of the sensor i to the robot frame B̂
B_A1_R = convert(Matrix{Float64}, transformation * [ê[1] ê[2] ê[3]])
A1_B_R = convert(Matrix{Float64}, inv(B_A1_R))
B_A2_R = convert(Matrix{Float64}, [ê[1] ê[2] ê[3]])
# B_A2_R = [-sin(α) cos(α) 0.0; -cos(α) -sin(α) 0.0; 0.0 0.0 1.0] # this is equal to B_O_R * B_A2_R the same as the one that is used on the device
A2_B_R = convert(Matrix{Float64}, inv(B_A2_R))
maxplotnumber = 800
timeaxiswindow= 30.0
fps = 24
minutes = 1
iterations = minutes * 60 * fps
data = Dict()
for header in headers
    data[header] = []
    readings[header] = []
end
filepath = joinpath("data", "csv", "$modelname.csv")
file = CSV.File(filepath)
color = load("data/basemap_mask.png")

eyeposition = normalize([0.0; 1.0; 0.0]) * 0.6
originaleyeposition = deepcopy(eyeposition)
up = [0.0; 0.0; 1.0]

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
backgroundcolor = RGBf(1.0, 1.0, 1.0)
lscene = LScene(fig[1:4, 2], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
ax1 = Axis(fig[1, 1], xlabel = "Time (sec)", ylabel = "x-Euler angle (rad)", xlabelsize = fontsize, ylabelsize = fontsize)
ax2 = Axis(fig[2, 1], xlabel = "Time (sec)", ylabel = "y-Euler angle (rad)", xlabelsize = fontsize, ylabelsize = fontsize)
ax3 = Axis(fig[3, 1], xlabel = "Time (sec)", ylabel = "P Matrix Parameters", xlabelsize = fontsize, ylabelsize = fontsize)

# buttoncolor = RGBf(0.3, 0.3, 0.3)
# buttons = [Button(fig, label=l, buttoncolor=buttoncolor) for l in buttonlabels]
controller_statustext = Observable("Deactive")
controller_statuslabel = Label(fig, controller_statustext, fontsize = fontsize)
jindextext = Observable("j: 1")
jindexlabel = Label(fig, jindextext, fontsize = fontsize)
kindextext = Observable("k: 1")
kindexlabel = Label(fig, kindextext, fontsize = fontsize)
recordtext = Observable("Not recording")
recordlabel = Label(fig, recordtext, fontsize = fontsize)
fig[4, 1] = grid!(hcat(controller_statuslabel, jindexlabel, kindexlabel, recordlabel), tellheight = true, tellwidth = false)
colsize!(fig.layout, 1, Relative(1 / 4))

unicycle = Unicycle(chassis_origin, offset, pivot, p1, p2, B_O_R, B_A1_R, B_A2_R, chassis_scale, rollingwheel_scale, reactionwheel_scale,
                    rollingwheel_origin, reactionwheel_origin, chassis_stl_path, rollingwheel_stl_path, reactionwheel_stl_path,
                    lscene, ax1, ax2, ax3, arrowscale, smallarrowscale, linewidth, arrowsize, markersize, ballsize, segments,
                    chassis_colormap, rollingwheel_colormap, reactionwheel_colormap, maxplotnumber, timeaxiswindow)

rotation = gettextrotation(lscene)
titles = ["X", "Y", "Z", "X₁", "Y₁", "Z₁", "X₂", "Y₂", "Z₂"]
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$(unicycle.origin_ps)[1] + $(unicycle.origin_ns)[1],
                                                      $(unicycle.origin_ps)[2] + $(unicycle.origin_ns)[2],
                                                      $(unicycle.origin_ps)[3] + $(unicycle.origin_ns)[3],
                                                      $(unicycle.sensor1frame_tails)[1] + $(unicycle.sensor1frame_heads)[1],
                                                      $(unicycle.sensor1frame_tails)[2] + $(unicycle.sensor1frame_heads)[2],
                                                      $(unicycle.sensor1frame_tails)[3] + $(unicycle.sensor1frame_heads)[3],
                                                      $(unicycle.sensor2frame_tails)[1] + $(unicycle.sensor2frame_heads)[1],
                                                      $(unicycle.sensor2frame_tails)[2] + $(unicycle.sensor2frame_heads)[2],
                                                      $(unicycle.sensor2frame_tails)[3] + $(unicycle.sensor2frame_heads)[3]])),
    text = titles,
    color = [:red, :green, :blue, :crimson, :chartreuse4, :indigo, :firebrick1, :seagreen, :deepskyblue2],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = textfontsize,
    markerspace = :data
)

lspaceθ = range(π / 2, stop = -π / 2, length = segments)
lspaceϕ = range(float(π), stop = float(-π), length = segments)
planematrix = [project(convert_to_cartesian([1.0; θ; ϕ]))- ℝ³(0.0, 0.0, 1.23 * offset) for θ in lspaceθ, ϕ in lspaceϕ]
planeobservable = buildsurface(lscene, planematrix, color, transparency = true)

lookat = deepcopy(pivot) + [0.0; 0.0; offset]
update_cam!(lscene.scene, Vec3f(eyeposition...), Vec3f(lookat...), Vec3f(up...))

period = file[end][:time] - file[begin][:time]

record(lscene.scene, joinpath("gallery", "$modelname.mp4"); framerate=fps) do io
    framesnumber = length(file)
    iterations = Int(floor(period * fps))

    for i = 1:iterations
        progress = float(i) / float(iterations)
        currenttime =  file[begin][:time] + progress * period
        for j in 1:framesnumber
            _time = file[j][:time]
            if _time ≥ currenttime
                println(_time)
                text = file[j]
                # println(text)
                for header in headers
                    readings[header] = text[Symbol(header)]
                end
                updatemodel(unicycle, readings)
                controller_statustext[] = isapprox(readings["active"], 1.0) ? "Active" : "Deactive"
                jindextext[] = "j: $(readings["j"])"
                kindextext[] = "k: $(readings["k"])"
                global lookat = vec(to_value(unicycle.translation) + ℝ³(0.0, 0.0, offset))
                global eyeposition = ℝ³(Float64.(vec(lookat))...) + (0.95 * norm(originaleyeposition - lookat) + 0.05 * cos(progress * 2π)) * normalize(ℝ³(Float64.(vec(originaleyeposition))...) - ℝ³(Float64.(vec(lookat))...))
                global eyeposition = (exp(-progress * period * 0.3) * ℝ³(5.0, 5.0, 5.0)) + eyeposition
                update_cam!(lscene.scene, Vec3f(vec(eyeposition)...), Vec3f(vec(lookat)...), Vec3f(vec(up)...))
                break
            end
        end
        sleep(1 / fps)
        recordframe!(io)
        recordtext[] = "frame $i/$iterations"
    end
end