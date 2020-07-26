import Base.+
import Base.-
import Base.*
import Base.conj


export ℍ


struct ℍ <: VectorSpace
    a::Array{Float64} # basis [1; i; j; k]
    ℍ(a::Array{Float64,1}) = begin
        @assert(length(a) == 4, "The input vector must contain exactly four elements.")
        new(Float64.(a))
    end
    ℍ(a::Array{Int64,1}) = ℍ(Float64.(a))
    ℍ(a::Real, b::Real, c::Real, d::Real) = ℍ([a; b; c; d])
    ℍ(θ::Real, u::ℝ³) = ℍ([cos(θ / 2); vec(sin(θ / 2) * u)])
    ℍ(z₁::Complex, z₂::Complex) = ℍ(real(z₁), imag(z₁), real(z₂), imag(z₂))
    ℍ(s::Array{Complex,2}) = ℍ(real(s[1,1]), imag(s[1,1]), -real(s[2,1]), -imag(s[2,1]))
    ℍ(s::Array{Complex{Float64},2}) = ℍ(convert(Array{Complex,2}, s))
end


## Unary Operators ##


+(h::ℍ) = h
-(h::ℍ) = ℍ(-vec(h))


## Binary Operators ##


+(h1::ℍ, h2::ℍ) = ℍ(vec(h1) + vec(h2))
-(h1::ℍ, h2::ℍ) = ℍ(vec(h1) - vec(h2))
*(h::ℍ, λ::Real) = ℍ(λ .* vec(h))
*(λ::Real, h::ℍ) = h * λ


## Product Spaces ##


adjoint(h::ℍ) = ℍ(convert(Array{Complex,2}, Base.adjoint(SU2(h))))
conj(h::ℍ) = adjoint(h)
z₁(h::ℍ) = Complex(h.a[1], h.a[2])
z₂(h::ℍ) = Complex(h.a[3], h.a[4])
SU2(h::ℍ) = [z₁(h) Base.conj(z₂(h)); -z₂(h) Base.conj(z₁(h))]
(*)(h1::ℍ, h2::ℍ) = ℍ(SU2(h1) * SU2(h2))
# the Hilbert-Schmidt norm and inner product
# sometimes we call them Frobenius norm and inner product
norm(h::ℍ) = sqrt(sum(map(x -> abs(x)^2, SU2(h))))
dot(h1::ℍ, h2::ℍ) = sum(sum(map(*, SU2(h1), SU2(h2)), dims=1))
