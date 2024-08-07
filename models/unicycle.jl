import GLMakie
import FileIO
import Makie
import MeshIO
import GeometryBasics
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

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

eyeposition = [0.3, 0.3, 0.3]
lookat = [0.0, 0.0, 0.0]
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

chassis_colormap = :rainbow
mainwheel_colormap = :lightrainbow
reactionwheel_colormap = :darkrainbow

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(0.0, 0.0, 0.0)
lscene = GLMakie.LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = backgroundcolor))

chassis_stl = FileIO.load(chassis_stl_path)
reactionwheel_stl = FileIO.load(reactionwheel_stl_path)
mainwheel_stl = FileIO.load(mainwheel_stl_path)

robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassis_rotation, chassis_scale, chassis_stl, chassis_colormap)
mainwheel = make_sprite(lscene.scene, robot, mainwheel_origin, mainwheel_rotation, mainwheel_scale, mainwheel_stl, mainwheel_colormap)
reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap)

chassis_centerofmass = find_centerofmass(chassis_stl)
lookat = deepcopy(chassis_centerofmass .* (1.0 / norm(ℝ³(chassis_centerofmass...))) .* chassis_scale)
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(up...))


animate(frame, number) = begin
    angle = frame / frames_number * 2pi
    reactionwheel_q = reactionwheel_q0 * Quaternion(angle, ẑ)
    reactionwheel_q = GLMakie.Quaternion(vec(reactionwheel_q)...)
    GLMakie.rotate!(reactionwheel_child, reactionwheel_q)
end


updatecamera(progress) = begin
    # global lookat = 0.99 .* lookat + 0.01 .* p
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(up...))
end

modelname = "unicycle"

GLMakie.record(fig, "./gallery/$modelname.mp4", 1:frames_number) do frame
    progress = frame / frames_number
    println("Frame: $frame, Number = $frames_number, Progress: $progress")
    animate(frame, frames_number)
    updatecamera(progress)
end

clientside  = connect("192.168.1.5", 2001)
errormonitor(@async while isopen(clientside)
    text = readline(clientside, keep = true)
    if length(text) > 30
        index = findfirst("Roll = ", text)
        if isnothing(index)
            continue
        end
        roll = replace(text, text[begin:index[end]] => "")
        if length(roll) < 3
            continue
        end
        index = findfirst(", ", roll)
        if isnothing(index)
            continue
        end
        roll = replace(roll, roll[index[begin]:end] => "")
        if length(roll) < 3
            continue
        end
        println(roll)
        roll = parse(Float64, roll)

        index = findfirst("Pitch = ", text)
        if isnothing(index)
            continue
        end
        pitch = replace(text, text[begin:index[end]] => "")
        if length(pitch) < 3
            continue
        end
        index = findfirst(", ", pitch)
        if isnothing(index)
            continue
        end
        pitch = replace(pitch, pitch[index[begin]:end] => "")
        if length(pitch) < 3
            continue
        end
        println(pitch)
        pitch = parse(Float64, pitch)

        index = findfirst("Yaw = ", text)
        if isnothing(index)
            continue
        end
        yaw = replace(text, text[begin:index[end]] => "")
        if length(yaw) < 3
            continue
        end
        index = findfirst(", ", yaw)
        if isnothing(index)
            continue
        end
        yaw = replace(yaw, yaw[index[begin]:end] => "")
        if length(yaw) < 3
            continue
        end
        println(yaw)
        yaw = parse(Float64, yaw)

        roll = -roll / 180.0 * pi
        pitch = -pitch / 180.0 * pi
        yaw = -yaw / 180.0 * pi

        cr = cos(pitch * 0.5) # cosine roll # put pitch to work
        sr = sin(pitch * 0.5) # sine roll   # put pitch to work
        cp = cos(yaw * 0.5) # cos pitch # put yaw to work
        sp = sin(yaw * 0.5) # sine yaw # put yaw to work
        cy = cos(roll * 0.5) # cos yaw # put roll to work
        sy = sin(roll * 0.5) # sine yaw # put roll to work

        w = cr * cp * cy + sr * sp * sy
        x = sr * cp * cy - cr * sp * sy
        y = cr * sp * cy + sr * cp * sy
        z = cr * cp * sy - sr * sp * cy
        q = Quaternion(w, x, y, z)
        q = q * q0
        q = GLMakie.Quaternion(vec(q)...)
        GLMakie.rotate!(child, q)
    end
end)

# close(clientside)