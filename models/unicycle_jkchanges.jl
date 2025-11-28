using FileIO
using LinearAlgebra
using GLMakie
using CSV
using Porta


# to plot the j and k time indices along with the changes in filter coefficients in one graph
figuresize = (1920, 1080)
datafilename = "take004_unicycle_tilt_estimation"
modelname = "$(datafilename)_jkchanges"
headers = ["changes", "time", "active", "AX1", "AY1", "AZ1", "AX2", "AY2", "AZ2", "roll", "pitch", "encT", "encB", "j", "k", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"]
readings = Dict()
fontsize = 30
markersize = 15
xminorticksize = 20.0
jlinecolor = :yellow
klinecolor = :green
changeslinecolor = :blue
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
ax1 = Axis(fig[1, 1], title = "Time k (value iteration) x Time j (policy iteration)", xlabel = "Time (sec)", ylabel = "time j",
           yticklabelcolor = jlinecolor, xlabelsize = fontsize, ylabelsize=fontsize, xminorticksvisible = true, xminorgridvisible = true,
           xminorticksize = xminorticksize, xticks = xticks)

ax2 = Axis(fig[1, 1], xlabel="Time (sec)",
           ylabel = "time k", xlabelsize = fontsize, ylabelsize = fontsize, xminorticksvisible = true, xminorgridvisible = true,
           yticklabelcolor = klinecolor, yaxisposition = :right, xminorticksize = xminorticksize)
hidespines!(ax2)
hidexdecorations!(ax2)

ax3 = Axis(fig[1, 2], title = "Sum of W_n - W_{n-1} after an iteration of RLS x The inverse auto-correlation matrix P", xlabel = "Time (sec)", ylabel = "changes",
           yticklabelcolor = changeslinecolor, xlabelsize = fontsize, ylabelsize = fontsize, xminorticksvisible = true,
           xminorgridvisible = true, xminorticksize = xminorticksize, xticks = xticks)

ax4 = Axis(fig[1, 2], xlabel="Time (sec)",
           ylabel = "P Matrix Parameters", xlabelsize = fontsize, ylabelsize = fontsize, xminorticksvisible = true, xminorgridvisible = true,
           yticklabelcolor = :purple, yaxisposition = :right, xminorticksize = xminorticksize)
hidespines!(ax4)
hidexdecorations!(ax4)

graphpoints1 = Point2f[(0, 0)]
graphpoints2 = Point2f[(0, 0)]
graphpoints3 = Point2f[(0, 0)]
graphpoints4 = [Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)]]

for i in 1:number
    text = file[i]
    for header in headers
        readings[header] = text[Symbol(header)]
    end
    timestamp = readings["time"]
    j = readings["j"]
    k = readings["k"]
    changes = readings["changes"]
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
    push!(graphpoints1, Point2f(timestamp, j))
    push!(graphpoints2, Point2f(timestamp, k))
    push!(graphpoints3, Point2f(timestamp, changes))
    push!(graphpoints4[1], Point2f(timestamp, P0))
    push!(graphpoints4[2], Point2f(timestamp, P1))
    push!(graphpoints4[3], Point2f(timestamp, P2))
    push!(graphpoints4[4], Point2f(timestamp, P3))
    push!(graphpoints4[5], Point2f(timestamp, P4))
    push!(graphpoints4[6], Point2f(timestamp, P5))
    push!(graphpoints4[7], Point2f(timestamp, P6))
    push!(graphpoints4[8], Point2f(timestamp, P7))
    push!(graphpoints4[9], Point2f(timestamp, P8))
    push!(graphpoints4[10], Point2f(timestamp, P9))
    push!(graphpoints4[11], Point2f(timestamp, P10))
    push!(graphpoints4[12], Point2f(timestamp, P11))
end
jline = scatter!(ax1, graphpoints1, color = jlinecolor, markersize = markersize, marker = :rect)
kline = scatter!(ax2, graphpoints2, color = klinecolor, markersize = markersize)
changesline = scatter!(ax3, graphpoints3, color = changeslinecolor, markersize = markersize, marker = :rect)
p0line = scatter!(ax4, graphpoints4[1], color=:lavenderblush, markersize = markersize)
p1line = scatter!(ax4, graphpoints4[2], color=:plum1, markersize = markersize)
p2line = scatter!(ax4, graphpoints4[3], color=:thistle, markersize = markersize)
p3line = scatter!(ax4, graphpoints4[4], color=:orchid2, markersize = markersize)
p4line = scatter!(ax4, graphpoints4[5], color=:mediumorchid1, markersize = markersize)
p5line = scatter!(ax4, graphpoints4[6], color=:magenta2, markersize = markersize)
p6line = scatter!(ax4, graphpoints4[7], color=:lavenderblush4, markersize = markersize)
p7line = scatter!(ax4, graphpoints4[8], color=:magenta3, markersize = markersize)
p8line = scatter!(ax4, graphpoints4[9], color=:plum4, markersize = markersize)
p9line = scatter!(ax4, graphpoints4[10], color=:mediumorchid4, markersize = markersize)
p10line = scatter!(ax4, graphpoints4[11], color=:mediumpurple4, markersize = markersize)
p11line = scatter!(ax4, graphpoints4[12], color=:purple4, markersize = markersize)

axislegend(ax1, [jline, kline], ["time j", "time k"], "Time j x Time k", position = :cc, orientation = :horizontal, framevisible = false)
axislegend(ax3, [changesline, p0line, p1line, p2line, p3line, p4line, p5line, p6line, p7line, p8line, p9line, p10line, p11line],
                ["W_n - W_{n-1}", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"],
                "Incremental W_n filter changes x The diagonal parameters of P matrix", position = :cc, orientation = :horizontal, framevisible = false)

# to find the upper and lower bounds of data distribution
P_parameters = []
for x in graphpoints4
    for y in x
        push!(P_parameters, y[2])
    end
end

xlims!(ax1, begintime, endtime)
xlims!(ax2, begintime, endtime)
xlims!(ax3, begintime, endtime)
xlims!(ax4, begintime, endtime)
ylims1 = [min(map(x -> x[2], graphpoints1)...) - 0.01; max(map(x -> x[2], graphpoints1)...) + 0.01]
ylims2 = [min(map(x -> x[2], graphpoints2)...) - 0.01; max(map(x -> x[2], graphpoints2)...) + 0.01]
ylims3 = [min(map(x -> x[2], graphpoints3)...) - 0.01; max(map(x -> x[2], graphpoints3)...) + 0.01]
ylims4 = [min(P_parameters...) - 0.01; max(P_parameters...) + 0.01]
ylims!(ax1, ylims1[1], ylims1[2])
ylims!(ax2, ylims2[1], ylims2[2])
ylims!(ax3, ylims3[1], ylims3[2])
ylims!(ax4, ylims4[1], ylims4[2])


save(joinpath("gallery", "$modelname.png"), fig)