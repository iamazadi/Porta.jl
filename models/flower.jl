using LinearAlgebra
using Makie


"""
λmap(p)
Sends a point on a 3-sphere to a point in the plane x₄=0 with the given point
in the form of 2 complex numbers representing a unit quaternion. This is the
stereographic projection of a 3-sphere. S³ ↦ R³
"""
function λmap(p)
    [real(p[1]), imag(p[1]), real(p[2])] ./ (1 - imag(p[2]))
end


"""
λ⁻¹map(p)
Sends a point on the plane back to a point on a unit sphere with the given
point. This is the inverse stereographic projection of a 3-sphere.
"""
function λ⁻¹map(p)
    x₁ = 2p[1] / (1 + p[1]^2 + p[2]^2 + p[3]^2)
    x₂ = 2p[2] / (1 + p[1]^2 + p[2]^2 + p[3]^2)
    x₃ = 2p[3] / (1 + p[1]^2 + p[2]^2 + p[3]^2)
    x₄ = (-1 + p[1]^2 + p[2]^2 + p[3]^2) / (1 + p[1]^2 + p[2]^2 + p[3]^2)
    [Complex(x₁, x₂), Complex(x₃, x₄)]
end


"""
S¹action(α, p)
Performs a group action corresponding to moving along the circumference of a
circle with the given angle and the point in the form of 2 complex numbers
representing a unit quaternion.
"""
function S¹action(α, p)
    [exp(im * α) * p[1], exp(im * α) * p[2]]
end


"""
convert_to_cartesian(p)
Converts a point in the geographic coordinate system to a point in the
cartesian one with the given point in radians.
"""
function convert_to_cartesian(p)
    [cos(p[2]) * cos(p[1]),
     cos(p[2]) * sin(p[1]),
     sin(p[2])]
end


"""
convert_to_geographic(p)
Converts a point in the cartesian coordinate system to a point in the
geographic one with the given point.
"""
function convert_to_geographic(p)
    r = sqrt(p[1]^2 + p[2]^2 + p[3]^2)
    if p[1] > 0
          ϕ = atan(p[2] / p[1])
    elseif p[2] > 0
          ϕ = atan(p[2] / p[1]) + pi
    else
          ϕ = atan(p[2] / p[1]) - pi
    end
    θ = asin(p[3] / r)
    [ϕ, θ]
end


"""
get_center(A, B, C)

Finds the center point of the fiber circle under stereographic projection
with the given 3 points on the circle circumference.
"""
function get_center(A, B, C)
    a = LinearAlgebra.norm(B - C)
    b = LinearAlgebra.norm(A - C)
    c = LinearAlgebra.norm(A - B)
    numerator = a^2 * (b^2 + c^2 - a^2) * A +
                b^2 * (a^2 + c^2 - b^2) * B +
                c^2 * (a^2 + b^2 - c^2) * C
    denominator = a^2 * (b^2 + c^2 - a^2) +
                  b^2 * (a^2 + c^2 - b^2) +
                  c^2 * (a^2 + b^2 - c^2)
    numerator / denominator
end


"""
get_flower(;N=4, A=.5, B=-pi/7, P=pi/2, Q=0, number=300)

Calculates the x, y and z points of a flower in the base space.
with the given number of petals N, the fattness of the petals A,
the height of the petals B, the latitude of the flower P,
the rotation of the flower Q, and the total number of points in the grid.
"""
function get_flower(;N=4, A=.5, B=-pi/7, P=pi/2, Q=0, number=300)
    N = 7
    A = .5
    B = -pi/7
    P = pi/3
    Q = 0
    t = range(0, stop = 2pi, length = number)
    az = 2pi .* t + A .* cos.(N .* 2pi .* t) .+ Q
    po = B .* sin.(N .* 2pi .* t) .+ P
    x = cos.(az).*sin.(po)
    y = sin.(az).*sin.(po)
    z = cos.(po)
    points = Array{Float64}(undef, number, 2)
    for i in 1:number
        points[i, :] = convert_to_geographic([x[i], y[i], z[i]])
    end
    points
end


"""
build_surface(scene, points, color; transparency, shading)

Builds a surface with the given scene, points, color, transparency and shading.
"""
function build_surface(scene,
                       points,
                       color;
                       transparency = false,
                       shading = true)
    surface!(scene,
             @lift($points[:, :, 1]),
             @lift($points[:, :, 2]),
             @lift($points[:, :, 3]),
             color = color,
             transparency = transparency,
             shading = shading)
end


"""
rotate3D_geographic(point, q)

Rotates a point in the 3D space with the given point and the unit quaternion.
"""
function rotate3D_geographic(point, q)
    c = convert_to_cartesian(point)
    p = Quaternion(c[1], c[2], c[3], 0.0)
    R = conj(q) * p * q
    convert_to_geographic([R[1], R[2], R[3]])
end


"""
rotate3D_cartesian(point, q)

Rotates a point in the 3D space with the given point and the unit quaternion.
"""
function rotate3D_cartesian(point, q)
    p = Quaternion(point..., 0.0)
    R = conj(q) * p * q
    [R[1], R[2], R[3]]
end


"""
get_fiber(point, segments, samples; r=0.025)

Calculates a torus of revolution for building a surface in a specific way with
the given point in the base space, the number of segments, the number of
samples and the radius of the smaller circle in the torus of revolution.
"""
function get_fiber(point, segments, samples; r=0.025)
    # Find 3 points on the circle
    b = λ⁻¹map(convert_to_cartesian(point))
    A = λmap(S¹action(pi / 6, b))
    B = λmap(S¹action(pi / 4, b))
    C = λmap(S¹action(pi / 3, b))
    # The fiber circle center
    Q = get_center(A, B, C)
    # The bigger radius
    R = norm(Q - A)
    # Get the normal to the plane containing the points
    n = LinearAlgebra.cross(A - Q, B - Q)
    n = n / LinearAlgebra.norm(n)
    # The initial normal to the circle
    i = [0.0, 0.0, 1.0]
    # The axis of rotation
    u = LinearAlgebra.cross(n, i)
    u = u / LinearAlgebra.norm(u)
    # The angle of rotation
    angle = acos(LinearAlgebra.dot(n, i)) / 2.0
    q = Quaternion(sin(angle)*u[1],
                   sin(angle)*u[2],
                   sin(angle)*u[3],
                   cos(angle))
    # Construct a torus of revolution grid
    manifold = Array{Float64}(undef, segments, samples, 3)
    for i in 1:segments
        for j in 1:samples
            longitude = i * 2pi / (segments - 1)
            latitude = j * 2pi / (samples - 1)
            x₁ = (Q[1] + (R + r * cos(longitude)) * cos(latitude)) / R
            x₂ = (Q[2] + (R + r * cos(longitude)) * sin(latitude)) / R
            x₃ = (Q[3] + r * sin(longitude)) / R
            manifold[i, j, :] = rotate3D_cartesian([x₁, x₂, x₃], q)
        end
    end
    manifold
end


# The scene object that contains other visual objects
universe = Scene(backgroundcolor = :black, show_axis=false, resolution = (360, 360))

# Calculate a unit quaternion as the rotation axis
u = [sqrt(3)/3, sqrt(3)/3, sqrt(3)/3]
ϕ = Node(0.0)
q = @lift(Quaternion(sin($ϕ)*u[1],
                     sin($ϕ)*u[2],
                     sin($ϕ)*u[3],
                     cos($ϕ)))
segments = 30
samples = 30
number = 420
points = get_flower(number = number)
for i in 1:number
    rotated = @lift(rotate3D_geographic(points[i, :], $q))
    fiber = @lift(get_fiber($rotated, segments, samples))
    color = @lift begin
        x₁, x₂, x₃ = convert_to_cartesian($rotated)
        fill(RGBAf0(rand()/2+x₁/2, rand()/2+x₂/2, rand()/2+x₃/2, 1.0),
             segments,
             samples)
    end
    build_surface(universe, fiber, color, shading = false)
end

# update eye position
eye_position, lookat, upvector = Vec3f0(0.01, 0, 6), Vec3f0(0), Vec3f0(0, 0, 1.0)
update_cam!(universe, eye_position, lookat)
universe.center = false # prevent scene from recentering on display
#Makie.save("gallery/porta.jpg", universe)

record(universe, "gallery/flower.gif") do io
    frames = 90
    for i in 1:frames
            ϕ[] = i*pi/frames # animate scene
        recordframe!(io) # record a new frame
    end
end
