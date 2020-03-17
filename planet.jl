using LinearAlgebra
using AbstractPlotting
using Makie
using CSV
using StatsBase
using ReferenceFrameRotations
using Porta


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
        sample!(total_longitudes, sampled_longitudes, replace=false, ordered=true)
        sample!(total_latitudes, sampled_latitudes, replace=false, ordered=true)
        longitudes = sampled_longitudes
        latitudes = sampled_latitudes
    else
        longitudes = total_longitudes
        latitudes = total_latitudes
    end
    count = length(longitudes)
    points = Array{Float64}(undef, count, 2)
    for i in 1:count
        points[i, :] = [longitudes[i], latitudes[i]]
    end
    points
end


function π(z, w)
    x₁ = real(z)
    x₂ = imag(z)
    x₃ = real(w)
    x₄ = imag(w)
    [2(x₁*x₃ + x₂*x₄), 2(x₂*x₃ - x₁*x₄), x₁^2+x₂^2-x₃^2-x₄^2]
end


function σ(ϕ, θ; β=0)
    exp(-im * (β + ϕ)) * sqrt((1 + sin(θ)) / 2), sqrt((1 - sin(θ)) / 2)
end


function τ(ϕ, θ; β=0)
    sqrt((1 + sin(θ)) / 2), exp(im * (β + ϕ)) * sqrt((1 - sin(θ)) / 2)
end


function S¹action(α, z, w)
    exp(im * α) * z, exp(im * α) * w
end


function λ(z, w)
    [real(z), imag(z), real(w)] ./ (1 - imag(w))
end


function get_manifold(points, segments, cut)
    samples = size(points, 1)
    manifold = Array{Complex}(undef, segments, samples, 3)
    α = (2pi-cut) / (segments-1)
    for i in 1:samples
            ϕ, θ = points[i, :]
        z, w = τ(ϕ, θ)
        for j in 1:segments
            z, w = S¹action(α, z, w)
            x₁ = (real(w) + 1) * sin(α*j)
            x₂ = (real(w) + 1) * cos(α*j)
            x₃ = imag(w)
            manifold[j, i, :] = [x₁, x₂, x₃]
        end
    end
    manifold
end


universe = Scene(backgroundcolor = :black, show_axis=false)
sg₁, og₁ = textslider(0:0.05:2pi, "g₁", start = 0)
sg₂, og₂ = textslider(0:0.05:2pi, "g₂", start = 0)
sg₃, og₃ = textslider(0:0.05:2pi, "g₃", start = 0)
# The three sphere rotations axis
g = @lift(ReferenceFrameRotations.Quaternion(cos($og₁),
                                             sin($og₁)*cos($og₂)*cos($og₃),
                                             sin($og₁)*cos($og₂)*sin($og₃),
                                             sin($og₁)*sin($og₂)))

max_samples = 300
segments = 30
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.
countries = Dict("iran" => [1.0, 0.0, 0.0], # red
                 "us" => [0.0, 1.0, 0.0], # green
                 "china" => [0.0, 0.0, 1.0], # blue
                 "ukraine" => [1.0, 1.0, 0.0], # yellow
                 "australia" => [0.0, 1.0, 1.0], # cyan
                 "germany" => [1.0, 0.0, 1.0], #magenta
                 "israel" => [1.0, 1.0, 1.0]) # white
path = "data/natural_earth_vector"
for country in countries
    dataframe = CSV.read(joinpath(path, "$(country[1])-nodes.csv"))
    points = sample(dataframe, max_samples)
    samples = size(points, 1)
    specific = RGBAf0(country[2]..., 1.0)
    inverse = RGBAf0((1 .- country[2])..., 1.0)
    
    rotated = @lift begin
        R = similar(points)
        for i in 1:samples
            cartesian = convert_to_cartesian(points[i, :])
            R[i, :] = convert_to_geographic(rotate(cartesian, $g))
        end
        R
    end
    
    cut = pi/2
    manifold = @lift(get_manifold($rotated, segments, cut))
    color = fill(specific, segments, samples)
    surface!(universe,
             @lift($manifold[:, :, 1]),
             @lift($manifold[:, :, 2]),
             @lift($manifold[:, :, 3]),
             color = color)
end

scene = hbox(universe,
             vbox(sg₁, sg₂, sg₃),
             parent = Scene(resolution = (400, 400)))

eyepos = Vec3f0(-2, 3, -2)
lookat = Vec3f0(0)
update_cam!(universe, eyepos, lookat)
universe.center = false # prevent scene from recentering on display

record(universe, "planet.gif") do io
    frames = 100
    for i in 1:frames
        # animate scene
        og₁[] = i*2pi/frames
        #og₂[] = i*2pi/frames
        #og₃[] = i*2pi/frames
        recordframe!(io) # record a new frame
    end
end


