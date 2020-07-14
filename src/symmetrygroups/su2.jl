import Base.Matrix
import Base.+
import Base.*


export SU2


"""
    Represents the group SU(2), {[α -̅β; β ̅α] | α, β ∈ ℂ, |α|² + |β|² = 1}.

fields: α and β.
"""
struct SU2 <: Group
    α::U1
    β::U1
    function SU2(α::U1, β::U1)
        new(α, β)
    end
    function SU2(a::Array{U1,2})
        @assert(size(a) == (2, 2), "The size of Matrix must be 2×2.")
        new(a[1], a[2])
    end
    function SU2(a::Array{Complex,2})
        @assert(size(a) == (2, 2), "The size of Matrix must be 2×2.")
        new(U1(a[1]), U1(a[2]))
    end
    function SU2(a::Array{Complex{Float64},2})
        @assert(size(a) == (2, 2), "The size of Matrix must be 2×2.")
        new(U1(a[1]), U1(a[2]))
    end
end


"""
    Matrix(a::SU2)

Construct a Matrix with the given number.
"""
function Matrix(a::SU2)
    convert(Array{U1,2}, [a.α -conj(a.β); a.β conj(a.α)])
end


"""
    Base.show(io::IO, a::SU2)

Print a string representation of the given number.
"""
function Base.show(io::IO, a::SU2)
    print(io, Matrix(a))
end


"""
    +(a::SU2, b::SU2)

Add two numbers.
"""
function +(a::SU2, b::SU2)
    convert(Array{Complex,2}, Matrix(a) + Matrix(b))
end


"""
    +(a::SU2, b::Array{U1,2})

Add two numbers.
"""
function +(a::SU2, b::Array{U1,2})
    convert(Array{Complex,2}, Matrix(a) + b)
end


"""
    +(a::Array{U1,2}, b::SU2)

Add two numbers.
"""
function +(a::Array{U1,2}, b::SU2)
    convert(Array{Complex,2}, a + Matrix(b))
end


"""
    +(a::SU2, b::Array{Complex,2})

Add two numbers.
"""
function +(a::SU2, b::Array{Complex,2})
    Matrix(a) + b
end


"""
    +(a::Array{Complex,2}, b::SU2)

Add two numbers.
"""
function +(a::Array{Complex,2}, b::SU2)
    a + Matrix(b)
end


"""
    *(a::SU2, b::SU2)

Multiply two numbers.
"""
function *(a::SU2, b::SU2)
    SU2(Matrix(a) * Matrix(b))
end


"""
    *(a::SU2, b::Array{U1,2})

Multiply two numbers.
"""
function *(a::SU2, b::Array{U1,2})
    a * SU2(b)
end


"""
    *(a::Array{U1,2}, b::SU2)

Multiply two numbers.
"""
function *(a::Array{U1,2}, b::SU2)
    SU2(a) * b
end


"""
    *(a::SU2, b::Array{Complex,2})

Multiply two numbers.
"""
function *(a::SU2, b::Array{Complex,2})
    Matrix(a) * b
end


"""
    *(a::Array{Complex,2}, b::SU2)

Multiply two numbers.
"""
function *(a::Array{Complex,2}, b::SU2)
    s * Matrix(b)
end


"""
    *(a::SU2, b::U1)

Multiply two numbers.
"""
function *(a::SU2, b::U1)
    SU2(Matrix(a) .* b)
end


"""
    *(a::U1, b::SU2)

Multiply two numbers.
"""
function *(a::U1, b::SU2)
    SU2(a .* Matrix(b))
end
