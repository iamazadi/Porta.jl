import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using ModelingToolkit, DifferentialEquations, Latexify
using Porta


resolution = (1920, 1080)
segments = 60
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

r₀ = r₁
λ₀ = λ₂
ϕ₀ = 0.0

operator = imag(λ₀) ≥ 0 ? "+" : "-"
version = "r₀=$(r₀)_λ₀=$(float(real(λ₀)))_$(operator)_𝑖$(abs(float(imag(λ₀))))"
modelname = "gamma3_$version"
L = 10.0
L′ = -L
ẑ = [0.0; 0.0; 1.0]
α = 0.1
markersize = 0.01
linewidth = 5.0
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
    phases = Vector{Float64}(undef, samples)
    s = Vector{Float64}(undef, samples)
    path_s2 = Vector{Vector{Float64}}(undef, samples)
    for i in 1:samples
        γ₂[i] = Quaternion(sol[v][i])
        phases[i] = sol[θ][i]
        s[i] = sol[t][i]
        path_s2[i] = sol[w][i]
    end
    λ = convert_to_cartesian(sol[λᵣ] + im * sol[λᵢ])
    γ₂, phases, λ, path_s2, s, latex
end


"""
    getγ₃(L, L′)

Get path γ₃ with the given integration interval [`L`,`L′`], which defaults to (0, 2π].
Rupert Way (2008)
"""
function getγ₃(L::Float64 = 0.0, L′::Float64 = 2π)
    u₀ = get_u_L′_λ_s(L, L′, L)
    v₀ = vec(u₀)
    # Define our state variables: state(t) = initial condition
    @variables t
    @variables u1(t)=v₀[1] u2(t)=v₀[2] u3(t)=v₀[3] u4(t)=v₀[4]
    @variables w1(t)=v₀[1] w2(t)=v₀[2] w3(t)=v₀[3] w4(t)=v₀[4]
    @variables v(t)[1:4]=v₀
    @variables θ(t)=0
    @variables vhat(t)[1:4]=v₀
    @variables vdot(t)[1:4]=vec(Quaternion(im .* [u₀.a + im * u₀.c; u₀.b + im * u₀.d]))

    # Define our parameters
    @parameters K₃[1:4,1:4]=K(3) δ=(2π / 100000000)

    # Define our differential: takes the derivative with respect to `t`
    D = Differential(t)

    # Define the differential equations
    eqs = [u1 ~ get_u_L′_λ_s1(L, L′, t + δ)
           u2 ~ get_u_L′_λ_s2(L, L′, t + δ)
           u3 ~ get_u_L′_λ_s3(L, L′, t + δ)
           u4 ~ get_u_L′_λ_s4(L, L′, t + δ)
           w1 ~ get_u_L′_λ_s1(L, L′, t - δ)
           w2 ~ get_u_L′_λ_s2(L, L′, t - δ)
           w3 ~ get_u_L′_λ_s3(L, L′, t - δ)
           w4 ~ get_u_L′_λ_s4(L, L′, t - δ)
           D(v[1]) ~ (u1 - w1) / 2δ
           D(v[2]) ~ (u2 - w2) / 2δ
           D(v[3]) ~ (u3 - w3) / 2δ
           D(v[4]) ~ (u4 - w4) / 2δ
           vhat[1] ~ normalize1(v...)
           vhat[2] ~ normalize2(v...)
           vhat[3] ~ normalize3(v...)
           vhat[4] ~ normalize4(v...)
           vdot[1] ~ normalize1(D(v[1]), D(v[2]), D(v[3]), D(v[4])) 
           vdot[2] ~ normalize2(D(v[1]), D(v[2]), D(v[3]), D(v[4])) 
           vdot[3] ~ normalize3(D(v[1]), D(v[2]), D(v[3]), D(v[4])) 
           vdot[4] ~ normalize4(D(v[1]), D(v[2]), D(v[3]), D(v[4])) 
           D(θ) ~ -dot(K₃ * vhat, vdot)]

    # latexify(eqs)

    # Bring these pieces together into an ODESystem with independent variable t
    @named sys = ODESystem(eqs, t)

    # Symbolically Simplify the System
    simpsys = structural_simplify(sys)

    latexify(simpsys)

    # Convert from a symbolic to a numerical problem to simulate
    tspan = (0, 2π)
    prob = ODEProblem(simpsys, [], tspan)

    # Solve the ODE
    sol = solve(prob)
    samples = length(sol[v])
    γ₃ = Vector{Quaternion}(undef, samples)
    phases = Vector{Float64}(undef, samples)
    s = Vector{Float64}(undef, samples)
    for i in 1:samples
        γ₃[i] = Quaternion(sol[v][i])
        phases[i] = sol[θ][i]
        s[i] = sol[t][i]
    end
    γ₃, phases, s
end


γ₁, θ₁, λ₁, w₁, t₁, latex1 = getγ₁(0.0, 2π)
samples1 = length(t₁)
steps_number = samples1
γ₂ = Vector{Vector{Quaternion}}(undef, steps_number)
θ₂ = Vector{Vector{Float64}}(undef, steps_number)
λ_array = []
for i in 1:steps_number
    s₀ = t₁[i]
    _γ, _θ, _λ, _w, _t, _latex = getγ₂(L, L′, s₀)
    push!(λ_array, _λ)
    γ₂[i] = _γ
    θ₂[i] = _θ
end

makefigure() = GLMakie.Figure(resolution = resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=true, scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=:black, clear=true))

starman = FileIO.load("data/SpaceX_s_Starman_desk_toy_2804270/files/Starman_3.stl")
starman_sprite = GLMakie.mesh!(
    lscene,
    starman,
    color = [tri[1][2] for tri in starman for i in 1:3],
    colormap = GLMakie.Reverse(:Spectral)
)
scale = 1 / 600
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
    whirl1 = Whirl(lscene, w, [0.0 for _ in 1:length(w)], [2π for _ in 1:length(w)], segments, color, transparency = true)
end
Whirl(lscene, γ₁, [0.0 for _ in eachindex(γ₁)], [2π for _ in eachindex(γ₁)], segments, getcolor(πmap.(γ₁), colorref, α), transparency = true)
whirls = []
for i in 1:steps_number
    whirl = Whirl(lscene, γ₂[i], [0.0 for _ in eachindex(γ₂[i])], [0.0001 for _ in eachindex(γ₂[i])], segments, getcolor(πmap.(γ₂[i]), colorref, α), transparency = true)
    push!(whirls, whirl)
end
basemap1 = Basemap(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = true)
basemap2 = Basemap(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = true)
points1 = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors1 = GLMakie.Observable(Int[])
lines1 = GLMakie.lines!(lscene, points1, linewidth = linewidth, color = colors1, colormap = :jet, transparency = true)
points2 = [GLMakie.Observable(GLMakie.Point3f[]) for _ in 1:steps_number]
colors2 = [GLMakie.Observable(Int[]) for _ in 1:steps_number]
lines2 = [GLMakie.lines!(lscene, points2[i], linewidth = linewidth, color = colors2[i], colormap = :jet, transparency = true) for i in 1:steps_number]
points3 = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors3 = GLMakie.Observable(Int[])
lines3 = GLMakie.lines!(lscene, points3, linewidth = 3linewidth, color = colors3, colormap = :plasma, transparency = false)
memo1 = []
memo2 = [[] for _ in 1:steps_number]
memo3 = []

function step1(progress)
    i = max(1, Int(floor(progress * samples1)))
    p = project(γ₁[i])
    if i ∈ memo1
        return p
    else
        push!(memo1, i)
    end
    rainbowcolors = [GLMakie.RGBAf(convert_hsvtorgb([i / samples1 * 360; 1; 1])..., α) for i in 1:samples1]
    color1 = GLMakie.RGBAf(convert_hsvtorgb([progress * 360; 1; 1])..., α)
    color2 = GLMakie.RGBAf(convert_hsvtorgb([progress * 360; 0.5; 0.5])..., α)
    color3 = GLMakie.RGBAf(convert_hsvtorgb([progress * 360; 0.25; 0.25])..., α)
    linecolor = [color1, color2, color3]
    arrowcolor = [color1, color2, color3]
    w = πmap(γ₁[i])
    GLMakie.meshscatter!([w[1]], [w[2]], [w[3]], markersize = 2markersize, color = rainbowcolors[i], transparency = true)
    basepoints = map(x -> project(x), γ₁)
    px = [basepoints[j][1] for j in 1:i]
    py = [basepoints[j][2] for j in 1:i]
    pz = [basepoints[j][3] for j in 1:i]
    GLMakie.meshscatter!(px, py, pz, markersize = markersize, color = rainbowcolors[1:i], transparency = true)
    tail = [GLMakie.Point3f(p...) for _ in 1:3]
    head = [GLMakie.Point3f(p + project(K(3) * γ₁[i])), GLMakie.Point3f(p + project(K(1) * γ₁[i])) * 0.5, GLMakie.Point3f(p + project(K(2) * γ₁[i])) * 0.5]
    GLMakie.arrows!(lscene, tail, head, fxaa=true, linecolor = linecolor, arrowcolor = arrowcolor, linewidth = 0.01, arrowsize = arrowsize, transparency = true)
    GLMakie.meshscatter!([p[1]], [p[2]], [p[3]], markersize = markersize, color = color1, transparency = true)
    update!(basemap1, x -> G(θ₁[i], τmap(x)))
    push!(points1[], tail[1])
    frame = max(1, Int(floor(progress * frames_number)))
    push!(colors1[], frame)
    lines1.colorrange = (0, frame) # update plot attribute directly
    notify(points1); notify(colors1) # tell points and colors that their value has been updated
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(ẑ), -2(θ₁[i]))
    axis = Float64.(normalize(project(K(3) * γ₁[i])))
    rotation_angle, rotation_axis = getrotation(ẑ, axis)
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(rotation_axis), rotation_angle)
    GLMakie.translate!(starman_sprite, GLMakie.Point3f(p))
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
        update!(whirls[i], γ₂[i], [0.0 for _ in 1:_samples] ,[θ₂[i][j] for _ in 1:_samples])
    end
    phase = phase / N
    update!(basemap1, x -> G(phase, τmap(x)))
    p ./ N
end

function step3(progress)
    i = max(1, Int(floor(progress * steps_number)))
    p = project(γ₂[i][end])
    if i ∈ memo3
        return p
    else
        push!(memo3, i)
    end
    push!(points3[], p)
    frame = max(1, Int(floor(progress * frames_number)))
    push!(colors3[], frame)
    lines3.colorrange = (0, frame) # update plot attribute directly
    notify(points3); notify(colors3) # tell points and colors that their value has been updated
    update!(basemap1, x -> G(θ₂[i][end], τmap(x)))
    p
end


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
    distance = π / 2
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
        p = project(γ₂[i][end])
        distance += 1e-2
    end
    
    global lookat = 0.9 * lookat + 0.1 * GLMakie.Vec3f(p...)
    up = GLMakie.Vec3f(0, 0, 1)
    azimuth = -π / 2 + 0.3 * sin(2π * progress) # set the view angle of the axis
    eyeposition = GLMakie.Vec3f(distance .* convert_to_cartesian([1; azimuth; π / 7])...)
    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
