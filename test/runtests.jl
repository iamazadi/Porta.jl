using Test
using Porta
using LinearAlgebra

import Base: isapprox


"""
get_unit_quaternion()

Calculates a unit quaternion in the form of C², in a random way.
"""
function get_unit_quaternion()
    θ = 2pi * rand()
    ψ₁ = 2pi * rand()
    ψ₂ = pi * rand() - pi / 2
    u = [cos(θ),
         sin(θ) * cos(ψ₂) * cos(ψ₁),
         sin(θ) * cos(ψ₂) * sin(ψ₁),
         sin(θ) * sin(ψ₂)]
    [Complex(u[1], u[2]), Complex(u[3], u[4])]
end


"""
get_unit_3vec()

Calculates a unit vector of size 3, in a random way.
"""
function get_unit_3vec()
    ψ₁ = 2pi * rand()
    ψ₂ = pi * rand() - pi / 2
    [cos(ψ₂) * cos(ψ₁), cos(ψ₂) * sin(ψ₁), sin(ψ₂)]
end


# The tolerance value for approximate comparisons
const tolerance = 10^-5

# The number of samples.
const samples = 1000

for i in 1:samples

    # Sample a unit quaternion and then apply the π map
    p = πmap(get_unit_quaternion())
    # Test if it returns a point with the right size
    @test size(p) == (3,)
    # Test if it returns a point on a unit sphere
    @test isapprox(norm(p), 1.0, atol = tolerance)

    # Sample a unit quaternion and then apply the λ map
    p = λmap(get_unit_quaternion())
    # Test if it returns a point with the right size
    @test size(p) == (3,)
    
    # Sample a point in R³ and then apply the λ⁻¹ map
    p = λ⁻¹map(rand(3))
    # Test if it returns a point with the right size
    @test size(p) == (2,)
    
    # Sample a point in R³ and then apply the σ map
    p = σmap(get_unit_3vec())
    # Test if it returns a point with the right size
    @test size(p) == (2,)
    # Test if it returns a point on a unit sphere
    @test isapprox(norm(p), 1.0, atol = tolerance)
    
    # Sample a point in R³ and then apply the τ map
    p = τmap(get_unit_3vec())
    # Test if it returns a point with the right size
    @test size(p) == (2,)
    # Test if it returns a point on a unit sphere
    @test isapprox(norm(p), 1.0, atol = tolerance)
    
    # Sample an angle
    α = 2pi * rand()
    # Sample a unit quaternion and then apply the S¹ action
    p = S¹action(α, get_unit_quaternion())
    # Test if it returns a point with the right size
    @test size(p) == (2,)
    # Test if it returns a point on a unit sphere
    @test isapprox(norm(p), 1.0, atol = tolerance)
    
    # Sample a point in the geographic coordiante system and then convert the
    # point to one in the cartesian coordinate system
    p = convert_to_cartesian([2pi * rand(), pi * rand() - pi / 2])
    # Test if it returns a point with the right size
    @test size(p) == (3,)
    # Test if it returns a point on a unit sphere
    @test isapprox(norm(p), 1.0, atol = tolerance)
    
    # Sample a unit vector in R³ and then convert to geographic coordinates
    p = convert_to_geographic(get_unit_3vec())
    # Test if it returns a point with the right size
    @test size(p) == (2,)
    # Test if the longitude is within the correct range
    @test -pi - tolerance ≤ p[1] ≤ pi + tolerance
    # Test if the latitude is within the correct range
    @test -pi / 2 - tolerance ≤ p[2] ≤ pi / 2 + tolerance

end
