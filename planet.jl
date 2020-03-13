using LinearAlgebra
using FileIO
using Colors
using AbstractPlotting
using Makie
using CSV
using StatsBase
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
        angle = 2pi / segments
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
            angle += 2pi / segments
        end
    end
    pullback
end

samples = 3000
segments = 30
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.
countries = Dict("iran" => RGBAf0(1.0, 0.0, 0.0, 1.0), # red
                 "us" => RGBAf0(0.0, 1.0, 0.0, 1.0), # green
                 "china" => RGBAf0(0.0, 0.0, 1.0, 1.0)) # blue
path = "data/natural_earth_vector"
universe = Scene()
for country in countries
    dataframe = CSV.read(joinpath(path, "$(country[1])-nodes.csv"))
    points = sample_points(dataframe, samples)
    count = size(points, 1)
    color = fill(country[2], segments, count)
    pullback = get_pullback(points, segments)
    for i in segments
        meshscatter!(universe,
                     pullback[i, :, 1],
                     pullback[i, :, 2],
                     pullback[i, :, 3],
                     markersize = 0.01,
                     color = country[2])
    end
    surface!(universe,
             pullback[:, :, 1],
             pullback[:, :, 2],
             pullback[:, :, 3],
             color = color)
end

