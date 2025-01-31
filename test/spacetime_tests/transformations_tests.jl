status = rand(1:3)
progress = rand()
fourscrew = compute_fourscrew(progress, status)
@test typeof(fourscrew) <: Matrix{Float64}
@test size(fourscrew) == (4, 4)

nullrotation = compute_nullrotation(progress)
@test typeof(nullrotation) <: Matrix{Float64}
@test size(nullrotation) == (4, 4)

generate1() = 10rand() - 5 + im * (10rand() - 5)
scalar = exp(im * rand())
timesign = rand([-1, 1])
κ = scalar * SpinVector(generate1(), generate1(), timesign)
ω = SpinVector(generate1(), generate1(), timesign)

z₁ = Complex(κ)
z₂ = Complex(-ω)
z₃ = Complex(κ + ω)
α = rand()
w₁ = α * exp(im * 0.0) + (1 - α) * z₁
w₂ = α * exp(im * 2π / 3.0) + (1 - α) * z₂
w₃ = α * exp(im * 4π / 3.0) + (1 - α) * z₃
f = calculatetransformation(z₁, z₂, z₃, w₁, w₂, w₃)
complexnumber = rand() * exp(im * rand())
transformednumber = f(complexnumber)
@test typeof(transformednumber) <: Complex


ê₁, ê₂, ê₃, ê₄ = calculatebasisvectors(κ, ω)
@test all([typeof(x) <: ℝ⁴ for x in (ê₁, ê₂, ê₃, ê₄)])
@test all([isapprox(norm(x), 1.0) for x in (ê₁, ê₂, ê₃, ê₄)])