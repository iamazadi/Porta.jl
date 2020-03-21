using Porta
using LinearAlgebra
using Colors
using FileIO
using GeometryTypes
using AbstractPlotting
using Makie
using ReferenceFrameRotations


"""
get_fiber(point; r=0.025, N=30)

Calculates the grid of a fiber circle under stereographic projection with the
given coordinates in the base space. The optional arguments are the radius of
the spherical grid and the square root of the number of points in the grid.
"""
function get_fiber(point; r=0.025, N=30)
    lspace = range(0.0, stop = 2pi, length = N)
    # Find 3 points on the circle
    A, B, C = get_points(point, pi/4)
    # Get the circle center point
    Q = get_center(A, B, C)
    # Find the small and big radii
    R = Float64(LinearAlgebra.norm(A - Q))
    # Construct a torus of revolution grid
    x = (Q[1] .+ [(R + r * cos(i)) * cos(j) for i in lspace, j in lspace]) ./ R
    y = (Q[2] .+ [(R + r * cos(i)) * sin(j) for i in lspace, j in lspace]) ./ R
    z = (Q[3] .+ [r * sin(i) for i in lspace, j in lspace]) ./ R
    points = [[x[i], y[i], z[i]] for i in 1:length(x)]
    # Get the normal to the plane containing the points
    n = LinearAlgebra.cross(A - Q, B - Q)
    n = n / LinearAlgebra.norm(n)
    # The initial normal to the circle
    i = [0.0, 0.0, 1.0]
    # The axis of rotation
    u = LinearAlgebra.cross(n, i)
    u = u / LinearAlgebra.norm(u)
    # The angle of rotation
      ϕ = acos(LinearAlgebra.dot(n, i)) / 2.0
    q = ReferenceFrameRotations.Quaternion(cos(ϕ), 
                                           sin(ϕ)*u[1],
                                           sin(ϕ)*u[2],
                                           sin(ϕ)*u[3])
    # Rotate the grid
    rotated = [ReferenceFrameRotations.vect(q\[points[i][1]; 
                                               points[i][2]; 
                                               points[i][3]]*q)
                                               for i in 1:length(points)]
    rotatedx = [rotated[i][1] for i in 1:length(rotated)]
    rotatedy = [rotated[i][2] for i in 1:length(rotated)]
    rotatedz = [rotated[i][3] for i in 1:length(rotated)]
    rotatedx = reshape(Float64.(rotatedx), (N, N))
    rotatedy = reshape(Float64.(rotatedy), (N, N))
    rotatedz = reshape(Float64.(rotatedz), (N, N))
    [rotatedx, rotatedy, rotatedz]
end


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
construct(scene, point)

Constructs a fiber with the given scene and the observable point
in the base space.
"""
function construct(scene, point)
    # The radius parameter for constructing surfaces
    r=0.1
    # The square root of the number of points in the grid
    N=30
    lspace = range(0.0, stop = 2pi, length = N)
    # Calculate the marker grid for a point in the base space
    v = to_value(point)
    color = RGBAf0(v[1]/2+rand()/2, v[2]/2+rand()/2, v[3]/2+rand()/2, 0.9)
    # Calculate the marker grid for a fiber under streographic projection
    fiber = @lift(get_fiber($point, r = r, N = N))
    surface!(scene, 
             @lift($fiber[1]),
             @lift($fiber[2]), 
             @lift($fiber[3]), 
             color = [color for i in lspace, j in lspace],
             shading = false)
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
        θ, ϕ = convert_to_geographic(to_value(point))
        point[] = convert_to_cartesian([θ + (i-1)/100 * 2pi - i/100 * 2pi, ϕ])
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


