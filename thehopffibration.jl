using Porta
using LinearAlgebra
using Colors
using FileIO
using GeometryTypes
using AbstractPlotting
using Makie
using ReferenceFrameRotations

"""
construct(scene, a, g)

Constructs a fiber with the given scene, the observable point a
in the base space and the unit quaternion g for the three sphere rotation.
"""
function construct(scene, a, g)
    # The radius parameter for constructing surfaces
    r=0.025
    # The square root of the number of points in the grid
    N=30
    lspace = range(0.0, stop = 2pi, length = N)
    # Locate the point in the base space and then rotate the three sphere
    y = @lift(rotate(locate($a[1], $a[2]), $g))
    # Calculate the marker grid for a point in the base space
    base = @lift(base!($y, r, N))
    color = @lift([RGBAf0($y[1], $y[2], $y[3]) for i in lspace, j in lspace])
    # Calculate the marker grid for a fiber under the streographic projection
    fiber = @lift(fiber!($y, r, N))
    surface!(scene, 
             @lift($base[1]),
             @lift($base[2]),
             @lift($base[3]),
             color = color,
             shading = true)
    surface!(scene, 
             @lift($fiber[1]),
             @lift($fiber[2]), 
             @lift($fiber[3]), 
             color = color,
             shading = true)
end

"""
animate(points, i)

Moves the points on a path parallel to the equator in the base space
with the given array of coordinate observables and the progress percentage.
The coordinates are the latitude (θ) and longitude(ψ) in radians,
and the progress percentage ranges from 1 to 100.
"""
function animate(points, i)
    for point in points
        val = to_value(point)
        point[] = [val[1], (val[2] - (i - 1) / 100 * 2pi) + i / 100 * 2pi]
    end
end

sθ, oθ = textslider(0:0.01:2pi, 
                    "θ",
                    raw = true, 
                    camera = campixel!, 
                    start = 0)
sψ, oψ = textslider(0:0.01:2pi, 
                    "ψ",
                    raw = true, 
                    camera = campixel!, 
                    start = 0)
sϕ, oϕ = textslider(0:0.01:2pi, 
                    "ϕ",
                    raw = true, 
                    camera = campixel!, 
                    start = 0)

# The three sphere rotation axis
θ = Node(0.0)
ψ = Node(0.0)
ϕ = Node(4.0)
g = @lift(ReferenceFrameRotations.Quaternion(cos($θ),
                                             sin($θ)*cos($ψ)*cos($ϕ),
                                             sin($θ)*cos($ψ)*sin($ϕ),
                                             sin($θ)*sin($ψ)))
# Using sliders to find the perfect rotation axis
on(oθ) do val
    θ[] = val
end
on(oψ) do val
    ψ[] = val
end
on(oϕ) do val
    ϕ[] = val
end

scene = Scene(show_axis = false)
# The 3D coordinate marker
origin = Vec3f0(0); baselen = 0.05f0; dirlen = 0.5f0
# create an array of differently colored boxes in the direction of the 3 axes
rectangles = [
    (HyperRectangle(Vec3f0(origin), 
                    Vec3f0(dirlen, baselen, baselen)), 
                    RGBAf0(0.5,1.0,0.5,0.9)),
    (HyperRectangle(Vec3f0(origin), 
                    Vec3f0(baselen, dirlen, baselen)), 
                    RGBAf0(1.0,0.5,0.5,0.9)),
    (HyperRectangle(Vec3f0(origin), 
                    Vec3f0(baselen, baselen, dirlen)),
                    RGBAf0(0.5,0.5,1.0,0.9))
]
meshes = map(GLNormalMesh, rectangles)
mesh!(scene, merge(meshes), transparency = true)
sphere = mesh!(scene,
               GLNormalUVMesh(Sphere(Point3f0(0), 1f0), 60), 
               color = RGBAf0(0.75,0.75,0.75,0.5), 
               shading = true, 
               transparency = false)
coordinates = [[0.565, 2.204],
               [0.647, 1.670],
               [-0.441, 2.334],
               [0.541, 0.608],
               [0.625, 1.818]]
points = []
for i in coordinates
    point = Node(i)
    construct(scene, point, g)
    push!(points, point)
end
fullscene = hbox(scene,
                 vbox(sθ, sψ, sϕ),
                 parent = Scene(resolution = (500, 500)))
"""
record(scene, "output.gif") do io
    for i in range(0, stop = 2pi, length = 100)
        θ[] = i # animate scene
        recordframe!(io) # record a new frame
    end
end
"""

