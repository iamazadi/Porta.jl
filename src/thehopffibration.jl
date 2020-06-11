export ⭕
export HSVtoRGB

import LinearAlgebra

struct ⭕
    b::Array{Complex}
    f::Array{Float64,2}
    m::Array{Float64,4}
    c::Array{Float64,4}
    s::Integer
    r::Float64
    q::ℍ
    p::Array{Float64}
end

λ(z₁, z₂) = begin
    d = 1 .- imag.(z₂)
    y = [real.(z₁) ./ d imag.(z₁) ./ d real.(z₂) ./ d]
    c = similar(y)
    sigmoid(x) = 2 / (1 + exp(-x)) .- 1
    for i in 1:size(y, 1)
        c[i, :] = LinearAlgebra.normalize(y[i, :]) .* tanh(LinearAlgebra.norm(y[i, :]))
    end
    c
end

HSVtoRGB(hsv) = begin
    H, S, V = hsv
    C = V * S
    X = C * (1 - Base.abs((H / 60) % 2 - 1))
    m = V - C
    if 0 ≤ H < 60
        R′, G′, B′ = C, X, 0
    elseif 60 ≤ H < 120
        R′, G′, B′ = X, C, 0
    elseif 120 ≤ H < 180
        R′, G′, B′ = 0, C, X
    elseif 180 ≤ H < 240
        R′, G′, B′ = 0, X, C
    elseif 240 ≤ H < 300
        R′, G′, B′ = X, 0, C
    elseif 300 ≤ H < 360
        R′, G′, B′ = C, 0, X
    else
        R′, G′, B′ = rand(3)
    end
    R, G, B = R′ + m, G′ + m, B′ + m
    [R; G; B]
end

function get_fibers(b::Array{Complex},
                    f::Array{Float64,2},
                    s::Integer,
                    r::Float64,
                    q::ℍ,
                    offset::Array{Float64})
    samples = size(b, 1)
    θ₁, θ₂ = f[:, 1], f[:, 2]
    Q = [1.0; 0.0; 0.0; 0.0]
    nᵢ = [0; 0; 1]
    s2 = Integer(s ÷ 3)
    ψ = range(0, stop = 2pi, length = s2)
    zero = fill(0, s2)
    m = Array{Float64,4}(undef, samples, s, s2, 3)
    c = similar(m)
    construct(b, ξ₂, q) = begin
        samples = size(ξ₂, 1)
        z₁ = exp.(im .* (ξ₂ .+ imag.(b) ./ 2)) .* cos.(atan.(real.(b)))
        z₂ = exp.(im .* (ξ₂ .- imag.(b) ./ 2)) .* sin.(atan.(real.(b)))
        rotatedz₁ = Array{Complex}(undef, samples)
        rotatedz₂ =  similar(rotatedz₁)
        for i in 1:samples
            rotated = ℍ([real.(z₁[i]); imag.(z₁[i]); real.(z₂[i]); imag.(z₂[i])]) * q
            rotatedz₁[i] = Complex(rotated.q[1], rotated.q[2])
            rotatedz₂[i] = Complex(rotated.q[3], rotated.q[4])
        end
        rotatedz₁, rotatedz₂
    end
    for i in 1:samples
        ξ₂ = range(θ₁[i], stop = θ₂[i], length = s)
        z₁, z₂ = construct(b[i], ξ₂, q)
        p = λ(z₁, z₂)
        p′ = circshift(p, 1)
        P = [real(z₁[1]); imag(z₁[1]); real(z₂[1]); imag(z₂[1])]
        hue = acos(LinearAlgebra.dot(P, Q)) / pi
        rgb = HSVtoRGB([hue * 360; 1.0; 1.0])
        c[i, :, :, :] = reshape(repeat(rgb', s * s2), s, s2, 3)
        for j in 1:s
            n = LinearAlgebra.normalize(p′[j, :] - p[j, :])
            u = LinearAlgebra.normalize(LinearAlgebra.cross(nᵢ, n))
            β = acos(LinearAlgebra.dot(nᵢ, n)) / 2
            h2 = ℍ([cos(β); sin(β) .* u])
            circle = [r .* cos.(ψ) r .* sin.(ψ) zero]
            m[i, j, :, :] = 💞(circle,
                               h2) + repeat((p[j, :])', s2, 1) + repeat(offset', s2, 1)
        end
    end
    m, c
end

⭕(b::Array{Complex}, f::Array{Float64,2}, s::Int64, r::Float64, q::ℍ, p::Array{Float64}) = begin
    m, c = get_fibers(b, f, s, r, q, p)
    ⭕(b, f, m, c, s, r, q, p)
end
