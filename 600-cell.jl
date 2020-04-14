using LinearAlgebra
using Makie
using Combinatorics
using AbstractAlgebra
import Quaternions
H = Quaternions.Quaternion


const TOLERANCE = 1e-7
const GOLDEN_RATIO = (1 + sqrt(5)) / 2
const RADIUS = 0.025
const SEGMENTS = 60


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
    H(cos(θ/2), (sin(θ/2).*u)...)
end


"""
get_fiber(point; segments, r=0.025)

Calculates a torus of revolution for building a surface in a specific way with
the given point in the base space, the number of segments, the number of
samples and the radius of the smaller circle in the torus of revolution.
"""
function get_fiber(point; segments = 30, r = 0.025)
    # Find 3 points on the circle
    A = σ(S¹action(pi / 5, point))
    B = σ(S¹action(pi / 4, point))
    C = σ(S¹action(pi / 3, point))
    # The fiber circle center
    Q = get_center(A, B, C)
    # The bigger radius
    R = norm(Q - A)
    A = A ./ R
    B = B ./ R
    C = C ./ R
    Q = Q ./ R
    # The bigger radius
    R = norm(Q - A)
    # The normal to the initial circle
    i = [0.0, 0.0, 1.0]
    # Get the normal to the rotated circle
    n = normalize(normalize(cross(A - Q, B - Q)))
    # The first rotation versor
    q = get_rotation_axis(i, n)
    # The vector pointing to the positive direction of the x axis on the
    # plane of the rotated circle
    i = rotate3D([1.0, 0.0, 0.0], q)
    # The second rotation versor
    q′ = get_rotation_axis(i, normalize(A - Q))
    # Construct a torus of revolution grid
    fiber = Array{Point3f0}(undef, segments, segments)
    for i in 1:segments
        for j in 1:segments
            longitude = j * 2pi / (segments - 1)
            latitude = i * 2pi / (segments - 1)
            x₁ = (R + r * cos(longitude)) * cos(latitude)
            x₂ = (R + r * cos(longitude)) * sin(latitude)
            x₃ = r * sin(longitude)
            fiber[i, j] = rotate3D(Point3f0(x₁, x₂, x₃), q * q′) + Q
        end
    end
    fiber
end


"""
iseven(v, x)

Checks the parity of a permutation to see whether it is even or not with the
given original vector and the permutated vector.
"""
function iseven(v, x)
    # Get a trivial sequence of the given permutation
    g = Perm([findfirst(isequal(x[i]), v) for i in 1:length(x)])
    if AbstractAlgebra.parity(g) == 0
        return true
    else
        return false
    end
end


"""
get_vertices()

Returns the versors corresponding to the 120 vertices of a 600-cell inscribed
inside of a 3-sphere.
"""
function get_vertices()
    set = []
    set1 = [getindex.(Ref([1/2, -1/2]), 1 .+ digits(i-1; base=2, pad=4))
            for i=1:2^4]
    set2 = [i for i in permutations([0, 0, 0, 1]) |> collect]
    set3 = [i for i in permutations([0, 0, 0, -1]) |> collect]
    v = [[GOLDEN_RATIO, 1, 1/GOLDEN_RATIO, 0],
         [GOLDEN_RATIO, 1, -1/GOLDEN_RATIO, 0],
         [GOLDEN_RATIO, -1, 1/GOLDEN_RATIO, 0],
         [GOLDEN_RATIO, -1, -1/GOLDEN_RATIO, 0],
         [-GOLDEN_RATIO, 1, 1/GOLDEN_RATIO, 0],
         [-GOLDEN_RATIO, 1, -1/GOLDEN_RATIO, 0],
         [-GOLDEN_RATIO, -1, 1/GOLDEN_RATIO, 0],
         [-GOLDEN_RATIO, -1, -1/GOLDEN_RATIO, 0]] .* 1/2
    set4 = []
    for i in 1:length(v)
        f(x) = iseven(v[i], x)
        push!(set4, filter(f, [j for j in permutations(v[i]) |> collect])...)
    end
    push!(set, set1..., set2..., set3..., set4...)
    map((x) -> H(x...), unique(set))
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
    x = @lift([$points[i, j][1]
               for i in 1:size($points, 1), j in 1:size($points, 2)])
    y = @lift([$points[i, j][2]
               for i in 1:size($points, 1), j in 1:size($points, 2)])
    z = @lift([$points[i, j][3]
               for i in 1:size($points, 1), j in 1:size($points, 2)])
    surface!(scene,
             x,
             y,
             z,
             color = color,
             transparency = transparency,
             shading = shading)
end


"""
get_faces(vertices, distance)

Calculates the faces in a manifold with the given vertices and the distance
between each vertex in a face.
"""
function get_faces(vertices, distance)
    array = []
    for i in 1:length(vertices)
        for j in i:length(vertices)
            for k in j:length(vertices)
                a = vertices[i]
                b = vertices[j]
                c = vertices[k]
                ab = norm(a - b)
                ac = norm(a - c)
                bc = norm(b - c)
                if isapprox(ab, distance, atol = TOLERANCE) &&
                   isapprox(ac, distance, atol = TOLERANCE) &&
                   isapprox(bc, distance, atol = TOLERANCE)
                    push!(array, [a, b, c])
                end
            end
        end
    end
    unique(array)
end


"""
get_Hopf_vertices(vertices)

Filters the extra vertices that are on the same Hopf fiber with the given
vertices on a 3-sphere.
"""
function get_Hopf_vertices(vertices)
    array = []
    for i in 1:length(vertices)
        a = π(vertices[i])
        exists = false
        for j in 1:length(array)
            b = π(array[j])
            if isapprox(a, b, atol = TOLERANCE)
                exists = true
            end
        end
        if !exists
            push!(array, vertices[i])
        end
    end
    unique(array)
end


# The scene object that contains other visual objects
scene = Scene(backgroundcolor = :white, show_axis=false, resolution = (360, 360))
# Use a slider for rotating the base space in an interactive way
sθ, θ = textslider(0:0.01:2pi, "θ", start = 0)
sϕ, ϕ = textslider(0:0.01:2pi, "ϕ", start = 0)
sψ, ψ = textslider(0:0.01:2pi, "ψ", start = 0)
# Calculate a unit quaternion as the rotation axis
u = @lift([cos($ϕ) * cos($ψ), cos($ϕ) * sin($ψ), sin($ϕ)])
q = @lift(H(cos($θ), sin($θ) * $u[1], sin($θ) * u[2], sin($θ) * $u[3]))
vertices = get_vertices()
# Cut a 3-sphere into 2 pieces and get the first one
#f(x) = abs(Complex(x.s, x.v1)) < abs(Complex(x.v2, x.v3))
#vertices = filter(f, total_vertices)
fiber_vertices = get_Hopf_vertices(vertices)
faces = get_faces(vertices)
α₁ = Node(fill(0.0, length(fiber_vertices))
α₂ = Node(fill(1.0, length(faces))

for vertex in fiber_vertices
    fiber = @lift(get_fiber($q * vertex, segments = SEGMENTS, r = RADIUS) ./ GOLDEN_RATIO)
    color = @lift(fill(RGBAf0(compressed_σ($q * vertex)..., $α₁),
                       SEGMENTS,
                       SEGMENTS))
    build_surface(scene, fiber, color, shading = true, transparency = true)
end

for i in 1:length(faces)
    a, b, c = faces[i]
    rotateda = @lift(compressed_σ($q * a))
    rotatedb = @lift(compressed_σ($q * b))
    rotatedc = @lift(compressed_σ($q * c))
    l = @lift([$rotateda, $rotatedb, $rotatedc])
    indices = [1, 2, 3,   2, 3, 1,   3, 1, 2]
    r = rand(3)
    color = @lift([RGBAf0($rotateda..., r[1] * $α₂),
                   RGBAf0($rotatedb..., r[2] * $α₂),
                   RGBAf0($rotatedc..., r[3] * $α₂)])
    mesh!(scene, l, color = color)
end

# update eye position
eye_position, lookat = Vec3f0(2, 2, 2), Vec3f0(0)
update_cam!(scene, eye_position, lookat)
scene.center = false # prevent scene from recentering on display

#fullscene = hbox(scene, vbox(sθ, sϕ, sψ), parent = Scene(resolution = (500, 500)))
"""
record(scene, "600-cell.gif") do io
    frames = 180
    for i in 1:frames
        recordframe!(io) # record a new frame
        # animate the scene
        eye_position = Vec3f0(2 - 2sin(i / frames * pi) + 0.00001,
                              2 - 2sin(i / frames * pi) + 0.00001,
                              2 + 2sin(i / frames * pi))
        update_cam!(scene, eye_position, lookat)
        α₁[] = sin(i / frames * pi)
        α₂[] = 1.0 - sin(i / frames * pi)
        θ[] = i / frames * 2pi
        ψ[] = cos(i / frames * pi/2) * 2pi
            ϕ[] = sin(i / frames * pi/2) * 2pi
    end
end
"""

