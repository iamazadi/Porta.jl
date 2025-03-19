using LinearAlgebra
using ReinforcementLearning
using ReinforcementLearningTrajectories
using Plots
using Porta

environment = CartPoleEnv()
n = length(state(environment)) # xₖ ∈ ℝⁿ
m = length(action_space(environment)) # uₖ ∈ ℝᵐ
λ = 0.99
δ = 1e-3
model = LinearQuadraticRegulator(n, m, λ = λ, δ = δ)
maxreward = 0.0

for j in 1:1000
    global model = step!(environment, model)
    plot(environment)
    xₖ, uₖ, xₖ₊₁, uₖ₊₁ = model.dataset[end]
    global maxreward = max(maxreward, model.reward)
    println("j: $(model.j), max reward: $maxreward, reward: $(model.reward), xₖ: $xₖ, uₖ: $uₖ")
end