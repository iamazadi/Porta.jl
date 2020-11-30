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
    z::Complex
    U1(z::Complex) = begin
        @assert(isapprox(abs(z), 1), "The magnitude must be equal to 1.")
        new(z)
    end
    U1(α::Real) = begin
        #@assert(-pi ≤ α ≤ pi, "The phase angle must be in the interval [-π, π].")
        U1(exp(im * α))
    end
end


Base.angle(u::U1) = angle(u.z)
*(u1::U1, u2::U1) = U1(angle(u1.z * u2.z))
Base.isapprox(u1::U1, u2::U1) = isapprox(u1.z, u2.z)
