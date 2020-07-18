export Predicate
export all
export exists


"""
    Represents a predicate.

A proposition-valued function of one or more variables.

fields: value and x.
"""
struct Predicate <: Logic
    value::Logic
    x::Tuple
    Predicate(p::Logic, x...) = new(p, tuple(x...))
    Predicate(P::Predicate, R::Predicate) = new(P.value * R.value, (P.x..., R.x...))
end


"""
    all(x, P)

Construct a proposition with the given Predicate `P` and a single variable `x`.
"""
all(x, P::Predicate) = value(P)


"""
    exists(x, P)

Construct a proposition with the given Predicate `P` and a single variable `x`.
"""
exists(x, P::Predicate) = !all(x, !P)
