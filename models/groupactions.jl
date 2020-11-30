import FileIO
import GeometryBasics
import Observables
import AbstractPlotting
import Makie


using Porta


×(a::SU2, b::U1) = SU2(b.z .* a.a)


frames = 1440
resolution = (3840, 2160)
maxsamples = 720
segments = 720
speed = 1

# The scene object that contains other visual objects
AbstractPlotting.reasonable_resolution() = (800, 800)
AbstractPlotting.primary_resolution() = resolution
scene = AbstractPlotting.Scene(backgroundcolor = :black,
                               show_axis = false,
                               resolution = resolution)

s3rotation = Quaternion(1, 0, 0, 0)
config = Biquaternion(ℝ³(0, 0, 0))


v₀ = 1
p = ComplexPlane([0im; v₀ + 0im])
τ₃ = SU2([-im/2 0im; 0im im/2])


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i)
    step = (i - 1) / frames
    u = ℝ³(0, 0, 1)
    τ = step * speed * -pi
    q = Quaternion(τ, u)

    f(b::S²) = Cartesian(rotate(ℝ³(Cartesian(b)), q))

    for item in [solidwhirls; ghostwhirls; framesprites]
        #update(item, q)
        update(item, σmap, f)
    end
end


n = ℝ³(0, 0, 1)
v = ℝ³(-1, 1, 1)* pi
# update eye position
# scene.camera.eyeposition.val
upvector = GeometryBasics.Vec3f0(vec(n)...)
eyeposition = GeometryBasics.Vec3f0(vec(v)...)
lookat = GeometryBasics.Vec3f0(0, 0, 0)
Makie.update_cam!(scene, eyeposition, lookat, upvector)
scene.center = false # prevent scene from recentering on display
Makie.record(scene, "drorbarnatan2010.mkv") do io
    for i in 1:frames
        animate(i) # animate the scene
        Makie.recordframe!(io) # record a new frame
    end
end
