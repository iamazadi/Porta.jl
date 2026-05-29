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
headers = ["A", "B", "C", "D"]
readings = Dict()


disconnect(clientside) = begin
    if !isnothing(clientside)
        close(clientside)
    end
end


connect(clientside, ipaddress::String, portnumber::Int) = begin
    if !isnothing(clientside)
        disconnect(clientside)
    end
    # execute the command nc 192.168.4.1 10000 in terminal for testing
    clientside = Sockets.connect(ipaddress, portnumber)
    return clientside
end


makefigure() = Figure(size=figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw=(lights=[pl, al], clear=true, backgroundcolor=:black))

sg = SliderGrid(fig[2, 1],
    (label="Throttle", range=45:1:90, startvalue=45),
    (label="Rudder", range=20:1:160, startvalue=90),
    (label="Elevator", range=20:1:160, startvalue=90),
    (label="Ailorons", range=20:1:160, startvalue=90)
)

buttoncolor = RGBf(0.3, 0.3, 0.3)
buttonlabels = ["Connect", "Disconnect"]
buttons = [Button(fig[3, 1], label=l, buttoncolor=buttoncolor) for l in buttonlabels]
fig[3, 1] = grid!(hcat(buttons...), tellheight=true, tellwidth=false)

on(buttons[1].clicks) do n
    global clientside = connect(clientside, ipaddress, portnumber)
    if isopen(clientside)
        println("Connected.")
        message = "start\r\n"
        write(clientside, message)
    end
end

clientside = connect(clientside, ipaddress, portnumber)

on(sg.sliders[1].value) do val
    value1 = sg.sliders[1].value[]
    value2 = sg.sliders[2].value[]
    value3 = sg.sliders[3].value[]
    value4 = sg.sliders[4].value[]
    text1 = lpad(value1, 3, '0')
    text2 = lpad(value2, 3, '0')
    text3 = lpad(value3, 3, '0')
    text4 = lpad(value4, 3, '0')
    # rudder, elevator, ailorons, throttle
    message = "$(text2)$(text3)$(text4)$(text1)\r\n"
    write(clientside, message)
    in_text = readline(clientside, keep=true)
    filtered = replace(in_text, "\0" => "")
    filtered = replace(filtered, "\r\n" => "")
    readings = parsetext(filtered, headers)
    # calculate(readings)
    allkeys = keys(readings)
    flag = all([x ∈ allkeys for x in headers]) && all([!isnothing(readings[x]) for x in headers])
    if (flag && (!isapprox(readings["A"], value1) ||
                 !isapprox(readings["B"], value2) ||
                 !isapprox(readings["C"], value3) ||
                 !isapprox(readings["D"], value4)))
        write(clientside, message)
    end
end


clientside = connect(clientside, ipaddress, portnumber)

function send(sg)
    value1 = sg.sliders[1].value[]
    value2 = sg.sliders[2].value[]
    value3 = sg.sliders[3].value[]
    value4 = sg.sliders[4].value[]
    text1 = lpad(value1, 3, '0')
    text2 = lpad(value2, 3, '0')
    text3 = lpad(value3, 3, '0')
    text4 = lpad(value4, 3, '0')
    # rudder, elevator, ailorons, throttle
    message = "$(text2)$(text3)$(text4)$(text1)\r\n"
    write(clientside, message)
end

on(sg.sliders[1].value) do val
    send(sg)
end

on(sg.sliders[2].value) do val
    send(sg)
end

on(sg.sliders[3].value) do val
    send(sg)
end

on(sg.sliders[4].value) do val
    send(sg)
end

# readline(clientside, keep=true)

# message = "045045045045\r\n"
# write(clientside, message)

# readline(clientside, keep=true)