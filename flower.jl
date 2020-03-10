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
    A = .4
    B = -pi/7
    P = pi/3
    Q = 0
    t = range(0, stop = 2pi, length = number)
    az = 2pi .* t + A .* cos.(N .* 2pi .* t) .+ Q
    po = B .* sin.(N .* 2pi .* t) .+ P
    cos.(az).*sin.(po), sin.(az).*sin.(po), cos.(po)
end

"""
construct(scene, a)

Constructs a fiber with the given scene and the observable point a
in the base space.
"""
function construct(scene, y)
    # The radius parameter for constructing surfaces
    r=0.1
    # The square root of the number of points in the grid
    N=30
    lspace = range(0.0, stop = 2pi, length = N)
    # Calculate the marker grid for a point in the base space
    v = to_value(y)
    color = RGBAf0(v[1]/4+rand()*3/4, v[2]/4+rand()*3/4, v[3]/4+rand()*3/4, 0.9)
    # Calculate the marker grid for a fiber under streographic projection
    fiber = @lift(fiber!($y, r = r, N = N))
    surface!(scene, 
             @lift($fiber[1]),
             @lift($fiber[2]), 
             @lift($fiber[3]), 
             color = [color for i in lspace, j in lspace],
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

scene = Scene(show_axis = false, backgroundcolor = :black, resolution = (400, 400))

points = []
number = 420
x, y, z = flower!(number = number)
# Rotate the flower
u = [sqrt(3)/3, sqrt(3)/3, sqrt(3)/3]
ϕ = Node(0.0)
q = @lift(ReferenceFrameRotations.Quaternion(cos($ϕ), 
                                             sin($ϕ)*u[1],
                                             sin($ϕ)*u[2],
                                             sin($ϕ)*u[3]))
rotatedpoints = @lift([ReferenceFrameRotations.vect($q\[x[i]; y[i]; z[i]]*$q)
                       for i in 1:number])
for i in 1:number
    point = @lift([$rotatedpoints[i][1],
                   $rotatedpoints[i][2],
                   $rotatedpoints[i][3]])
    construct(scene, point)
    push!(points, point)
end

eyepos = Vec3f0(1, 0, 6)
lookat = Vec3f0(0)
update_cam!(scene, eyepos, lookat)
scene.center = false # prevent scene from recentering on display

record(scene, "flower.gif") do io
    for i in 1:100
        # animate scene
            ϕ[] = i*pi/100
        animate(points, i)
        recordframe!(io) # record a new frame
    end
end


