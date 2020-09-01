import FileIO
import CSV
import StatsBase
import AbstractPlotting
import Makie
import DataFrames

using Porta


α = 40 / 180 * pi
solidtop = U1(pi)
solidbottom = U1(-pi + 2α)
ghosttop = U1(-pi + 2α)
ghostbottom = U1(-pi)


"""
sample(dataframe, part, max)

Samples points from a dataframe with the given `dataframe`, `part` id, and the `max` number
of samples limit.
"""
function sample(dataframe, part, max)
    groupdataframe = DataFrames.groupby(dataframe, :partid)
    subdataframe = groupdataframe[(partid=part,)]
    ϕ = subdataframe.x ./ 180 .* pi
    θ = subdataframe.y ./ 180 .* pi
    coordinates = map(x -> Geographic(x[1], x[2]), eachrow([ϕ θ]))
    sampledpoints = Array{Geographic,1}(undef, max)
    count = length(coordinates)
    if count > max
        StatsBase.sample!(coordinates, sampledpoints, replace = false, ordered = true)
    else
        sampledpoints = coordinates
    end
    sampledpoints
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
                 "antarctica" => [0.875, 0.651, 0.357])
# The path to the dataset
path = "test/data/natural_earth_vector"
# The scene object that contains other visual objects
scene = Makie.Scene(backgroundcolor = :white, show_axis = false, resolution = (360, 360))
maxsamples = 360
segments = 36
s3rotation = Quaternion(0, ℝ³(0, 0, 1))
config = Biquaternion(ℝ³(0, 0, 0))
solidwhirls = []
ghostwhirls = []
parts = 3
for country in countries
    countryname = country[1]
    dataframe = DataFrames.DataFrame(CSV.File(joinpath(path, "$(countryname)-nodes.csv")))
    solidcolor = Makie.RGBAf0(country[2]..., 0.9)
    ghostcolor = Makie.RGBAf0(country[2]..., 0.1)
    part = 0
    if countryname == "antarctica"
        points = sample(dataframe, part, maxsamples)
        ghostwhirl = Whirl(scene,
                           points,
                           top = ghosttop,
                           bottom = ghostbottom,
                           s3rotation = s3rotation,
                           config = config,
                           segments = segments,
                           color = ghostcolor,
                           transparency = true)
        push!(ghostwhirls, ghostwhirl)
    elseif countryname in ["us", "france", "iran", "canada", "china"]
        for part in 0:parts-1
            # Sample a random subset of the points
            points = sample(dataframe, part, maxsamples)
            solidwhirl = Whirl(scene,
                               points,
                               top = solidtop,
                               bottom = solidbottom,
                               s3rotation = s3rotation,
                               config = config,
                               segments = segments,
                               color = solidcolor,
                               transparency = false)
            push!(solidwhirls, solidwhirl)
            ghostwhirl = Whirl(scene,
                               points,
                               top = ghosttop,
                               bottom = ghostbottom,
                               s3rotation = s3rotation,
                               config = config,
                               segments = segments,
                               color = ghostcolor,
                               transparency = true)
            push!(ghostwhirls, ghostwhirl)
        end
    else
        # Sample a random subset of the points
        points = sample(dataframe, part, maxsamples)
        solidwhirl = Whirl(scene,
                           points,
                           top = solidtop,
                           bottom = solidbottom,
                           s3rotation = s3rotation,
                           config = config,
                           segments = segments,
                           color = solidcolor,
                           transparency = false)
        push!(solidwhirls, solidwhirl)
    end
end
# Use QGIS to design a geo map
framecolor = FileIO.load("test/data/basemap90grid.png")
framesprites = []
framesprite1 = Frame(scene,
                     solidtop,
                     framecolor,
                     s3rotation = s3rotation,
                     config = config,
                     segments = segments,
                     transparency = false)
framesprite2 = Frame(scene,
                     solidbottom,
                     framecolor,
                     s3rotation = s3rotation,
                     config = config,
                     segments = segments,
                     transparency = false)
push!(framesprites, framesprite1)
push!(framesprites, framesprite2)
frames = 360


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i)
    step = (i - 1) / frames
    println("Step: ", 100step)
    τ = step * 2pi - pi
    q = Quaternion(τ, ℝ³(0, 0, 1))
    for whirl in solidwhirls
        update(whirl, q)
    end
    for whirl in ghostwhirls
        update(whirl, q)
    end
    update(framesprite1, q)
    update(framesprite2, q)
end


# update eye position
# scene.camera.eyeposition.val
upvector = Makie.Vec3f0(0, 0, 1)
eyeposition = Makie.Vec3f0(sqrt(3) / 3, -sqrt(3) / 3, sqrt(3) / 3) .* 4
lookat = Makie.Vec3f0(sqrt(3) / 3, sqrt(3) / 3, sqrt(3) / 3)
Makie.update_cam!(scene, eyeposition, lookat, upvector)
scene.center = false # prevent scene from recentering on display
# Makie.save("gallery/drorbarnatan2010.jpg", scene)
Makie.record(scene, "gallery/drorbarnatan2010.gif") do io
    for i in 1:frames
        animate(i)
        Makie.recordframe!(io) # record a new frame
    end
end
