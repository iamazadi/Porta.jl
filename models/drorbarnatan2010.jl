import AbstractPlotting
import Makie


using StatsBase
using FileIO
using CSV
using Porta


α = 40
α₁ = α / 180 * pi
α₂ = 2pi - α / 180 * pi
scale = 1.0


"""
    πmap(p)

Map the point `p` from S³ into S².
"""
πmap(p::ComplexPlane) = Geographic(ComplexLine(p.z₂ / p.z₁))
πmap(p::S³) = πmap(ComplexPlane(p))


"""
    f(p)

Map from S² into the upper hemisphere of S² with the given point `p`.
"""
function f(p::Geographic)
    ϕ, θ = p.ϕ, p.θ
    r = sqrt((1 - sin(θ)) / 2)
    Geographic(r * cos(ϕ), r * sin(ϕ))
end


"""
sample(dataframe, max)

Samples points from a dataframe with the given dataframe and the maximum number
of samples limit. The second column of the dataframe should contain longitudes
and the third one latitudes (in degrees.)
"""
function sample(dataframe, max)
    #total_longitudes = dataframe[dataframe[:shapeid].<0.1, 3] ./ 180 .* pi
    #total_latitudes = dataframe[dataframe[:shapeid].<0.1, 4] ./ 180 .* pi
    total_longitudes = dataframe[dataframe[:partid].==0, 3] ./ 180 .* pi
    total_latitudes = dataframe[dataframe[:partid].==0, 4] ./ 180 .* pi
    sampled_longitudes = Array{Float64}(undef, max)
    sampled_latitudes = Array{Float64}(undef, max)
    count = length(total_longitudes)
    if count > max
        sample!(total_longitudes,
                sampled_longitudes,
                replace=false,
                ordered=true)
        sample!(total_latitudes,
                sampled_latitudes,
                replace=false,
                ordered=true)
        longitudes = sampled_longitudes
        latitudes = sampled_latitudes
    else
        longitudes = total_longitudes
        latitudes = total_latitudes
    end
    count = length(longitudes)
    points = Array{Geographic,1}(undef, count)
    for i in 1:count
        points[i] = Geographic(longitudes[i], latitudes[i])
    end
    points
end


"""
sample(dataframe, part, max)

Samples points from a dataframe with the given `dataframe`, `part` id, and the `max` number
of samples limit. The second column of the dataframe should contain longitudes
and the third one latitudes (in degrees.)
"""
function sample(dataframe, part, max)
    total_longitudes = dataframe[dataframe[:partid].==part, 3] ./ 180 .* pi
    total_latitudes = dataframe[dataframe[:partid].==part, 4] ./ 180 .* pi
    sampled_longitudes = Array{Float64}(undef, max)
    sampled_latitudes = Array{Float64}(undef, max)
    count = length(total_longitudes)
    if count > max
        sample!(total_longitudes,
                sampled_longitudes,
                replace=false,
                ordered=true)
        sample!(total_latitudes,
                sampled_latitudes,
                replace=false,
                ordered=true)
        longitudes = sampled_longitudes
        latitudes = sampled_latitudes
    else
        longitudes = total_longitudes
        latitudes = total_latitudes
    end
    count = length(longitudes)
    points = Array{Geographic,1}(undef, count)
    for i in 1:count
        points[i] = Geographic(longitudes[i], latitudes[i])
    end
    points
end


"""
    build(scene, surface, color)

Build a surface with the given `scene`, `surface` and `color`.
"""
function build(scene, surface, color; transparency = false)
    x = Makie.Node(map(x -> vec(x)[1] , surface[:, :]))
    y = Makie.Node(map(x -> vec(x)[2] , surface[:, :]))
    z = Makie.Node(map(x -> vec(x)[3] , surface[:, :]))
    Makie.surface!(scene, x, y, z, color = color, transparency = transparency)
    x, y, z
end


"""
    updatestate(o, p)

Update an array of observables `o` with the given array of points `p`.
"""
function updatestate(o, p::Array{ℝ³,2})
    x, y, z = o
    x[] = map(i -> vec(i)[1] , p[:, :])
    y[] = map(i -> vec(i)[2] , p[:, :])
    z[] = map(i -> vec(i)[3] , p[:, :])
end


"""
    pullback(p, α)

Calculate the pullback to S³ with the given point `p` and the given angle `α`.
"""
function pullback(p::Geographic, α::Real)
    p′ = f(p)
    ϕ, θ = p′.ϕ + pi, (p′.θ + pi/2) / 2
    Quaternion(ComplexPlane(sin(θ) * exp(im * (ϕ + α) / 2),
                            cos(θ) * exp(im * (α - ϕ) / 2)))
end


"""
    pullback2(p, α)

Calculate the pullback to S³ with the given point `p` and the given angle `α`.
"""
function pullback2(p::Geographic, α::Real)
    p′ = f(p)
    ϕ, θ = p′.ϕ, p′.θ
    arg = angle(exp(-im * ϕ) * sqrt(1 + sin(θ)))
    z = exp(im * α) * exp(-im * (arg + ϕ)) * sqrt(1 + sin(θ)) / sqrt(2)
    w = exp(im * α) * exp(-im * arg) * sqrt(1 - sin(θ)) / sqrt(2)
    Quaternion(ComplexPlane(w, z))
end


"""
    getsurface(q, p, scale, segments)

Calculate a pullback surface using stereographic projection with the given S² rotation `q`,
an array of points 'p', `scale` and the number of `segments`.
"""
function getsurface(q::Quaternion, p::Array{Geographic,1}, scale::Real, segments::Int)
    surface = Array{ℝ³}(undef, segments, length(p))
    lspace = range(α₁, stop = α₂, length = segments)
    for (i, α) in enumerate(lspace)
        for (j, point) in enumerate(p)
            surface[i, j] = σmap(rotate(q, pullback2(point, α))) * scale
        end
    end
    surface
end


"""
    sphere(q, α, scale, [segments])

Calculate a Riemann sphere with the given S² rotation `q`, circle `α` and `scale`.
"""
function sphere(q::Quaternion, α::Real, scale; segments::Int=30)
    latitudeoffset = -pi / 2
    s2 = Array{ℝ³}(undef, segments, segments)
    lspace = collect(range(-pi, stop = pi, length = segments)) #.+ longitudeoffset
    lspace2 = collect(range(pi / 2, stop = latitudeoffset, length = segments))
    for (i, θ) in enumerate(lspace2)
        for (j, ϕ) in enumerate(lspace)
            h = pullback2(Geographic(ϕ, θ), α)
            s2[i, j] = σmap(rotate(q, h)) * scale
        end
    end
    s2
end


# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.
countries = Dict("iran" => [0.800, 0.867, 0.090],
                 "us" => [0.788, 0.200, 0.067],
                 "china" => [0.882, 0.882, 0.431],
                 "ukraine" => [0.776, 0.447, 0.788],
                 "australia" => [0.827, 0.145, 0.510],
                 "germany" => [0.082, 0.784, 0.573],
                 "israel" => [0.522, 0.333, 0.875],
                 "canada" => [0.212, 0.933, 0.369],
                 "india" => [0.525, 0.902, 0.584],
                 "southkorea" => [0.180, 0.827, 0.784],
                 "france" => [0.518, 0.812, 0.184],
                 "antarctica" => [0.875, 0.651, 0.357]
                 )
# The path to the dataset
path = "test/data/natural_earth_vector"

# The scene object that contains other visual objects
scene = Makie.Scene(backgroundcolor = :white, show_axis = false, resolution = (360, 360))
#scene = Makie.Scene(backgroundcolor = :black, show_axis = false, resolution = (1920, 1080))
#scene = Makie.Scene(backgroundcolor = :white,
#                    show_axis = false,
#                    resolution = (360, 360),
#                    camera = Makie.cam3d_cad!)
# Use a slider for rotating the base space in an interactive way
#sg, og = textslider(0:0.05:2pi, "g", start = 0)
# Instantiate a horizontal box for holding the visuals and the controls
#scene = hbox(universe,
#             vbox(sg),
#             parent = Scene(resolution = (360, 360)))

# The maximum number of points to sample from the dataset for each country
#maxsamples = 720
#segments = 72
maxsamples = 360
segments = 36
q = Quaternion(α₁, ℝ³(0, 0, 1))
observables = []
ghosts = []
ghostpoints = []
points = []
parts = 3
for country in countries
    countryname = country[1]
    dataframe = CSV.read(joinpath(path, "$(countryname)-nodes.csv"))
    if countryname in ["us", "france", "iran", "canada"]
        for part in 0:parts-1
            # Sample a random subset of the points
            p = sample(dataframe, part, maxsamples)
            color = fill(Makie.RGBAf0(country[2]..., 0.9), segments, length(p))
            x, y, z = build(scene, getsurface(q, p, scale, segments), color)
            push!(observables, (x, y, z))
            push!(points, p)
            color = fill(Makie.RGBAf0(country[2]..., 0.5), segments, length(p))
            x, y, z = build(scene,
                            getsurface(q, p, scale, segments),
                            color,
                            transparency = true)
            push!(ghosts, (x, y, z))
            push!(ghostpoints, p)
        end
    else
        # Sample a random subset of the points
        p = sample(dataframe, maxsamples)
        color = fill(Makie.RGBAf0(country[2]..., 0.1), segments, length(p))
        x, y, z = build(scene,
                        getsurface(q, p, scale, segments),
                        color,
                        transparency = true)
        push!(observables, (x, y, z))
        push!(points, p)
    end
end


# Use QGIS to design a geo map
s2color = load("test/data/basemap90grid.png")
s2observables = build(scene, sphere(q, α₁, scale, segments = segments), s2color)
s2observables2 = build(scene, sphere(q, α₂, scale, segments = segments), s2color)

frames = 90


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i)
    step = 2(sqrt((i - 1) / frames) - 0.5) * pi
    println("Step ", 100(i - 1) / frames)
    ϕ = cos(step) * pi
    θ = (sin(step) * pi) / 2
    τ = -(i - 1) / frames * 2pi
    global α₁ = α / 180 * pi #+ τ
    global α₂ = 2pi - α / 180 * pi #+ τ
    # global α₁ = 2(α / 180 * pi)
    # global α₂ = 2(2pi - α / 180 * pi)
    #q = Quaternion(τ, ℝ³(Cartesian(f(Geographic(ϕ, θ)))))
    q = Quaternion(τ, ℝ³(0, 0, 1))
    for (p, nodes) in zip(points, observables)
        updatestate(nodes, getsurface(q, p, scale, segments))
    end
    updatestate(s2observables, sphere(q, α₁, scale, segments = segments))
    updatestate(s2observables2, sphere(q, α₂, scale, segments = segments))
    global α₁ = α / 180 * pi
    global α₂ = -α / 180 * pi
    for (p, nodes) in zip(ghostpoints, ghosts)
        updatestate(nodes, getsurface(q, p, scale, segments))
    end
    # update eye position
    # scene.camera.eyeposition.val
    a₁ = σmap(rotate(q, pullback2(Geographic(0, pi/2), α₁))) * scale
    a₂ = σmap(rotate(q, pullback2(Geographic(0, pi/2), α₂))) * scale
    a₃ = σmap(rotate(q, pullback2(Geographic(0, pi/2), 0))) * scale
    n = normalize(cross(a₁, a₂))
    upvector = Makie.Vec3f0(vec(n)...)
    eyeposition = Makie.Vec3f0(vec(a₁ + a₂)...) .* pi
    lookat = Makie.Vec3f0(vec(a₃)...)
    Makie.update_cam!(scene, eyeposition, lookat, upvector)
    scene.center = false # prevent scene from recentering on display
end

# Makie.save("gallery/drorbarnatan2010.jpg", scene)
Makie.record(scene, "gallery/drorbarnatan2010.gif") do io
    for i in 1:frames
        animate(i)
        Makie.recordframe!(io) # record a new frame
    end
end
