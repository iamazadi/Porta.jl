using Porta
using LinearAlgebra
using Colors
using FileIO
using GeometryTypes
using AbstractPlotting
using Makie
using ReferenceFrameRotations

"""
flower!(;N=4, A=.5, B=-pi/7, P=pi/2, Q=0, number=300)

Calculates the x, y and z points of a flower in the base space.
with the given number of petals N, the fattness of the petals A,
the height of the petals B, the latitude of the flower P,
the rotation of the flower Q, and the total number of points in the grid.
"""
function flower!(;N=4, A=.5, B=-pi/7, P=pi/2, Q=0, number=300)
    N = 7
    A = .5
    B = -pi/7
    P = pi/3
    Q = 0
    t = range(0, stop = 2pi, length = number)
    az = 2pi .* t + A .* cos.(N .* 2pi .* t) .+ Q
    po = B .* sin.(N .* 2pi .* t) .+ P
    cos.(az).*sin.(po), sin.(az).*sin.(po), cos.(po)
end

"""
construct(scene, a, g)

Constructs a fiber with the given scene, the observable point a
in the base space and the unit quaternion g for the three sphere rotation.
"""
function construct(scene, y, g)
    # The radius parameter for constructing surfaces
    r=0.07
    # The square root of the number of points in the grid
    N=50
    lspace = range(0.0, stop = 2pi, length = N)
    # Locate the point in the base space and then rotate the three sphere
    # y = @lift(rotate(locate($a[1], $a[2]), $g))
    #y = @lift(locate($a[1], $a[2]))
    # Calculate the marker grid for a point in the base space
    #base = @lift(base!($y, r, N))
    #color = @lift([RGBAf0($y[3], $y[1], $y[2]) for i in lspace, j in lspace])
    c = RGBAf0(rand(), rand(), rand(), 1.0)
    color = [c for i in lspace, j in lspace]
    # Calculate the marker grid for a fiber under streographic projection
    fiber = @lift(fiber!($y, r = r, N = N))
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
with the given array of coordinate observables, the direction indicator
and the progress percentage. The coordinates are the latitude (θ)
and longitude(ψ) in radians, and the progress percentage ranges from 1 to 100.
"""
function animate(points, i)
    for point in points
        x, y, z = to_value(point)
        r = sqrt(x^2 + y^2 + z^2)
        θ = asin(z/r)
        if x > 0
                ϕ = atan(y/x)
        elseif y > 0
                ϕ = atan(y/x) + pi
        else
                ϕ = atan(y/x) - pi
        end
        point[] = locate(θ, ϕ + (i-1)/100 * 2pi - i/100 * 2pi)
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
ϕ = Node(0.0)
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

scene = Scene(show_axis = false, backgroundcolor = :black)

points = []
number = 400
x, y, z = flower!(number = number)
for i in 1:number
    point = Node([x[i], y[i], z[i]])
    construct(scene, point, g)
    push!(points, point)
end

fullscene = hbox(scene,
                 vbox(sθ, sψ, sϕ),
                 parent = Scene(resolution = (640, 640)))

eyepos = Vec3f0(1, 0, 10)
lookat = Vec3f0(0)
update_cam!(scene, eyepos, lookat)
scene.center = false # prevent scene from recentering on display

record(scene, "hopfflower.gif") do io
    for i in 1:100
        # animate scene
        # θ[] = i
        animate(points, i)
        recordframe!(io) # record a new frame
    end
end


