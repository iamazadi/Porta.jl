module Porta

export πmap
export λmap
export λ⁻¹map
export σmap
export τmap
export S¹action
export convert_to_cartesian
export convert_to_geographic

import LinearAlgebra


"""
πmap(p)

Sends a point on a unit 3-sphere to a point on a unit 2-sphere with the given
point in the form of 2 complex numbers representing a unit quaternion.
S³ ↦ S² (x,y,z)
"""
function πmap(p)
    x₁ = real(p[1])
    x₂ = imag(p[1])
    x₃ = real(p[2])
    x₄ = imag(p[2])
    [2(x₁*x₃ + x₂*x₄), 2(x₂*x₃ - x₁*x₄), x₁^2+x₂^2-x₃^2-x₄^2]
end


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
σmap(p)

Sends a point on a 2-sphere to a point on a 3-sphere with the given point in
the form of longitude and latitude coordinate in radians. S² ↦ S³
"""
function σmap(p)
    z = exp(-im * p[1]) * sqrt((1 + sin(p[2])) / 2)
    w = Complex(sqrt((1 - sin(p[2])) / 2))
    [z, w]
end


"""
τmap(p)

Sends a point on a 2-sphere to a point on a 3-sphere with the given point in
the form of longitude and latitude coordinate in radians. S² ↦ S³
"""
function τmap(p)
    z = Complex(sqrt((1 + sin(p[2])) / 2))
    w = exp(im * p[1]) * sqrt((1 - sin(p[2])) / 2)
    [z, w]
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


end # module
