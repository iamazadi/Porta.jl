export Bundle
export Clifford


abstract type Bundle end


"""
    Represents a Clifford bundle, AKA the Hopf fibration of S³.

fields: total and base.
"""
struct Clifford <: Bundle
    total::S³
    base::S²
end


"""
    Clifford(w, z, A, B)

Construct a Clifford bundle with the given Complex numbers: `w`, `z`, `A` and `B`. The ratio
A:B distinguishes the fibers from one another.
"""
Clifford(w::Complex, z::Complex, A::Complex, B::Complex) = begin
    @assert(isapprox(abs(w)^2 + abs(z)^2, 1),
            "The equation |w|² + |z|² = 1 must hold for the given w and z.")
    @assert(!isapprox(abs(A), 0) || !isapprox(abs(B), 0),
            "Aw + Bz = 0, either of A or B can be zero, but not both.")
    Clifford(ComplexPlane(w, z), ComplexLine(A / B))
end


"""
    Clifford(w, z, B)

Construct a Clifford bundle with the given Complex numbers: `w`, `z` and `B`. Here, `B`
on its own identifies a point in the base space and we compute A on the fly.
"""
Clifford(w::Complex, z::Complex, B::Complex) = begin
    # Aw + Bz = 0
    # Aw = -Bz
    # A = -Bz/w
    Clifford(w, z, -B * z / w, B)
end
