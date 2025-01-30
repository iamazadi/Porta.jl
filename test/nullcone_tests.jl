origin = ℝ³(rand(3))
segments = rand(5:10)
twospherematrix = maketwosphere(origin, segments = segments)
@test typeof(twospherematrix) <: Matrix{ℝ³}
@test size(twospherematrix) == (segments, segments)


axis = normalize(ℝ³(rand(3)))
M = ℍ(rand(), axis)
T = rand([-1.0, 0.0, 1.0])
compressedprojection = rand([true, false])
spherematrix = makesphere(M, T, compressedprojection = compressedprojection, segments = segments)
@test typeof(spherematrix) <: Matrix{ℝ³}
@test size(spherematrix) == (segments, segments)

v = [rand() + im * rand() for _ in 1:4]
α, β, γ, δ = v
α = (β * γ + 1.0) / δ
spintransformation = SpinTransformation(α, β, γ, δ)
spherematrix = makesphere(spintransformation, T, compressedprojection = compressedprojection, segments = segments)
@test typeof(spherematrix) <: Matrix{ℝ³}
@test size(spherematrix) == (segments, segments)

a = normalize(ℍ(rand(4)))
b = normalize(ℍ(rand(4)))
makesphere(a, b, T, compressedprojection = compressedprojection, segments = segments)
@test typeof(spherematrix) <: Matrix{ℝ³}
@test size(spherematrix) == (segments, segments)

M = Identity(4)
makesphere(M, T, compressedprojection = compressedprojection, segments = segments)
@test typeof(spherematrix) <: Matrix{ℝ³}
@test size(spherematrix) == (segments, segments)

makespheretminusz(spintransformation, T = T, compressedprojection = compressedprojection, segments = segments)
@test typeof(spherematrix) <: Matrix{ℝ³}
@test size(spherematrix) == (segments, segments)


makestereographicprojectionplane(spintransformation, T = T, segments = segments)
@test typeof(spherematrix) <: Matrix{ℝ³}
@test size(spherematrix) == (segments, segments)

M = Identity(4)
makestereographicprojectionplane(M, T = T, segments = segments)
@test typeof(spherematrix) <: Matrix{ℝ³}
@test size(spherematrix) == (segments, segments)

M = ℍ(rand(), axis)
makestereographicprojectionplane(M, T = T, segments = segments)
@test typeof(spherematrix) <: Matrix{ℝ³}
@test size(spherematrix) == (segments, segments)

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), Int(T))
θ = rand() * 2π
ϕ = rand() * 2π
ψ = rand() * 2π
spintransform = SpinTransformation(θ, ϕ, ψ)
vector = 𝕍(spintransform * κ)
projection = projectontoplane(vector)
@test typeof(projection) <: ℝ³
@test isapprox(vec(projection)[3], 0.0)