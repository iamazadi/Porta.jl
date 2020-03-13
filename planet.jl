using LinearAlgebra
using FileIO
using Colors
using AbstractPlotting
using Makie
using CSV
using StatsBase
using ReferenceFrameRotations
using Porta


"""
sample_points(dataframe, max)

Samples points from a dataframe and converts them to cartesian coordinates
with the given dataframe and the maximum number of samples limit.
The second column of the dataframe should contain longitudes
and the third one latitudes (in degrees.)
"""
function sample_points(dataframe, max)
    total_latitudes = dataframe[dataframe[:shapeid].<0.1, 3] ./ 180 .* pi
    total_longitudes = dataframe[dataframe[:shapeid].<0.1, 2] ./ 180 .* pi
    sampled_latitudes = Array{Float64}(undef, max)
    sampled_longitudes = Array{Float64}(undef, max)
    count = length(total_latitudes)
    if count > max
        sample!(total_latitudes, sampled_latitudes, replace=false, ordered=true)
        sample!(total_longitudes, sampled_longitudes, replace=false, ordered=true)
        latitudes = sampled_latitudes
        longitudes = sampled_longitudes
    else
        latitudes = total_latitudes
        longitudes = total_longitudes
    end
    count = length(latitudes)
    points = Array{Float64}(undef, count, 3)
    for i in 1:count
        points[i, :] = locate(latitudes[i], longitudes[i])[:]
    end
    points
end


"""
get_pullback(points, segments)

Calculates a pullback to the three sphere of a map with the given points
as the boundry and the number of segments around the circles.
"""
function get_pullback(points, segments)
    samples = size(points, 1)
    pullback = Array{Float64}(undef, segments, samples, 3)
    for i in 1:samples
        angle = 2pi / (segments-1)
        # Get the base point
        B = points[i, :]
        X, Y, Z = get_points(B, angle)
        # Get the circle center point
        Q = get_center(X, Y, Z)
        # Find the circle radius
        radius = Float64(norm(X - Q))
        for j in 1:segments
            X, Y, Z = get_points(B, angle)
            pullback[j, i, :] = Z ./ radius
            angle += 2pi / (segments-1)
        end
    end
    pullback
end


sg₁, og₁ = textslider(0:0.01:2pi, "g₁", start = pi/6)
sg₂, og₂ = textslider(0:0.01:2pi, "g₂", start = 0)
sg₃, og₃ = textslider(0:0.01:2pi, "g₃", start = pi/6)
# The three sphere rotations axis
g = @lift(ReferenceFrameRotations.Quaternion(cos($og₁),
                                             sin($og₁)*cos($og₂)*cos($og₃),
                                             sin($og₁)*cos($og₂)*sin($og₃),
                                             sin($og₁)*sin($og₂)))

samples = 300
segments = 30
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.
countries = Dict("iran" => (1.0, 0.0, 0.0), # red
                 "us" => (0.0, 1.0, 0.0), # green
                 "china" => (0.0, 0.0, 1.0), # blue
                 "ukraine" => (1.0, 1.0, 0.0), # yellow
                 "australia" => (0.0, 1.0, 1.0), # cyan
                 "germany" => (1.0, 0.0, 1.0), #magenta
                 "israel" => (1.0, 1.0, 1.0)) # white
path = "data/natural_earth_vector"
universe = Scene(backgroundcolor = :black, show_axis=false)
for country in countries
    dataframe = CSV.read(joinpath(path, "$(country[1])-nodes.csv"))
    points = sample_points(dataframe, samples)
    count = size(points, 1)
    color = fill(RGBAf0(country[2]..., 1.0), segments, count)
    color[1:6, :] = fill(RGBAf0(country[2]..., 0.3), 6, count)
    rotated = @lift begin
        R = similar(points)
        for i in 1:count
            R[i, :] = rotate(points[i, :], $g)
        end
        R
    end
    pullback = @lift(get_pullback($rotated, segments))
    surface!(universe,
             @lift($pullback[:, :, 1]),
             @lift($pullback[:, :, 2]),
             @lift($pullback[:, :, 3]),
             color = color)
end

scene = hbox(universe,
             vbox(sg₁, sg₂, sg₃),
             parent = Scene(resolution = (400, 400)))

eyepos = Vec3f0(1, 1, -1)
lookat = Vec3f0(0)
update_cam!(universe, eyepos, lookat)
universe.center = false # prevent scene from recentering on display

record(universe, "planet.gif") do io
    for i in 1:100
        og₂[] = i*2pi/100 # animate scene
        recordframe!(io) # record a new frame
    end
end


