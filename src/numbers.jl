module NumberTypes

export ℝ³
export ℂ²
export S²
export S³
export w
export x
export y
export z
export vec
export SU2
export lon
export lat
export point
export left

import LinearAlgebra.norm

struct ℝ³
    x::Float64
    y::Float64
    z::Float64
end

ℝ³(a::Array) = ℝ³(a...)
x(p::ℝ³) = p.x
y(p::ℝ³) = p.y
z(p::ℝ³) = p.z
vec(p::ℝ³) = [x(p) y(p) z(p)]

struct ℂ²
    z::Complex
    w::Complex
end

ℂ²(p::ℝ³) = ℂ²(Complex(0, x(p)), Complex(y(p), z(p)))
ℂ²(a::Array) = ℂ²(a[1, 1], -a[2, 1])
z(q::ℂ²) = q.z
w(q::ℂ²) = q.w
SU2(q::ℂ²) = [z(q) conj(w(q));
             -w(q) conj(z(q))]

struct S²
    ϕ::Float64
    θ::Float64
end

S²(p::ℝ³) = begin
    if x(p) > 0
          ϕ = atan(y(p) / x(p))
    elseif y(p) > 0
          ϕ = atan(y(p) / x(p)) + pi
    else
          ϕ = atan(y(p) / x(p)) - pi
    end
    θ = asin(z(p) / norm(vec(p)))
    S²(ϕ, θ)
end
S²(q::ℂ²) = S²(ℝ³(q))
lon(s::S²) = s.ϕ
lat(s::S²) = s.θ

struct S³
    p::S²
    left::Bool
end

point(s::S³) = s.p
left(s::S³) = s.left

ℝ³(s::S²) = ℝ³(cos(lat(s)) * cos(lon(s)),
               cos(lat(s)) * sin(lon(s)),
               sin(lat(s)))
ℝ³(q::ℂ²) = ℝ³(imag(z(q)), real(w(q)), imag(w(q)))
ℂ²(s::S²) = ℂ²(Complex(0, x(ℝ³(s))), Complex(y(ℝ³(s)), z(ℝ³(s))))

end  # module NumberTypes
