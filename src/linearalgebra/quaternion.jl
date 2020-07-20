import Base.+
import Base.-
import Base.*
import Base.vec
import Base.conj
import Base.isapprox


export ℍ


struct ℍ
    a::Array{Float64} # basis [1; i; j; k]
end


ℍ(a, b, c, d) = ℍ([Float64(a); Float64(b); Float64(c); Float64(d)])
ℍ(s::Array{Complex,2}) = ℍ(real(s[1,1]), imag(s[1,1]), -real(s[2,1]), -imag(s[2,1]))
ℍ(s::Array{Complex{Float64},2}) = ℍ(convert(Array{Complex,2}, s))
x₁(h::ℍ) = h.a[1]
x₂(h::ℍ) = h.a[2]
x₃(h::ℍ) = h.a[3]
x₄(h::ℍ) = h.a[4]
Base.vec(h::ℍ) = [x₁(h); x₂(h); x₃(h); x₄(h)]
ijk(h::ℍ) = vec(h)[2:4]
z₁(h::ℍ) = Complex(x₁(h), x₂(h))
z₂(h::ℍ) = Complex(x₃(h), x₄(h))
SU2(h::ℍ) = [z₁(h) conj(z₂(h)); -z₂(h) conj(z₁(h))]
Base.adjoint(h::ℍ) = ℍ(convert(Array{Complex,2}, adjoint(SU2(h))))
Base.conj(h::ℍ) = adjoint(h)
(+)(g::ℍ, h::ℍ) = ℍ(SU2(g) + SU2(h))
(-)(g::ℍ, h::ℍ) = ℍ(SU2(g) - SU2(h))
(*)(g::ℍ, h::ℍ) = ℍ(SU2(g) * SU2(h))
(*)(λ::Number, h::ℍ) = ℍ(λ .* SU2(h))
Base.isapprox(g::ℍ, h::ℍ) = isapprox(vec(g), vec(h))
