import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using ModelingToolkit, DifferentialEquations, Latexify
using Porta


"""
    We begin with a path of λ(s) in ℂ. λ: ℝ → ℂ
    Then, u_∞ maps this path of vectors in ℂ to a γ₁ path of vectors in ℂ². u_∞: ℂ → ℂ²
    Then, solving uₓ = Au from x = L to L' generates γ₂ paths in ℂ². 
    The end points of which together form a γ₃ path in ℂ².
    And these three types of path in ℂ² project to paths on S³ along which we integrate the connection form ω to calculate the phase. P: ℂ² → S³
    And of course all these paths may then be mapped onto S² by the Hopf map. π: S³ → S² ⊂ ℝ³
    Rupert Way (2008)
"""


modelname = "gamma2"
resolution = (1920, 1080)
segments = 100
frames_number = 720

makefigure() = GLMakie.Figure(resolution = resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=:black, clear=true))

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
eyeposition = GLMakie.Vec3f(cam.eyeposition[]...)
lookat = GLMakie.Vec3f(0, 0, 0)
up = GLMakie.Vec3f(0, 0, 1)
# GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask1.png")


## Load the Natural Earth data

attributespath = "./data/gdp/geometry-attributes.csv"
nodespath = "./data/gdp/geometry-nodes.csv"

countries = loadcountries(attributespath, nodespath)

country_name1 = "United States of America"
country_name2 = "South Africa"
country_name3 = "Iran"
country_name4 = "Turkey"
country_name5 = "Australia"
country_nodes1 = Vector{Vector{Float64}}()
country_nodes2 = Vector{Vector{Float64}}()
country_nodes3 = Vector{Vector{Float64}}()
country_nodes4 = Vector{Vector{Float64}}()
country_nodes5 = Vector{Vector{Float64}}()
for i in 1:length(countries["name"])
    if countries["name"][i] == country_name1
        country_nodes1 = countries["nodes"][i]
        country_nodes1 = convert(Vector{Vector{Float64}}, country_nodes1)
        println(typeof(country_nodes1))
        println(country_name1)
    end
    if countries["name"][i] == country_name2
        country_nodes2 = countries["nodes"][i]
        println(country_name2)
    end
    if countries["name"][i] == country_name3
        country_nodes3 = countries["nodes"][i]
        println(country_name3)
    end
    if countries["name"][i] == country_name4
        country_nodes4 = countries["nodes"][i]
        println(country_name4)
    end
    if countries["name"][i] == country_name5
        country_nodes5 = countries["nodes"][i]
        println(country_name5)
    end
end

α = 0.1
color1 = getcolor(country_nodes1, colorref, α)
color2 = getcolor(country_nodes2, colorref, α)
color3 = getcolor(country_nodes3, colorref, α)
color4 = getcolor(country_nodes4, colorref, α)
color5 = getcolor(country_nodes5, colorref, α)
w1 = [σmap(country_nodes1[i]) for i in eachindex(country_nodes1)]
w2 = [σmap(country_nodes2[i]) for i in eachindex(country_nodes2)]
w3 = [σmap(country_nodes3[i]) for i in eachindex(country_nodes3)]
w4 = [σmap(country_nodes4[i]) for i in eachindex(country_nodes4)]
w5 = [σmap(country_nodes5[i]) for i in eachindex(country_nodes5)]
whirl1 = Whirl(lscene, w1, [0.0 for i in 1:length(w1)], [2π for i in 1:length(w1)], segments, color1, transparency = true)
whirl2 = Whirl(lscene, w2, [0.0 for i in 1:length(w2)], [2π for i in 1:length(w2)], segments, color2, transparency = true)
whirl3 = Whirl(lscene, w3, [0.0 for i in 1:length(w3)], [2π for i in 1:length(w3)], segments, color3, transparency = true)
whirl4 = Whirl(lscene, w4, [0.0 for i in 1:length(w4)], [2π for i in 1:length(w4)], segments, color4, transparency = true)
whirl5 = Whirl(lscene, w5, [0.0 for i in 1:length(w5)], [2π for i in 1:length(w5)], segments, color5, transparency = true)
frame1 = Frame(lscene, x -> G(-π, σmap(x)), segments, basemap_color, transparency = true)

λ₀ = 1 + 0.2 * im
r = 0.8
getλ(s) = λ₀ + r * ℯ^(im * s)
getf(x) = (3 / 2) * sech(x / 2)^2
getA(x, s) = [0 1; getλ(s) + 1 - 2getf(x) + 1 0]


"""
    getu∞(s)

Get the eigenvector corresponding to the most negative eigenvalue when x → ∞.
u_∞: ℂ → ℂ²
"""
getu∞(s) = begin
    x = 100 # x → ∞
    A∞ = getA(x, s)
    μ, ξ = eigen(A∞)
    _, index = findmin(real.(μ))
    ξ[:, index]
end


s = 0
λ = getλ(s)
L = 10.0

# Define our state variables: state(t) = initial condition
@variables t
@variables v(t)[1:4]=vec(normalize(Quaternion(getu∞(s))))
@variables θ(t)=0
@variables f(t)=getf(L)

C = [0 1;λ + 1 - 2f 0]
A = real.(C)
B = imag.(C)

# Define our parameters
@parameters I₄[1:4,1:4]=[1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1] Σ[1:4,1:4]=[A -B; B A] K₃[1:4,1:4]=K(3)

# Define our differential: takes the derivative with respect to `t`
D = Differential(t)

# Define the differential equations
eqs = [D(v[1]) ~ ((I₄ - v * v') * (Σ * v))[1]
        D(v[2]) ~ ((I₄ - v * v') * (Σ * v))[2]
        D(v[3]) ~ ((I₄ - v * v') * (Σ * v))[3]
        D(v[4]) ~ ((I₄ - v * v') * (Σ * v))[4]
        D(θ) ~ -dot(K₃ * v, Σ * v)
        f ~ getf(t)]

latexify(eqs)

# Bring these pieces together into an ODESystem with independent variable t
@named sys = ODESystem(eqs, t)

# Symbolically Simplify the System
simpsys = structural_simplify(sys)

# Convert from a symbolic to a numerical problem to simulate
tspan = (L, -L)
prob = ODEProblem(simpsys, [], tspan)

# Solve the ODE
sol = solve(prob)

samples = length(sol[v])
γ₂ = Vector{Quaternion}(undef, samples)
path_x = Vector{Float64}(undef, samples)
path_y = Vector{Float64}(undef, samples)
path_z = Vector{Float64}(undef, samples)
points = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors = GLMakie.Observable(Int[])
lines = GLMakie.lines!(lscene, points, linewidth = 3.0, color = colors, colormap = :rainbow, transparency = true)
for i in 1:samples
    q = sol[v][i]
    γ₂[i] = Quaternion([q[1] + q[3] * im; q[2] + q[4] * im])
    p = project(γ₂[i])
    path_x[i] = p[1]
    path_y[i] = p[2]
    path_z[i] = p[3]
end


function step!(i, frame)
    push!(points[], GLMakie.Point3f(path_x[i], path_y[i], path_z[i]))
    push!(colors[], frame)
end


GLMakie.record(fig, "$modelname.mp4", 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
    hsv = [progress * 360; 1; 1]
    rgb = convert_hsvtorgb(hsv)

    for i in 1:samples
        step!(i, frame) # update arrays inplace
    end
    α = 0.9
    i = max(1, Int(floor(progress * samples)))
    tail = [GLMakie.Point3f(project(γ₂[i])...)]
    head = [GLMakie.Point3f(project(Quaternion(im .* [γ₂[i].a + im * γ₂[i].c; γ₂[i].b + im * γ₂[i].d]))...)]
    p = project(γ₂[i])
    GLMakie.arrows!(lscene, tail, head, fxaa=true, linecolor = GLMakie.RGBAf(rgb..., α), arrowcolor = GLMakie.RGBAf(rgb..., α), linewidth = 0.01, arrowsize = GLMakie.Vec3f(0.025, 0.025, 0.05), transparency = false)
    GLMakie.meshscatter!([p[1]], [p[2]], [p[3]], markersize = 0.025, color = GLMakie.RGBAf(rgb..., α), transparency = false)
    ps = hopfmap(γ₂[i]) # π: S³ → S² ⊂ ℝ³
    GLMakie.meshscatter!([p[1]], [p[2]], [p[3]], markersize = 0.025, color = GLMakie.RGBAf(rgb..., α), transparency = false)

    update(frame1, x -> G(sol[θ][i], σmap(x)))

    lines.colorrange = (0, frame) # update plot attribute directly
    notify(points); notify(colors) # tell points and colors that their value has been updated
    lookat = GLMakie.Vec3f(p...)
    up = GLMakie.Vec3f(0, 0, 1)
    azimuth = -π / 2 + 0.3 * sin(2π * progress) # set the view angle of the axis
    eyeposition = GLMakie.Vec3f(2 .* convert_to_cartesian([1; azimuth; π / 8])...)
    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
