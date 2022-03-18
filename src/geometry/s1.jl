import Base.*


export S¹
export U1


"""
    Represents a point in a one-sphere.
"""
abstract type S¹ end


"""
    Represents a point in U(1).

field: α.
"""
struct U1 <: S¹
    r::Float64
    U1(z::Complex) = begin
        @assert(isapprox(abs(z), 1), "The magnitude must be equal to 1, but it's $(abs(z)).")
        θ = angle(z) ≥ 0 ? angle(z) : π + angle(z)
        new(θ)
    end
    U1(α::Real) = begin
        #@assert(-pi ≤ α ≤ pi, "The phase angle must be in the interval [-π, π].")
        new(float(α))
    end
end


Base.angle(u::U1) = u.r
*(u1::U1, u2::U1) = U1(u1.r + u2.r)
*(u::U1, scale::Float64) = U1(u.r * scale)
*(scale::Float64, u::U1) = U1(u.r * scale)
Base.isapprox(u1::U1, u2::U1) = isapprox(u1.r, u2.r)
