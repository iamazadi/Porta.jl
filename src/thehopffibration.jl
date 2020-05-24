export ℍ
export 💞
export ⭕

import LinearAlgebra

struct ℍ
    su2::Array{Complex,2}
    q::Array{Float64}
end

struct ⭕
    b::Array{Complex}
    f::Array{Float64,2}
    m::Array{Float64,4}
    c::Array{Float64,4}
    s::Integer
    r::Float64
    q::ℍ
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

ℍ(q::Array{Float64}) = begin
    z₁, z₂ = Complex(q[1], q[2]), Complex(q[3], q[4])
    s = [z₁ conj(z₂); -z₂ conj(z₁)]
    ℍ(s, q)
end

ℍ(s::Array{Complex,2}) = begin
    q = [real(s[1]); imag(s[1]); -real(s[3]); -imag(s[3])]
    ℍ(s, q)
end

Base.imag(h::ℍ) = [imag(h.su2[1]); -real(h.su2[3]); -imag(h.su2[3])]

Base.adjoint(h::ℍ) = ℍ(convert(Array{Complex,2}, adjoint(h.su2)))

function Base.:*(h₁::ℍ, h₂::ℍ)
    s = h₁.su2 * h₂.su2
    q = [real(s[1]); imag(s[1]); -real(s[3]); -imag(s[3])]
    ℍ(s, q)
end

💞(p::Array{Float64}, h::ℍ) = imag(adjoint(h) * ℍ([0; p]) * h)

function 💞(p::Array{Float64,2}, h::ℍ)
    r = similar(p)
    for i in 1:size(p, 1)
        r[i, :] = 💞(p[i, :], h)
    end
    r
end

function 💞(p::Array{Float64,3}, center::Array{Float64}, h::ℍ)
    r = similar(p)
    c = reshape(repeat(center', size(p, 2)), size(p, 2), size(p, 3))
    for i in 1:size(p, 1)
        oldposition = p[i, :, :] - c
        r[i, :, :] = 💞(oldposition, h) + c
    end
    r
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

function geographic(y)
    samples = size(y, 1)
    g = Array{Float64,2}(undef, samples, 2)
    for i in 1:samples
        if y[i, 1] > 0
            ϕ = atan(y[i, 2] / y[i, 1])
        elseif y[i, 2] > 0
            ϕ = atan(y[i, 2] / y[i, 1]) + pi
        else
            ϕ = atan(y[i, 2] / y[i, 1]) - pi
        end
        r = sqrt(LinearAlgebra.norm(y[i, :]))
        θ = asin(y[i, 3] / r)
        g[i, :] = [ϕ; θ]
    end
    g
end

function get_fibers(b::Array{Complex}, f::Array{Float64,2}, s::Integer, r::Float64, q::ℍ)
    samples = size(b, 1)
    θ₁, θ₂ = f[:, 1], f[:, 2]
    x, y = real.(b), imag.(b)
    d = x .^ 2 .+ y .^ 2 .+ 1
    y₁, y₂, y₃ = 2x ./ d, 2y ./ d, (d .- 2) ./ d
    g = geographic([y₁ y₂ y₃])
    ϕ, θ = g[:, 1], g[:, 2]
    ξ₁, η = g[:, 1] .+ pi, (g[:, 2] .+ (pi / 2)) ./ 2
    Q = [1.0; 0.0; 0.0; 0.0]
    nᵢ = [0; 0; 1]
    s2 = Integer(s ÷ 3)
    ψ = range(0, stop = 2pi, length = s2)
    zero = fill(0, s2)
    m = Array{Float64,4}(undef, samples, s, s2, 3)
    c = similar(m)
    construct(η, ξ₁, ξ₂, q) = begin
        samples = size(ξ₂, 1)
        z₁ = exp.(im .* ξ₂) .* cos(η)
        z₂ = exp.(im .* (ξ₂ .+ ξ₁)) .* sin(η)
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
        factor = η[i] / (pi / 2)
        lspace = range(θ₁[i], stop = θ₂[i], length = s)
        ξ₂ = Array{Float64}(undef, s)
        for j in 1:s
            x = lspace[j]
            if x < pi
                ξ₂[j] = pi * tanh((factor + 1) * x)
            else
                ξ₂[j] = pi * tanh((factor + 1) * (x - 2pi)) + 2pi
            end
        end
        ξ₂ = ξ₂ .- ξ₁[i] .- (pi / 2)
        z₁, z₂ = construct(η[i], ξ₁[i], ξ₂, q)
        p = λ(z₁, z₂)
        ξ₂′ = ξ₂ .+ 1e-10
        z₁′, z₂′ = construct(η[i], ξ₁[i], ξ₂′, q)
        p′ = λ(z₁′, z₂′)
        P = [real(z₁[1]); imag(z₁[1]); real(z₂[1]); imag(z₂[1])]
        hue = acos(LinearAlgebra.dot(P, Q)) / pi
        #hue = (ϕ[i] + pi + 2θ[i] + pi) / 4pi
        rgb = HSVtoRGB([hue * 360; 1.0; 1.0])
        c[i, :, :, :] = reshape(repeat(rgb', s * s2), s, s2, 3)
        for j in 1:s
            n = LinearAlgebra.normalize(p′[j, :] - p[j, :])
            u = LinearAlgebra.normalize(LinearAlgebra.cross(nᵢ, n))
            β = acos(LinearAlgebra.dot(n, nᵢ)) / 2
            h2 = ℍ([cos(β); sin(β) .* u])
            m[i, j, :, :] = 💞([r .* cos.(ψ) r .* sin.(ψ) zero],
                               h2) + repeat((p[j, :])', s2, 1)
        end
    end
    m, c
end

⭕(b::Array{Complex}, f::Array{Float64,2}, s::Int64, r::Float64, q::ℍ) = begin
    m, c = get_fibers(b, f, s, r, q)
    ⭕(b, f, m, c, s, r, q)
end
