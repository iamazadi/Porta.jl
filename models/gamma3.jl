import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using ModelingToolkit, DifferentialEquations, Latexify
using Porta


resolution = (1920, 1080)
segments = 180
frames_number = 360

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

r₀ = 0.8 # radius of lambda path circle
λ₀ = 1.0 + 0.2 * im # center of lambda path circle
ϕ₀ = 0.0

operator = imag(λ₀) ≥ 0 ? "+" : "-"
version = "r₀=$(r₀)_λ₀=$(float(real(λ₀)))_$(operator)_𝑖$(abs(float(imag(λ₀))))"
modelname = "gamma3_$version"
L = 10.0 # max x range
L′ = -L
ẑ = [0.0; 0.0; 1.0]
α = 0.05
markersize = 0.04
linewidth = 8.0
arrowsize = GLMakie.Vec3f(0.02, 0.02, 0.04)

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
           D(θ) ~ imag(u' * uₗ * (λₛᵣ + λₛᵢ * im)) / (u' * u)]
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
    λ = convert_to_cartesian(sol[λᵣ] + im * sol[λᵢ])
    γ₂, u₂, phases, λ, path_s2, s, latex
end


get_u(L::Float64, L′::Float64, s::Float64) = vec(getγ₂(L, L′, s)[2][end])
get_u(L::Float64, L′::Float64, s::Num) = get_u(L, L′, s)
get_u(L::Float64, L′::Float64, s::SymbolicUtils.BasicSymbolic{Real}) = get_u(L, L′, s)
@register_symbolic get_u(L::Float64, L′::Float64, s::Num)::Vector{Float64}
@register_symbolic get_u(L::Float64, L′::Float64, s::SymbolicUtils.BasicSymbolic{Real})::Vector{Float64}


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
    @parameters K₃[1:4,1:4]=K(3) δ=(2π / 10000)
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
γ₃, θ₃, s2_path₃, t₃, latex3 = getγ₃(L, L′)

makefigure() = GLMakie.Figure(resolution = resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=true, scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=:black, clear=true))

starman = FileIO.load("data/Starman_3.stl")
starman_sprite = GLMakie.mesh!(
    lscene,
    starman,
    color = [tri[1][2] for tri in starman for i in 1:3],
    colormap = GLMakie.Reverse(:Spectral)
)
scale = 1 / 400
GLMakie.scale!(starman_sprite, scale, scale, scale)

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
# eyeposition = GLMakie.Vec3f(cam.eyeposition[]...)
eyeposition = GLMakie.Vec3f(1, 1, 1)
lookat = GLMakie.Vec3f(0, 0, 0)
up = GLMakie.Vec3f(0, 0, 1)
GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask1.png")
## Load the Natural Earth data
attributespath = "./data/gdp/geometry-attributes.csv"
nodespath = "./data/gdp/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = ["United States of America", "South Africa", "Iran", "Turkey", "Australia", "New Zealand"]
boundary_nodes = Vector{Vector{Vector{Float64}}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
        end
    end
end
boundary_colors = []
boundary_w = []
for i in eachindex(boundary_nodes)
    color = getcolor(boundary_nodes[i], colorref, α)
    push!(boundary_colors, color)
    w = [τmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])]
    push!(boundary_w, w)
    whirl1 = Whirl(lscene, w, [float(π) for _ in 1:length(w)], [0.0 for _ in 1:length(w)], segments, color, transparency = true)
end
# Whirl(lscene, γ₁, [0.0 for _ in γ₁], [2π for _ in γ₁], segments, getcolor(πmap.(γ₁), colorref, α), transparency = true)
# whirl = Whirl(lscene, γ₃, [0.0 for i in γ₃], [2π for _ in γ₃], segments, getcolor(πmap.(γ₃), colorref, α), transparency = true)
# whirls = []
# for i in 1:steps_number
#     c = GLMakie.RGBAf(convert_hsvtorgb([i / steps_number * 360; 1; 1])..., α)
#     whirl = Whirl(lscene, γ₂[i], [0.0 for i in γ₂[i]], [θ₂[i][begin] for _ in γ₂[i]], segments, c, transparency = true)
#     push!(whirls, whirl)
# end
# w = map(x -> x[end], γ₂)
# Whirl(lscene, w, [0.0 for _ in w], [2π for _ in w], segments, getcolor(πmap.(w), colorref, 0.1), transparency = true)
basemap1 = Basemap(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = true)
basemap2 = Basemap(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = true)
basemap3 = Basemap(lscene, x -> G(π, τmap(x)), segments, basemap_color, transparency = true)
points1 = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors1 = GLMakie.Observable(Int[])
lines1 = GLMakie.lines!(lscene, points1, linewidth = linewidth, color = colors1, colormap = :jet, transparency = false)
points2 = [GLMakie.Observable(GLMakie.Point3f[]) for _ in 1:steps_number]
colors2 = [GLMakie.Observable(Int[]) for _ in 1:steps_number]
lines2 = [GLMakie.lines!(lscene, points2[i], linewidth = linewidth, color = colors2[i], colormap = :jet, transparency = false) for i in 1:steps_number]
points3 = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors3 = GLMakie.Observable(Int[])
lines3 = GLMakie.lines!(lscene, points3, linewidth = 3linewidth, color = colors3, colormap = :plasma, transparency = false)
memo1 = []
memo2 = [[] for _ in 1:steps_number]
memo3 = []

function step1(progress)
    i = max(1, Int(floor(progress * steps_number)))
    p = project(γ₁[i])
    if i ∈ memo1
        return p
    else
        push!(memo1, i)
    end
    rainbowcolors = [GLMakie.RGBAf(convert_hsvtorgb([i / steps_number * 360; 1; 1])..., α) for i in 1:steps_number]
    color1 = GLMakie.RGBAf(convert_hsvtorgb([progress * 360; 1; 1])..., 0.9)
    red, green, blue = GLMakie.RGBAf(1, 0, 0, 1), GLMakie.RGBAf(0, 1, 0, 1), GLMakie.RGBAf(0, 0, 1, 1)
    linecolor = [red, green, blue]
    arrowcolor = [red, green, blue]
    w = πmap(γ₁[i])
    GLMakie.meshscatter!([w[1]], [w[2]], [w[3]], markersize = 2markersize, color = rainbowcolors[i], transparency = true)
    basepoints = map(x -> project(x), γ₁)
    px = [basepoints[j][1] for j in 1:i]
    py = [basepoints[j][2] for j in 1:i]
    pz = [basepoints[j][3] for j in 1:i]
    GLMakie.meshscatter!(px, py, pz, markersize = markersize, color = rainbowcolors[1:i], transparency = true)
    tail = [GLMakie.Point3f(p...) for _ in 1:3]
    head = [GLMakie.Point3f(project(K(3) * γ₁[i])) * 0.2, GLMakie.Point3f(project(K(1) * γ₁[i])) * 0.2, GLMakie.Point3f(project(K(2) * γ₁[i])) * 0.2]
    GLMakie.arrows!(lscene, tail, head, fxaa=true, linecolor = linecolor, arrowcolor = arrowcolor, linewidth = 0.01, arrowsize = arrowsize, transparency = true)
    GLMakie.meshscatter!([p[1]], [p[2]], [p[3]], markersize = markersize, color = color1, transparency = true)
    update!(basemap1, x -> G(θ₁[i], τmap(x)))
    push!(points1[], tail[1])
    frame = max(1, Int(floor(progress * frames_number)))
    push!(colors1[], frame)
    lines1.colorrange = (0, frame) # update plot attribute directly
    notify(points1); notify(colors1) # tell points and colors that their value has been updated
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(ẑ), θ₁[i])
    axis = Float64.(normalize(project(K(3) * γ₁[i])))
    rotation_angle, rotation_axis = getrotation(ẑ, axis)
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(rotation_axis), rotation_angle)
    GLMakie.translate!(starman_sprite, GLMakie.Point3f(p))
    # update!(whirl, color1)
    p
end


function step2(progress)
    p = [0.0; 0.0; 0.0]
    N = 0
    phase = 0.0
    for i in 1:steps_number
        _samples = length(γ₂[i])
        j = max(1, Int(floor(progress * _samples)))
        _p = project(γ₂[i][j])
        N += 1
        p += _p
        phase += θ₂[i][j]
        if j ∈ memo2[i]
            continue
        else
            push!(memo2[i], j)
        end
        push!(points2[i][], _p)
        frame = max(1, Int(floor(progress * frames_number)))
        push!(colors2[i][], frame)
        lines2[i].colorrange = (0, frame) # update plot attribute directly
        notify(points2[i]); notify(colors2[i]) # tell points and colors that their value has been updated
        # update!(whirls[i], γ₂[i], [0.0 for _ in 1:_samples] ,[-θ₂[i][j] for _ in 1:_samples])
        # c = GLMakie.RGBAf(convert_hsvtorgb([i * steps_number * 360; 1; 1])..., α / 2)
        # update!(whirls[i], c)
    end
    update!(basemap1, x -> G(θ₂[end][end], τmap(x)))
    i = max(1, Int(floor(progress * length(γ₂[end]))))
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(ẑ), θ₂[end][i])
    axis = Float64.(normalize(project(K(3) * γ₂[end][i])))
    rotation_angle, rotation_axis = getrotation(ẑ, axis)
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(rotation_axis), rotation_angle)
    GLMakie.translate!(starman_sprite, GLMakie.Point3f(project(γ₂[end][i])))
    p ./ N
end


function step3(progress)
    α = 0.9
    i = max(1, Int(floor(progress * length(γ₃))))
    p = project(γ₃[i])
    if i ∈ memo3
        return p
    else
        push!(memo3, i)
    end
    w = πmap(γ₃[i])
    rainbowcolors = [GLMakie.RGBAf(convert_hsvtorgb([i / length(γ₃) * 360; 1; 1])..., α) for i in 1:length(γ₃)]
    GLMakie.meshscatter!([w[1]], [w[2]], [w[3]], markersize = 2markersize, color = rainbowcolors[i], transparency = true)
    push!(points3[], p)
    frame = max(1, Int(floor(progress * frames_number)))
    push!(colors3[], frame)
    lines3.colorrange = (0, frame) # update plot attribute directly
    notify(points3); notify(colors3) # tell points and colors that their value has been updated
    color1 = GLMakie.RGBAf(convert_hsvtorgb([progress * 360; 1; 1])..., α)
    red, green, blue = GLMakie.RGBAf(1, 0, 0, 1), GLMakie.RGBAf(0, 1, 0, 1), GLMakie.RGBAf(0, 0, 1, 1)
    linecolor = [red, green, blue]
    arrowcolor = [red, green, blue]
    tail = [GLMakie.Point3f(p...) for _ in 1:3]
    head = [GLMakie.Point3f(project(K(3) * γ₃[i])), GLMakie.Point3f(project(K(1) * γ₃[i])), GLMakie.Point3f(project(K(2) * γ₃[i]))]
    GLMakie.arrows!(lscene, tail, head, fxaa=true, linecolor = linecolor, arrowcolor = arrowcolor, linewidth = 0.01, arrowsize = arrowsize, transparency = false)
    GLMakie.meshscatter!([p[1]], [p[2]], [p[3]], markersize = markersize, color = color1, transparency = false)
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(ẑ), θ₃[i])
    axis = Float64.(normalize(project(K(3) * γ₃[i])))
    rotation_angle, rotation_axis = getrotation(ẑ, axis)
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(rotation_axis), rotation_angle)
    GLMakie.translate!(starman_sprite, GLMakie.Point3f(project(γ₃[i])))
    update!(basemap1, x -> G(θ₃[i], τmap(x)))
    p
end


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
    distance = 2π / 3
    _segments = 4
    if progress ≤ 1 / _segments
        _progress = _segments * progress
        p = step1(_progress)
    end
    if 1 / _segments < progress ≤ 2 / _segments
        _progress = _segments * (progress - 1 / _segments)
        p = step2(_progress)
    end
    if 2 / _segments < progress ≤ 3 / _segments
        _progress = _segments * (progress - 2 / _segments)
        p = step3(_progress)
    end
    if 3 / _segments < progress ≤ 4 / _segments
        _progress = _segments * (progress - 3 / _segments)
        i = max(1, Int(floor(_progress * steps_number)))
        p = project(γ₃[end])
        distance += 1e-2
    end
    
    global lookat = 0.9 * lookat + 0.1 * GLMakie.Vec3f(p...)
    up = GLMakie.Vec3f(0, 0, 1)
    azimuth = π + π / 4 + 0.3 * sin(2π * progress) # set the view angle of the axis
    eyeposition = GLMakie.Vec3f(distance .* convert_to_cartesian([1; azimuth; π / 6])...)
    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
