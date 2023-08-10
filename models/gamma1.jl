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


resolution = (1920, 1080)
segments = 120
frames_number = 240

r₁ = 0.8
λ₁ = 1 + 0.2 * im # experiment 1
λ₂ = im # experiment 2
λ₃ = 2 + im # experiment 3
λ₄ = 0 # experiment 4
λ₅ = 1 # experiment 5
λ₆ = -im # experiment 6

r₇ = 0.5
λ₇ = -im # experiment 7

r₈ = 0.8
λ₈ = 2 - im # experiment 8

λ₀ = λ₂
r = r₁

version = "r=$(r)_λ₀=$(real(λ₀))+𝑖$(imag(λ₀))"
modelname = "gamma1_$version"

getλ(s) = λ₀ + r * exp(im * s)
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


L = 10.0
L′ = -L
C₀ = [0 1; getλ(L) + 1 - 2getf(L) 0]
A₀ = real.(C₀)
B₀ = imag.(C₀)
v₀ = vec(normalize(Quaternion(getu∞(L))))

# Define our state variables: state(t) = initial condition
@variables t
@variables λᵣ(t)=real(getλ(L))
@variables λᵢ(t)=imag(getλ(L))
@variables v(t)[1:4]=v₀
@variables θ(t)=0
@variables f(t)=getf(L)
@variables A(t)[1:2,1:2]=A₀
@variables B(t)[1:2,1:2]=B₀
@variables Σ(t)[1:4,1:4]=[A₀ -B₀; B₀ A₀]

# Define our parameters
@parameters I₄[1:4,1:4]=[1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1] K₃[1:4,1:4]=K(3)

# Define our differential: takes the derivative with respect to `t`
D = Differential(t)

# Define the differential equations
eqs = [f ~ getf(t)
       λᵣ ~ real(getλ(t))
       λᵢ ~ imag(getλ(t))
       A[1,1] ~ 0
       A[1,2] ~ 1
       A[2,1] ~ λᵣ + 1 - 2f
       A[2,2] ~ 0
       B[1,1] ~ 0
       B[1,2] ~ 0
       B[2,1] ~ λᵢ
       B[2,2] ~ 0
       Σ[1,1] ~ A[1,1]
       Σ[1,2] ~ A[1,2]
       Σ[2,1] ~ A[2,1]
       Σ[2,2] ~ A[2,2]
       Σ[1,3] ~ -B[1,1]
       Σ[1,4] ~ -B[1,2]
       Σ[2,3] ~ -B[2,1]
       Σ[2,4] ~ -B[2,2]
       Σ[3,1] ~ B[1,1]
       Σ[3,2] ~ B[1,2]
       Σ[4,1] ~ B[2,1]
       Σ[4,2] ~ B[2,2]
       Σ[3,3] ~ A[1,1]
       Σ[3,4] ~ A[1,2]
       Σ[4,3] ~ A[2,1]
       Σ[4,4] ~ A[2,2]
       D(v[1]) ~ ((I₄ - v * v') * (Σ * v))[1]
       D(v[2]) ~ ((I₄ - v * v') * (Σ * v))[2]
       D(v[3]) ~ ((I₄ - v * v') * (Σ * v))[3]
       D(v[4]) ~ ((I₄ - v * v') * (Σ * v))[4]
       D(θ) ~ -dot(K₃ * v, Σ * v)]

latexify(eqs)

# Bring these pieces together into an ODESystem with independent variable t
@named sys = ODESystem(eqs, t)

# Symbolically Simplify the System
simpsys = structural_simplify(sys)

# Convert from a symbolic to a numerical problem to simulate
tspan = (L, L′)
prob = ODEProblem(simpsys, [], tspan)

# Solve the ODE
sol = solve(prob)

makefigure() = GLMakie.Figure(resolution = resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=:white, clear=true))

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
country_name6 = "New Zealand"
country_nodes1 = Vector{Vector{Float64}}()
country_nodes2 = Vector{Vector{Float64}}()
country_nodes3 = Vector{Vector{Float64}}()
country_nodes4 = Vector{Vector{Float64}}()
country_nodes5 = Vector{Vector{Float64}}()
country_nodes6 = Vector{Vector{Float64}}()
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
    if countries["name"][i] == country_name6
        country_nodes6 = countries["nodes"][i]
        println(country_name6)
    end
end

α = 0.1
color1 = getcolor(country_nodes1, colorref, α)
color2 = getcolor(country_nodes2, colorref, α)
color3 = getcolor(country_nodes3, colorref, α)
color4 = getcolor(country_nodes4, colorref, α)
color5 = getcolor(country_nodes5, colorref, α)
color6 = getcolor(country_nodes6, colorref, α)
w1 = [τmap(country_nodes1[i]) for i in eachindex(country_nodes1)]
w2 = [τmap(country_nodes2[i]) for i in eachindex(country_nodes2)]
w3 = [τmap(country_nodes3[i]) for i in eachindex(country_nodes3)]
w4 = [τmap(country_nodes4[i]) for i in eachindex(country_nodes4)]
w5 = [τmap(country_nodes5[i]) for i in eachindex(country_nodes5)]
w6 = [τmap(country_nodes6[i]) for i in eachindex(country_nodes6)]
whirl1 = Whirl(lscene, w1, [0.0 for i in 1:length(w1)], [2π for i in 1:length(w1)], segments, color1, transparency = true)
whirl2 = Whirl(lscene, w2, [0.0 for i in 1:length(w2)], [2π for i in 1:length(w2)], segments, color2, transparency = true)
whirl3 = Whirl(lscene, w3, [0.0 for i in 1:length(w3)], [2π for i in 1:length(w3)], segments, color3, transparency = true)
whirl4 = Whirl(lscene, w4, [0.0 for i in 1:length(w4)], [2π for i in 1:length(w4)], segments, color4, transparency = true)
whirl5 = Whirl(lscene, w5, [0.0 for i in 1:length(w5)], [2π for i in 1:length(w5)], segments, color5, transparency = true)
whirl6 = Whirl(lscene, w6, [0.0 for i in 1:length(w6)], [2π for i in 1:length(w6)], segments, color6, transparency = true)
frame1 = Frame(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = true)
frame2 = Frame(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = true)


samples = length(sol[v])
γ₁ = Vector{Quaternion}(undef, samples)
phases = Vector{Float64}(undef, samples)
path_x = Vector{Float64}(undef, samples)
path_y = Vector{Float64}(undef, samples)
path_z = Vector{Float64}(undef, samples)
points = GLMakie.Observable(GLMakie.Point3f[]) # Signal that can be used to update plots efficiently
colors = GLMakie.Observable(Int[])
lines = GLMakie.lines!(lscene, points, linewidth = 3.0, color = colors, colormap = :jet, transparency = true)
for i in 1:samples
    γ₁[i] = Quaternion(sol[v][i])
    p = project(γ₁[i])
    path_x[i] = p[1]
    path_y[i] = p[2]
    path_z[i] = p[3]
    phases[i] = sol[θ][i]
end


_hopfmap(q) = begin
    a, b, c, d = vec(q)
    z₁ = a + c * im
    z₂ = b + d * im
    cartesian = convert_to_cartesian(z₂ / z₁)
    geographic = convert_to_geographic(cartesian)
    r, ϕ, _θ = vec(geographic)
    convert_to_cartesian([r; -ϕ; _θ])
end


basepoints = map(x -> project(τmap(_hopfmap(x))), γ₁)
px = [basepoints[i][1] for i in 1:samples] # π: S³ → S² ⊂ ℝ³
py = [basepoints[i][2] for i in 1:samples]
pz = [basepoints[i][3] for i in 1:samples]
rainbowcolors = [GLMakie.RGBAf(convert_hsvtorgb([i / samples * 360; 1; 1])..., 0.9) for i in 1:samples]


function step!(i, frame)
    push!(points[], GLMakie.Point3f(path_x[i], path_y[i], path_z[i]))
    push!(colors[], frame)
end


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
    rgb = convert_hsvtorgb([progress * 360; 1; 1])
    rgb′ = convert_hsvtorgb([progress * 360; 0.5; 0.5])
    i = max(1, Int(floor(progress * samples)))
    step!(i, frame) # update arrays inplace
    
    α = 0.25
    
    GLMakie.meshscatter!([px[i]], [py[i]], [pz[i]], markersize = 0.015, color = rainbowcolors[i], transparency = true)

    _basepoints = map(x -> project(G(phases[i], τmap(_hopfmap(x)))), γ₁)
    _px = [_basepoints[j][1] for j in 1:i] # π: S³ → S² ⊂ ℝ³
    _py = [_basepoints[j][2] for j in 1:i]
    _pz = [_basepoints[j][3] for j in 1:i]
    GLMakie.meshscatter!(_px, _py, _pz, markersize = 0.01, color = rainbowcolors[1:i], transparency = true)
    
    p = project(γ₁[i])
    tail = [GLMakie.Point3f(p...) for _ in 1:3]
    head = [GLMakie.Point3f(project(K(3) * γ₁[i])...), GLMakie.Point3f(project(K(1) * γ₁[i])...) * 0.25, GLMakie.Point3f(project(K(2) * γ₁[i])...) * 0.25]
    linecolor = [GLMakie.RGBAf(rgb..., α), GLMakie.RGBAf(rgb′..., α / 2), GLMakie.RGBAf(rgb′..., α / 2)]
    arrowcolor = [GLMakie.RGBAf(rgb..., α), GLMakie.RGBAf(rgb′..., α / 2), GLMakie.RGBAf(rgb′..., α / 2)]
    GLMakie.arrows!(lscene, tail, head, fxaa=true, linecolor = linecolor, arrowcolor = arrowcolor, linewidth = 0.01, arrowsize = GLMakie.Vec3f(0.025, 0.025, 0.05), transparency = true)
    GLMakie.meshscatter!([p[1]], [p[2]], [p[3]], markersize = 0.01, color = GLMakie.RGBAf(rgb..., α), transparency = true)
    update!(frame1, x -> G(phases[i], τmap(x)))

    # hor_xs = LinRange(0, 10, 100)
    # hor_ys = LinRange(0, 15, 100)
    # hor_zs = [cos(x) * sin(y) for x in xs, y in ys]

    # surface(xs, ys, zs, axis=(type=Axis3,))

    lines.colorrange = (0, frame) # update plot attribute directly
    notify(points); notify(colors) # tell points and colors that their value has been updated
    global lookat = 0.99 * lookat + 0.01 * GLMakie.Vec3f(p...)
    up = GLMakie.Vec3f(0, 0, 1)
    azimuth = -π / 2 + 0.3 * sin(2π * progress) # set the view angle of the axis
    eyeposition = GLMakie.Vec3f(π / 2 .* convert_to_cartesian([1; azimuth; π / 8])...)
    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
