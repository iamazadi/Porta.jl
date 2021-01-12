import FileIO
import CSV
import GeometryBasics
import Observables
import AbstractPlotting
import Makie
import DataFrames


using Porta


startframe = 1
frames = 90
resolution = (360, 360)
maxsamples = 90
segments = 90
speed = 1
α = 40 / 180 * pi
solidtop = U1(pi - 2α)
solidbottom = U1(-pi)
ghosttop = U1(pi)
ghostbottom = solidtop
exportmode = ["gif", "frames", "video"]
exportmode = exportmode[1]
modelname = "planethopf"
FPS = 24


# Map from S² into itself
fmap(b::S²) = b


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
    coordinates = map(x -> Geographic(1, x[1], x[2]), eachrow([ϕ θ]))
    sampledpoints = Array{Geographic,1}(undef, max)
    count = length(coordinates)
    if count > max
        indices = convert(Array{Int64}, floor.(range(1, stop=count, length=max)))
        sampledpoints = coordinates[indices]
    else
        sampledpoints = coordinates
    end
    sampledpoints
end


# Use QGIS to design a geo map
colorref = FileIO.load("data/basemap_color.png")
color = FileIO.load("data/basemap_mask.png")
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.
countries = Dict("iran" => Geographic(1, 0.29826 * pi, 0.36031 * pi / 2),
                 "us" => Geographic(1, -0.53173 * pi, 0.41211 * pi / 2),
                 "china" => Geographic(1, 0.57886 * pi, 0.39846 * pi / 2),
                 "ukraine" => Geographic(1, 0.17314 * pi, 0.53754 * pi / 2),
                 "australia" => Geographic(1, 0.74319 * pi, -0.28082 * pi / 2),
                 "germany" => Geographic(1, 0.05806 * pi, 0.56850 * pi / 2),
                 "israel" => Geographic(1, 0.19362 * pi, 0.34495 * pi / 2),
                 "canada" => Geographic(1, -0.59081 * pi, 0.62367 * pi / 2),
                 "india" => Geographic(1, 0.43868 * pi, 0.22881 * pi / 2),
                 "southkorea" => Geographic(1, 0.70981 * pi, 0.39897 * pi / 2),
                 "france" => Geographic(1, 0.01229 * pi, 0.51364 * pi / 2),
                 "uganda" => Geographic(1, 0.1794 * pi , 0.0153 * pi / 2),
                 "brazil" => Geographic(1, 0.2884 * -pi, 0.1581 * -pi / 2),
                 "antarctica" => Geographic(1, 0.75 * pi, -0.92069 * pi / 2))
highlighted = ["us", "china", "iran"]
# The path to the dataset
path = "data/natural_earth_vector"
# The scene object that contains other visual objects
# AbstractPlotting.reasonable_resolution() = (800, 800)
AbstractPlotting.primary_resolution() = resolution
scene = AbstractPlotting.Scene(backgroundcolor = :black,
                               show_axis = false,
                               resolution = resolution)

s3rotation = Quaternion(1, 0, 0, 0)
config = Biquaternion(ℝ³(0, 0, 0))
solidwhirls = []
ghostwhirls = []
for country in countries
    countryname = country[1]
    dataframe = DataFrames.DataFrame(CSV.File(joinpath(path, "$(countryname)-nodes.csv")))
    center = country[2]
    x = Int(floor((center.ϕ + pi) / 2pi * size(color, 2)))
    y = size(color, 1) - Int(floor((center.θ + pi / 2) / pi * size(color, 1)))
    r, g, b, a = colorref[y, x].r, colorref[y, x].g, colorref[y, x].b, colorref[y, x].alpha
    solidcolor = AbstractPlotting.RGBAf0(r, g, b, 0.9)
    ghostcolor = AbstractPlotting.RGBAf0(r, g, b, 0.1)
    transparency = false
    if countryname == "antarctica"
        transparency = true
        solidcolor = AbstractPlotting.RGBAf0(r, g, b, 0.1)
    end
    parts = countryname == "us" ? 2 : 1 # countryname in highlighted ? 12 : 1
    for part in 0:parts-1
        # Sample a random subset of the points
        points = sample(dataframe, part, maxsamples)
        solidwhirl = Whirl(scene,
                           points,
                           τmap,
                           fmap,
                           top = solidtop,
                           bottom = solidbottom,
                           s3rotation = s3rotation,
                           config = config,
                           segments = segments,
                           color = solidcolor,
                           transparency = transparency)
        push!(solidwhirls, solidwhirl)
        if countryname in highlighted
            ghostwhirl = Whirl(scene,
                               points,
                               τmap,
                               fmap,
                               top = ghosttop,
                               bottom = ghostbottom,
                               s3rotation = s3rotation,
                               config = config,
                               segments = segments,
                               color = ghostcolor,
                               transparency = true)
            push!(ghostwhirls, ghostwhirl)
        end
    end
end

framesprites = []
framesprite1 = Frame(scene,
                     ghostbottom,
                     τmap,
                     fmap,
                     color,
                     s3rotation = s3rotation,
                     config = config,
                     segments = segments,
                     transparency = true)
framesprite2 = Frame(scene,
                     ghosttop,
                     τmap,
                     fmap,
                     color,
                     s3rotation = s3rotation,
                     config = config,
                     segments = segments,
                     transparency = true)
push!(framesprites, framesprite1)
push!(framesprites, framesprite2)


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i)
    step = (i - 1) / frames
    u = ℝ³(0, 0, 1)
    τ = step * speed * 2pi
    q = Quaternion(τ, u)
    #β = step * 2π
    #α = 80 / 180 * pi
    #solidtop = U1(pi - α) * U1(β)
    #solidbottom = U1(-pi) * U1(β)
    #ghosttop = U1(pi) * U1(β)
    #ghostbottom = solidtop
    #f(b::S²) = Cartesian(rotate(ℝ³(Cartesian(b)), q))

    for item in solidwhirls
        update(item, q)
        #update(item, σmap, f)
        #update(item, solidtop, solidbottom)
    end

    for item in ghostwhirls
        update(item, q)
        #update(item, σmap, f)
        #update(item, ghosttop, ghostbottom)
    end
    update(framesprite1, q)
    update(framesprite2, q)
end


n = ℝ³(0, 0, 1)
v = ℝ³(-2, 2, 1) * 0.9
# update eye position
# scene.camera.eyeposition.val
upvector = GeometryBasics.Vec3f0(vec(n)...)
eyeposition = GeometryBasics.Vec3f0(vec(v)...)
lookat = GeometryBasics.Vec3f0(0, 0, 0)
Makie.update_cam!(scene, eyeposition, lookat, upvector)
scene.center = false # prevent scene from recentering on display

if exportmode ∈ ["gif", "video"]
    outputextension = exportmode == "gif" ? "gif" : "mkv"
    Makie.record(scene, "gallery/$modelname.$outputextension",
                 framerate = FPS) do io
        for i in startframe:frames
            animate(i) # animate the scene
            Makie.recordframe!(io) # record a new frame
            step = (i - 1) / frames
            println("Completed step $(100step).\n")
        end
    end
elseif exportmode == "frames"
    directory = joinpath("gallery", modelname)
    if !isdir(directory)
        mkdir(directory)
    end
    for i in startframe:frames
        start = time()
        animate(i) # animate the scene
        elapsed = time() - start
        println("Generating frame $i took $elapsed (s).")

        start = time()
        imagename = "drorbarnatan2010_$(resolution[2])_$i.jpeg"
        filepath = joinpath(directory, imagename)
        FileIO.save(filepath,
                    scene;
                    resolution = resolution,
                    pt_per_unit = 100.0,
                    px_per_unit = 100.0)
        elapsed = time() - start
        println("Saving file $filepath took $elapsed (s).")

        step = (i - 1) / frames
        println("Completed step $(100step).\n")
        sleep(1)
    end
end
