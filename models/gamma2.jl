import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using ModelingToolkit, DifferentialEquations, Latexify
using Porta


resolution = (1920, 1080)
segments = 90
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

r₀ = 0.0
λ₀ = 0.5 + 0.5 * im
ϕ₀ = 0.0

operator = imag(λ₀) ≥ 0 ? "+" : "-"
version = "r₀=$(r₀)_λ₀=$(float(real(λ₀)))_$(operator)_𝑖$(abs(float(imag(λ₀))))"
modelname = "gamma2_$version"

getλ(s) = λ₀ + r₀ * exp(im * (s + ϕ₀))
getμ(s) = √(getλ(s) + 1)
getf(x) = (3 / 2) * sech(x / 2)^2
getA(x, s) = [0 1; getλ(s) + 1 - 2getf(x) 0]


sqrtᵣ(r::Real, i::Real) = real(√(r + im * i))
sqrtᵢ(r::Real, i::Real) = imag(√(r + im * i))
sqrtᵣ(r::Num, i::Num) = real(√(r + im * i))
sqrtᵢ(r::Num, i::Num) = imag(√(r + im * i))
@register_symbolic sqrtᵣ(r, i)
@register_symbolic sqrtᵢ(r, i)


L = 10.0
L′ = -L


"""
    getγ₂(L, L′)

Get path γ₂ by integating a connection 1-form in the x direction with the given bounds [`L`,`L′`].
Rupert Way (2008)
"""
function getγ₂(L::Float64, L′::Float64)
    s₀ = 0.0
    μ₀ = getμ(s₀)
    u₀ = Quaternion([1.0; -μ₀])
    θ₀ = 0.0
    v₀ = normalize(u₀)
    w₀ = πmap(v₀)
    m₀ = norm(u₀)
    f₀ = getf(L)
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

    simplified_latex = latexify(simpsys)

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
    γ₂, phases, λ, path_s2, s, latex, simplified_latex
end


γ₂, θ₂, λ₂, w₂, t₂, latex, simplified_latex = getγ₂(L, L′)
samples = length(t₂)

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


_hopfmap(q) = begin
    a, b, c, d = vec(q)
    z₁ = a + c * im
    z₂ = b + d * im
    cartesian = convert_to_cartesian(z₂ / z₁)
    geographic = convert_to_geographic(cartesian)
    r, ϕ, _θ = vec(geographic)
    convert_to_cartesian([r; -ϕ; _θ])
end


basepoints = map(x -> project(τmap(_hopfmap(x))), γ₂)
px = [basepoints[i][1] for i in 1:samples] # π: S³ → S² ⊂ ℝ³
py = [basepoints[i][2] for i in 1:samples]
pz = [basepoints[i][3] for i in 1:samples]
rainbowcolors = [GLMakie.RGBAf(convert_hsvtorgb([i / samples * 360; 1; 1])..., 0.5) for i in 1:samples]

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
α = 0.1
boundary_colors = []
boundary_w = []
whirls = []
for i in eachindex(boundary_nodes)
    color = getcolor(boundary_nodes[i], colorref, α)
    push!(boundary_colors, color)
    w = [τmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])]
    push!(boundary_w, w)
    whirl1 = Whirl(lscene, w, [0.0 for _ in 1:length(w)], [2π for _ in 1:length(w)], segments, color, transparency = true)
end

w = [τmap(_hopfmap(γ₂[i])) for i in eachindex(γ₂)]
color = getcolor(_hopfmap.(w), colorref, α)
whirl = Whirl(lscene, w, [0.0 for _ in eachindex(w)], [2π for _ in eachindex(w)], segments, color, transparency = true)
frame1 = Frame(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = true)
frame2 = Frame(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = true)

path_x = Vector{Float64}(undef, samples)
path_y = Vector{Float64}(undef, samples)
path_z = Vector{Float64}(undef, samples)
points = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors = GLMakie.Observable(Int[])
lines = GLMakie.lines!(lscene, points, linewidth = 4.0, color = colors, colormap = :jet, transparency = false)


sub(M::Array{Float64}, i, j) = M[1:end .!= i, 1:end .!= j]
det(a::Array{Float64}) = begin
    if size(a) == (2, 2)
        a[1, 1] * a[2, 2] - a[1, 2] * a[2, 1]
    else
        sum([(-1)^(i+1) * a[i, 1] * det(sub(a, i, 1)) for i in 1:size(a, 1)])
        # performance tip, look for the best row/column choice for expansion.
    end
end
minor(M::Array{Float64}, i, j) = det(sub(M, i, j))
cofactor(M::Array{Float64}, i, j) = minor(M, i, j) * (-1)^(i+j)
"""
cross(r1, r2)

Perform a cross product with the given vectors `r1` and `r2`.
"""
cross(r1::Vector{Float64}, r2::Vector{Float64}) = begin
    M = transpose(reshape([r1; r1; r2], :, length(r1)))
    M = convert(Array{Float64}, M)
    map(x -> cofactor(M, 1, x), 1:length(r1))
end
getrotation(i::Vector{Float64}, n::Vector{Float64}) = begin
    if isapprox(normalize(i), normalize(n))
        return 0, normalize(i)
    end
    u = normalize(cross(i, n))
    ang = acos(dot(normalize(i), normalize(n)))
    ang, u
end


ẑ = [0.0; 0.0; 1.0]


function step2(progress, frame)
    rgb = convert_hsvtorgb([progress * 360; 1; 1])
    rgb1 = convert_hsvtorgb([progress * 360; 0.5; 1.0])
    rgb2 = convert_hsvtorgb([progress * 360; 1.0; 0.5])
    i = max(1, Int(floor(progress * samples)))
    α = 0.1
    markersize = 0.01
    w = _hopfmap(γ₂[i])
    GLMakie.meshscatter!([w[1]], [w[2]], [w[3]], markersize = markersize, color = rainbowcolors[i], transparency = true)
    _basepoints = map(x -> project(G(θ₂[i], τmap(_hopfmap(x)))), γ₂)
    _px = [_basepoints[j][1] for j in 1:i] # π: S³ → S² ⊂ ℝ³
    _py = [_basepoints[j][2] for j in 1:i]
    _pz = [_basepoints[j][3] for j in 1:i]
    GLMakie.meshscatter!(_px, _py, _pz, markersize = markersize, color = rainbowcolors[1:i], transparency = true)
    # p = project(γ₁[i])
    p = G(θ₂[i], τmap(_hopfmap(γ₂[i])))
    p′ = project(p)
    tail = [GLMakie.Point3f(p′...) for _ in 1:3]
    head = [GLMakie.Point3f((p′ + project(K(3) * p))...), GLMakie.Point3f((p′ + project(K(1) * p))...) * 0.5, GLMakie.Point3f((p′ + project(K(2) * p))...) * 0.5]
    linecolor = [GLMakie.RGBAf(rgb..., α), GLMakie.RGBAf(rgb1..., α), GLMakie.RGBAf(rgb2..., α)]
    arrowcolor = [GLMakie.RGBAf(rgb..., α), GLMakie.RGBAf(rgb1..., α), GLMakie.RGBAf(rgb2..., α)]
    GLMakie.arrows!(lscene, tail, head, fxaa=true, linecolor = linecolor, arrowcolor = arrowcolor, linewidth = 0.01, arrowsize = GLMakie.Vec3f(0.02, 0.02, 0.04), transparency = true)
    GLMakie.meshscatter!([p′[1]], [p′[2]], [p′[3]], markersize = markersize, color = GLMakie.RGBAf(rgb..., α), transparency = true)
    update!(frame1, x -> G(θ₂[i], τmap(x)))
    push!(points[], tail[1])
    push!(colors[], frame)

    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(ẑ...), -2(θ₂[i]))
    axis = normalize(project(K(3) * p))
    axis = Float64.([axis[1]; axis[2]; axis[3]])
    rotation_angle, rotation_axis = getrotation(ẑ, axis)
    GLMakie.rotate!(starman_sprite, GLMakie.Vec3f(rotation_axis...), rotation_angle)
    GLMakie.translate!(starman_sprite, GLMakie.Point3f(p′))

    p′
end


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
    distance = π / 2
    _segments = 2
    if progress ≤ 1 / _segments
        _progress = _segments * progress
        p = step2(_progress, frame)
        lines.colorrange = (0, frame) # update plot attribute directly
        notify(points); notify(colors) # tell points and colors that their value has been updated
    end
    if 1 / _segments < progress ≤ 2 / _segments
        p = project(G(θ₂[end], τmap(_hopfmap(γ₂[end]))))
        distance += 1e-2
    end
    
    global lookat = 0.9 * lookat + 0.1 * GLMakie.Vec3f(p...)
    up = GLMakie.Vec3f(0, 0, 1)
    azimuth = -π / 2 + 0.3 * sin(2π * progress) # set the view angle of the axis
    eyeposition = GLMakie.Vec3f(distance .* convert_to_cartesian([1; azimuth; π / 8])...)
    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
