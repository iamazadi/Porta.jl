import LinearAlgebra
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using Latexify

@variables x(t) y(t) z(t) θ(t) α(t) β(t) γ(t) δ(t)  # independent and dependent variables
@parameters m_w m_c m_r I_w1 I_w2 I_w3 I_c1 I_c2 I_c3 I_r1 I_r2 I_r3 r_w l_c l_cr g # parameters
@parameters I_w[1:4, 1:4] I_c[1:4, 1:4] I_r[1:4, 1:4] r_P_r[1:4] w2_P_w[1:4] c_P_c[1:4]
@variables (w2_cp_T(t))[1:4,1:4] (cp_g_T(t))[1:4,1:4] (w2_g_T(t))[1:4,1:4] (c_w2_T(t))[1:4,1:4] (c_g_T(t))[1:4,1:4] (r_w2_T(t))[1:4,1:4] (r_c_T(t))[1:4,1:4] (r_g_T(t))[1:4,1:4] 
@variables (g_P_w(t))[1:4] (g_P_c(t))[1:4] (g_P_r(t))[1:4]
@variables L(t) T_total(t) P_total(t) (V_w(t))[1:4] (V_c(t))[1:4]  (V_r(t))[1:4]  (Ω_w(t))[1:4]  (Ω_c(t))[1:4]  (Ω_r(t))[1:4]
@variables T_w(t) T_c(t) T_r(t) P_w(t) P_c(t) P_r(t)
@constants h = 1    # constants
eqs = [I_w ~ [[I_w1; 0.0; 0.0; 0.0] [0.0; I_w2; 0.0; 0.0] [0.0; 0.0; I_w3; 0.0] [0.0; 0.0; 0.0; 0.0]]
       I_c ~ [[I_c1; 0.0; 0.0; 0.0] [0.0; I_c2; 0.0; 0.0] [0.0; 0.0; I_c3; 0.0] [0.0; 0.0; 0.0; 0.0]]
       I_r ~ [[I_r1; 0.0; 0.0; 0.0] [0.0; I_r2; 0.0; 0.0] [0.0; 0.0; I_r3; 0.0] [0.0; 0.0; 0.0; 0.0]]
       D(x) ~ r_w * D(θ) * cos(δ)
       D(y) ~ r_w * D(θ) * sin(δ)
       D(z) ~ 0.0
       w2_cp_T ~ [[1.0; 0.0; 0.0; 0.0] [0.0; cos(α); sin(α); 0.0] [0.0; -sin(α); cos(α); 0.0] [0.0; 0.0; 0.0; 1.0]] *
                 [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; r_w; 1.0]]
       cp_g_T ~ [[cos(δ); sin(δ); 0.0; 0.0] [-sin(δ); cos(δ); 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [x; y; 0.0; 1.0]]
       w2_g_T ~ cp_g_T * w2_cp_T
       w2_P_w ~ [0.0; 0.0; 0.0; 1.0]
       g_P_w ~ w2_g_T * w2_P_w
       c_w2_T ~ [[cos(β); 0.0; -sin(β); 0.0] [0.0; 1.0; 0.0; 0.0] [sin(β); 0.0; cos(β); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_c; 1.0]]
       c_g_T ~ w2_g_T * c_w2_T
       c_P_c ~ [0.0; 0.0; 0.0; 1.0]
       g_P_c ~ c_g_T * c_P_c
       r_c_T ~ [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; l_cr; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; cos(γ); sin(γ); 0.0] [0.0; -sin(γ); cos(γ); 0.0] [0.0; 0.0; 0.0; 1.0]] * [[1.0; 0.0; 0.0; 0.0] [0.0; 1.0; 0.0; 0.0] [0.0; 0.0; 1.0; 0.0] [0.0; 0.0; 0.0; 1.0]]
       r_g_T ~ c_g_T * r_c_T
       r_P_r ~ [0.0; 0.0; 0.0; 1.0]
       g_P_r ~ r_g_T * r_P_r
       r_w2_T ~ LinearAlgebra.inv(w2_g_T) * r_g_T
       V_w ~ D(g_P_w)
       V_c ~ D(g_P_c)
       V_r ~ D(g_P_r)
       Ω_w ~ [0.0; D(θ); 0.0; 0.0] + [D(α); 0.0; 0.0; 0.0] + LinearAlgebra.inv(w2_g_T) * [0.0; 0.0; D(δ); 0.0]
       Ω_c ~ [0.0; D(β); 0.0; 0.0] + LinearAlgebra.inv(c_w2_T) * [D(α); 0.0; 0.0; 0.0] + LinearAlgebra.inv(c_g_T) * [0.0; 0.0; D(δ); 0.0]
       Ω_r ~ [D(γ); 0.0; 0.0; 0.0] + LinearAlgebra.inv(r_c_T) * [0.0; D(β); 0.0; 0.0] + LinearAlgebra.inv(r_w2_T) * [D(α); 0.0; 0.0; 0.0] + LinearAlgebra.inv(r_g_T) * [0.0; 0.0; D(δ); 0.0]
       T_w ~ 0.5 * m_w * V_w' * V_w + 0.5 * Ω_w' * I_w * Ω_w
       P_w ~ m_w * g * g_P_w[3]
       T_c ~ 0.5 * m_c * V_c' * V_c + 0.5 * Ω_c' * I_c * Ω_c
       P_c ~ m_c * g * g_P_c[3]
       T_r ~ 0.5 * m_r * V_r' * V_r + 0.5 * Ω_r' * I_r * Ω_r
       P_r ~ m_r * g * g_P_r[3]
       T_total ~ T_w + T_c + T_r
       P_total ~ P_w + P_c + P_r
       L ~ T_total - P_total] # create an array of equations

# your first ODE, consisting of a single equation, indicated by ~
@named model = ODESystem(eqs, t)

# Perform the standard transformations and mark the model complete
# Note: Complete models cannot be subsystems of other models!
fol_model = structural_simplify(model)

latex_model = latexify(fol_model)

fname = "foobar.jmd"
dirpath = "/tmp"
fpath = joinpath(dirpath, fname)

open(fpath, "w") do file
    write(file, latex_model)
end