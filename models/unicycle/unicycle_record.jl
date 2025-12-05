using FileIO
using LinearAlgebra
using GLMakie
using Sockets
using CSV
using DataFrames
using Porta


ipaddress = "192.168.4.1"
portnumber = 10000
# headers = ["changes", "time", "active", "AX1", "AY1", "AZ1", "AX2", "AY2", "AZ2", "roll", "pitch", "encT", "encB", "j", "k", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"]
headers = ["changes", "time", "active", "AX1", "AY1", "AZ1", "roll", "pitch", "encT", "encB", "j", "k", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11"]
modelname = "sample5_dec4_unicycle_tiltestimation"
readings = Dict()
clientside = nothing
fps = 24
minutes = 2
iterations = minutes * 60 * fps
data = Dict()
for header in headers
    data[header] = []
end

disconnect(clientside) = begin
    if !isnothing(clientside)
        close(clientside)
    end
end

if !isnothing(clientside)
    disconnect(clientside)
end
# execute the command nc 192.168.4.1 10000 in terminal for testing
clientside = connect(ipaddress, portnumber)

if isopen(clientside)
    println("Connected.")
else
    println("Disconnected.")
end


elapsedtime = 0.0
begintime = 0.0
previoustime = 0.0
i = 1

while true
    text = []
    try
        if !isnothing(clientside) && isopen(clientside)
            push!(text, readline(clientside, keep=true))
        end
    catch e
        println(e)
    end
    if length(text) == 1
        text = text[1]
    else
        text = ""
    end
    # println(text)
    # x1k: -13.76, x2k: 1.60, u1k: -40.00, u2k: 43.36, x1k+: -13.76, x2k+: 1.60, u1k+: -40.00, u2k+: 43.36, dt: 0.000006
    filtered = replace(text, "\0" => "")
    filtered = replace(filtered, "\r\n" => "")
    global readings = parsetext(filtered, headers)
    # calculate(readings)
    allkeys = keys(readings)
    flag = all([x ∈ allkeys for x in headers]) && all([!isnothing(readings[x]) for x in headers])
    if flag
        global previoustime = readings["time"]
        for header in headers
            push!(data[header], readings[header])
        end
        if length(data["time"]) > 1
            elapsedtime = data["time"][end] - data["time"][begin]
            if elapsedtime > minutes * 60
                break
            end
        end
    end
    println("Recorded frame $i out of $iterations frames.")
    global i = i + 1
end

dataframe = DataFrame(data)
filepath = joinpath("data", "csv", "$modelname.csv")
CSV.write(filepath, dataframe)
println("Recorded $(length(data["time"])) frames.")