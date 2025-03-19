using ReinforcementLearning


environment = CartPoleEnv()
n = length(state(environment)) # xₖ ∈ ℝⁿ
m = length(action_space(environment)) # uₖ ∈ ℝᵐ
λ = 0.99
δ = 1e-3
model = LinearQuadraticRegulator(n, m, λ = λ, δ = δ)
model = step!(environment, model)
@test length(model.dataset) > 0