import GLMakie
import FileIO
import Makie
import MeshIO
import GeometryBasics
using LibSerialPort
using Porta


figuresize = (1080, 1920)
segments = 30
frames_number = 360
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(1.0, 1.0, 1.0)
lscene = GLMakie.LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = backgroundcolor))

eyeposition = [0.35, 0.35, 0.35]
lookat = [0.0, 0.0, 0.0]
up = [0.0; 0.0; 1.0]
origin = GLMakie.Point3f(-0.1, -0.1, -0.02)

q1 = Quaternion(0.0, x̂)
q2 = Quaternion(0.0, ŷ)
q3 = Quaternion(pi / 2.0, ẑ)
q0 = q1 * q2 * q3
rotation = GLMakie.Quaternion(vec(q0)...)

robot_stl_path = joinpath("data", "unicycle", "unicycle.STL")
robot_stl = FileIO.load(robot_stl_path)

center_of_mass = [0.0; 0.0; 0.0]
points_number = 0
for tri in robot_stl
    for point in tri
        center_of_mass = center_of_mass + point
        points_number += 1
    end
end
center_of_mass = center_of_mass .* (1.0 / points_number)

parent = lscene.scene;
# Create a child transformation from the parent
child = GLMakie.Transformation(parent)
# get the transformation of the parent
ptrans = Makie.transformation(parent)

# center the mesh to its origin, if we have one
if !isnothing(origin)
    GLMakie.rotate!(child, rotation)
    scale = 0.001
    GLMakie.scale!(child, scale, scale, scale)
    centered = robot_stl.position .- GLMakie.Point3f(center_of_mass...)
    robot_stl = GeometryBasics.Mesh(GeometryBasics.meta(centered; normals=robot_stl.normals), GeometryBasics.faces(robot_stl))
    GLMakie.translate!(child, origin) # translates the visual mesh in the viewport
else
    # if we don't have an origin, we need to correct for the parents translation
    GLMakie.translate!(child, -ptrans.translation[])
end
# plot the part with transformation & color
robot = GLMakie.mesh!(lscene.scene, robot_stl; color=color = [tri[1][2] for tri in robot_stl for i in 1:3], colormap = :rainbow, transformation=child)
GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(up...))



# sprite = GLMakie.mesh!(
#     lscene,
#     robot_stl,
#     color = [tri[1][2] for tri in robot_stl for i in 1:3],
#     colormap = GLMakie.Reverse(:rainbow)
# )

# GLMakie.translate!(sprite, GLMakie.Point3f(translation))
# scale = 1.0
# GLMakie.scale!(sprite, scale, scale, scale)

# animate(frame, number) = begin
#     angle = frame / frames_number * 2pi
#     q = q0 * Quaternion(angle, ŷ)
#     q = GLMakie.Quaternion(vec(q)...)
#     GLMakie.rotate!(child, q)
# end


# updatecamera(progress) = begin
#     # global lookat = 0.99 .* lookat + 0.01 .* p
#     GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(eyeposition...), GLMakie.Vec3f(lookat...), GLMakie.Vec3f(up...))
# end

# modelname = "unicycle"

# GLMakie.record(fig, "./gallery/$modelname.mp4", 1:frames_number) do frame
#     progress = frame / frames_number
#     println("Frame: $frame, Number = $frames_number, Progress: $progress")
#     animate(frame, frames_number)
#     updatecamera(progress)
# end


# Modify these as needed
portname = "COM3"
baudrate = 9600

# text = "roll = 145.29, pitch = 28.15, yaw = 0.00, v1 = 0, v2 = 0, f = 0, w = 0.00, h = 0.000000"

# Snippet from examples/mwe.jl
LibSerialPort.open(portname, baudrate) do serialport
    for i in 1:1000
        sleep(0.1)

        if bytesavailable(serialport) > 0
            text = String(read(serialport))
            println(text)
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
                # q1 = Quaternion(roll / 180.0 * pi, ẑ)
                # q2 = Quaternion(pitch / 180.0 * pi, x̂)
                # q3 = Quaternion(yaw / 180.0 * pi, ŷ)
                # q = q1 * q2 * q3 * q0
                q = q * q0
                q = GLMakie.Quaternion(vec(q)...)
                GLMakie.rotate!(child, q)
            end
        end
    end
end