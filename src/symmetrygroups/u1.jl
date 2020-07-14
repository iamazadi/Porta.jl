import Base.:+
import Base.:-
import Base.:*
import Base.:/
import Base.:(==)
import Base.:<


export U1
export arg
export len


abstract type Group end


"""
    U1 <: Group

The symmetry group U(1), AKA the circle group, {z ∈ ℂ : |z| = 1}.

fields: θ.
"""
struct U1 <: Group
    θ::Float64
end


"""
    show(x)

Print a string representation of `x`.
"""
Base.show(io::IO, x::U1) = print(io, "eⁱᶿ : θ = $(x.θ)")


"""
    arg(x)

The phase or argument of `x` = eⁱᶿ.
"""
arg(x::U1) = x.θ


"""
    len(x)

The magnitude or length of `x` = eⁱᶿ.
"""
len(x::U1) = 1


## Unary Operators ##


"""
    +x

Unary plus, the identity operation on `x`.
"""
+(x::U1) = U1(+x.θ)


"""
    -x

Unary minus, map `x` to its additive inverse.
"""
-(x::U1) = U1(π - x.θ)


## Binary Operators ##


"""
    x * y

Multiply `x` times `y`.
"""
*(x::U1, y::U1) = U1(x.θ + y.θ)


"""
    x / y

Divide `x` over `y`.
"""
/(x::U1, y::U1) = U1(x.θ - y.θ)


## Numeric Comparisons ##


"""
    x == y

Check whether `x` and `y` are equal.
"""
==(x::U1, y::U1) = isapprox(x.θ, y.θ, atol=TOLERANCE)


"""
    x < y

Check whether `x` is less than `y`.
"""
<(x::U1, y::U1) = x.θ < y.θ
