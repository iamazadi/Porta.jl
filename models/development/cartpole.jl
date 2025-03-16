using LinearAlgebra
using ReinforcementLearning
using ReinforcementLearningTrajectories
using Plots


"""
    ϕ(z)

Calculate a basis vector consisting of quadratic terms in the given elements of `z`,
which contains state and input components.
"""
function ϕ(z::Vector{Float64})
    1 ./ (1 .+ exp.(-z))
end


env = CartPoleEnv()
plot(env)
S = state_space(env)

statedimension = length(state(env)) # xₖ ∈ ℝⁿ
inputdimension = length(action_space(env)) # uₖ ∈ ℝᵐ
number = statedimension + inputdimension
λ = 0.99
δ = 1e-3
w₀ = rand(number, number)
P₀ = I(number) .* (1.0 / δ)
wₙ = deepcopy(w₀)
Pₙ = deepcopy(P₀)
cumulativereward = 0.0
maxreward = 0.0

#########################################
# INITIALIZE.
#########################################

# Select an initial feedback policy at j = 0.
# The initial gain matrix need not be stabalizing and can be selected equal to zero.
K⁰ = rand(inputdimension, statedimension)
Kʲ = deepcopy(K⁰)
reset!(env)
plot(env)

#########################################
# STEP j.
#########################################
for j in 1:1000
    ### Identify the Q function using RLS
    reset!(env)
    k = 1
    global cumulativereward = 0.0
    _wₙ = deepcopy(wₙ)
    _Pₙ = deepcopy(Pₙ)
    while true
        if is_terminated(env) break end
        # At time k, apply the control uₖ based on the current policy uₖ = -Kʲ * xₖ
        # and measure the data set (xₖ, uₖ, xₖ₊₁, uₖ₊₁) where uₖ₊₁ is computed using uₖ₊₁ = -Kʲ * xₖ₊₁.
        xₖ = state(env)
        uₖ = -Kʲ * xₖ # feeback policy
        action = argmax(uₖ + δ .* rand(2))
        cumulativereward += reward(env)
        if cumulativereward > maxreward
            global maxreward = deepcopy(cumulativereward)
        end
        println("j: $j, max reward: $maxreward, reward: $cumulativereward, k: $k, xₖ: $xₖ, uₖ: $uₖ")
        act!(env, action)
        plot(env)
        xₖ₊₁ = state(env)
        uₖ₊₁ = -Kʲ * xₖ₊₁ # feedback policy
        # dataset = (xₖ, uₖ, xₖ₊₁, uₖ₊₁)
        # Compute the quadratic basis sets ϕ(zₖ), ϕ(zₖ₊₁).
        zₖ = [xₖ; uₖ]
        zₖ₊₁ = [xₖ₊₁; uₖ₊₁]
        # basisset1 = ϕ(zₖ)
        # basisset2 = ϕ(zₖ₊₁)
        # Now perform a one-step update in the parameter vector W by applying RLS to equation (S27).
        wₙ₋₁ = deepcopy(_wₙ)
        Pₙ₋₁ = deepcopy(_Pₙ)
        xₙ = zₖ
        zₙ = Pₙ₋₁ * xₙ
        gₙ = (1.0 / (λ + transpose(xₙ) * zₙ)) * zₙ
        # αₙ = dₙ - transpose(wₙ₋₁) * xₙ
        αₙ = wₙ₋₁ * (ϕ(zₖ) - ϕ(zₖ₊₁))
        _wₙ = wₙ₋₁ + αₙ * transpose(gₙ)
        _Pₙ = (1.0 / λ) .* (Pₙ₋₁ - gₙ * transpose(zₙ))
        # Repeat at the next time k + 1 and continue until RLS converges and the new parameter vector Wⱼ₊₁ is found.
        k = k + 1
    end
    
    global wₙ = deepcopy(_wₙ)
    global Pₙ = deepcopy(_Pₙ)

    ### Update the control policy

    # Unpack the vector Wⱼ₊₁ into the kernel matrix
    # Q(xₖ, uₖ) ≡ 0.5 * transpose([xₖ; uₖ]) * S * [xₖ; uₖ] = 0.5 * transpose([xₖ; uₖ]) * [Sₓₓ Sₓᵤ; Sᵤₓ Sᵤᵤ] * [xₖ; uₖ]

    S = wₙ
    Sᵤₓ = S[statedimension + 1: end, begin: statedimension]
    Sᵤᵤ = S[statedimension + 1: end, statedimension + 1: end]

    # Perform the control update using (S24), which is uₖ = -S⁻¹ᵤᵤ * Sᵤₓ * xₖ
    # uₖ = -S⁻¹ᵤᵤ * Sᵤₓ * xₖ
    try
        global Kʲ = inv(Sᵤᵤ) * Sᵤₓ
    catch e
        println(e)
    end

    #########################################
    # SET j = j + 1. GO TO STEP j.
    #########################################
end

#########################################
# TERMINATION.
#########################################

# The algorithm is terminated when there are no further updates to the Q function or the control policy at each step.
