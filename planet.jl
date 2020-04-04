using LinearAlgebra
using StatsBase
using FileIO
using Colors
using Makie
using CSV
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
    points = Array{Float64}(undef, count, 2)
    for i in 1:count
        points[i, :] = [longitudes[i], latitudes[i]]
    end
    points
end


"""
get_manifold(points, segments, distance, start, finish)

Calculates a grid of points in R³ for constructing a surface in a specific way
with the given points in the base space, the number of segments, the distance
from z axis, and the start and finish angles that determine where to cut.
"""
function get_manifold(points, segments, distance, start, finish)
    samples = size(points, 1)
    manifold = Array{Float64}(undef, segments, samples, 3)
    α = (finish - start) / (segments - 1)
    for i in 1:samples
            ϕ, θ = points[i, :]
        z, w = S¹action(start, σmap([ϕ, -θ]))
        for j in 1:segments
            x₁ = (real(z) + distance) * sin(start + (α * (j - 1)))
            x₂ = (real(z) + distance) * cos(start + (α * (j - 1)))
            x₃ = imag(z)
            manifold[j, i, :] = [x₁, x₂, x₃]
            z, w = S¹action(α, [z, w])
        end
    end
    manifold
end


"""
build_surface(scene, points, color; transparency, shading)

Builds a surface with the given scene, points, color, transparency and shading.
"""
function build_surface(scene,
                       points,
                       color;
                       transparency = false,
                       shading = true)
    surface!(scene,
             @lift($points[:, :, 1]),
             @lift($points[:, :, 2]),
             @lift($points[:, :, 3]),
             color = color,
             transparency = transparency,
             shading = shading)
end


# The scene object that contains other visual objects
universe = Scene(backgroundcolor = :black, show_axis=false, resolution = (360, 360))
# Use a slider for rotating the base space in an interactive way
sg, og = textslider(0:0.05:2pi, "g", start = 0)

# The maximum number of points to sample from the dataset for each country
max_samples = 300
segments = 60
# The angle to cut the manifolds for a better visualization
cut = 2pi / 360 * 80
# The manifold and ghost segments determine where to cut the fibers
ghost_segments = Integer(floor((cut / 2pi) * segments))
manifold_segments = segments - ghost_segments
manifold_start = 0
manifold_finish = 2pi - cut
ghost_start = 2pi - cut
ghost_finish = 2pi
# The distance from z axis
distance = pi / 2
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
path = "data/natural_earth_vector"
# Construct a manifold for each country in the dictionary
for country in countries
    dataframe = CSV.read(joinpath(path, "$(country[1])-nodes.csv"))
    # Sample a random subset of the points
    points = sample(dataframe, max_samples)
    samples = size(points, 1)
    color = fill(RGBAf0(country[2]..., 1.0), manifold_segments, samples)
    ghost_color = fill(RGBAf0(country[2]..., 0.5), ghost_segments, samples)
    # Rotate the points by adding to the longitudes
    rotated = @lift begin
        R = similar(points)
        for i in 1:samples
                  ϕ, θ = points[i, :]
            R[i, :] = [ϕ + $og, θ]
        end
        R
    end
    manifold = @lift(get_manifold($rotated,
                                  manifold_segments,
                                  distance,
                                  manifold_start,
                                  manifold_finish))
    build_surface(universe, manifold, color)
    if country[1] in ["iran", "us", "australia"]
        ghost = @lift(get_manifold($rotated,
                                   ghost_segments,
                                   distance,
                                   ghost_start,
                                   ghost_finish))
        build_surface(universe, ghost, ghost_color, transparency = false)
     end
end

disk_segments = 30
disk_samples = 30
# Parameters for the base map and fibers alignment
longitude_align = -pi/2 + pi / 100
latitude_align = 1.4

"""
get_disk(radius, segments, samples, x, y, phase, distance, rotation)

Calculates a grid of points in R³ for constructing a disk in a specific way
with the given radius, segments, samples, longitude alignment, latitude
alignment, the phase, the distance from z axis and the rotation around z axis.
the initial position of a disk is in the x = 0 plane.
"""
function get_disk(radius, segments, samples, x, y, distance, phase, rotation)
    p = Array{Float64}(undef, disk_segments, disk_samples, 3)
    lspace = range(0, stop = 2pi, length = disk_samples)
    for i in 1:segments
        yₐ = ((i-1) + y) / segments
        xₐ = phase + x + 2pi - rotation
        p[i, :, 1] = [(radius * yₐ * sin(j + xₐ) + distance) * sin(rotation)
                      for j in lspace]
        p[i, :, 2] = [(radius * yₐ * sin(j + xₐ) + distance) * cos(rotation)
                      for j in lspace]
        p[i, :, 3] = [yₐ * cos(j + xₐ) for j in lspace] .* radius
    end
    p
end

# Construct the 2 disks that show the base map
disk1 = @lift(get_disk(1,
                       disk_segments,
                       disk_samples,
                       longitude_align,
                       latitude_align,
                       distance,
                       $og,
                       0))
disk2 = @lift(get_disk(1,
                       disk_segments,
                       disk_samples,
                       longitude_align,
                       latitude_align,
                       distance,
                       $og,
                       2pi-cut))
# Construct the 2 disks that show the guidance grid
grid1 = @lift(get_disk(distance,
                       disk_segments,
                       disk_samples,
                       longitude_align,
                       latitude_align,
                       distance,
                       $og,
                       0))
grid2 = @lift(get_disk(distance,
                       disk_segments,
                       disk_samples,
                       longitude_align,
                       latitude_align,
                       distance,
                       $og,
                       2pi-cut))

base_image = load("data/BaseMap.png")
grid_image = load("data/boqugrid.png")

build_surface(universe, disk1, base_image, shading = false)
build_surface(universe, disk2, base_image, shading = false)
build_surface(universe, grid1, grid_image, shading = false)
build_surface(universe, grid2, grid_image, shading = false)

# Instantiate a horizontal box for holding the visuals and the controls
#scene = hbox(universe,
#             vbox(sg),
#             parent = Scene(resolution = (360, 360)))

# update eye position
eye_position, lookat, upvector = Vec3f0(-3, 3, 2), Vec3f0(0), Vec3f0(0, 0, 0.001)
update_cam!(universe, eye_position, lookat)
universe.center = false # prevent scene from recentering on display

record(universe, "planet.gif") do io
    frames = 180
    for i in 1:frames
        og[] = i*2pi/frames # animate scene
        recordframe!(io) # record a new frame
    end
end


