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

Locates the base point on the two sphere
with the given latitude (θ) and longitude(ψ)
both of which are measured in radians.
"""
function locate(θ, ψ)
    y₁ = cos(θ)*cos(ψ)
    y₂ = cos(θ)*sin(ψ)
    y₃ = sin(θ)
    [y₁,y₂,y₃]
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
points!(p)

Finds 2 points on the fiber circle under stereographic projection 
with the given point in the base space.
"""
function points!(p)
    λ₁ = complex(cos(1), sin(1))
    λ₂ = complex(cos(2), sin(2))
    x₁, x₂, x₃, x₄ = σ⁻¹(p[1], p[2], p[3])
    z₁ = λ₁ * complex(x₁, x₂)
    z₂ = λ₁ * complex(x₃, x₄)
    w₁ = λ₂ * complex(x₁, x₂)
    w₂ = λ₂ * complex(x₃, x₄)
    q = σ(real(z₁), imag(z₁), real(z₂), imag(z₂))
    r = σ(real(w₁), imag(w₁), real(w₂), imag(w₂))
    [q, r]
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
fiber!(θ, ψ)

Calculates the grid of a fiber circle under sterographic projection
with the given coordinates in the base space: latitude (θ) and longitude(ψ),
both of which are measured in radians.
"""
function fiber!(θ, ψ)
    # Locate the point on the two sphere
    C = locate(θ, ψ)
    # Find two other points on the circle
    A, B = points!(C)
    # Get the circle center point
    Q = center!(A, B, C)
    # Find the small and big radii
    r = 0.025
    R = Float64(norm(A - Q))
    # Construct a torus of revolution
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
base!(θ, ψ)

Calculates the grid of a marker on the base two sphere
with the given coordinates in the base space: latitude (θ) and longitude(ψ),
both of which are measured in radians.
"""
function base!(θ, ψ)
    # Locate the point on the two sphere
    l = locate(θ, ψ)
    # Construct a two sphere
    r = 0.05
    x = l[1] .+ [r * cos(i)*cos(j) for i in lspace, j in lspace]
    y = l[2] .+ [r * cos(i)*sin(j) for i in lspace, j in lspace]
    z = l[3] .+ [r * sin(i) for i in lspace, j in lspace]
    [x, y, z]
end

"""
animate(location, θ, ψ, sweep)

Moves a point on a path parallel to the equator on the base space
with the given location Node which is an observable, 
the coordinates in the base space: latitude (θ) and longitude(ψ) in radians,
and the sweep angle which ranges from 0 to 2pi.
"""
function animate(location, θ, ψ, sweep)
    location[] = [θ, ψ + sweep]
end

sθ, oθ = textslider(-pi/2:0.01:pi/2, 
                    "θ", 
                    raw = true, 
                    camera = campixel!, 
                    start = 0)
sψ, oψ = textslider(0:0.01:2pi, 
                    "ψ", raw = true, 
                    camera = campixel!, 
                    start = 0)

# The point on the base space
a = @lift([$oθ, $oψ])

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
fiber = surface!(scene, 
                 @lift(fiber!($a[1], $a[2])[1]), 
                 @lift(fiber!($a[1], $a[2])[2]), 
                 @lift(fiber!($a[1], $a[2])[3]), 
                 color = @lift([RGBAf0(locate($a[1], $a[2])[1], 
                                       locate($a[1], $a[2])[2], 
                                       locate($a[1], $a[2])[3])
                                for i in lspace, j in lspace]),
                 shading = false)
base = surface!(scene, 
                @lift(base!($a[1], $a[2])[1]), 
                @lift(base!($a[1], $a[2])[2]), 
                @lift(base!($a[1], $a[2])[3]), 
                color = @lift([RGBAf0(locate($a[1], $a[2])[1], 
                                      locate($a[1], $a[2])[2], 
                                      locate($a[1], $a[2])[3])
                               for i in lspace, j in lspace]), 
                shading = false)
fullscene = hbox(scene, vbox(sθ, sψ), parent = Scene(resolution = (500, 500)))

record(scene, "output.gif") do io
    for sweep in range(0, stop = 2pi, length = 50)
        θ = 0.5659736245
        ψ = 0.937032369
        animate(a, θ, ψ, sweep) # animate scene
        recordframe!(io) # record a new frame
    end
end

