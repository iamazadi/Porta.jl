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
        @assert(isapprox(abs(z), 1), "The magnitude must be equal to 1.")
        new(angle(z))
    end
    U1(α::Real) = begin
        #@assert(-pi ≤ α ≤ pi, "The phase angle must be in the interval [-π, π].")
        new(float(α))
    end
end


Base.angle(u::U1) = u.r
*(u1::U1, u2::U1) = U1(u1.r + u2.r)
Base.isapprox(u1::U1, u2::U1) = isapprox(u1.r, u2.r)
