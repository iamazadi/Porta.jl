using Porta
using LinearAlgebra
using Colors
using FileIO
using GeometryTypes
using AbstractPlotting
using Makie
using ReferenceFrameRotations

"""
cutfiber!(θ, ψ, sweep=pi/2, r=0.025, N=30)

Calculates the grid of a fiber circle under stereographic projection
with the given coordinates in the base space (in randians.)
The optional arguments are the sweep angle of the fiber, the radius of
the spherical grid and the square root of the number of points in the grid.
"""
function cutfiber!(point, sweep=pi/2, r=0.025, N=30)
    θ, ψ = point
    corrected_sweep = sweep - sweep*(ψ/(pi/2)) * 0.95
    lspace = range(0, stop = 2pi, length = N)
    lspace2 = range(pi-corrected_sweep, stop = pi+corrected_sweep, length = N)
    # Find 3 points on the circle
    A, B, C = get_points(convert_to_cartesian(point), pi/4)
    # Get the circle center point
    Q = get_center(A, B, C)
    # Find the small and big radii
    R = Float64(LinearAlgebra.norm(A - Q))
    # Construct a torus of revolution grid
    x = Q[1] .+ [(R + r * cos(i)) * cos(j + θ + pi/2) for i in lspace, j in lspace2]
    y = Q[2] .+ [(R + r * cos(i)) * sin(j + θ + pi/2) for i in lspace, j in lspace2]
    z = Q[3] .+ [r * sin(i) for i in lspace, j in lspace2]
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
    rotatedpoints = [ReferenceFrameRotations.vect(q\[points[i][1]; 
                                                     points[i][2]; 
                                                     points[i][3]]*q)
                                                     for i in 1:length(points)]
    rotatedx = [rotatedpoints[i][1] for i in 1:length(rotatedpoints)]
    rotatedy = [rotatedpoints[i][2] for i in 1:length(rotatedpoints)]
    rotatedz = [rotatedpoints[i][3] for i in 1:length(rotatedpoints)]
    rotatedx = reshape(Float64.(rotatedx), (N, N))
    rotatedy = reshape(Float64.(rotatedy), (N, N))
    rotatedz = reshape(Float64.(rotatedz), (N, N))
    [rotatedx, rotatedy, rotatedz]
end

"""
construct(scene, a, g)

Constructs a fiber with the given scene, the observable point a
in the base space and the unit quaternion g for the three sphere rotation.
"""
function construct(scene, a, g, direction)
    if direction > 0
        shade = 0.45
    else
        shade = 0.9
    end
    # The radius parameter for constructing surfaces
    r=0.025
    # The square root of the number of points in the grid
    N=30
    lspace = range(0.0, stop = 2pi, length = N)
    # Locate the point in the base space and then rotate the three sphere
    # y = @lift(rotate(locate($a[1], $a[2]), $g))
    y = @lift(convert_to_cartesian($a))
    # Calculate the marker grid for a point in the base space
    v = to_value(y)
    color = RGBAf0(v[1]*4/5+rand()/5, v[2]*4/5+rand()/5, (v[3]*4/5+rand()/5)/10+shade, 1.0)
    # Calculate the marker grid for a fiber under the streographic projection
    sweep = pi/2
    fiber = @lift(cutfiber!($a, sweep, r, N))
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
function animate(item, i)
    points, direction = item
    for point in points
        val = to_value(point)
        if direction > 0
            point[] = [(val[1] - (i-1)/100 * 2pi) + i/100 * 2pi, val[2]]
        else
            point[] = [(val[1] + (i-1)/100 * 2pi) - i/100 * 2pi, val[2]]
        end
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

stars = 100_000
scene = Scene(show_axis = false, backgroundcolor = :orange)
scatter!(
    scene,
    map(i-> (randn(Point3f0) .- 0.5) .* 10, 1:stars),
    glowwidth = 1, glowcolor = (:white, 0.1), color = rand(stars),
    colormap = [(:white, 0.4), (:gold, 0.4), (:yellow, 0.4)],
    markersize = rand(range(0.0001, stop = 0.05, length = 100), stars),
    show_axis = false, transparency = true
)

points = []
latitudes = [pi/12, pi/6, pi/4, pi/3, 5pi/12]
for i in 1:length(latitudes)
    torus = []
    direction = (-1)^i
    #for j in range(0, stop = 2pi, length = 30)
    for j in range(pi/4, stop = 2pi - pi/4, length = 30)
        point = Node([j+i, latitudes[i]])
        construct(scene, point, g, direction)
        push!(torus, point)
    end
    push!(points, (torus, direction))
end
fullscene = hbox(scene,
                 vbox(sθ, sψ, sϕ),
                 parent = Scene(resolution = (400, 400)))
update_cam!(scene, FRect3D(Vec3f0(-0.75), Vec3f0(1.5)))
scene.center = false
record(scene, "londontsai.gif") do io
    p = 2.81
    for i in 1:100
        for torus in points
            animate(torus, i)
        end
        rotate_cam!(scene, 0.0, p/100, 2p/100)
        recordframe!(io) # record a new frame
    end
end


