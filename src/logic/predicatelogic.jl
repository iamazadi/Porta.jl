export Predicate
export all
export exists


"""
    Represents a predicate.

A proposition-valued function of one or more variables.

fields: value and m.
"""
struct Predicate <: Logic
    value::Logic
    m::Number
    Predicate(p::Logic, m::Number) = new(p, m)
end


"""
    exists(x, P)

Construct a proposition with the given Predicate `P` and a single variable `x`.
"""
exists(x, P::Predicate) = !all(x, !P)


"""
    all(x, P)

Construct a proposition with the given Predicate `P` and a single variable `x`.
"""
all(x, P::Predicate) = value(P)
