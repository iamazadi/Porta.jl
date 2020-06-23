import Base.+
import Base.-
import Base.*
import Base.vec
import Base.isapprox


export ℝ³


struct ℝ³
    p::Array{Float64} # basis [x; y; z]
end


ℝ³(a, b, c) = ℝ³([Float64(a); Float64(b); Float64(c)])
x(r::ℝ³) = r.p[1]
y(r::ℝ³) = r.p[2]
z(r::ℝ³) = r.p[3]
Base.vec(r::ℝ³) = [x(r); y(r); z(r)]
(+)(p::ℝ³, r::ℝ³) = ℝ³(vec(p) + vec(r))
(-)(p::ℝ³, r::ℝ³) = ℝ³(vec(p) - vec(r))
(*)(λ::Number, r::ℝ³) = ℝ³(λ .* vec(r))
Base.isapprox(p::ℝ³, r::ℝ³) = isapprox(vec(p), vec(r))
