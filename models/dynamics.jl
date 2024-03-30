using LinearAlgebra
using Serialization
using ModelingToolkit, DifferentialEquations, Latexify
using Porta


λ₀ = λ₁
r₀ = r₁

r₁ = 0.8 # experiments: 1-6
λ₁ = 1 + 0.2 * im # experiment 1
λ₂ = im # experiment 2
λ₃ = 2 + im # experiment 3
λ₄ = 0 # experiment 4
λ₅ = 1 # experiment 5
λ₆ = -im # experiment 6

r₇ = 0.5 # experiment 7
λ₇ = -im # experiment 7

r₈ = 0.8 # experiment 8
λ₈ = 2 - im # experiment 8

# r₀ = 3.0 # radius of lambda path circle
# λ₀ = λ₈ # center of lambda path circle
ϕ₀ = 0.0

operator = imag(λ₀) ≥ 0 ? "+" : "-"
version = "r₀=$(r₀)_λ₀=$(float(real(λ₀)))_$(operator)_𝑖$(abs(float(imag(λ₀))))"
modelname = "segment26_gamma3_$version"
L = 10.0 # max x range
L′ = -L


getλ(s) = λ₀ + r₀ * exp(im * (s + ϕ₀))
getλₛ(s, _r) = im * _r * exp(im * (s + ϕ₀))
getμ(s) = √(getλ(s) + 1)
getf(x) = (3 / 2) * sech(x / 2)^2
getA(x, s) = [0 1; getλ(s) + 1 - 2getf(x) 0]
sqrtᵣ(r::Real, i::Real) = real(√(r + im * i))
sqrtᵢ(r::Real, i::Real) = imag(√(r + im * i))
sqrtᵣ(r::Num, i::Num) = real(√(r + im * i))
sqrtᵢ(r::Num, i::Num) = imag(√(r + im * i))
@register_symbolic sqrtᵣ(r, i)
@register_symbolic sqrtᵢ(r, i)


"""
    getγ₁(L, L′)

Get path γ₁ by integating a connection 1-form around a loop in λ-space with the given interval [`L`,`L′`].
Rupert Way (2008)
"""
function getγ₁(L::Float64, L′::Float64)
    s₀ = L
    u₀ = Quaternion([1.0; -√(getλ(s₀) + 1)])
    uₗ₀ = Quaternion([0.0; -1 / 2(√(getλ(s₀) + 1))])
    v₀ = normalize(u₀)
    w₀ = πmap(v₀)
    λₛ₀ = getλₛ(s₀, r₀)
    θ₀ = 0.0
    m₀ = norm(u₀)
    # TDOO: define λₛ in terms of the D differential operator
    # Define our state variables: state(t) = initial condition
    @variables t
    @variables λᵣ(t)=real(getλ(L))
    @variables λᵢ(t)=imag(getλ(L))
    @variables λₛᵣ(t)=real(λₛ₀)
    @variables λₛᵢ(t)=imag(λₛ₀)
    @variables u(t)[1:4]=vec(u₀)
    @variables uₗ(t)[1:4]=vec(uₗ₀)
    @variables v(t)[1:4]=vec(v₀)
    @variables w(t)[1:3]=w₀
    @variables θ(t)=θ₀
    @variables m(t)=m₀
    # Define our parameters
    @parameters r::Float64=r₀ ϕ::Float64=ϕ₀
    # Define our differential: takes the derivative with respect to `t`
    D = Differential(t)
    # Define the differential equations
    eqs = [λᵣ ~ real(getλ(t))
           λᵢ ~ imag(getλ(t))
           λₛᵣ ~ real(getλₛ(t, r))
           λₛᵢ ~ imag(getλₛ(t, r))
           u[1] ~ 1.0
           u[2] ~ -sqrtᵣ(real(λᵣ + λᵢ * im + 1), imag(λᵣ + λᵢ * im + 1))
           u[3] ~ 0.0
           u[4] ~ -sqrtᵢ(real(λᵣ + λᵢ * im + 1), imag(λᵣ + λᵢ * im + 1))
           uₗ[1] ~ 0.0
           uₗ[2] ~ real(-1 / 2(sqrtᵣ(real(λᵣ + λᵢ * im + 1), imag(λᵣ + λᵢ * im + 1)) + im * sqrtᵢ(real(λᵣ + λᵢ * im + 1), imag(λᵣ + λᵢ * im + 1))))
           uₗ[3] ~ 0.0
           uₗ[4] ~ imag(-1 / 2(sqrtᵣ(real(λᵣ + λᵢ * im + 1), imag(λᵣ + λᵢ * im + 1)) + im * sqrtᵢ(real(λᵣ + λᵢ * im + 1), imag(λᵣ + λᵢ * im + 1))))
           m ~ sqrtᵣ(sum(abs.([u[1] + u[3] * im; u[2] + u[4] * im]).^2), 0.0)
           v ~ u ./ m
           w[3] ~ real(conj(v[1] + v[3] * im) * (v[2] + v[4] * im) + (v[1] + v[3] * im) * conj(v[2]) + v[4] * im)
           w[2] ~ real(im * (conj(v[1] + v[3] * im) * (v[2] + v[4] * im) - (v[1] + v[3] * im) * conj(v[2] + v[4] * im)))
           w[1] ~ real(abs(v[1] + v[3] * im)^2 - abs(v[2] + v[4] * im)^2)
           D(θ) ~ imag((u' * uₗ) * (λₛᵣ + λₛᵢ * im)) / (u' * u)]
    latex = latexify(eqs)
    println("γ₁")
    println(latex)
    # Bring these pieces together into an ODESystem with independent variable t
    @named sys = ODESystem(eqs, t)
    # Symbolically Simplify the System
    simpsys = structural_simplify(sys)
    # Convert from a symbolic to a numerical problem to simulate
    tspan = (L, L′)
    prob = ODEProblem(simpsys, [], tspan)
    # Solve the ODE
    sol = solve(prob)
    samples = length(sol[v])
    γ₁ = Vector{Quaternion}(undef, samples)
    phases = Vector{Float64}(undef, samples)
    path_λ = Vector{Vector{Float64}}(undef, samples)
    s = Vector{Float64}(undef, samples)
    path_s2 = Vector{Vector{Float64}}(undef, samples)
    for i in 1:samples
        γ₁[i] = Quaternion(sol[v][i])
        path_λ[i] = convert_to_cartesian(sol[λᵣ][i] + im * sol[λᵢ][i])
        phases[i] = sol[θ][i]
        s[i] = sol[t][i]
        path_s2[i] = sol[w][i]
    end
    γ₁, phases, path_λ, path_s2, s, latex
end


"""
    getγ₂(L, L′, s₀)

Get path γ₂ by integating a connection 1-form in the x direction with the given bounds [`L`,`L′`] and a fixed value for λ `s₀`.
Rupert Way (2008)
"""
function getγ₂(L::Float64, L′::Float64, s₀::Float64)
    μ₀ = getμ(s₀)
    u₀ = Quaternion([1.0; -μ₀])
    θ₀ = 0.0
    v₀ = normalize(u₀)
    w₀ = πmap(v₀)
    m₀ = norm(u₀)
    f₀ = getf(s₀)
    λᵣ₀ = real(getλ(s₀))
    λᵢ₀ = imag(getλ(s₀))
    # Define our state variables: state(t) = initial condition
    @variables t
    @variables f(t)=f₀
    @variables μᵣ(t)=real(μ₀)
    @variables μᵢ(t)=imag(μ₀)
    @variables u(t)[1:4]=vec(u₀)
    @variables v(t)[1:4]=vec(v₀)
    @variables w(t)[1:3]=w₀
    @variables θ(t)=θ₀
    @variables m(t)=m₀
    # Define our parameters
    @parameters λᵣ::Float64=λᵣ₀ λᵢ::Float64=λᵢ₀
    # Define our differential: takes the derivative with respect to `t`
    D = Differential(t)
    # Define the differential equations
    eqs = [μᵣ ~ sqrtᵣ(real(λᵣ + λᵢ * im + 1), imag(λᵣ + λᵢ * im + 1))
           μᵢ ~ sqrtᵢ(real(λᵣ + λᵢ * im + 1), imag(λᵣ + λᵢ * im + 1))
           f ~ getf(t)
           D(u[1]) ~ real( ([0 1; (λᵣ + λᵢ * im) + 1 - 2f 0] + [μᵣ + μᵢ * im 0; 0 μᵣ + μᵢ * im]) * [u[1] + u[3] * im; u[2] + u[4] * im] )[1]
           D(u[2]) ~ real( ([0 1; (λᵣ + λᵢ * im) + 1 - 2f 0] + [μᵣ + μᵢ * im 0; 0 μᵣ + μᵢ * im]) * [u[1] + u[3] * im; u[2] + u[4] * im] )[2]
           D(u[3]) ~ imag( ([0 1; (λᵣ + λᵢ * im) + 1 - 2f 0] + [μᵣ + μᵢ * im 0; 0 μᵣ + μᵢ * im]) * [u[1] + u[3] * im; u[2] + u[4] * im] )[1]
           D(u[4]) ~ imag( ([0 1; (λᵣ + λᵢ * im) + 1 - 2f 0] + [μᵣ + μᵢ * im 0; 0 μᵣ + μᵢ * im]) * [u[1] + u[3] * im; u[2] + u[4] * im] )[2]
           D(θ) ~ imag(([u[1] + u[3] * im u[2] + u[4] * im] * ([0 1; (λᵣ + λᵢ * im) + 1 - 2f 0] * [u[1] + u[3] * im; u[2] + u[4] * im]))[1]) / (u' * u)
           m ~ sqrtᵣ(sum(abs.([u[1] + u[3] * im; u[2] + u[4] * im]).^2), 0)
           v ~ u ./ m
           w[3] ~ real(conj(v[1] + v[3] * im) * (v[2] + v[4] * im) + (v[1] + v[3] * im) * conj(v[2]) + v[4] * im)
           w[2] ~ real(im * (conj(v[1] + v[3] * im) * (v[2] + v[4] * im) - (v[1] + v[3] * im) * conj(v[2] + v[4] * im)))
           w[1] ~ real(abs(v[1] + v[3] * im)^2 - abs(v[2] + v[4] * im)^2)]
    latex = latexify(eqs)
    # Bring these pieces together into an ODESystem with independent variable t
    @named sys = ODESystem(eqs, t)
    # Symbolically Simplify the System
    simpsys = structural_simplify(sys)
    # Convert from a symbolic to a numerical problem to simulate
    tspan = (L, L′)
    prob = ODEProblem(simpsys, [], tspan)
    # Solve the ODE
    sol = solve(prob)
    samples = length(sol[v])
    γ₂ = Vector{Quaternion}(undef, samples)
    u₂ = Vector{Quaternion}(undef, samples)
    phases = Vector{Float64}(undef, samples)
    s = Vector{Float64}(undef, samples)
    path_s2 = Vector{Vector{Float64}}(undef, samples)
    for i in 1:samples
        γ₂[i] = Quaternion(sol[v][i])
        u₂[i] = Quaternion(sol[u][i])
        phases[i] = sol[θ][i]
        s[i] = sol[t][i]
        path_s2[i] = sol[w][i]
    end
    λ = convert_to_cartesian(λᵣ + im * λᵢ)
    γ₂, u₂, phases, λ, path_s2, s, latex
end


@register_symbolic get_u(L, L′, s)::Vector{Float64}
get_u(L::Float64, L′::Float64, s::Float64) = vec(getγ₂(L, L′, s)[2][end])


"""
    getγ₃(L, L′)

Get path γ₃ with the given integration interval [`L`,`L′`] along paths of type γ₂.
Rupert Way (2008)
"""
function getγ₃(L::Float64, L′::Float64)
    u₀ = get_u(L, L′, L)
    v₀ = vec(normalize(u₀))
    w₀ = πmap(Quaternion(v₀))
    m₀ = norm(u₀)
    # Define our parameters
    @parameters K₃[1:4,1:4]=K(3) δ=(2π / 1000)
    # Define our state variables: state(t) = initial condition
    @variables t
    @variables u(t)[1:4]=u₀
    @variables uₛ(t)[1:4]=u₀
    @variables v(t)[1:4]=v₀
    @variables w(t)[1:3]=w₀
    @variables m(t)=m₀
    @variables θ(t)=0

    # Define our differential: takes the derivative with respect to `t`
    D = Differential(t)

    # Define the differential equations
    eqs = [u .~ get_u(L, L′, t)[1:4]
           uₛ .~ (get_u(L, L′, t + δ)[1:4] - get_u(L, L′, t - δ)[1:4]) ./ 2δ
           D(θ) ~ imag([u[1] + u[3] * im; u[2] + u[4] * im]' * [uₛ[1] + uₛ[3] * im; uₛ[2] + uₛ[4] * im]) / (u' * u)
           m ~ sqrtᵣ(sum(abs.([u[1] + u[3] * im; u[2] + u[4] * im]).^2), 0)
           v ~ u ./ m
           w[3] ~ real(conj(v[1] + v[3] * im) * (v[2] + v[4] * im) + (v[1] + v[3] * im) * conj(v[2]) + v[4] * im)
           w[2] ~ real(im * (conj(v[1] + v[3] * im) * (v[2] + v[4] * im) - (v[1] + v[3] * im) * conj(v[2] + v[4] * im)))
           w[1] ~ real(abs(v[1] + v[3] * im)^2 - abs(v[2] + v[4] * im)^2)]

    latex = latexify(eqs)
    println("γ₃")
    println(latex)

    # Bring these pieces together into an ODESystem with independent variable t
    @named sys = ODESystem(eqs, t)

    # Symbolically Simplify the System
    simpsys = structural_simplify(sys)

   # latexify(simpsys)

    # Convert from a symbolic to a numerical problem to simulate
    tspan = (0, 2π)
    prob = ODEProblem(simpsys, [], tspan)

    # Solve the ODE
    sol = solve(prob)
    samples = length(sol[v])
    γ₃ = Vector{Quaternion}(undef, samples)
    phases = Vector{Float64}(undef, samples)
    s = Vector{Float64}(undef, samples)
    s2_path = Vector{Vector{Float64}}(undef, samples)
    for i in 1:samples
        γ₃[i] = Quaternion(sol[v][i])
        phases[i] = sol[θ][i]
        s[i] = sol[t][i]
        s2_path = sol[w][i]
    end
    γ₃, phases, s2_path, s, latex
end


γ₁, θ₁, λ₁, w₁, t₁, latex1 = getγ₁(0.0, 2π)
serialize("gamma1_$version", [γ₁, θ₁, λ₁, w₁, t₁, latex1])
steps_number = length(t₁)
γ₂ = Vector{Vector{Quaternion}}(undef, steps_number)
θ₂ = Vector{Vector{Float64}}(undef, steps_number)
λ_array = []
for i in 1:steps_number
    _γ, _u, _θ, _λ, _w, _t, _latex2 = getγ₂(L, L′, t₁[i])
    push!(λ_array, _λ)
    γ₂[i] = _γ
    θ₂[i] = _θ
end
serialize("gamma2_$version", [γ₂, θ₂, λ_array])
γ₃, θ₃, s2_path₃, t₃, latex3 = getγ₃(L, L′)
serialize("gamma3_$version", [γ₃, θ₃, s2_path₃, t₃, latex3])