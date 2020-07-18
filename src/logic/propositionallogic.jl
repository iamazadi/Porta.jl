import Base.:+
import Base.:*
import Base.:!


export Logic
export Proposition
export True
export False
export T
export F
export ↑
export ⟹
export ↔


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
    Represents a proposition.

A variable that can take the value `True` or `False`. No others.

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
value(p::True) = T
value(p::False) = F
value(p::Logic) = value(p.value)


"""
    show(p)

Print a string representation of the logical value `p`.
"""
Base.show(io::IO, p::True) = print(io, 'T')
Base.show(io::IO, p::False) = print(io, 'F')
Base.show(io::IO, p::Logic) = show(io, value(p))


## Binary Operators ##


"""
    p ↑ q

Not both. Alternative denial. Logical NAND.
"""
↑(p::True, q::True) = F
↑(p::True, q::False) = T
↑(p::False, q::True) = T
↑(p::False, q::False) = T
↑(p::Logic, q::Logic) = value(p) ↑ value(q)


"""
    p * q

Logical conjunction (AND).
"""
*(p::Logic, q::Logic) = (p ↑ q) ↑ (p ↑ q)


"""
    p + q

Logical disjunction (OR).
"""
+(p::Logic, q::Logic) = (p ↑ p) ↑ (q ↑ q)


"""
    p ⟹ q

Logical implication.
"""
⟹(p::Logic, q::Logic) = p ↑ (q ↑ q)


"""
    ↔(p, q)

Logical equality (=).
"""
↔(p::Logic, q::Logic) = (p ↑ q) ↑ ((p ↑ p) ↑ (q ↑ q))


## Unary Operators ##


"""
    !(p)

Negate the proposition `p`. Logical negation.
"""
!(p::Logic) = p ↑ p


"""
    +(p)

Returns a proposition identical to `p`. Logical identity.
"""
+(p::Logic) = p


"""
    True(p)

Returns a Proposition that is True for all `p`. Logical true.
"""
True(p::Logic) = T


"""
    False(p)

Returns a Proposition that is False for all `p`. Logical false.
"""
False(p::Logic) = F
