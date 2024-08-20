import GLMakie
import FileIO
import Makie
import MeshIO
import GeometryBasics
import LinearAlgebra
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

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

eyeposition = LinearAlgebra.normalize([-0.9, 0.3, 0.5]) .* 0.6
lookat = [-0.1, -0.1, 0.05]
up = [0.0; 0.0; 1.0]

chassis_scale = 0.001
rollingwheel_scale = 1.0
reactionwheel_scale = 1.0

chassis_origin = GLMakie.Point3f(-0.1, -0.1, -0.02)
rollingwheel_origin = GLMakie.Point3f(3.0, -12.0, 0.0)
reactionwheel_origin = GLMakie.Point3f(0.0, 153.0, 1.0)

chassis_qx = Quaternion(0.0, x̂)
chassis_qy = Quaternion(0.0, ŷ)
chassis_qz = Quaternion(pi / 2.0, ẑ)
chassis_q0 = chassis_qx * chassis_qy * chassis_qz
chassis_rotation = GLMakie.Quaternion(vec(chassis_q0)...)
rollingwheel_qx = Quaternion(0.0, x̂)
rollingwheel_qy = Quaternion(0.0, ŷ)
rollingwheel_qz = Quaternion(0.0, ẑ) # the axis of rotation
rollingwheel_q0 = rollingwheel_qx * rollingwheel_qy * rollingwheel_qz
rollingwheel_rotation = GLMakie.Quaternion(vec(rollingwheel_q0)...)
reactionwheel_qx = Quaternion(0.0, x̂)
reactionwheel_qy = Quaternion(0.0, ŷ)
reactionwheel_qz = Quaternion(0.0, ẑ) # the axis of rotation
reactionwheel_q0 = reactionwheel_qx * reactionwheel_qy * reactionwheel_qz
reactionwheel_rotation = GLMakie.Quaternion(vec(reactionwheel_q0)...)

chassis_stl_path = joinpath("data", "unicycle", "unicycle_chassis.STL")
rollingwheel_stl_path = joinpath("data", "unicycle", "unicycle_main_wheel.STL")
reactionwheel_stl_path = joinpath("data", "unicycle", "unicycle_reaction_wheel.STL")

chassis_colormap = :grays
rollingwheel_colormap = :phase
reactionwheel_colormap = :delta

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(1.0, 1.0, 1.0)
lscene = GLMakie.LScene(fig[1, 1], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = backgroundcolor))

chassis_stl = FileIO.load(chassis_stl_path)
reactionwheel_stl = FileIO.load(reactionwheel_stl_path)
rollingwheel_stl = FileIO.load(rollingwheel_stl_path)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap)

arrow_scale = 0.1
R1_tail = [-0.1, -0.1, 0.05]
R2_tail = [-0.1, -0.1, 0.05]
R3_tail = [-0.1, -0.1, 0.05]
R4_tail = [-0.1, -0.1, 0.05]
R1 = [0.0; 0.0; -1.0] .* arrow_scale
R2 = [0.0; 0.0; -1.0] .* arrow_scale
R3 = [0.0; 0.0; -1.0] .* arrow_scale
R4 = [0.0; 0.0; -1.0] .* arrow_scale

ps = GLMakie.Observable([GLMakie.Point3f(R1_tail...), GLMakie.Point3f(R2_tail...), GLMakie.Point3f(R3_tail...), GLMakie.Point3f(R4_tail...)])
ns = GLMakie.Observable([GLMakie.Vec3f(R1...), GLMakie.Vec3f(R2...), GLMakie.Vec3f(R3...),  GLMakie.Vec3f(R4...)])
arrowsize = GLMakie.Observable(GLMakie.Vec3f(0.01, 0.02, 0.03))
linewidth = GLMakie.Observable(0.01)
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue, :orange],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :center
)

point1 = GLMakie.Observable(GLMakie.Point3f(-0.05, -0.135, -0.03))
point2 = GLMakie.Observable(GLMakie.Point3f(0.025, -0.144, -0.07))
point3 = GLMakie.Observable(GLMakie.Point3f(-0.11, -0.01, 0.13))
point4 = GLMakie.Observable(GLMakie.Point3f(-0.11, -0.19, 0.13))
# ball = GLMakie.meshscatter!(lscene, point3, markersize = 0.01, color = :red) # for measurements of the configuration space
reference_point1 = deepcopy(point1[])
reference_point2 = deepcopy(point2[])
reference_point3 = deepcopy(point3[])
reference_point4 = deepcopy(point4[])
_p = Float64.([chassis_origin...])

lookat = deepcopy(_p)
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(up...))


parse3vector(text::String, beginninglabel::String, endinglabel::String, delimiter::String) = begin
    vector = []
    index = findfirst(beginninglabel, text)
    if !isnothing(index)
        _text = replace(text, text[begin:index[end]] => "")
        if length(_text) > 3
            index = findfirst(endinglabel, _text)
            if !isnothing(index)
                _text = replace(_text, _text[index[begin]:end] => "")
                if length(_text) > 3
                    _text = strip(_text)
                    println(_text)
                    items = split(_text, delimiter)
                    try
                        push!(vector, parse(Float64, items[1]))
                        push!(vector, parse(Float64, items[2]))
                        push!(vector, parse(Float64, items[3]))
                    catch e
                        println("Not parsed: $_text. $e")
                    end
                end
            end
        end
    end
    vector
end


parsescalar(text::String, beginninglabel::String, endinglabel::String) = begin
    scalar = Nothing
    index = findfirst(beginninglabel, text)
    if !isnothing(index)
        _text = replace(text, text[begin:index[end]] => "")
        if length(_text) > 1
            index = findfirst(endinglabel, _text)
            if !isnothing(index)
                _text = replace(_text, _text[index[begin]:end] => "")
                if length(_text) > 0
                    _text = strip(_text)
                    println(_text)
                    try
                        scalar = parse(Int, _text)
                    catch e
                        println("Not parsed: $_text. $e")
                    end
                end
            end
        end
    end
    scalar
end


parsetext(text::String) = begin
    readings = Dict()
    if length(text) > 30
        vector = parse3vector(text, "A1: ", "A2: ", ",")
        if length(vector) == 3
            readings["R1"] = vector
        end
        vector = parse3vector(text, "A2: ", "A3: ", ",")
        if length(vector) == 3
            readings["R2"] = vector
        end
        vector = parse3vector(text, "A3: ", "A4: ", ",")
        if length(vector) == 3
            readings["R3"] = vector
        end
        vector = parse3vector(text, "A4: ", "c1: ", ",")
        if length(vector) == 3
            readings["R4"] = vector
        end
        scalar = parsescalar(text, "c1: ", ", ")
        if !isnothing(scalar)
            readings["v1"] = scalar
        end
        scalar = parsescalar(text, "c2: ", ", ")
        if !isnothing(scalar)
            readings["v2"] = scalar
        end
    end
    readings
end


rotate(point::Vector{Float64}, q::Quaternion) = vec(conj(q) * Quaternion(0.0, (point)...) * q)[2:4]


clientside  = connect("192.168.4.1", 10000)

run = true
counter = 0
errormonitor(@async while (isopen(clientside) && run)
    text = readline(clientside, keep = true)
    global counter += 1
    println(text)
    readings = parsetext(text)
    flag = "R1" in keys(readings) && "R2" in keys(readings) && "R3" in keys(readings) && "R4" in keys(readings) && "v1" in keys(readings) && "v2" in keys(readings)
    if flag && counter > 10
        global counter = 0
        R1 = readings["R1"]
        R2 = readings["R2"]
        R3 = readings["R3"]
        R4 = readings["R4"]
        v1 = readings["v1"]
        v2 = readings["v2"]
        R1 = R1
        R2 = R2
        R3 = R3
        R4 = R4
        R0 = GLMakie.Vec3f(R1[1], R1[2], R1[3]) + GLMakie.Vec3f(-R2[1], R2[2], -R2[3]) + GLMakie.Vec3f(R3[3], R3[1], R3[2]) + GLMakie.Vec3f(R4[3], -R4[1], -R4[2])
        R0 = R0 .* 0.25
        pitch = atan(R0[1], R0[3])
        roll = atan(R0[2], R0[3])
        yaw = 0.0
        global R1 = R1 .* arrow_scale
        global R2 = R2 .* arrow_scale
        global R3 = R3 .* arrow_scale
        global R4 = R4 .* arrow_scale

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
        chassis_q = q * chassis_q0
        q = GLMakie.Quaternion(vec(chassis_q)...)
        GLMakie.rotate!(robot, q)

        
        mq = GLMakie.Quaternion(vec(Quaternion(float(v1) / 600.0 * 2pi, x̂))...)
        rq = GLMakie.Quaternion(vec(Quaternion(float(-v2) / 1800.0 * 2pi, ẑ))...)
        GLMakie.rotate!(rollingwheel, mq)
        GLMakie.rotate!(reactionwheel, rq)

        g = Quaternion(roll, x̂) * Quaternion(-pitch, ŷ)
        p1 = deepcopy(Float64.([reference_point1...]))
        p2 = deepcopy(Float64.([reference_point2...]))
        p3 = deepcopy(Float64.([reference_point3...]))
        p4 = deepcopy(Float64.([reference_point4...]))
        point1[] = GLMakie.Point3f(rotate(p1 - _p, g) + _p)
        point2[] = GLMakie.Point3f(rotate(p2 - _p, g) + _p)
        point3[] = GLMakie.Point3f(rotate(p3 - _p, g) + _p)
        point4[] = GLMakie.Point3f(rotate(p4 - _p, g) + _p)
        ps[] = [GLMakie.Point3f(point1[]...), GLMakie.Point3f(point2[]...), GLMakie.Point3f(point3[]...), GLMakie.Point3f(point4[]...)]
        ns[] = [GLMakie.Vec3f(-R1[1], R1[2], R1[3]), GLMakie.Vec3f(R2[1], R2[2], -R2[3]), GLMakie.Vec3f(-R3[3], R3[1], R3[2]),  GLMakie.Vec3f(-R4[3], -R4[1], -R4[2])]
    end
end)

# close(clientside)