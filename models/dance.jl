using LinearAlgebra
using Makie
using Porta


samples = 360
segments = 72
radius = 0.005
const FPS = 24 # frames per second
R = 1.0
θ = Node(0.0)

function makehopf(scene)
    lspace = range(0, stop = 2pi, length = samples)
    basepoints = convert(Array{Complex}, R .* Complex.(cos.(lspace), sin.(lspace)))
    fiberactions = [fill(0.0, samples) fill(2pi, samples)]
    q = ℍ([cos(0); sin(0) .* [sqrt(3)/3; sqrt(3)/3; sqrt(3)/3]])
    h = ⭕(basepoints, fiberactions, segments, radius, q)
    surfacesx = []
    surfacesy = []
    surfacesz = []
    colors = []
    surfaces = []
    for i in 1:samples
        surfacex = Node(h.m[i, :, :, 1])
        surfacey = Node(h.m[i, :, :, 2])
        surfacez = Node(h.m[i, :, :, 3])
        color = Node(RGBAf0.(h.c[i, :, :, 1],
                             h.c[i, :, :, 2],
                             h.c[i, :, :, 3],
                             0.9))
        push!(surfacesx, surfacex)
        push!(surfacesy, surfacey)
        push!(surfacesz, surfacez)
        push!(colors, color)
        push!(surfaces, surface!(scene,
                                 surfacex,
                                 surfacey,
                                 surfacez,
                                 color = color)[end])
    end
    surfacesx, surfacesy, surfacesz, colors
end

name = "WelcometoThePortal"
signal = Signal("data" * "/" * name * ".wav")
total_samples = Integer(fps(signal) ÷ FPS) - 2
indices = convert(Array{Int64}, floor.(range(2, stop=total_samples-1, length=samples)))
frames = chunks(signal, FPS)
q = @lift(ℍ([cos($θ); sin($θ) .* [sqrt(3)/3; sqrt(3)/3; sqrt(3)/3]]))

function animate(i, surfacesx, surfacesy, surfacesz, colors)
    f = fft(chunk(signal, i, FPS))[indices]
    basepoints = convert(Array{Complex}, f)
    M = [real.(f) imag.(f)]
    powers = Array{Float64}(undef, samples)
    for j in 1:samples
        powers[j] = tanh(norm(M[j, :]))
    end
    fiberactions = [fill(0.0, samples) replace(powers, NaN=>0.01) .* 2pi]
    h = ⭕(basepoints, fiberactions, segments, radius, to_value(q))
    for j in 1:samples
        surfacesx[j][] = h.m[j, :, :, 1]
        surfacesy[j][] = h.m[j, :, :, 2]
        surfacesz[j][] = h.m[j, :, :, 3]
        rg = [0.9; 0.9; 0.9]
        rg′ = 1 .- rg
        colors[j][] = RGBAf0.((rg[1] .* h.c[j, :, :, 1]) .+ rg′[1] .* rand(Float64, size(h.c[j, :, :, 1])),
                              (rg[2] .* h.c[j, :, :, 2]) .+ rg′[2] .* rand(Float64, size(h.c[j, :, :, 2])),
                              (rg[3] .* h.c[j, :, :, 3]) .+ rg′[3] .* rand(Float64, size(h.c[j, :, :, 3])),
                              0.9)
    end
    θ[] = 2pi * (i - 1) / frames
end

function preparescene(scene)
    eyeposition, lookat = Vec3f0(2, 2, 1), Vec3f0(0)
    update_cam!(scene, eyeposition, lookat)
    scene.center = false # prevent scene from recentering on display
    #rotate_cam!(universe, 0.0, 0.0, pi/2)
end

scene = Scene(backgroundcolor = :white, show_axis=false, resolution=(1920, 1080))
surfacesx, surfacesy, surfacesz, colors = makehopf(scene)

preparescene(scene)
record(scene, "gallery" * "/" * name * ".mkv") do io
    for i in 1:frames
        @show (i / frames) * 100
        animate(i, surfacesx, surfacesy, surfacesz, colors)
        recordframe!(io) # record a new frame
    end
end
