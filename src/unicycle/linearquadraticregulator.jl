using LinearAlgebra
using ReinforcementLearning


export LinearQuadraticRegulator
export step!


"""
    Represents a Linear Quadratic Regulator (LQR) model.

fields: Wₙ, Pₙ, Kʲ, j, reward, dataset, n, m, λ and δ.
"""
struct LinearQuadraticRegulator
    Wₙ::Matrix{Float64} # filter matrix
    Pₙ::Matrix{Float64} # inverse autocorrelation matrix
    Kʲ::Matrix{Float64} # feedback policy
    j::Int # step number
    reward::Float64 # the cumulative reward
    dataset::Vector{Tuple} # (xₖ, uₖ, xₖ₊₁, uₖ₊₁)
    n::Int # # xₖ ∈ ℝⁿ
    m::Int # uₖ ∈ ℝᵐ
    λ::Float64 # exponential wighting factor
    δ::Float64 # value used to intialize P(0)
    LinearQuadraticRegulator(Wₙ::Matrix{Float64}, Pₙ::Matrix{Float64}, Kʲ::Matrix{Float64},
                            j::Int, reward::Float64, dataset::Vector{Tuple}, n::Int, m::Int,
                            λ::Float64, δ::Float64) = begin
        new(Wₙ, Pₙ, Kʲ, j, reward, dataset, n, m, λ, δ)
    end
    LinearQuadraticRegulator(n::Int, m::Int; λ::Float64 = 0.99, δ::Float64 = 1e-3) = begin
        number = m + n
        Wₙ = rand(number, number)
        Pₙ = convert(Matrix{Float64}, I(number) .* (1.0 / δ))
        Kʲ = rand(m, n)
        j = 1
        reward = 0.0
        dataset = Tuple[]
        LinearQuadraticRegulator(Wₙ, Pₙ, Kʲ, j, reward, dataset, n, m, λ, δ)
    end
end


"""
    sigmoid(z)

Calculate a basis vector consisting of exponential terms in the given elements of `z`,
which contains state and input components.
"""
sigmoid(z::Vector{Float64}) = 1 ./ (1 .+ exp.(-z))


"""
    step!(environment, model)

Identify the Q function using RLS and update the control policy,
with the given `environment` and `model`.
The algorithm is terminated when there are no further updates
to the Q function or the control policy at each step.
"""
function step!(environment::CartPoleEnv, model::LinearQuadraticRegulator)
    ### Identify the Q function using RLS
    reset!(environment)
    k = 1
    _reward = 0.0
    _Wₙ = deepcopy(model.Wₙ)
    _Pₙ = deepcopy(model.Pₙ)
    Kʲ = model.Kʲ
    λ = model.λ
    δ = model.δ
    n = model.n
    while !is_terminated(environment)
        # At time k, apply the control uₖ based on the current policy uₖ = -Kʲ * xₖ
        # and measure the data set (xₖ, uₖ, xₖ₊₁, uₖ₊₁) where uₖ₊₁ is computed using uₖ₊₁ = -Kʲ * xₖ₊₁.
        xₖ = state(environment)
        uₖ = -Kʲ * xₖ # feeback policy
        action = argmax(uₖ + δ .* rand(2))
        _reward += reward(environment)
        act!(environment, action)
        xₖ₊₁ = state(environment)
        uₖ₊₁ = -Kʲ * xₖ₊₁ # feedback policy
        # dataset = (xₖ, uₖ, xₖ₊₁, uₖ₊₁)
        push!(model.dataset, (xₖ, uₖ, xₖ₊₁, uₖ₊₁))
        # Compute the quadratic basis sets ϕ(zₖ), ϕ(zₖ₊₁).
        zₖ = [xₖ; uₖ]
        zₖ₊₁ = [xₖ₊₁; uₖ₊₁]
        basisset1 = sigmoid(zₖ)
        basisset2 = sigmoid(zₖ₊₁)
        # Now perform a one-step update in the parameter vector W by applying RLS to equation (S27).
        Wₙ₋₁ = deepcopy(_Wₙ)
        Pₙ₋₁ = deepcopy(_Pₙ)
        xₙ = zₖ
        zₙ = Pₙ₋₁ * xₙ
        gₙ = (1.0 / (λ + transpose(xₙ) * zₙ)) * zₙ
        # αₙ = dₙ - transpose(wₙ₋₁) * xₙ
        αₙ = Wₙ₋₁ * (basisset1 - basisset2)
        _Wₙ = Wₙ₋₁ + αₙ * transpose(gₙ)
        _Pₙ = (1.0 / λ) .* (Pₙ₋₁ - gₙ * transpose(zₙ))
        # Repeat at the next time k + 1 and continue until RLS converges and the new parameter vector Wⱼ₊₁ is found.
        k = k + 1
    end

    ### Update the control policy
    # Unpack the vector Wⱼ₊₁ into the kernel matrix
    # Q(xₖ, uₖ) ≡ 0.5 * transpose([xₖ; uₖ]) * S * [xₖ; uₖ] = 0.5 * transpose([xₖ; uₖ]) * [Sₓₓ Sₓᵤ; Sᵤₓ Sᵤᵤ] * [xₖ; uₖ]
    S = _Wₙ
    Sᵤₓ = S[n + 1: end, begin: n]
    Sᵤᵤ = S[n + 1: end, n + 1: end]
    # Perform the control update using (S24), which is uₖ = -S⁻¹ᵤᵤ * Sᵤₓ * xₖ
    # uₖ = -S⁻¹ᵤᵤ * Sᵤₓ * xₖ
    try
        return LinearQuadraticRegulator(_Wₙ, _Pₙ, inv(Sᵤᵤ) * Sᵤₓ, model.j + 1, _reward, model.dataset, model.n, model.m, model.λ, model.δ)
    catch e
        println("The control update is not performed because an error has occured: $e")
        return LinearQuadraticRegulator(_Wₙ, _Pₙ, model.Kʲ, model.j + 1, _reward, model.dataset, model.n, model.m, model.λ, model.δ)
    end
end