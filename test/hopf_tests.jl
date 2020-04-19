using Porta
using Test

S¹() = rand() * 2pi
S²() = begin
    array = Array{Float64,1}(undef, 2)
    array[1] = rand() * 2pi - pi
    array[2] = rand() * pi - pi / 2
    array
end
S³() = begin
    array = Array{Complex,2}(undef, 2, 2)
    s = S²()
    ϕ = s[1]
    θ = s[2]
    u = [cos(θ) * cos(ϕ), cos(θ) * sin(ϕ), sin(θ)]
    ψ = S¹()
    z = Complex(cos(ψ), sin(ψ) * u[1])
    w = Complex(sin(ψ) * u[2], sin(ψ) * u[3])
    array[1] = z
    array[2] = conj(w)
    array[3] = -w
    array[4] = conj(z)
    array
end

N = 5
s2_points = Array{Float64,2}(undef, N, 2)
s3_points = Array{Complex,3}(undef, N, 2, 2)
for i = 1:N
    s2_points[i, :] = S²()
    s3_points[i, :, :] = S³()
end
chirality = rand() ≥ 0.5 ? true : false
h = Hopf(S²(), chirality)
rotated_s2_points = rotate(s2_points, S³(), chirality)
@test typeof(rotated_s2_points) == Array{Float64,2}
@test size(rotated_s2_points) == (N, 2)
@test all([-pi ≤ rotated_s2_points[i, 1] ≤ pi for i = 1:N])
@test all([-pi / 2 ≤ rotated_s2_points[i, 2] ≤ pi / 2 for i = 1:N])
base_points = πmap(s3_points, h)
@test typeof(base_points) == Array{Float64,2}
@test size(base_points) == (N, 2)
@test all([-pi ≤ base_points[i, 1] ≤ pi for i = 1:N])
@test all([-pi / 2 ≤ base_points[i, 2] ≤ pi / 2 for i = 1:N])
