export ℝ


"""
    Represents Real numbers.

fields: value.
"""
struct ℝ <: Field
    value::ℂ
end


"""
    value(r)

Return a string representation of `r`.
"""
value(r::ℝ) = real(r.value)


"""
    show(r)

print a string representation of `r`
"""
Base.show(io::IO, r::ℝ) = print(io, value(r))
