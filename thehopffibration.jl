using FileIO, Colors
using Makie
using AbstractPlotting
using GeometryTypes
using LinearAlgebra
using ReferenceFrameRotations

# Parameters for constructing the surfaces
N = 30
lspace = range(0.0, stop = 2pi, length = N)

"""
locate(θ, ψ)

Locates the point in the base space
with the given corrdinates on the two sphere: latitude (θ) and longitude(ψ)
both of which are measured in radians.
"""
function locate(θ, ψ)
    y₁ = cos(θ)*cos(ψ)
    y₂ = cos(θ)*sin(ψ)
    y₃ = sin(θ)
    [y₁, y₂, y₃]
end

"""
σ⁻¹(y₁, y₂, y₃)

Sends a point on the plane back to a point on the unit sphere.
It is the inverse stereographic projection of a three sphere.
"""
function σ⁻¹(y₁, y₂, y₃)
    x₁ = 2y₁ / (1 + y₁^2 + y₂^2 + y₃^2)
    x₂ = 2y₂ / (1 + y₁^2 + y₂^2 + y₃^2)
    x₃ = 2y₃ / (1 + y₁^2 + y₂^2 + y₃^2)
    x₄ = (-1 + y₁^2 + y₂^2 + y₃^2) / (1 + y₁^2 + y₂^2 + y₃^2)
    [x₁, x₂, x₃, x₄]
end

"""
σ(x₁, x₂, x₃, x₄)

Sends a point on the unit sphere to a point on the plane.
It is the stereographic projection of a three sphere.
"""
function σ(x₁, x₂, x₃, x₄)
    y₁ = x₁ / (1 - x₄)
    y₂ = x₂ / (1 - x₄)
    y₃ = x₃ / (1 - x₄)
    [y₁, y₂, y₃]
end

"""
points!(a)

Finds 3 points on the fiber circle under stereographic projection 
with the given point in the base space.
"""
function points!(a)
    λ₁ = complex(cos(1), sin(1))
    λ₂ = complex(cos(2), sin(2))
    λ₃ = complex(cos(3), sin(3))
    w₁, w₂, w₃, w₄ = σ⁻¹(a[1], a[2], a[3])
    x₁ = λ₁ * complex(w₁, w₂)
    x₂ = λ₁ * complex(w₃, w₄)
    y₁ = λ₂ * complex(w₁, w₂)
    y₂ = λ₂ * complex(w₃, w₄)
    z₁ = λ₃ * complex(w₁, w₂)
    z₂ = λ₃ * complex(w₃, w₄)
    p = σ(real(x₁), imag(x₁), real(x₂), imag(x₂))
    q = σ(real(y₁), imag(y₁), real(y₂), imag(y₂))
    r = σ(real(z₁), imag(z₁), real(z₂), imag(z₂))
    [p, q, r]
end

"""
center!(A, B, C)

Finds the center point of the fiber circle under stereographic projection
with the given 3 points on the circle circumference.
"""
function center!(A, B, C)
    a = norm(B - C)
    b = norm(A - C)
    c = norm(A - B)
    numerator = a^2 * (b^2 + c^2 - a^2) * A + 
                b^2 * (a^2 + c^2 - b^2) * B + 
                c^2 * (a^2 + b^2 + - c^2) * C
    denominator = a^2 * (b^2 + c^2 - a^2) + 
                  b^2 * (a^2 + c^2 - b^2) + 
                  c^2 * (a^2 + b^2 - c^2)
    numerator / denominator
end

"""
rotate(y, g)

Rotates the three sphere with the given unit quaternion g
and returns the rotated version of the point a in the base space.
"""
function rotate(y, g)
    x₁, x₂, x₃, x₄ = σ⁻¹(y[1], y[2], y[3])
    q = ReferenceFrameRotations.Quaternion(x₁, x₂, x₃, x₄)
    vect(g * q)
end

"""
fiber!(a)

Calculates the grid of a fiber circle under stereographic projection
with the given coordinates in the base space.
"""
function fiber!(a)
    # Find 3 points on the circle
    A, B, C = points!(a)
    # Get the circle center point
    Q = center!(A, B, C)
    # Find the small and big radii
    r = 0.025
    R = Float64(norm(A - Q))
    # Construct a torus of revolution grid
    x = Q[1] .+ [(R + r * cos(i)) * cos(j) for i in lspace, j in lspace]
    y = Q[2] .+ [(R + r * cos(i)) * sin(j) for i in lspace, j in lspace]
    z = Q[3] .+ [r * sin(i) for i in lspace, j in lspace]
    points = [Point3f0(x[i], y[i], z[i]) for i in 1:length(x)]
    # Get the normal to the plane containing the points
    n = cross(A - Q, B - Q)
    n = n / norm(n)
    # The initial normal to the circle
    i = Point3f0(0.0, 0.0, 1.0)
    # The axis of rotation
    u = cross(n, i)
    u = u / norm(u)
    # The angle of rotation
      ϕ = acos(dot(n, i)) / 2.0
    q = ReferenceFrameRotations.Quaternion(cos(ϕ), 
                                           sin(ϕ)*u[1],
                                           sin(ϕ)*u[2],
                                           sin(ϕ)*u[3])
    # Rotate the grid
    rotatedpoints = [vect(q\[points[i][1]; 
                             points[i][2]; 
                             points[i][3]]*q) for i in 1:length(points)]
    rotatedx = [rotatedpoints[i][1] for i in 1:length(rotatedpoints)]
    rotatedy = [rotatedpoints[i][2] for i in 1:length(rotatedpoints)]
    rotatedz = [rotatedpoints[i][3] for i in 1:length(rotatedpoints)]
    rotatedx = reshape(Float64.(rotatedx), (N, N))
    rotatedy = reshape(Float64.(rotatedy), (N, N))
    rotatedz = reshape(Float64.(rotatedz), (N, N))
    [rotatedx, rotatedy, rotatedz]
end

"""
base!(a)

Calculates the marker grid for a point in the base space
with the given coordinates in the base space.
"""
function base!(a)
    # Construct a two sphere grid
    r = 0.05
    x = a[1] .+ [r * cos(i)*cos(j) for i in lspace, j in lspace]
    y = a[2] .+ [r * cos(i)*sin(j) for i in lspace, j in lspace]
    z = a[3] .+ [r * sin(i) for i in lspace, j in lspace]
    [x, y, z]
end

"""
construct(scene, a, g)

Constructs a fiber with the given scene, the observable point a
in the base space and the unit quaternion g for the three sphere rotation.
"""
function construct(scene, a, g)
    # Locate the point in the base space and then rotate the three sphere
    y = @lift(rotate(locate($a[1], $a[2]), $g))
    color = @lift([RGBAf0($y[1], $y[2], $y[3]) for i in lspace, j in lspace])
    # Calculate the marker grid for a point in the base space
    base = @lift(base!($y))
    # Calculate the marker grid for a fiber under the streographic projection
    fiber = @lift(fiber!($y))
    surface!(scene, 
             @lift($base[1]),
             @lift($base[2]),
             @lift($base[3]),
             color = color,
             shading = false)
    surface!(scene, 
             @lift($fiber[1]),
             @lift($fiber[2]), 
             @lift($fiber[3]), 
             color = color,
             shading = false)
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
                    "θ", raw = true, 
                    camera = campixel!, 
                    start = 0)
sψ, oψ = textslider(0:0.01:2pi, 
                    "ψ", raw = true, 
                    camera = campixel!, 
                    start = 0)
sϕ, oϕ = textslider(0:0.01:2pi, 
                    "ϕ", raw = true, 
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
               shading = false, 
               transparency = true)
coordinates = [[0.565, 2.204], # iran
               [0.647, 1.670], # us
               [-0.441, 2.334], # australia
               [0.541, 0.608], # isreal
               [0.625, 1.818]] # china
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

