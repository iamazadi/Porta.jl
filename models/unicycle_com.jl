import GLMakie
import FileIO
import Makie
import MeshIO
import GeometryBasics
import LinearAlgebra
using LibSerialPort
using Sockets
using Porta


find_centerofmass(stl) = begin
    center_of_mass = [0.0; 0.0; 0.0]
    points_number = 0
    for tri in stl
        for point in tri
            center_of_mass = center_of_mass + point
            points_number += 1
        end
    end
    center_of_mass .* (1.0 / points_number)
end


make_sprite(scene, parent, origin, rotation, scale, stl, colormap) = begin
    center_of_mass = find_centerofmass(stl)
    # Create a child transformation from the parent
    child = GLMakie.Transformation(parent)
    # get the transformation of the parent
    ptrans = Makie.transformation(parent)

    # center the mesh to its origin, if we have one
    if !isnothing(origin)
        GLMakie.rotate!(child, rotation)
        GLMakie.scale!(child, scale, scale, scale)
        centered = stl.position .- GLMakie.Point3f(center_of_mass...)
        stl = GeometryBasics.Mesh(GeometryBasics.meta(centered; normals=stl.normals), GeometryBasics.faces(stl))
        GLMakie.translate!(child, origin) # translates the visual mesh in the viewport
    else
        # if we don't have an origin, we need to correct for the parents translation
        GLMakie.translate!(child, -ptrans.translation[])
    end
    # plot the part with transformation & color
    GLMakie.mesh!(scene, stl; color = [tri[1][2] for tri in stl for i in 1:3], colormap = colormap, transformation = child)
end


figuresize = (1080, 1920)
segments = 30
frames_number = 360
portname = "COM5"
baudrate = 460800
mainwheel_accumulator = 0.0
reactionwheel_accumulator = 0.0

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

eyeposition = [0.3, -0.3, -0.0]
lookat = [-0.1, -0.1, 0.0]
up = [0.0; 0.0; 1.0]

chassis_scale = 0.001
mainwheel_scale = 1.0
reactionwheel_scale = 1.0

chassis_origin = GLMakie.Point3f(-0.1, -0.1, -0.02)
mainwheel_origin = GLMakie.Point3f(3.0, -12.0, 0.0)
reactionwheel_origin = GLMakie.Point3f(0.0, 153.0, 1.0)

chassis_qx = Quaternion(0.0, x̂)
chassis_qy = Quaternion(0.0, ŷ)
chassis_qz = Quaternion(pi / 2.0, ẑ)
chassis_q0 = chassis_qx * chassis_qy * chassis_qz
chassis_rotation = GLMakie.Quaternion(vec(chassis_q0)...)
mainwheel_qx = Quaternion(0.0, x̂)
mainwheel_qy = Quaternion(0.0, ŷ)
mainwheel_qz = Quaternion(0.0, ẑ) # the axis of rotation
mainwheel_q0 = mainwheel_qx * mainwheel_qy * mainwheel_qz
mainwheel_rotation = GLMakie.Quaternion(vec(mainwheel_q0)...)
reactionwheel_qx = Quaternion(0.0, x̂)
reactionwheel_qy = Quaternion(0.0, ŷ)
reactionwheel_qz = Quaternion(0.0, ẑ) # the axis of rotation
reactionwheel_q0 = reactionwheel_qx * reactionwheel_qy * reactionwheel_qz
reactionwheel_rotation = GLMakie.Quaternion(vec(reactionwheel_q0)...)

chassis_stl_path = joinpath("data", "unicycle", "unicycle_chassis.STL")
mainwheel_stl_path = joinpath("data", "unicycle", "unicycle_main_wheel.STL")
reactionwheel_stl_path = joinpath("data", "unicycle", "unicycle_reaction_wheel.STL")

chassis_colormap = :grays
mainwheel_colormap = :greens
reactionwheel_colormap = :Purples

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(1.0, 1.0, 1.0)
lscene = GLMakie.LScene(fig[1, 1], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = backgroundcolor))

chassis_stl = FileIO.load(chassis_stl_path)
reactionwheel_stl = FileIO.load(reactionwheel_stl_path)
mainwheel_stl = FileIO.load(mainwheel_stl_path)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
mainwheel = make_sprite(lscene.scene, robot, mainwheel_origin, mainwheel_rotation, mainwheel_scale, mainwheel_stl, mainwheel_colormap)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap)

arrow_scale = 0.1
R1_tail = [-0.1, -0.1, 0.05]
R2_tail = [-0.1, -0.1, 0.05]
R3_tail = [-0.1, -0.1, 0.05]
R_tail = [-0.1, -0.1, 0.05]
R1 = [0.0; 0.0; -1.0] .* arrow_scale
R2 = [0.0; 0.0; -1.0] .* arrow_scale
R3 = [0.0; 0.0; -1.0] .* arrow_scale
R = [0.0; 0.0; -1.0] .* arrow_scale

ps = GLMakie.Observable([GLMakie.Point3f(R1_tail...), GLMakie.Point3f(R2_tail...), GLMakie.Point3f(R3_tail...), GLMakie.Point3f(R_tail...)])
ns = GLMakie.Observable([GLMakie.Vec3f(R1...), GLMakie.Vec3f(R2...), GLMakie.Vec3f(R3...),  GLMakie.Vec3f(R...)])
arrowsize = GLMakie.Observable(GLMakie.Vec3f(0.01, 0.02, 0.03))
linewidth = GLMakie.Observable(0.01)
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue, :orange],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :center
)

point1 = GLMakie.Observable(GLMakie.Point3f(-0.11, -0.19, 0.13))
point2 = GLMakie.Observable(GLMakie.Point3f(-0.11, -0.01, 0.13))
point3 = GLMakie.Observable(GLMakie.Point3f(-0.02, -0.01, -0.07))
point = GLMakie.Observable(GLMakie.Point3f(-0.1, -0.1, -0.02))
# ball = GLMakie.meshscatter!(lscene, point2, markersize = 0.01, color = :red)
reference_point1 = deepcopy(point1[])
reference_point2 = deepcopy(point2[])
reference_point3 = deepcopy(point3[])
reference_point = deepcopy(point[])
_p = Float64.([chassis_origin...])

lookat = deepcopy(_p)
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(up...))


list_ports()
ports = get_port_list()
serialport = LibSerialPort.open(portname, baudrate)
test_string = "R1: 0.26, 0.96, 0.09, R2: -0.50, -0.84, -0.21, R3: 0.31, 0.01, 0.95, R: 0.36, -0.04, 0.93, roll: 0.37, pitch: -0.05, v1: 0, v2: 54, dt = 0.007524, log_dt = 0.023078"

for i in 1:10000
    # while bytesavailable(serialport) < 1
    sleep(0.01)
    # end
    if bytesavailable(serialport) > 0
        text = String(read(serialport))
        println(text)
        if length(text) > 30
            index = findfirst("R1: ", text)
            if isnothing(index) continue end
            r1_text = replace(text, text[begin:index[end]] => "")
            if length(r1_text) < 3 continue end
            index = findfirst("R2:", r1_text)
            if isnothing(index) continue end
            r1_text = replace(r1_text, r1_text[index[begin]:end] => "")
            if length(r1_text) < 3 continue end
            r1_text = strip(r1_text)
            # println(r1_text)
            items = split(r1_text, ',')
            R1[1] = parse(Float64, items[1])
            R1[2] = parse(Float64, items[2])
            R1[3] = parse(Float64, items[3])

            index = findfirst("R2: ", text)
            if isnothing(index) continue end
            r2_text = replace(text, text[begin:index[end]] => "")
            if length(r2_text) < 3 continue end
            index = findfirst("R3:", r2_text)
            if isnothing(index) continue end
            r2_text = replace(r2_text, r2_text[index[begin]:end] => "")
            if length(r2_text) < 3 continue end
            r2_text = strip(r2_text)
            # println(r2_text)
            items = split(r2_text, ',')
            R2[1] = parse(Float64, items[1])
            R2[2] = parse(Float64, items[2])
            R2[3] = parse(Float64, items[3])

            index = findfirst("R3: ", text)
            if isnothing(index) continue end
            r3_text = replace(text, text[begin:index[end]] => "")
            if length(r3_text) < 3 continue end
            index = findfirst("R:", r3_text)
            if isnothing(index) continue end
            r3_text = replace(r3_text, r3_text[index[begin]:end] => "")
            if length(r3_text) < 3 continue end
            r3_text = strip(r3_text)
            # println(r3_text)
            items = split(r3_text, ',')
            R3[1] = parse(Float64, items[1])
            R3[2] = parse(Float64, items[2])
            R3[3] = parse(Float64, items[3])

            index = findfirst("R: ", text)
            if isnothing(index) continue end
            r_text = replace(text, text[begin:index[end]] => "")
            if length(r_text) < 3 continue end
            index = findfirst("roll:", r_text)
            if isnothing(index) continue end
            r_text = replace(r_text, r_text[index[begin]:end] => "")
            if length(r_text) < 3 continue end
            r_text = strip(r_text)
            # println(r_text)
            items = split(r_text, ',')
            R[1] = parse(Float64, items[1])
            R[2] = parse(Float64, items[2])
            R[3] = parse(Float64, items[3])

            index = findfirst("roll: ", text)
            if isnothing(index) continue end
            roll_text = replace(text, text[begin:index[end]] => "")
            if length(roll_text) < 3 continue end
            index = findfirst(", ", roll_text)
            if isnothing(index) continue end
            roll_text = replace(roll_text, roll_text[index[begin]:end] => "")
            if length(roll_text) < 3 continue end
            roll_text = strip(roll_text)
            # println(roll_text)
            roll = parse(Float64, roll_text)

            index = findfirst("pitch: ", text)
            if isnothing(index) continue end
            pitch_text = replace(text, text[begin:index[end]] => "")
            if length(pitch_text) < 3 continue end
            index = findfirst(", ", pitch_text)
            if isnothing(index) continue end
            pitch_text = replace(pitch_text, pitch_text[index[begin]:end] => "")
            if length(pitch_text) < 3 continue end
            pitch_text = strip(pitch_text)
            # println(pitch_text)
            pitch = parse(Float64, pitch_text)

            index = findfirst("f1: ", text)
            if isnothing(index) continue end
            v1_text = replace(text, text[begin:index[end]] => "")
            if length(v1_text) < 1 continue end
            index = findfirst(", ", v1_text)
            if isnothing(index) continue end
            v1_text = replace(v1_text, v1_text[index[begin]:end] => "")
            if length(v1_text) < 1 continue end
            v1_text = strip(v1_text)
            # println(v1_text)
            v1 = parse(Int, v1_text)

            index = findfirst("f2: ", text)
            if isnothing(index) continue end
            v2_text = replace(text, text[begin:index[end]] => "")
            if length(v2_text) < 1 continue end
            index = findfirst(", ", v2_text)
            if isnothing(index) continue end
            v2_text = replace(v2_text, v2_text[index[begin]:end] => "")
            if length(v2_text) < 1 continue end
            v2_text = strip(v2_text)
            # println(v2_text)
            v2 = parse(Int, v2_text)

            global R1 = R1 .* arrow_scale
            global R2 = R2 .* arrow_scale
            global R3 = R3 .* arrow_scale
            global R = R .* arrow_scale
            
            println("roll = $roll, pitch = $pitch")
            yaw = 0.0

            cr = cos(pitch * 0.5) # cosine roll
            sr = sin(pitch * 0.5) # sine roll
            cp = cos(yaw * 0.5) # cos pitch
            sp = sin(yaw * 0.5) # sine pitch
            cy = cos(roll * 0.5) # cos yaw
            sy = sin(roll * 0.5) # sine yaw

            w = cr * cp * cy + sr * sp * sy
            x = sr * cp * cy - cr * sp * sy
            y = cr * sp * cy + sr * cp * sy
            z = cr * cp * sy - sr * sp * cy
            q = Quaternion(w, x, y, z)
            q = q * chassis_q0
            q = GLMakie.Quaternion(vec(q)...)
            GLMakie.rotate!(robot, q)

            global mainwheel_accumulator += float(v1) * pi / 12.0
            global reactionwheel_accumulator += float(-v2) * pi / 26.0
            mq = GLMakie.Quaternion(vec(Quaternion(mainwheel_accumulator, x̂))...)
            rq = GLMakie.Quaternion(vec(Quaternion(reactionwheel_accumulator, ẑ))...)
            GLMakie.rotate!(mainwheel, mq)
            GLMakie.rotate!(reactionwheel, rq)

            g = Quaternion(roll, x̂) * Quaternion(-pitch, ŷ)
            p1 = deepcopy(Float64.([reference_point1...]))
            p2 = deepcopy(Float64.([reference_point2...]))
            p3 = deepcopy(Float64.([reference_point3...]))
            p = deepcopy(Float64.([reference_point...]))
            point1[] = GLMakie.Point3f(vec(conj(g) * Quaternion(0.0, (p1 - _p)...) * g)[2:4] + _p)
            point2[] = GLMakie.Point3f(vec(conj(g) * Quaternion(0.0, (p2 - _p)...) * g)[2:4] + _p)
            point3[] = GLMakie.Point3f(vec(conj(g) * Quaternion(0.0, (p3 - _p)...) * g)[2:4] + _p)
            point[] = GLMakie.Point3f(vec(conj(g) * Quaternion(0.0, (p - _p)...) * g)[2:4] + _p)
            ps[] = [GLMakie.Point3f(point1[]...), GLMakie.Point3f(point2[]...), GLMakie.Point3f(point3[]...), GLMakie.Point3f(point[]...)]
            ns[] = [GLMakie.Vec3f(R1[1], R1[3], R1[2]), GLMakie.Vec3f(-R2[1], R2[3], -R2[2]), GLMakie.Vec3f(R3[1], -R3[2], R3[3]),  GLMakie.Vec3f(R...)]
        end
    end
end
# close(serialport)