using Plots, OrdinaryDiffEq, ModelingToolkit
gr()

G = 2.95912208286e-4
M = [
    1.00000597682,
    0.000954786104043,
    0.000285583733151,
    0.0000437273164546,
    0.0000517759138449,
    1 / 1.3e8
]
planets = ["Sun", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]

pos = [0.0 -3.5023653 9.0755314 8.310142 11.4707666 -15.5387357
       0.0 -3.8169847 -3.0458353 -16.2901086 -25.7294829 -25.2225594
       0.0 -1.5507963 -1.6483708 -7.2521278 -10.8169456 -3.1902382]
vel = [0.0 0.00565429 0.00168318 0.00354178 0.0028893 0.00276725
       0.0 -0.0041249 0.00483525 0.00137102 0.00114527 -0.00170702
       0.0 -0.00190589 0.00192462 0.00055029 0.00039677 -0.00136504]
tspan = (0.0, 200_000.0)

const ∑ = sum
const N = 6
@variables t u(t)[1:3, 1:N]
u = collect(u)
D = Differential(t)
potential = -G *
            ∑(
    i -> ∑(j -> (M[i] * M[j]) / √(∑(k -> (u[k, i] - u[k, j])^2, 1:3)), 1:(i - 1)),
    2:N)

eqs = vec(@. D(D(u))) .~ .-ModelingToolkit.gradient(potential, vec(u)) ./ repeat(M, inner = 3)
@named sys = ODESystem(eqs, t)
ss = structural_simplify(sys)
prob = ODEProblem(ss, [vec(u .=> pos); vec(D.(u) .=> vel)], tspan)
sol = solve(prob, Tsit5());

plt = plot()
for i in 1:N
    plot!(plt, sol, idxs = (u[:, i]...,), lab = planets[i])
end
plot!(plt; xlab = "x", ylab = "y", zlab = "z", title = "Outer solar system")