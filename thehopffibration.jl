using FileIO, Colors
using Makie
using AbstractPlotting
using GeometryTypes
using LinearAlgebra
using ReferenceFrameRotations

# Parameters for constructing the circle surface
N = 30
lspace = range(0.0, stop = 2pi, length = N)

function locate(θ, ψ)
    y₁ = cos(θ)*cos(ψ)
    y₂ = cos(θ)*sin(ψ)
    y₃ = sin(θ)
    [y₁,y₂,y₃]
end

function σ⁻¹(y₁, y₂, y₃)
    x₁ = 2y₁ / (1 + y₁^2 + y₂^2 + y₃^2)
    x₂ = 2y₂ / (1 + y₁^2 + y₂^2 + y₃^2)
    x₃ = 2y₃ / (1 + y₁^2 + y₂^2 + y₃^2)
    x₄ = (-1 + y₁^2 + y₂^2 + y₃^2) / (1 + y₁^2 + y₂^2 + y₃^2)
    [x₁, x₂, x₃, x₄]
end

function σ(x₁, x₂, x₃, x₄)
    y₁ = x₁ / (1 - x₄)
    y₂ = x₂ / (1 - x₄)
    y₃ = x₃ / (1 - x₄)
    [y₁, y₂, y₃]
end

function getpoints(y₁, y₂, y₃)
    λ₁ = complex(cos(1), sin(1))
    λ₂ = complex(cos(2), sin(2))
    λ₃ = complex(cos(3), sin(3))
    x₁, x₂, x₃, x₄ = σ⁻¹(y₁, y₂, y₃)
    p₁ = λ₁ * complex(x₁, x₂)
    p₂ = λ₁ * complex(x₃, x₄)
    q₁ = λ₂ * complex(x₁, x₂)
    q₂ = λ₂ * complex(x₃, x₄)
    r₁ = λ₃ * complex(x₁, x₂)
    r₂ = λ₃ * complex(x₃, x₄)
    p = σ(real(p₁), imag(p₁), real(p₂), imag(p₂))
    q = σ(real(q₁), imag(q₁), real(q₂), imag(q₂))
    r = σ(real(r₁), imag(r₁), real(r₂), imag(r₂))
    [p, q, r]
end

function getcenter(A, B, C)
    a = norm(B - C)
    b = norm(A - C)
    c = norm(A - B)
    numerator = a^2 * (b^2 + c^2 - a^2) * A + b^2 * (a^2 + c^2 - b^2) * B + c^2 * (a^2 + b^2 + - c^2) * C
    denominator = a^2 * (b^2 + c^2 - a^2) + b^2 * (a^2 + c^2 - b^2) + c^2 * (a^2 + b^2 - c^2)
    numerator / denominator
end

function getcircle(A, B, C)
    # Get the circle center point
    Q = getcenter(A, B, C)
    # Find the small and big radii
    r = 0.025
    R = Float64(norm(A - Q))
    # Construct a torus of revolution
    x = Q[1] .+ [(R + r * cos(θ)) * cos(ϕ) for θ in lspace, ϕ in lspace]
    y = Q[2] .+ [(R + r * cos(θ)) * sin(ϕ) for θ in lspace, ϕ in lspace]
    z = Q[3] .+ [r * sin(θ) for θ in lspace, ϕ in lspace]
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
    θ = acos(dot(n, i)) / 2.0
    q = ReferenceFrameRotations.Quaternion(cos(θ), sin(θ)*u[1], sin(θ)*u[2], sin(θ)*u[3])
    rotatedpoints = [ReferenceFrameRotations.vect(q\[points[i][1]; 
                                                     points[i][2]; 
                                                     points[i][3]]*q) for i in 1:length(points)]
    rotatedx = [rotatedpoints[i][1] for i in 1:length(rotatedpoints)]
    rotatedy = [rotatedpoints[i][2] for i in 1:length(rotatedpoints)]
    rotatedz = [rotatedpoints[i][3] for i in 1:length(rotatedpoints)]
    rotatedx = reshape(Float64.(rotatedx), (N, N))
    rotatedy = reshape(Float64.(rotatedy), (N, N))
    rotatedz = reshape(Float64.(rotatedz), (N, N))
    rotatedx, rotatedy, rotatedz
end

function animate(location, i)
    θ = 0.5659736245
    ψ = 0.937032369
    location[] = locate(θ, ψ + (i/100.0) * 2pi)
end

sθ, oθ = textslider(-pi/2:0.01:pi/2, "θ", raw = true, camera = campixel!, start = 0)
sψ, oψ = textslider(0:0.01:2pi, "ψ", raw = true, camera = campixel!, start = 0)

location = @lift(locate($oθ, $oψ))

pointsABC = @lift(getpoints($location[1], $location[2], $location[3]))

pointA = @lift begin
    A, B, C = $pointsABC
    Point3f0(A[1], A[2], A[3])
end

pointB = @lift begin
    A, B, C = $pointsABC
    Point3f0(B[1], B[2], B[3])
end

pointC = @lift begin
    A, B, C = $pointsABC
    Point3f0(C[1], C[2], C[3])
end

circle = @lift(getcircle($pointA, $pointB, $pointC))

scene = Scene(show_axis = false)

# The 3D coordinate indicator
originc = Vec3f0(0); baselen = 0.05f0; dirlen = 0.5f0
# create an array of differently colored boxes in the direction of the 3 axes
rectangles = [
    (HyperRectangle(Vec3f0(originc), Vec3f0(dirlen, baselen, baselen)), RGBAf0(0.5,1.0,0.5,0.9)),
    (HyperRectangle(Vec3f0(originc), Vec3f0(baselen, dirlen, baselen)), RGBAf0(1.0,0.5,0.5,0.9)),
    (HyperRectangle(Vec3f0(originc), Vec3f0(baselen, baselen, dirlen)), RGBAf0(0.5,0.5,1.0,0.9))
]
meshes = map(GLNormalMesh, rectangles)
mesh!(scene, merge(meshes), transparency = true)
m = GLNormalUVMesh(Sphere(Point3f0(0), 1f0), 60)
twosphere = mesh!(scene, m, color = RGBAf0(0.75,0.75,0.75,0.5), shading = false, transparency = true)[end]
circlemarker = surface!(scene, @lift($circle[1]), @lift($circle[2]), @lift($circle[3]), color = @lift([RGBAf0($location[1], $location[2], $location[3]) for i in lspace, j in lspace]), shading = false)[end]
marker = mesh!(scene, HyperSphere(Point3f0(0), 0.05f0), color = @lift(RGBf0($location[1], $location[2], $location[3])), shading = false)[end]
fullscene = hbox(scene, vbox(sθ, sψ), parent = Scene(resolution = (500, 500)))

on(location) do val
    y = to_value(location)
    translate!(Absolute, marker, y[1], y[2], y[3])
end

record(scene, "thehopffibration.gif") do io
    for i = 1:100
        animate(location, i)     # animate scene
        recordframe!(io) # record a new frame
    end
end


