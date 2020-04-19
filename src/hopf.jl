export Hopf
export rotate
export πmap
export λ
export λ⁻¹
export σ
export τ
export S¹action

struct Hopf
    point::Array{Float64,1}
    chirality::Bool
end

function SU2(s::Array{Float64,1})
    array = Array{Complex,2}(undef, 2, 2)
    ϕ = s[1]
    θ = s[2]
    u = [cos(θ) * cos(ϕ), cos(θ) * sin(ϕ), sin(θ)]
    z = Complex(0, u[1])
    w = Complex(u[2], u[3])
    array[1] = z
    array[2] = conj(w)
    array[3] = -w
    array[4] = conj(z)
    array
end

function S²(s::Array{Complex,2})
    array = Array{Float64,1}(undef, 2)
    z = s[1]
    w = -s[3]
    u = [imag(z) real(w) imag(w)]
    r = sqrt(u[1]^2 + u[2]^2 + u[3]^2)
    if u[1] > 0
          ϕ = atan(u[2] / u[1])
    elseif u[2] > 0
          ϕ = atan(u[2] / u[1]) + pi
    else
          ϕ = atan(u[2] / u[1]) - pi
    end
    θ = asin(u[3] / r)
    array[1] = ϕ
    array[2] = θ
    array
end

function rotate(p::Array{Float64,1}, q::Array{Complex,2}, chirality::Bool)
    if chirality
        S²(q * SU2(p) * adjoint(q))
    else
        S²(adjoint(q) * SU2(p) * q)
    end
end

function rotate(p::Array{Float64,2}, q::Array{Complex,2}, chirality::Bool)
    result = similar(p)
    for i in size(p, 1)
        result[i, :] = rotate(p[i, :], q, chirality)
    end
    result
end

function πmap(q::Array{Complex,3}, h::Hopf)
    samples = size(q, 1)
    result = Array{Float64,2}(undef, samples, 2)
    for i in 1:samples
        result[i, :] = rotate(h.point, q[i, :, :], h.chirality)
    end
    result
end

"""
function rotation(a::S², b::S²)
    u = normalize(cross(vec(ℝ³(a)), vec(ℝ³(b))))
    θ = acos(dot(vec(ℝ³(a)), vec(ℝ³(b))))
    z = Complex(cos(θ / 2), sin(θ / 2) * u[1])
    w = Complex(sin(θ / 2) * u[2], sin(θ / 2) * u[3])
    ℂ²(z, w)
end

rotation(s::S²) = rotation(S²(ℝ³(1, 0, 0)), s)

π(q::ℂ², s::S³) = rotateS²(point(s), q, left(s))

function σ(p′::S², s::S³)
    p = rotateS²(p′, rotation(point(s)), left(s))
    z = exp(-im * lon(S²(p))) * sqrt((1 + sin(lat(S²(p)))) / 2)
    w = Complex(sqrt((1 - sin(lat(S²(p)))) / 2))
    ℂ²(z, w)
end

function τ(p′::S², s::S³)
    p = rotateS²(p′, rotation(point(s)), left(s))
    z = Complex(sqrt((1 + sin(lat(S²(p)))) / 2))
    w = exp(im * lon(S²(p))) * sqrt((1 - sin(lat(S²(p)))) / 2)
    ℂ²(z, w)
end

S¹action(α::Float64, q::ℂ²) = ℂ²(exp(α * im) * z(q), exp(α * im) * w(q))

λ(q::ℂ²) = ℝ³([real(z(q)) imag(z(q)) real(w(q))] ./ (1 - imag(w(q))))

function λ⁻¹(p::ℝ³)
    x₁ = 2 * x(p) / (1 + norm(vec(p)))
    x₂ = 2 * y(p) / (1 + norm(vec(p)))
    x₃ = 2 * z(p) / (1 + norm(vec(p)))
    x₄ = (-1 + norm(vec(p))) / (1 + norm(vec(p)))
    ℂ²(Complex(x₁, x₂), Complex(x₃, x₄))
end
"""
