import Base.:+
import Base.:*
import Base.:-
import Base.:/
import Base.:(==)
import Base.:<


export Field
export ℂ
export 𝟎
export 𝟏
export 𝑖


export arg
export len
export fst
export sec
export cnj


"""
    Represents a 𝑓𝑖𝑒𝑙𝑑.

A mathematical object for which one defines the operations of addition, subtraction,
multiplication and division.
"""
abstract type Field end


"""
    Represents a complex number.

fields: r and θ.
"""
struct ℂ <: Field
    r::Float64
    θ::Float64
    function ℂ(r::Real, θ::Real)
        new(float(r), float(θ))
    end
end


"""
    show(z)

Print a string representation of `z` = a + b𝑖.
"""
Base.show(io::IO, z::ℂ) = print(io, "$(z.r)exp(𝑖$(z.θ))")


"""
    ℂ(a, b)

Construct a complex number z = `a` + `b`𝑖.
"""
ℂ(a::ℂ, b::ℂ) = ℂ(a.r * cos(a.θ), b.r * cos(b.θ))


"""
    len(z)

The magnitude or length of `z` = reⁱᶿ.
"""
len(z::ℂ) = ℂ(z.r, 0)


"""
    arg(z)

The phase or argument of `z` = reⁱᶿ.
"""
arg(z::ℂ) = ℂ(z.θ, 0)


## Unary Operators ##


"""
    +z

Unary plus, the identity operation.
"""
+(z::ℂ) = z


"""
    -z

Unary minus, maps a value to its additive inverse.
"""
-(z::ℂ) = begin
    a, b = -z.r * cos(z.θ), -z.r * sin(z.θ)
    r = sqrt(a^2 + b^2)
    if b ≠ 0
        θ = 2atan((r - a) / b)
    elseif a > 0 && b == 0
        θ = 0
    elseif a < 0 && b == 0
        θ = π
    elseif a == b && b == 0
        θ = NaN
    end
    ℂ(r, θ)
end


## Binary Operators ##


"""
    z * w

Times, performs multiplication.
"""
*(z::ℂ, w::ℂ) = begin
    ℂ(z.r * w.r, z.θ + w.θ)
end


"""
    z / w

Divide, performs division.
"""
/(z::ℂ, w::ℂ) = ℂ(z.r / w.r, z.θ - w.θ)
end


"""
    z + w

Binary plus, performs addition.
"""
+(z::ℂ, w::ℂ) = begin
    a = z.r * cos(z.θ) + w.r * cos(w.θ)
    b = z.r * sin(z.θ) + w.r * sin(w.θ)
    r = sqrt(a^2 + b^2)
    if b ≠ 0
        θ = 2atan((r - a) / b)
    elseif a > 0 && b == 0
        θ = 0
    elseif a < 0 && b == 0
        θ = π
    elseif a == b && b == 0
        θ = NaN
    end
    ℂ(r, θ)
end


"""
    z - w

Binary minus, performs subtraction.
"""
-(z::ℂ, w::ℂ) = z + (-w)


## Generic Functions ##


"""
    fst(z)

The first part of `z` = a + b𝑖.
"""
fst(z::ℂ) = ℂ(z.r * cos(z.θ), 0)


"""
    sec(z)

The second part of `z` = a + b𝑖.
"""
sec(z::ℂ) = ℂ(z.r * sin(z.θ), 0)


"""
    conj(z)

The complex conjugate of `z`. If `z` = a + b𝑖 then z̅ = a - b𝑖.
"""
conj(z::ℂ) = ℂ(fst(z), -sec(z))


## Constants ##


"""
    The zero element, \bfzero.
"""
const 𝟎 = ℂ(0, 0)


"""
    The scalar one element, \bfone.
"""
const 𝟏 = ℂ(1, 0)


"""
    The magic number √-1 = 𝑖, \iti.
"""
const 𝑖 = ℂ(0, π / 2)


## Numeric Comparisons ##


"""
    z == w

Check whether `z` and `w` are equal.
"""
==(z::ℂ, w::ℂ) = isapprox(z.r, w.r, atol=TOLERANCE) && isapprox(z.θ, w.θ, atol=TOLERANCE)


"""
    z < w

Check whether the length of `z` is less than that of `w`.
"""
<(z::ℂ, w::ℂ) = z.r < w.r
