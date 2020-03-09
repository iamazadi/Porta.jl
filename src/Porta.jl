module Porta

export locate
export σ
export σ⁻¹
export points!
export center!
export rotate
export fiber!
export base!

import LinearAlgebra
import ReferenceFrameRotations

"""
locate(θ, ψ)

Locates the point in the base space
with the given corrdinates on the two sphere: latitude (θ) and longitude(ψ)
both of which are measured in radians.
"""
function locate(θ, ψ)
    y₁ = cos(θ) * cos(ψ)
    y₂ = cos(θ) * sin(ψ)
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
rotate(y, g)

Rotates the three sphere with the given unit quaternion g
and returns the rotated version of the point a in the base space.
"""
function rotate(y, g)
    x₁, x₂, x₃, x₄ = σ⁻¹(y[1], y[2], y[3])
    q = ReferenceFrameRotations.Quaternion(x₁, x₂, x₃, x₄)
    ReferenceFrameRotations.vect(g * q)
end

"""
fiber!(a; r=0.025, N=30)

Calculates the grid of a fiber circle under stereographic projection
with the given coordinates in the base space.
The optional arguments are the radius of the spherical grid
and the square root of the number of points in the grid.
"""
function fiber!(a; r=0.025, N=30)
    lspace = range(0.0, stop = 2pi, length = N)
    # Find 3 points on the circle
    A, B, C = points!(a)
    # Get the circle center point
    Q = center!(A, B, C)
    # Find the small and big radii
    R = Float64(LinearAlgebra.norm(A - Q))
    # Construct a torus of revolution grid
    x = Q[1] .+ [(R + r * cos(i)) * cos(j) for i in lspace, j in lspace]
    y = Q[2] .+ [(R + r * cos(i)) * sin(j) for i in lspace, j in lspace]
    z = Q[3] .+ [r * sin(i) for i in lspace, j in lspace]
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
base!(a; r=0.05, N=30)

Calculates the marker grid for a point in the base space
with the given coordinates in the base space.
The optional arguments are the radius of the spherical grid
and the square root of the number of points in the grid.
"""
function base!(a; r=0.05, N=30)
    lspace = range(0.0, stop = 2pi, length = N)
    # Construct a two sphere grid
    x = a[1] .+ [r * cos(i)*cos(j) for i in lspace, j in lspace]
    y = a[2] .+ [r * cos(i)*sin(j) for i in lspace, j in lspace]
    z = a[3] .+ [r * sin(i) for i in lspace, j in lspace]
    [x, y, z]
end

end # module
