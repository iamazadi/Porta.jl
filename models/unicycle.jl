import GLMakie
import FileIO
import Makie
import MeshIO
import GeometryBasics
import LinearAlgebra
import GLMakie.Quaternion
using Sockets
using Porta


GLMakie.Quaternion(q::Porta.Quaternion) = GLMakie.Quaternion(vec(q)[2:4]..., vec(q)[1])


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


rotate(point::Vector{Float64}, q::Porta.Quaternion) = vec(conj(q) * Porta.Quaternion(0.0, (point)...) * q)[2:4]


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
lookat = [-0.1, -0.1, 0.1]
up = [0.0; 0.0; 1.0]

chassis_scale = 0.001
rollingwheel_scale = 1.0
reactionwheel_scale = 1.0

chassis_origin = GLMakie.Point3f(-0.1, -0.1, -0.02)
rollingwheel_origin = GLMakie.Point3f(3.0, -12.0, 0.0)
reactionwheel_origin = GLMakie.Point3f(0.0, 153.0, 1.0)

chassis_qx = Porta.Quaternion(π / 2, x̂)
chassis_qy = Porta.Quaternion(0.0, ŷ)
# chassis_qz = Porta.Quaternion(pi / 2.0, ẑ)
chassis_qz = Porta.Quaternion(0.0, ẑ)
chassis_q0 = chassis_qx * chassis_qy * chassis_qz
chassis_rotation = GLMakie.Quaternion(chassis_q0)
rollingwheel_qx = Porta.Quaternion(0.0, x̂)
rollingwheel_qy = Porta.Quaternion(0.0, ŷ)
rollingwheel_qz = Porta.Quaternion(0.0, ẑ) # the axis of rotation
rollingwheel_q0 = rollingwheel_qx * rollingwheel_qy * rollingwheel_qz
rollingwheel_rotation = GLMakie.Quaternion(rollingwheel_q0)
reactionwheel_qx = Porta.Quaternion(0.0, x̂)
reactionwheel_qy = Porta.Quaternion(0.0, ŷ)
reactionwheel_qz = Porta.Quaternion(0.0, ẑ) # the axis of rotation
reactionwheel_q0 = reactionwheel_qx * reactionwheel_qy * reactionwheel_qz
reactionwheel_rotation = GLMakie.Quaternion(reactionwheel_q0)

chassis_stl_path = joinpath("data", "unicycle", "unicycle_chassis.STL")
rollingwheel_stl_path = joinpath("data", "unicycle", "unicycle_main_wheel.STL")
reactionwheel_stl_path = joinpath("data", "unicycle", "unicycle_reaction_wheel.STL")

chassis_colormap = :Blues
rollingwheel_colormap = :rose
reactionwheel_colormap = :gold

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(1.0, 1.0, 1.0)
lscene = GLMakie.LScene(fig[1, 1], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))

chassis_stl = FileIO.load(chassis_stl_path)
reactionwheel_stl = FileIO.load(reactionwheel_stl_path)
rollingwheel_stl = FileIO.load(rollingwheel_stl_path)

pivot = GLMakie.Observable(GLMakie.Point3f(-0.097, -0.1, -0.033))
point1 = GLMakie.Observable(GLMakie.Point3f(-0.035, -0.19, -0.04))
point2 = GLMakie.Observable(GLMakie.Point3f(0.025, -0.144, -0.07))
point3 = GLMakie.Observable(GLMakie.Point3f(-0.11, -0.01, 0.13))
point4 = GLMakie.Observable(GLMakie.Point3f(-0.11, -0.19, 0.13))
point0 = GLMakie.Observable((point1[] + point2[] + point3[] + point4[]) .* 0.25)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap)

arrowscale = 0.1
R0_tail = vec(point0[])
R1_tail = vec(point1[])
R2_tail = vec(point2[])
R3_tail = vec(point3[])
R4_tail = vec(point4[])
R0 = [0.0; 0.0; -1.0] .* arrowscale
R1 = [0.0; 0.0; -1.0] .* arrowscale
R2 = [0.0; 0.0; -1.0] .* arrowscale
R3 = [0.0; 0.0; -1.0] .* arrowscale
R4 = [0.0; 0.0; -1.0] .* arrowscale

ps = GLMakie.Observable([GLMakie.Point3f(R0_tail...), GLMakie.Point3f(R1_tail...), GLMakie.Point3f(R2_tail...), GLMakie.Point3f(R3_tail...), GLMakie.Point3f(R4_tail...)])
ns = GLMakie.Observable([GLMakie.Vec3f(R0...), GLMakie.Vec3f(R1...), GLMakie.Vec3f(R2...), GLMakie.Vec3f(R3...),  GLMakie.Vec3f(R4...)])
arrowsize = GLMakie.Observable(GLMakie.Vec3f(0.01, 0.02, 0.03))
linewidth = GLMakie.Observable(0.01)
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:gold, :orange, :lime, :pink, :purple],
    linewidth = linewidth, arrowsize = arrowsize,
    align = :center
)

pivotball = GLMakie.meshscatter!(lscene, pivot, markersize = 0.01, color = :gold)
ball0 = GLMakie.meshscatter!(lscene, point0, markersize = 0.01, color = :gold) # for measurements of the configuration space
ball1 = GLMakie.meshscatter!(lscene, point1, markersize = 0.01, color = :orange)
ball2 = GLMakie.meshscatter!(lscene, point2, markersize = 0.01, color = :lime)
ball3 = GLMakie.meshscatter!(lscene, point3, markersize = 0.01, color = :pink)
ball4 = GLMakie.meshscatter!(lscene, point4, markersize = 0.01, color = :purple)
pivot_reference_point = deepcopy(pivot[])
reference_point0 = deepcopy(point0[])
reference_point1 = deepcopy(point1[])
reference_point2 = deepcopy(point2[])
reference_point3 = deepcopy(point3[])
reference_point4 = deepcopy(point4[])
_p = Float64.([chassis_origin...])

pivot_ps = GLMakie.Observable([pivot[], pivot[], pivot[]])
pivot_ns = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
ps0 = GLMakie.Observable([point0[], point0[], point0[]])
ps1 = GLMakie.Observable([point1[], point1[], point1[]])
ps2 = GLMakie.Observable([point2[], point2[], point2[]])
ps3 = GLMakie.Observable([point3[], point3[], point3[]])
ps4 = GLMakie.Observable([point4[], point4[], point4[]])
ns0 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
ns1 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
ns2 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
ns3 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
ns4 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
_ps0 = GLMakie.Observable([point0[], point0[], point0[]])
_ps1 = GLMakie.Observable([point1[], point1[], point1[]])
_ps2 = GLMakie.Observable([point2[], point2[], point2[]])
_ps3 = GLMakie.Observable([point3[], point3[], point3[]])
_ps4 = GLMakie.Observable([point4[], point4[], point4[]])
_ns0 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
_ns1 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
_ns2 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
_ns3 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
_ns4 = GLMakie.Observable([GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)])
arrowsize1 = GLMakie.Observable(GLMakie.Vec3f(0.01, 0.02, 0.03))
linewidth1 = GLMakie.Observable(0.005)
GLMakie.arrows!(lscene,
    pivot_ps, pivot_ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
    ps0, ns0, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
    ps1, ns1, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
    ps2, ns2, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
ps3, ns3, fxaa = true, # turn on anti-aliasing
color = [:red, :green, :blue],
linewidth = linewidth1, arrowsize = arrowsize1,
align = :center
)
GLMakie.arrows!(lscene,
ps4, ns4, fxaa = true, # turn on anti-aliasing
color = [:red, :green, :blue],
linewidth = linewidth1, arrowsize = arrowsize1,
align = :center
)
GLMakie.arrows!(lscene,
    _ps0, _ns0, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
    _ps1, _ns1, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
    _ps2, _ns2, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue],
    linewidth = linewidth1, arrowsize = arrowsize1,
    align = :center
)
GLMakie.arrows!(lscene,
_ps3, _ns3, fxaa = true, # turn on anti-aliasing
color = [:red, :green, :blue],
linewidth = linewidth1, arrowsize = arrowsize1,
align = :center
)
GLMakie.arrows!(lscene,
_ps4, _ns4, fxaa = true, # turn on anti-aliasing
color = [:red, :green, :blue],
linewidth = linewidth1, arrowsize = arrowsize1,
align = :center
)

r1 = [GLMakie.Vec3f(1, 0, 0), GLMakie.Vec3f(0, 1, 0), GLMakie.Vec3f(0, 0, 1)]
pivot_ns[] = r1
ns0[] = r1
ns1[] = [-r1[2], r1[1], r1[3]]
ns2[] = [r1[1], -r1[2], -r1[3]]
ns3[] = [r1[1], -r1[2], -r1[3]]
ns4[] = [r1[1], -r1[2], -r1[3]]

lookat = deepcopy(_p)
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(up...))


clientside  = connect("192.168.4.1", 10000)

run = true
errormonitor(@async while (isopen(clientside) && run)
    text = readline(clientside, keep = true)
    readings = parsetext(text)
    flag = "R1" in keys(readings) && "R2" in keys(readings) && "R3" in keys(readings) && "R4" in keys(readings) && "v1" in keys(readings) && "v2" in keys(readings)
    if flag
        R1 = readings["R1"]
        R2 = readings["R2"]
        R3 = readings["R3"]
        R4 = readings["R4"]
        v1 = readings["v1"]
        v2 = readings["v2"]
        R1 = [-R1[2]; R1[1]; R1[3]]
        R2 = [R2[1]; -R2[2]; -R2[3]]
        R3 = [R3[1]; -R3[2]; -R3[3]]
        R4 = [R4[1]; -R4[2]; -R4[3]]
        R0 = (R1 + R2 + R3 + R4) .* 0.3333
        pitch = atan(R0[1], R0[3])
        roll = atan(R0[2], R0[3])
        yaw = 0.0
        println("Pitch: $pitch, Roll: $roll")
      
        q = Porta.Quaternion(roll, x̂) * Porta.Quaternion(pitch, ŷ)
        g = q * chassis_q0
        GLMakie.rotate!(robot, GLMakie.Quaternion(g)) # change the comibination to correct for an API difference
        pivotpoint = deepcopy(Float64.([pivot_reference_point...]))
        p0 = deepcopy(Float64.([reference_point0...]))
        p1 = deepcopy(Float64.([reference_point1...]))
        p2 = deepcopy(Float64.([reference_point2...]))
        p3 = deepcopy(Float64.([reference_point3...]))
        p4 = deepcopy(Float64.([reference_point4...]))
        pivot[] = GLMakie.Point3f(rotate(pivotpoint - _p, q) + _p)
        point0[] = GLMakie.Point3f(rotate(p0 - _p, q) + _p)
        point1[] = GLMakie.Point3f(rotate(p1 - _p, q) + _p)
        point2[] = GLMakie.Point3f(rotate(p2 - _p, q) + _p)
        point3[] = GLMakie.Point3f(rotate(p3 - _p, q) + _p)
        point4[] = GLMakie.Point3f(rotate(p4 - _p, q) + _p)
        ps[] = [GLMakie.Point3f(point0[]...), GLMakie.Point3f(point1[]...), GLMakie.Point3f(point2[]...), GLMakie.Point3f(point3[]...), GLMakie.Point3f(point4[]...)]
        ns[] = map(x -> x .* arrowscale, [GLMakie.Vec3f(R0...), GLMakie.Vec3f(R1...), GLMakie.Vec3f(R2...), GLMakie.Vec3f(R3...),  GLMakie.Vec3f(R4...)])

        pivot_ps[] = [GLMakie.Point3f(pivot[]...), GLMakie.Point3f(pivot[]...), GLMakie.Point3f(pivot[]...)]
        ps0[] = [GLMakie.Point3f(point0[]...), GLMakie.Point3f(point0[]...), GLMakie.Point3f(point0[]...)]
        ps1[] = [GLMakie.Point3f(point1[]...), GLMakie.Point3f(point1[]...), GLMakie.Point3f(point1[]...)]
        ps2[] = [GLMakie.Point3f(point2[]...), GLMakie.Point3f(point2[]...), GLMakie.Point3f(point2[]...)]
        ps3[] = [GLMakie.Point3f(point3[]...), GLMakie.Point3f(point3[]...), GLMakie.Point3f(point3[]...)]
        ps4[] = [GLMakie.Point3f(point4[]...), GLMakie.Point3f(point4[]...), GLMakie.Point3f(point4[]...)]
        _ps0[] = [GLMakie.Point3f(point0[]...), GLMakie.Point3f(point0[]...), GLMakie.Point3f(point0[]...)]
        _ps1[] = [GLMakie.Point3f(point1[]...), GLMakie.Point3f(point1[]...), GLMakie.Point3f(point1[]...)]
        _ps2[] = [GLMakie.Point3f(point2[]...), GLMakie.Point3f(point2[]...), GLMakie.Point3f(point2[]...)]
        _ps3[] = [GLMakie.Point3f(point3[]...), GLMakie.Point3f(point3[]...), GLMakie.Point3f(point3[]...)]
        _ps4[] = [GLMakie.Point3f(point4[]...), GLMakie.Point3f(point4[]...), GLMakie.Point3f(point4[]...)]
        
        smallarrowscale = arrowscale * 0.5
        _ns0[] = [smallarrowscale * R0[1] .* r1[1], smallarrowscale * R0[2] .* r1[2], smallarrowscale * R0[3] .* r1[3]]
        _ns1[] = [smallarrowscale * R1[1] .* r1[1], smallarrowscale * R1[2] .* r1[2], smallarrowscale * R1[3] .* r1[3]]
        _ns2[] = [smallarrowscale * R2[1] .* r1[1], smallarrowscale * R2[2] .* r1[2], smallarrowscale * R2[3] .* r1[3]]
        _ns3[] = [smallarrowscale * R3[1] .* r1[1], smallarrowscale * R3[2] .* r1[2], smallarrowscale * R3[3] .* r1[3]]
        _ns4[] = [smallarrowscale * R4[1] .* r1[1], smallarrowscale * R4[2] .* r1[2], smallarrowscale * R4[3] .* r1[3]]
        ns0[] = map(x -> x .* LinearAlgebra.norm(R0) .* smallarrowscale, r1)
        ns1[] = map(x -> x .* LinearAlgebra.norm(R1) .* smallarrowscale, [-r1[2], r1[1], r1[3]])
        ns2[] = map(x -> x .* LinearAlgebra.norm(R2) .* smallarrowscale, [r1[1], -r1[2], -r1[3]])
        ns3[] = map(x -> x .* LinearAlgebra.norm(R3) .* smallarrowscale, [r1[1], -r1[2], -r1[3]])
        ns4[] = map(x -> x .* LinearAlgebra.norm(R4) .* smallarrowscale, [r1[1], -r1[2], -r1[3]])
        

        mq = GLMakie.Quaternion(Porta.Quaternion(float(-v1) / 600.0 * 2pi, ẑ))
        rq = GLMakie.Quaternion(Porta.Quaternion(float(-v2) / 1800.0 * 2pi, x̂))
        GLMakie.rotate!(rollingwheel, mq)
        GLMakie.rotate!(reactionwheel, rq)
    end
end)

# close(clientside)