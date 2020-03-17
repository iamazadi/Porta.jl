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
    leftover_segments = Integer(floor((cut / 2pi) * segments))
    manifold_segments = segments - leftover_segments
    manifold = Array{Float64}(undef, manifold_segments, samples, 3)
    leftover = Array{Float64}(undef, leftover_segments, samples, 3)
    α = (2pi-cut) / (manifold_segments-1)
    γ = cut / (leftover_segments-1)
    for i in 1:samples
        z, w = τ(points[i, :]...)
        for j in 1:segments
            if j ≤ manifold_segments
                x₁ = (real(w) + 1) * sin(α*(j-1))
                x₂ = (real(w) + 1) * cos(α*(j-1))
                x₃ = imag(w)
                manifold[j, i, :] = [x₁, x₂, x₃]
                if j != manifold_segments
                    z, w = S¹action(α, z, w)
                end
            else
                index = j-manifold_segments
                x₁ = (real(w) + 1) * sin((2pi-cut)+γ*(index-1))
                x₂ = (real(w) + 1) * cos((2pi-cut)+γ*(index-1))
                x₃ = imag(w)
                leftover[index, i, :] = [x₁, x₂, x₃]
                z, w = S¹action(γ, z, w)
            end
        end
    end
    manifold, leftover
end


universe = Scene(backgroundcolor = :black, show_axis=false)
sg, og = textslider(0:0.05:2pi, "g", start = 0)

max_samples = 1000
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
    ghost = RGBAf0(country[2]..., 0.2)
    inverse = RGBAf0((1 .- country[2])..., 1.0)
    
    rotated = @lift begin
        R = similar(points)
        for i in 1:samples
                  ϕ, θ = points[i, :]
            R[i, :] = [ϕ + $og, θ]
        end
        R
    end
    
    cut = 2pi/360*80
    leftover_segments = Integer(floor((cut / 2pi) * segments))
    manifold_segments = segments - leftover_segments
    manifold_color = fill(specific, manifold_segments, samples)
    manifolds = @lift(get_manifold($rotated, segments, cut))
    manifold = @lift($manifolds[1])
    surface!(universe,
             @lift($manifold[:, :, 1]),
             @lift($manifold[:, :, 2]),
             @lift($manifold[:, :, 3]),
             color = manifold_color)
    if country[1] in ["iran", "us", "australia"]
        ghost_color = fill(ghost, leftover_segments, samples)
        leftover = @lift($manifolds[2])
        surface!(universe,
                 @lift($leftover[:, :, 1]),
                 @lift($leftover[:, :, 2]),
                 @lift($leftover[:, :, 3]),
                 color = ghost_color,
                 transparency = true)
     end
end

scene = hbox(universe,
             vbox(sg),
             parent = Scene(resolution = (400, 400)))

eyepos = Vec3f0(-2, 2, 0)
lookat = Vec3f0(0)
update_cam!(universe, eyepos, lookat)
universe.center = false # prevent scene from recentering on display

record(universe, "planet.gif") do io
    frames = 100
    for i in 1:frames
        og[] = i*2pi/frames # animate scene
        recordframe!(io) # record a new frame
    end
end


