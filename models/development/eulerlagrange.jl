using LinearAlgebra
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using Latexify

const ∑ = sum

@variables x(t) y(t) z(t) θ(t) α(t) β(t) γ(t) δ(t)  # generalized coordinates
@parameters m_w m_c m_r I_w1 I_w2 I_w3 I_c1 I_c2 I_c3 I_r1 I_r2 I_r3 r_w l_c l_cr g # parameters
@parameters λ₁ λ₂ τ_p τ_w
@parameters I_w[1:4, 1:4] I_c[1:4, 1:4] I_r[1:4, 1:4] w2P_w[1:4] cP_c[1:4] rP_r[1:4]
@variables (w2cpT(t))[1:4,1:4] (cpgT(t))[1:4,1:4] (w2gT(t))[1:4,1:4] (cw2T(t))[1:4,1:4] (cgT(t))[1:4,1:4] (rw2T(t))[1:4,1:4] (rcT(t))[1:4,1:4] (rgT(t))[1:4,1:4] 
@variables (gP_w(t))[1:4] (gP_c(t))[1:4] (gP_r(t))[1:4]
@variables (V_w(t))[1:4] (V_c(t))[1:4] (V_r(t))[1:4] (Ω_w(t))[1:4] (Ω_c(t))[1:4] (Ω_r(t))[1:4]
@variables T_w(t) T_c(t) T_r(t) P_w(t) P_c(t) P_r(t)
@variables T_total(t) P_total(t) L(t)
eqs = [I_w ~ [[I_w1; 0.0; 0.0; 0.0] [0.0; I_w2; 0.0; 0.0] [0.0; 0.0; I_w3; 0.0] [0.0; 0.0; 0.0; 0.0]]
       I_c ~ [[I_c1; 0.0; 0.0; 0.0] [0.0; I_c2; 0.0; 0.0] [0.0; 0.0; I_c3; 0.0] [0.0; 0.0; 0.0; 0.0]]
       I_r ~ [[I_r1; 0.0; 0.0; 0.0] [0.0; I_r2; 0.0; 0.0] [0.0; 0.0; I_r3; 0.0] [0.0; 0.0; 0.0; 0.0]]
       D(x) ~ r_w * D(θ) * cos(δ)
       D(y) ~ r_w * D(θ) * sin(δ)
       D(z) ~ 0.0
       w2cpT ~ [[1.0; 0.0; 0.0; 0.0] [0.0; cos(α); sin(α); 0.0] [0.0; -sin(α); cos(α); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; r_w; 1.0]]
       cpgT ~ [[cos(δ); sin(δ); 0.0; 0.0] [-sin(δ); cos(δ); 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [x; y; 0.0; 1.0]]
       w2gT ~ cpgT * w2cpT
       w2P_w ~ [0.0; 0.0; 0.0; 1.0]
       gP_w ~ w2gT * w2P_w
       cw2T ~ [[cos(β); 0.0; -sin(β); 0.0] [0.0; 1.0; 0.0; 0.0] [sin(β); 0.0; cos(β); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_c; 1.0]]
       cgT ~ w2gT * cw2T
       cP_c ~ [0.0; 0.0; 0.0; 1.0]
       gP_c ~ cgT * cP_c
       rcT ~ [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_cr; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; cos(γ); sin(γ); 0.0] [0.0; -sin(γ); cos(γ); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; 0.0; 1.0]]
       rgT ~ cgT * rcT
       rP_r ~ [0.0; 0.0; 0.0; 1.0]
       gP_r ~ rgT * rP_r
       rw2T ~ inv(w2gT) * rgT
       V_w ~ D.(gP_w)
       V_c ~ D.(gP_c)
       V_r ~ D.(gP_r)
       Ω_w ~ [0.0; D(θ); 0.0; 0.0] + [D(α); 0.0; 0.0; 0.0] + inv(w2gT) * [0.0; 0.0; D(δ); 0.0]
       Ω_c ~ [0.0; D(β); 0.0; 0.0] + inv(cw2T) * [D(α); 0.0; 0.0; 0.0] + inv(cgT) * [0.0; 0.0; D(δ); 0.0]
       Ω_r ~ [D(γ); 0.0; 0.0; 0.0] + inv(rcT) * [0.0; D(β); 0.0; 0.0] + inv(rw2T) * [D(α); 0.0; 0.0; 0.0] + inv(rgT) * [0.0; 0.0; D(δ); 0.0]
       T_w ~ 0.5 * m_w * V_w' * V_w + 0.5 * Ω_w' * I_w * Ω_w
       P_w ~ m_w * g * gP_w[3]
       T_c ~ 0.5 * m_c * V_c' * V_c + 0.5 * Ω_c' * I_c * Ω_c
       P_c ~ m_c * g * gP_c[3]
       T_r ~ 0.5 * m_r * V_r' * V_r + 0.5 * Ω_r' * I_r * Ω_r
       P_r ~ m_r * g * gP_r[3]
       T_total ~ T_w + T_c + T_r
       P_total ~ P_w + P_c + P_r
       L ~ T_total - P_total
       D.(ModelingToolkit.gradient(L, [D(x); D(y); D(θ); D(α); D(β); D(γ); D(δ)])) ~ ModelingToolkit.gradient(L, [x; y; θ; α; β; γ; δ]) + [λ₁; λ₂; τ_w - r_w * cos(δ) * λ₁ - r_w * sin(δ) * λ₂; -τ_w; 0.0; τ_p; 0.0]] # create an array of equations

@named model = ODESystem(eqs, t)

# Perform the standard transformations and mark the model complete
# Note: Complete models cannot be subsystems of other models!
fol_model = structural_simplify(model)

# @latexrecipe function f(x::Differential)
#        return Expr(:latexifymerge, "D")
# end

latex_model = latexify(L)

# save the latex file for publishing
fname = "foobar.jmd"
dirpath = "/tmp"
fpath = joinpath(dirpath, fname)

open(fpath, "w") do file
    write(file, latex_model)
end



I_w = [[I_w1; 0.0; 0.0; 0.0] [0.0; I_w2; 0.0; 0.0] [0.0; 0.0; I_w3; 0.0] [0.0; 0.0; 0.0; 0.0]]
I_c = [[I_c1; 0.0; 0.0; 0.0] [0.0; I_c2; 0.0; 0.0] [0.0; 0.0; I_c3; 0.0] [0.0; 0.0; 0.0; 0.0]]
I_r = [[I_r1; 0.0; 0.0; 0.0] [0.0; I_r2; 0.0; 0.0] [0.0; 0.0; I_r3; 0.0] [0.0; 0.0; 0.0; 0.0]]
# _I_w = substitute(I_w, Dict([I_w1 => 0.1, I_w2 => 0.2, I_w3 => 0.3]))
# _I_c = substitute(I_c, Dict([I_c1 => 0.1, I_c2 => 0.2, I_c3 => 0.3]))
# _I_r = substitute(I_r, Dict([I_r1 => 0.1, I_r2 => 0.2, I_r3 => 0.3]))
D(x) = r_w * D(θ) * cos(δ)
D(y) = r_w * D(θ) * sin(δ)
D(z) = 0.0
w2cpT = [[1.0; 0.0; 0.0; 0.0] [0.0; cos(α); sin(α); 0.0] [0.0; -sin(α); cos(α); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; r_w; 1.0]]
cpgT = [[cos(δ); sin(δ); 0.0; 0.0] [-sin(δ); cos(δ); 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [x; y; 0.0; 1.0]]
w2gT = cpgT * w2cpT
w2P_w = [0.0; 0.0; 0.0; 1.0]
gP_w = w2gT * w2P_w
cw2T = [[cos(β); 0.0; -sin(β); 0.0] [0.0; 1.0; 0.0; 0.0] [sin(β); 0.0; cos(β); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_c; 1.0]]
cgT = w2gT * cw2T
cP_c = [0.0; 0.0; 0.0; 1.0]
gP_c = cgT * cP_c
rcT = [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_cr; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; cos(γ); sin(γ); 0.0] [0.0; -sin(γ); cos(γ); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; 0.0; 1.0]]
rgT = cgT * rcT
rP_r = [0.0; 0.0; 0.0; 1.0]
gP_r = rgT * rP_r
rw2T = inv(w2gT) * rgT
V_w = D.(gP_w)
V_c = D.(gP_c)
V_r = D.(gP_r)
Ω_w = [0.0; D(θ); 0.0; 0.0] + [D(α); 0.0; 0.0; 0.0] + inv(w2gT) * [0.0; 0.0; D(δ); 0.0]
Ω_c = [0.0; D(β); 0.0; 0.0] + inv(cw2T) * [D(α); 0.0; 0.0; 0.0] + inv(cgT) * [0.0; 0.0; D(δ); 0.0]
Ω_r = [D(γ); 0.0; 0.0; 0.0] + inv(rcT) * [0.0; D(β); 0.0; 0.0] + inv(rw2T) * [D(α); 0.0; 0.0; 0.0] + inv(rgT) * [0.0; 0.0; D(δ); 0.0]
T_w = 0.5 * m_w * V_w' * V_w + 0.5 * Ω_w' * I_w * Ω_w
P_w = m_w * g * gP_w[3]
T_c = 0.5 * m_c * V_c' * V_c + 0.5 * Ω_c' * I_c * Ω_c
P_c = m_c * g * gP_c[3]
T_r = 0.5 * m_r * V_r' * V_r + 0.5 * Ω_r' * I_r * Ω_r
P_r = m_r * g * gP_r[3]
T_total = T_w + T_c + T_r
P_total = P_w + P_c + P_r
L = T_total - P_total
D.(ModelingToolkit.gradient(L, [D(x); D(y); D(θ); D(α); D(β); D(γ); D(δ)])) = ModelingToolkit.gradient(L, [x; y; θ; α; β; γ; δ]) + [λ₁; λ₂; τ_w - r_w * cos(δ) * λ₁ - r_w * sin(δ) * λ₂; -τ_w; 0.0; τ_p; 0.0]

