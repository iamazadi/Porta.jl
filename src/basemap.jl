export ℍ
export 💞
export 🌐
export cartesian
export geographic
export sphere
export ℝ³
export ℂ


struct ℍ
    su2::Array{Complex,2}
    q::Array{Float64}
end

struct 🌐
    basemanifold::Array{Float64,3}
    basecolor::Array{Float64,3}
    basecenter::Array{Float64}
    markermanifold::Array{Float64,4}
    markercolor::Array{Float64,4}
    markercenter::Array{Float64,2}
    markerradius::Float64
    segments::Integer
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

ℝ³(b::Array{Complex}) = begin
    x, y = real.(b), imag.(b)
    d = x .^ 2 .+ y .^ 2 .+ 1
    [2x ./ d 2y ./ d (d .- 2) ./ d]
end

cartesian(x::Array{Float64,2}) = begin
    ϕ = x[:, 1]
    θ = x[:, 2]
    r = x[:, 3]
    y₁ = r .* cos.(θ) .* cos.(ϕ)
    y₂ = r .* cos.(θ) .* sin.(ϕ)
    y₃ = r .* sin.(θ)
    [y₁ y₂ y₃]
end

function geographic(y)
    samples = size(y, 1)
    g = Array{Float64,2}(undef, samples, 3)
    for i in 1:samples
        if y[i, 1] > 0
            ϕ = atan(y[i, 2] / y[i, 1])
        elseif y[i, 2] > 0
            ϕ = atan(y[i, 2] / y[i, 1]) + pi
        else
            ϕ = atan(y[i, 2] / y[i, 1]) - pi
        end
        r = LinearAlgebra.norm(y[i, :])
        θ = asin(y[i, 3] / r)
        g[i, :] = [ϕ; θ; r]
    end
    g
end

function geographic(b::Array{Complex})
    geographic(ℝ³(b))
end

function ℂ(p::Array{Float64,2})
    xyz = cartesian(p)
    d = 1 .- xyz[:, 3]
    x, y = xyz[:, 1] ./ d, xyz[:, 2] ./ d
    convert(Array{Complex}, Complex.(x, y))
end

function sphere(center, radius, segments)
    manifold = Array{Float64,3}(undef, segments, segments, 3)
    for i in 1:segments
        θ = (i - 1) / (segments - 1) * pi - pi / 2
        for j in 1:segments
            ϕ = (j - 1) / (segments - 1) * 2pi - pi
            manifold[i, j, :] = vec(cartesian([ϕ -θ radius])) + center
        end
    end
    manifold
end

function 🌐(basecenter::Array{Float64},
            basecolor::Array{Float64},
            baseradius::Float64,
            markercenter::Array{Float64,2},
            markercolor2::Array{Float64,2},
            markerradius::Float64,
            segments::Integer)
    basemanifold = sphere(basecenter, baseradius - markerradius, segments)
    basecolor = reshape(repeat(basecolor', segments^2), segments, segments, 3)
    samples = size(markercenter, 1)
    markermanifold = Array{Float64,4}(undef, samples, segments, segments, 3)
    markercolor4 = similar(markermanifold)
    for i in 1:samples
        markermanifold[i, :, :, :] = sphere((markercenter[i, :] .* baseradius) + basecenter,
                                            markerradius,
                                            segments)
        markercolor4[i, :, :, :] = reshape(repeat(markercolor2[i, :]', segments^2),
                                           segments,
                                           segments,
                                           3)
    end
    🌐(basemanifold,
       basecolor,
       basecenter,
       markermanifold,
       markercolor4,
       markercenter,
       markerradius,
       segments)
end
