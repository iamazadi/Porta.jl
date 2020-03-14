module Porta

export convert_to_cartesian
export convert_to_geographic
export σ
export σ⁻¹
export get_points
export get_center
export rotate
export fiber!
export base!

import LinearAlgebra
import ReferenceFrameRotations


"""
convert_to_cartesian(point)

Converts a point in the geographic coordinate system to a point in the
cartesian one with the given point in radians.
"""
function convert_to_cartesian(point)
    θ, ψ = point
    y₁ = cos(ψ) * cos(θ)
    y₂ = cos(ψ) * sin(θ)
    y₃ = sin(ψ)
    [y₁, y₂, y₃]
end


"""
convert_to_geographic(point)

Converts a point in the cartesian coordinate system to a point in the
geographic one with the given point.
"""
function convert_to_geographic(point)
    x, y, z = point
    r = sqrt(x^2 + y^2 + z^2)
    ψ = asin(z/r)
    if x > 0
        θ = atan(y/x)
    elseif y > 0
        θ = atan(y/x) + pi
    else
        θ = atan(y/x) - pi
    end
    [θ, ψ]
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
get_points(y, angle)

Finds 2 more points on the fiber circle under stereographic projection 
with the given point in the base space which is also on the circle
and the phase angle between the points along the circle.
"""
function get_points(y, angle)
    λ₁ = complex(cos(-angle), sin(-angle))
    λ₂ = complex(cos(angle), sin(angle))
    w₁, w₂, w₃, w₄ = σ⁻¹(y[1], y[2], y[3])
    x₁ = λ₁ * complex(w₁, w₂)
    x₂ = λ₁ * complex(w₃, w₄)
    z₁ = λ₂ * complex(w₁, w₂)
    z₂ = λ₂ * complex(w₃, w₄)
    x = σ(real(x₁), imag(x₁), real(x₂), imag(x₂))
    z = σ(real(z₁), imag(z₁), real(z₂), imag(z₂))
    x, y, z
end


"""
get_center(X, Y, Z)

Finds the center point of the fiber circle under stereographic projection
with the given 3 points on the circle circumference.
"""
function get_center(X, Y, Z)
    a = LinearAlgebra.norm(Y - Z)
    b = LinearAlgebra.norm(X - Z)
    c = LinearAlgebra.norm(X - Y)
    numerator = a^2 * (b^2 + c^2 - a^2) * X + 
                b^2 * (a^2 + c^2 - b^2) * Y + 
                c^2 * (a^2 + b^2 - c^2) * Z
    denominator = a^2 * (b^2 + c^2 - a^2) + 
                  b^2 * (a^2 + c^2 - b^2) + 
                  c^2 * (a^2 + b^2 - c^2)
    numerator / denominator
end


"""
rotate(point, g)

Rotates a point in the base space by rotating the corresponding three sphere
with the given point and the unit quaternion.
"""
function rotate(point, g)
    q = ReferenceFrameRotations.Quaternion(σ⁻¹(point...)...)
    r = g * q
    σ(real(r), imag(r)...)
end


"""
fiber!(point; r=0.025, N=30)

Calculates the grid of a fiber circle under stereographic projection
with the given coordinates in the base space.
The optional arguments are the radius of the spherical grid
and the square root of the number of points in the grid.
"""
function fiber!(point; r=0.025, N=30)
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
