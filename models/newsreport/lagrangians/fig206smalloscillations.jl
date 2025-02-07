using LinearAlgebra
using FileIO
using GLMakie
using Porta
using OrdinaryDiffEq, ForwardDiff, NonlinearSolve


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig206smalloscillations"
totalstages = 4
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 0.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
markersize = 0.07
arrowlinewidth = 0.06
arrowsize = Vec3f(0.08, 0.08, 0.1)
pathlinewidth = 10
fontsize = 0.3

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

sprite = Observable(normalize(Point3f(rand(3))))
basepoint = Observable(Point3f(rand()))
meshscatter!(lscene, sprite, markersize = markersize, color = :gold)
meshscatter!(lscene, basepoint, markersize = markersize / 2, color = :red)

particle_ps = @lift([$sprite])
particle_ns = Observable([Point3f(ẑ)])
arrows!(lscene,
particle_ps, particle_ns, fxaa = true, # turn on anti-aliasing
    color = [:black],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

pathpoints = Observable(Point3f[])
headpoints = Observable(Point3f[])
originpoints = Observable(Point3f[])
pathcolors = Observable(Int[])
lines!(lscene, pathpoints, color = pathcolors, linewidth = pathlinewidth, colorrange = (1, frames_number), colormap = :rainbow, linestyle = :dash)
lines!(lscene, headpoints, color = pathcolors, linewidth = pathlinewidth, colorrange = (1, frames_number), colormap = :lightrainbow, linestyle = :dot)
lines!(lscene, originpoints, color = pathcolors, linewidth = pathlinewidth, colorrange = (1, frames_number), colormap = :darkrainbow, linestyle = :dash)

lpoints = Observable([α * Point3f(ẑ) for α in range(0.0, stop = 1.0, length = segments)])
lcolors = collect(1:segments)
lines!(lscene, lpoints, color = lcolors, linewidth = 2pathlinewidth, colorrange = (1, segments), colormap = :plasma, linestyle = :solid)


titles = ["o", "q", "p"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift([$basepoint, ($particle_ps)[1], ($particle_ps)[1] + ($particle_ns)[1]]),
    text = titles,
    color = [:red, :gold, :black],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data, transparency = false
)

q₀ = ℝ³(0.0, 0.0, 0.0)

# Hamiltonian begin

const g = 1.0 # m / s²
const m = 1.0 # unit mass
const l = 1.0 # pendulum length

H(q, p) = norm(p)^2 / (2.0 * m * l^2) + m * g * l * (1.0 - cos(norm(q)))
L(q, p, dq, dp) = (1.0 / 2.0) * m * l^2 * norm(dp)^2 - m * g * l * (1.0 - cos(norm(q)))

pdot(dp, p, q, params, t) = ForwardDiff.gradient!(dp, q -> -H(q, p), q)
qdot(dq, p, q, params, t) = ForwardDiff.gradient!(dq, p -> H(q, p), p)

initial_position = [0.0, 0.0, 0.1]
initial_velocity = [0.0, 0.0, 0.0]
initial_cond = (initial_position, initial_velocity)
initial_first_integrals = (H(initial_cond...), L(initial_cond..., 0.0, 0.0))
tspan = (0, 30.0)
prob = DynamicalODEProblem(pdot, qdot, initial_velocity, initial_position, tspan)
sol = solve(prob, KahanLi6(), dt = 1 // 100);
solutionnumber = length(sol.u)

# Hamiltonian end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    q₀ = progress * ŷ

    basepoint[] = Point3f(q₀ + x̂)

    index = max(1, Int(floor(progress * solutionnumber)))
    p₁ = ℝ³((vec(sol.u[index])[1:3])...)
    q₁ = ℝ³((vec(sol.u[index])[4:6])...)
    sprite[] = Point3f(q₀ + q₁)
    particle_ns[] = [Point3f(p₁)]
    push!(pathpoints[], sprite[])
    push!(headpoints[], sprite[] + Point3f(p₁))
    push!(originpoints[], Point3f(q₀ + x̂))
    push!(pathcolors[], frame)
    notify(pathpoints)
    notify(headpoints)
    notify(originpoints)
    notify(pathcolors)

    lpoints[] = [Point3f(q₀) + (1 - α) * Point3f(x̂) + α * Point3f(q₁) for α in range(0.0, stop = 1.0, length = segments)]
    notify(lpoints)
    try
        lines!(lscene, lpoints[], color = collect(1:length(lpoints[])), linewidth = pathlinewidth / 4, colorrange = (1, length(lpoints[])), colormap = :magma, linestyle = :solid)
    catch e
        println(e)
    end
    
    global lookat = q₁
    global up = x̂

    if stage == 1
        global eyeposition = normalize(ℝ³(1.0, 0.0, -1.0)) * float(π - stageprogress * π / 2)
    end
    if stage == 2
        global eyeposition = normalize(ℝ³(1.0 - stageprogress, 0.0, -1.0)) * float(π / 2)
    end
    if stage == 3
        global eyeposition = rotate(normalize(ℝ³(0.0, stageprogress, -1.0)), ℍ(stageprogress * 2π, x̂)) * float(π / 2)
    end
    if stage == 4
        global eyeposition = normalize(ℝ³(stageprogress, 1.0 - stageprogress, -1.0)) * float(π / 2 + stageprogress * π / 2)
    end
    try
        updatecamera!(lscene, eyeposition, lookat, up)
    catch e
        println(e)
    end
end


animate(1)

pathpoints[] = Point3f[]
headpoints[] = Point3f[]
originpoints[] = Point3f[]
pathcolors[] = Int[]

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end