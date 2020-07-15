import Base.+
import Base.:*
import Base.:!


export Logic
export Proposition
export True
export False
export ↔
export ⟹
export T
export F


## Data Structures ##


"""
    Represents a logical object.
"""
abstract type Logic end


"""
    Represents the value True.

field: value.
"""
struct True <: Logic
    value::True
    True() = new()
end


"""
    Represents the value False.

field: value.
"""
struct False <: Logic
    value::False
    False() = new()
end


"""
    Represents a Proposition.

a variable that can take the value `true` or `false`. No other.

field: value.
"""
mutable struct Proposition <: Logic
    value::Logic
    Proposition() = new()
    function Proposition(p::Logic)
        instance = new()
        instance.value = p
        instance
    end
end


## Global Constants ##


const T = True()
const F = False()


## Generic Functions ##


"""
    value(p)

Return the logical value of `p`.
"""
value(p::True) = True()
value(p::False) = False()
value(p::Logic) = value(p.value)


"""
    show(p)

Print a string representation of the logical value `p`.
"""
Base.show(io::IO, p::True) = print(io, 'T')
Base.show(io::IO, p::False) = print(io, 'F')
Base.show(io::IO, p::Logic) = show(io, value(p))


## Unary Operators ##


"""
    !(p)

Negate the proposition `p`. Logical negation.
"""
!(p::True) = False()
!(p::False) = True()
!(p::Logic) = !(value(p))


"""
    +(p)

Returns a proposition identical to `p`. Logical identity.
"""
+(p::Logic) = p


"""
    True(p)

Returns a Proposition that is True for all `p`. Logical true.
"""
True(p::Logic) = True()


"""
    False(p)

Returns a Proposition that is False for all `p`. Logical false.
"""
False(p::Logic) = False()


## Binary Operators ##


"""
    p * q

Logical conjunction (AND).
"""
*(p::True, q::True) = True()
*(p::True, q::False) = False()
*(p::False, q::True) = False()
*(p::False, q::False) = False()
*(p::Logic, q::Logic) = *(value(p), value(q))


"""
    ↔(p, q)

Logical equality (=).
"""
↔(p::True, q::True) = True()
↔(p::True, q::False) = False()
↔(p::False, q::True) = False()
↔(p::False, q::False) = True()
↔(p::Logic, q::Logic) = ↔(value(p), value(q))


"""
    p + q

Logical disjunction (OR).
"""
+(p::Logic, q::Logic) = ↔(p * q, ↔(p, q))


"""
    p ⟹ q

Logical implication.
"""
⟹(p::Logic, q::Logic) = ↔((p + q), q)
