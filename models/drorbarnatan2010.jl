import AbstractPlotting
import Makie


using StatsBase
using FileIO
using CSV
using Porta


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
    total_longitudes = dataframe[dataframe[:shapeid].<0.1, 2] ./ 180 .* pi
    total_latitudes = dataframe[dataframe[:shapeid].<0.1, 3] ./ 180 .* pi
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
    update(o, p)

Update an array of observables `o` with the given array of points `p`.
"""
function update(o, p::Array{ℝ³,2})
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


α₁ = 0
α₂ = 2(2pi - 80 / 180 * pi)


"""
    getsurface(q, p, s)

Calculate a pullback surface using stereographic projection with the given S² rotation `q`,
an array of points 'p' and the number of segments `s`.
"""
function getsurface(q::Quaternion, p::Array{Geographic,1}, s::Int)
    surface = Array{ℝ³}(undef, s, length(p))
    lspace = range(α₁, stop = α₂, length = s)
    for (i, α) in enumerate(lspace)
        for (j, point) in enumerate(p)
            surface[i, j] = σmap(rotate(q, pullback(point, α)))
        end
    end
    surface
end


"""
    sphere(q, α)

Calculate a Riemann sphere with the given S² rotation `q` and circle `α`.
"""
function sphere(q::Quaternion, α::Real, segments::Int=30)
    latitudeoffset = -pi / 3
    s2 = Array{ℝ³}(undef, segments, segments)
    lspace = collect(range(-pi, stop = pi, length = segments)) #.+ longitudeoffset
    lspace2 = collect(range(pi / 2, stop = latitudeoffset, length = segments))
    for (i, θ) in enumerate(lspace2)
        for (j, ϕ) in enumerate(lspace)
            h = pullback(Geographic(ϕ, θ), α)
            s2[i, j] = σmap(rotate(q, h))
        end
    end
    s2
end


# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.
countries = Dict("iran" => [0.0, 1.0, 0.29], # green
                 "us" => [0.494, 1.0, 0.0], # green
                 "china" => [1.0, 0.639, 0.0], # orange
                 "ukraine" => [0.0, 0.894, 1.0], # cyan
                 "australia" => [1.0, 0.804, 0.0], # orange
                 "germany" => [0.914, 0.0, 1.0], # purple
                 "israel" => [0.0, 1.0, 0.075]) # green
# The path to the dataset
path = "test/data/natural_earth_vector"

# The scene object that contains other visual objects
scene = Makie.Scene(backgroundcolor = :white,
                    show_axis = false,
                    resolution = (360, 360))
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
maxsamples = 300
segments = 30
q = Quaternion(α₁, ℝ³(0, 0, 1))
observables = []
ghosts = []
ghostpoints = []
points = []
for country in countries
    countryname = country[1]
    dataframe = CSV.read(joinpath(path, "$(countryname)-nodes.csv"))
    # Sample a random subset of the points
    p = sample(dataframe, maxsamples)
    color = fill(Makie.RGBAf0(country[2]..., 1.0), segments, length(p))
    x, y, z = build(scene, getsurface(q, p, segments), color)
    push!(observables, (x, y, z))
    push!(points, p)
    if countryname in ["iran", "us", "china"]
        color = fill(Makie.RGBAf0(country[2]..., 0.5), segments, length(p))
        x, y, z = build(scene, getsurface(q, p, segments), color, transparency = true)
        push!(ghosts, (x, y, z))
        push!(ghostpoints, p)
    end
end


s2color = load("test/data/BaseMap.png")
s2observables = build(scene, sphere(q, α₁, segments), s2color)
s2observables2 = build(scene, sphere(q, α₂, segments), s2color)

frames = 90
function animate(i)
    τ = i / frames * 2pi
    global α₁ = 2(40 / 180 * pi) + 2τ
    global α₂ = 2(2pi - 40 / 180 * pi) + 2τ
    q = Quaternion(τ, ℝ³(0, 0, 1))
    for (p, nodes) in zip(points, observables)
        update(nodes, getsurface(q, p, segments))
    end
    update(s2observables, sphere(q, α₁, segments))
    update(s2observables2, sphere(q, α₂, segments))
    global α₁ = 2(40 / 180 * pi) + 2τ
    global α₂ = 2(-40 / 180 * pi) + 2τ
    for (p, nodes) in zip(ghostpoints, ghosts)
        update(nodes, getsurface(q, p, segments))
    end
end

# update eye position
# scene.camera.eyeposition.val
upvector = Makie.Vec3f0(1, 0, 1)
eyeposition = Makie.Vec3f0(1/3, 1, 1/3) .* sqrt(3)
lookat = Makie.Vec3f0(0, 0, 0)
Makie.update_cam!(scene, eyeposition, lookat, upvector)
scene.center = false # prevent scene from recentering on display

Makie.record(scene, "gallery/drorbarnatan2010.gif") do io
    for i in 1:frames
        animate(i)
        Makie.recordframe!(io) # record a new frame
    end
end
