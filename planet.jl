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
    points = Array{Float64}(undef, count, 3)
    for i in 1:count
        points[i, :] = convert_to_cartesian([longitudes[i], latitudes[i]])
    end
    points
end


"""
get_pullback(points, segments, sweep)

Calculates a pullback to the three sphere of a map with the given points
as the boundry, the number of segments around the circles and the sweep angle.
"""
function get_pullback(points, segments, sweep)
    samples = size(points, 1)
    pullback = Array{Float64}(undef, segments, samples, 3)
    phase = sweep / (segments-1)
    for i in 1:samples
        # Get the base point
        B = points[i, :]
        θ, ψ = convert_to_geographic(B)
        angle = phase
        X, Y, Z = get_points(B, angle)
        # Get the circle center point
        Q = get_center(X, Y, Z)
        # Find the circle radius
        radius = Float64(norm(X - Q))
        for j in 1:segments
            X, Y, Z = get_points(B, angle)
            pullback[j, i, :] = Z ./ radius
            angle += phase
        end
    end
    pullback
end


sg₁, og₁ = textslider(0:0.05:2pi, "g₁", start = 0)
sg₂, og₂ = textslider(0:0.05:2pi, "g₂", start = pi/12)
sg₃, og₃ = textslider(0:0.05:2pi, "g₃", start = pi/12)
# The three sphere rotations axis
g = @lift(ReferenceFrameRotations.Quaternion(cos($og₁),
                                             sin($og₁)*cos($og₂)*cos($og₃),
                                             sin($og₁)*cos($og₂)*sin($og₃),
                                             sin($og₁)*sin($og₂)))

samples = 1000
segments = 100
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.
countries = Dict("iran" => [1.0, 0.0, 0.0], # red
                 "us" => [0.0, 1.0, 0.0], # green
                 "china" => [0.0, 0.0, 1.0])#, # blue
                 #"ukraine" => [1.0, 1.0, 0.0], # yellow
                 #"australia" => [0.0, 1.0, 1.0], # cyan
                 #"germany" => [1.0, 0.0, 1.0], #magenta
                 #"israel" => [1.0, 1.0, 1.0]) # white
path = "data/natural_earth_vector"
universe = Scene(backgroundcolor = :black, show_axis=false)
for country in countries
    dataframe = CSV.read(joinpath(path, "$(country[1])-nodes.csv"))
    points = sample_points(dataframe, samples)
    count = size(points, 1)
    # Assign the country specific color to all points
    specific = RGBAf0(country[2]..., 1.0)
    inverse = RGBAf0((1 .- country[2])..., 1.0)
    color = fill(specific, segments, count)
    meshcolor = vec(fill(inverse, segments, count))
    # Assign a different color to one half of the points in every segment
    # For visualizing rotations around the axis perpendicular to a segment
    #for i in 1:segments
    #    color[i, 1:fld(count, 2)] = fill(inverse, fld(count, 2))
    #end
    rotated = @lift begin
        R = similar(points)
        for i in 1:count
            R[i, :] = rotate(points[i, :], $g)
        end
        R
    end
    sweep = 2pi
    pullback = @lift(get_pullback($rotated, segments, sweep))
    surface!(universe,
             @lift($pullback[:, :, 1]),
             @lift($pullback[:, :, 2]),
             @lift($pullback[:, :, 3]),
             color = color)
    #meshscatter!(universe,
    #             @lift(vec($pullback[:, :, 1])),
    #             @lift(vec($pullback[:, :, 2])),
    #             @lift(vec($pullback[:, :, 3])),
    #             markersize = 0.005,
    #             color = meshcolor)
end

scene = hbox(universe,
             vbox(sg₁, sg₂, sg₃),
             parent = Scene(resolution = (400, 400)))

eyepos = Vec3f0(3, 3, 3)
lookat = Vec3f0(0)
update_cam!(universe, eyepos, lookat)
universe.center = false # prevent scene from recentering on display

record(universe, "planet.gif") do io
    frames = 100
    for i in 1:frames
        og₁[] = i*2pi/frames # animate scene
        recordframe!(io) # record a new frame
    end
end


