using LinearAlgebra
using Makie
using Combinatorics
import Quaternions
H = Quaternions.Quaternion


const TOLERANCE = 1e-7


"""
σ(q)

Sends a point on a 3-sphere to a point in the plane x₄=0 with the given point.
This is the stereographic projection of a 3-sphere. S³ ↦ R³
"""
function σ(q)
    Point3f0(q.s, q.v1, q.v2) ./ (1 - q.v3)
end


"""
π(q)

Sends a point on a unit 3-sphere to a point on a unit 2-sphere with the given
point. S³ ↦ S²
"""
function π(q)
    x₁ = q.s
    x₂ = q.v1
    x₃ = q.v2
    x₄ = q.v3
    Point3f0(2(x₁*x₃ + x₂*x₄), 2(x₂*x₃ - x₁*x₄), x₁^2+x₂^2-x₃^2-x₄^2)
end


"""
S¹action(α, q)

Performs a group action corresponding to moving along the circumference of a
circle with the given angle and the point.
"""
function S¹action(α, q)
    z₁ = Complex(q.s, q.v1)
    z₂ = Complex(q.v2, q.v3)
    αz₁, αz₂ = exp(im * α) * z₁, exp(im * α) * z₂
    H(real(αz₁), imag(αz₁), real(αz₂), imag(αz₂))
end


"""
rotate3D(point, q)

Rotates a point in the 3D space with the given point and the unit quaternion.
"""
function rotate3D(point, q)
    p = H(0, point[1], point[2], point[3])
    R = conj(q) * p * q
    Point3f0(R.v1, R.v2, R.v3)
end


"""
get_center(A, B, C)

Finds the center point of the fiber circle under stereographic projection
with the given 3 points on the circle circumference.
"""
function get_center(A, B, C)
    a = norm(B - C)
    b = norm(A - C)
    c = norm(A - B)
    numerator = a^2 * (b^2 + c^2 - a^2) * A + 
                b^2 * (a^2 + c^2 - b^2) * B + 
                c^2 * (a^2 + b^2 - c^2) * C
    denominator = a^2 * (b^2 + c^2 - a^2) + 
                  b^2 * (a^2 + c^2 - b^2) + 
                  c^2 * (a^2 + b^2 - c^2)
    numerator / denominator
end


"""
get_fiber(point, segments, samples; r=0.025)

Calculates a torus of revolution for building a surface in a specific way with
the given point in the base space, the number of segments, the number of
samples and the radius of the smaller circle in the torus of revolution.
"""
function get_fiber(point; segments = 30, r = 0.025)
    # Find 3 points on the circle
    A = σ(S¹action(pi / 6, point))
    B = σ(S¹action(pi / 4, point))
    C = σ(S¹action(pi / 3, point))
    # The fiber circle center
    Q = get_center(A, B, C)
    # The bigger radius
    R = norm(Q - A)
    # Get the normal to the plane containing the points
    n = cross(A - Q, B - Q)
    n = n / norm(n)
    # The initial normal to the circle
    i = [0.0, 0.0, 1.0]
    # The axis of rotation
    u = cross(n, i)
    u = u / norm(u)
    # The angle of rotation
    angle = acos(dot(n, i)) / 2.0
    q = H(cos(angle), sin(angle)*u[1], sin(angle)*u[2], sin(angle)*u[3])
    # Construct a torus of revolution grid
    fiber = Array{Point3f0}(undef, segments, segments)
    for i in 1:segments
        for j in 1:segments
            longitude = j * 2pi / (segments - 1)
            latitude = i * 2pi / (segments - 1)
            x₁ = Q[1] + (R + r * cos(longitude)) * cos(latitude) / R
            x₂ = Q[2] + (R + r * cos(longitude)) * sin(latitude) / R
            x₃ = Q[3] + r * sin(longitude) / R
            fiber[i, j] = rotate3D(Point3f0(x₁, x₂, x₃), q)
        end
    end
    fiber
end


"""
compressed_σ(q)

Sends a point on a 3-sphere to a point in the compressed plane x₄=0 with the
given point. This is the stereographic projection of a 3-sphere. S³ ↦ R³
"""
function compressed_σ(q)
    sigmoid(x) = exp(x) / (1 + exp(x))
    2 .* (sigmoid.(σ(q)) .- 0.5)
end


"""
get_rotation_axis(i, n)

Calculates a unit quaternion corresponding to the axis of a 3D rotation with
the given initial and end unit vectors.
"""
function get_rotation_axis(i, n)
    u = normalize(cross(n, i))
    # The angle of rotation
    dotproduct = dot(n, i)
    if isapprox(dotproduct, 1, atol=TOLERANCE)
        θ = acos(1)
    elseif isapprox(dotproduct, -1, atol=TOLERANCE)
        θ = acos(-1)
    else
        θ = acos(dotproduct)
    end
    H(cos(θ/2), sin(θ/2)*u[1], sin(θ/2)*u[2], sin(θ/2)*u[3])
end


"""
get_cylinder(A, B; segments = 30, r = 0.025)

Calculates a cylinder with the given 2 points, the number of segments and the
radius. The points correspond to the beginning and the end of the cylinder.
"""
function get_cylinder(A, B; segments = 30, r = 0.025)
    cylinder = Array{Point3f0}(undef, segments, segments)
    i = [0.0, 0.0, 1.0]
    n = normalize(B - A)
    q = get_rotation_axis(i, n)
    for i in 1:segments
        for j in 1:segments
            α = (j-1) * 2pi / (segments - 1)
            x₁ = r * sin(α)
            x₂ = r * cos(α)
            x₃ = (i-1) * norm(B - A) / (segments - 1)
            cylinder[i, j] = (rotate3D(Point3f0(x₁, x₂, x₃), q) + A)
        end
    end
    cylinder
end


"""
get_torus(A, B, C; segments = 30, r = 0.025)

Calculates a section of a 2-torus with the given 3 points, the number of
segments and the radius of the smaller circle. The points correspond to the
beginning, middle and the end of the arc of the bigger circle.
"""
function get_torus(A, B, C; segments = 30, r = 0.025)
    torus = Array{Point3f0}(undef, segments, segments)
    # The fiber circle center
    Q = get_center(A, B, C)
    # The bigger radius
    R = norm(Q - A)
    # Find the arc sweep angle
    QA = normalize(A - Q)
    QC = normalize(C - Q)
    dotproduct = dot(QA, QC)
    if isapprox(dotproduct, 1, atol=TOLERANCE)
        α = acos(1)
    elseif isapprox(dotproduct, -1, atol=TOLERANCE)
        α = acos(-1)
    else
        α = acos(dotproduct)
    end
    # The normal to the initial circle
    i = [0.0, 0.0, 1.0]
    # Get the normal to the rotated circle
    n = normalize(normalize(cross(A - Q, B - Q)) +
                  normalize(cross(A - Q, C - Q)) +
                  normalize(cross(B - Q, C - Q)))
    # The first rotation versor
    q = get_rotation_axis(i, n)
    # The vector pointing to the positive direction of the x axis on the
    # plane of the rotated circle
    i = rotate3D([1.0, 0.0, 0.0], q)
    # The second rotation versor
    q′ = get_rotation_axis(i, QA)
    # Construct a torus of revolution
    for i in 1:segments
        for j in 1:segments
            longitude = (j-1) * 2pi / (segments - 1)
            latitude = (i-1) * α / (segments - 1)
            x₁ = (R + r * cos(longitude)) * cos(latitude)
            x₂ = (R + r * cos(longitude)) * sin(latitude)
            x₃ = r * sin(longitude)
            torus[i, j] = rotate3D(Point3f0(x₁, x₂, x₃), q * q′) + Q
        end
    end
    torus
end


"""
get_manifold(points, segments, radius)

Calculates a grid of points in order to build a surface with the given 3 points
that are on a circle, the number of segments and the radius of torus/cylinder.
The points should be quaternions.
"""
function get_manifold(points, segments, radius)
    # Use stereographic projection to send the points to R³
    A, B, C = map((x) -> compressed_σ(x), points)
    # If the points are collinear, then build a cylinder
    if isapprox(norm(cross(A - B, C - B)), 0, atol = TOLERANCE)
        manifold = get_cylinder(A, C, segments = segments, r = radius)
        # manifold = get_torus(A, B, C, segments = segments, r = radius)
    # And if they are not collinear, then build a torus of revolution
    else
        # manifold = get_torus(A, B, C, segments = segments, r = radius)
        manifold = get_cylinder(A, C, segments = segments, r = radius)
    end
    manifold
end


"""
get_vertices()

Returns the versors corresponding to the 24 vertices of a 24-cell inscribed
inside of a 3-sphere.
"""
function get_vertices()
    set = []
    set1 = [H(getindex.(Ref([-1/2, 1/2]), 1 .+ digits(i-1; base=2, pad=4))...)
            for i=1:2^4]
    set2 = [H(i...) for i in permutations([1, 0, 0, 0]) |> collect]
    set3 = [H(i...) for i in permutations([-1, 0, 0, 0]) |> collect]
    push!(set, set1..., set2..., set3...)
    unique(set)
end


# The scene object that contains other visual objects
scene = Scene(backgroundcolor = :navyblue, show_axis=false, resolution = (360, 360))
# Use a slider for rotating the base space in an interactive way
sθ, θ = textslider(0:0.01:2pi, "θ", start = pi/4)
sϕ, ϕ = textslider(0:0.01:2pi, "ϕ", start = 0)
sψ, ψ = textslider(0:0.01:2pi, "ψ", start = 0)
# Calculate a unit quaternion as the rotation axis
u = @lift([cos($ϕ) * cos($ψ), cos($ϕ) * sin($ψ), sin($ϕ)])
q = @lift(H(cos($θ), sin($θ) * $u[1], sin($θ) * u[2], sin($θ) * $u[3]))
vertices = get_vertices()
segments = 30
radius = 0.025

edges = []
for i in 1:length(vertices)
    for j in i:length(vertices)
        g = vertices[i]
        h = vertices[j]
        distance = norm(g - h)
        if isapprox(distance, 1)
            m = normalize((g + h) / 2)
            push!(edges, [g, m, h])
        end
    end
end
faces = []
for i in 1:length(vertices)
    for j in i:length(vertices)
        for k in j:length(vertices)
            a = vertices[i]
            b = vertices[j]
            c = vertices[k]
            ab = norm(a - b)
            ac = norm(a - c)
            bc = norm(b - c)
            if isapprox(ab, 1, atol = TOLERANCE) &&
               isapprox(ac, 1, atol = TOLERANCE) &&
               isapprox(bc, 1, atol = TOLERANCE)
                push!(faces, [a, b, c])
            end
        end
    end
end
gold = [0.8314, 0.6863, 0.2157]
saturated = [0.9098, 0.7255, 0.1373]
rosegold = [0.718, 0.431, 0.475]
platinum = [0.898, 0.894, 0.886]
silver = [0.752, 0.752, 0.752]
manifolds = []
for i in 1:length(edges)
    # First use 3-sphere rotations to rotate the points
    rotated = @lift(map((x) -> $q * x, edges[i]))
    manifold = @lift(get_manifold($rotated, segments, radius))
    x = @lift([m[1] for m in $manifold])
    y = @lift([m[2] for m in $manifold])
    z = @lift([m[3] for m in $manifold])
    if i > length(edges) / 2
        color = fill(RGBAf0(gold..., 0.9), segments, segments)
    else
        color = fill(RGBAf0(saturated..., 0.9), segments, segments)
    end
    surface!(scene, x, y, z, color = color, shading = true)
end

for vertex in vertices
    rotated = @lift(compressed_σ($q * vertex))
    x = @lift([$rotated[1]])
    y = @lift([$rotated[2]])
    z = @lift([$rotated[3]])
    color = RGBAf0(rosegold..., 0.9)
    meshscatter!(scene, x, y, z, markersize = 2radius, color = color, shading = true)
end

for i in 1:length(faces)
    a, b, c = faces[i]
    rotateda = @lift(compressed_σ($q * a))
    rotatedb = @lift(compressed_σ($q * b))
    rotatedc = @lift(compressed_σ($q * c))
    l = @lift([($rotateda[1], $rotateda[2], $rotateda[3]),
               ($rotatedb[1], $rotatedb[2], $rotatedb[3]),
               ($rotatedc[1], $rotatedc[2], $rotatedc[3])])
    indices = [1, 2, 3,   2, 3, 1,   3, 1, 2]
    color = [RGBAf0(gold..., rand()), RGBAf0(saturated..., rand()), RGBAf0(rosegold..., rand())]
    mesh!(scene, l, color = color)
end

# update eye position
eye_position, lookat, upvector = Vec3f0(2, 2, 2), Vec3f0(0), Vec3f0(0.0, 0.0, 0.0001)
update_cam!(scene, eye_position, lookat)
scene.center = false # prevent scene from recentering on display

#fullscene = hbox(scene, vbox(sθ, sϕ, sψ), parent = Scene(resolution = (500, 500)))

record(scene, "24-cell.gif") do io
    frames = 180
    for i in 1:frames
        # animate scene
        ϕ[] = i/frames*2pi
        ψ[] = -tanh(10i/frames)*2pi
        recordframe!(io) # record a new frame
    end
end


