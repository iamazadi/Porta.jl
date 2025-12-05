using GeometryBasics
using GLMakie
using FileIO
using Porta


ballsize = 0.01
scale = 0.001
radius = 0.075
offset = 0.012 + radius
origin = Point3f(-0.1, -0.1, -0.02)
origin1 = origin - Point3f(0.0, 0.0, radius)
origin2 = origin - Point3f(0.0, 0.0, offset - radius)
rollingwheel_origin = Point3f(3.0, -12.0 + (1.0 / scale) * offset, 0.0)
rollingwheel_scale = 1.0

fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])
parent = deepcopy(lscene.scene);

stl_path = joinpath("data", "unicycle", "unicycle_chassis.STL")
rollingwheel_stl_path = joinpath("data", "unicycle", "unicycle_main_wheel.STL")
stl = load(stl_path)
rollingwheel_stl = load(rollingwheel_stl_path)

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
chassis_qx = ℍ(π / 2, x̂)
chassis_qy = ℍ(0.0, ŷ)
chassis_qz = ℍ(0.0, ẑ)
rotation = chassis_qx * chassis_qy * chassis_qz

rollingwheel_qx = ℍ(0.0, x̂)
rollingwheel_qy = ℍ(0.0, ŷ)
rollingwheel_qz = ℍ(0.0, ẑ) # the axis of rotation
rollingwheel_q0 = rollingwheel_qx * rollingwheel_qy * rollingwheel_qz
rollingwheel_rotation = rollingwheel_q0

center_of_mass = Porta.find_centerofmass(stl)
# Create a child transformation from the parent
child = GLMakie.Transformation(parent)
# get the transformation of the parent
ptrans = GLMakie.Transformation(parent)
centeroffset = GLMakie.Point3f(center_of_mass...) - Point3f(0.0, offset / scale, 0.0)
centered = map(x -> x - centeroffset, stl.position)
stl = GeometryBasics.Mesh(GeometryBasics.meta(centered, normals = stl.normals), GeometryBasics.faces(stl))
GLMakie.rotate!(child, GLMakie.Quaternion(rotation))
GLMakie.scale!(child, scale, scale, scale)
robot = GLMakie.mesh!(lscene, stl; color = [tri[1][2] for tri in stl for i in 1:3], colormap = :rainbow, transformation = child, transparency = true)
GLMakie.translate!(child, origin - Point3f(0.0, 0.0, offset)) # translates the visual mesh in the viewport

rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, :jet, transparency = true)

meshscatter!(lscene, origin, markersize = ballsize, color = :red)
meshscatter!(lscene, origin1, markersize = ballsize, color = :green)
meshscatter!(lscene, origin2, markersize = ballsize, color = :blue)

eyeposition = normalize([1.0; 1.0; 1.0]) * 0.5
up = [0.0; 0.0; 1.0]
lookat = deepcopy(origin)
update_cam!(lscene.scene, Vec3f(eyeposition...), Vec3f(lookat...), Vec3f(up...))

rotation_angle = π / 7
q = Quaternion(ℍ(rotation_angle, x̂) * rotation)
GLMakie.rotate!(robot, q)