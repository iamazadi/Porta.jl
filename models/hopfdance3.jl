import LinearAlgebra
import FileIO
import GeometryBasics
import Observables
import Makie
import GLMakie
import VideoIO
import Images

using Porta


startframe = 1
FPS = 60
resolution = (3840, 2160)
segments = 36
speed = 1
factor = 0.0025
scale = 1.0
radius = 0.005
basemapradius = 1.015
basemapsegments = 2segments
basepointradius = 0.015
basepointsegments = 10
basepointtransparency = false
exportmode = ["gif", "frames", "video"]
exportmode = exportmode[2]
modelname = "hopfdance"


# Loping Sting by Kevin MacLeod is licensed under a Creative Commons Attribution
# 4.0 license. https://creativecommons.org/licenses/by/4.0/

# Source: http://incompetech.com/music/royalty-free/index.html?isrc=USUAN1200014

# Artist: http://incompetech.com/

audioname = "eric"
extension = ".wav"
audiopath = joinpath("data", audioname * extension)
signal = Signal(audiopath)
chunkspersecond = FPS
#totalsamples = Integer(getframerate(signal) ÷ chunkspersecond) - 1
totalsamples = length(getdata(getfftchunk(signal,1, chunkspersecond, 3)))
number = totalsamples
#indices = convert(Array{Int64},
#                  floor.(range(2, stop = totalsamples-1, length = number)))
frames = countchunks(signal, chunkspersecond)

videopath = "data/eric.mp4"
videoframes = VideoIO.openvideo(videopath)


# The scene object that contains other visual objects
#Makie.reasonable_resolution() = (800, 800)
scene = Makie.Scene(backgroundcolor = :black,
                               show_axis = false,
                               resolution = resolution)


function composeframes(image1, image2)
    height1, width1 = size(image1)
    height2, width2 = size(image2)
    scalefactor = height2 / height1
    newsize = (Int(floor(height1 * scalefactor)), Int(floor(width1 * scalefactor)))
    image3 = Images.imresize(image1, newsize)
    height3, width3 = size(image3)
    pad = Int((width2 - width3) ÷ 2)
    image4 = deepcopy(image2)
    image4[:, pad:pad+width3-1] = image2[begin:end, pad:pad+width3-1] .* 0.5 + image3 .* 0.5
    image4
end


fmap(b::S²) = b


"""
λ⁻¹map(p)
Sends a point on the plane back to a point on a unit sphere with the given
point. This is the inverse stereographic projection of a 3-sphere.
"""
function λ⁻¹map(p::S²)
    r3 = ℝ³(Cartesian(p))
    p₁, p₂, p₃ = vec(r3)
    mgnitude² = norm(r3)^2
    x₁ = 2p₁ / (1 + mgnitude²)
    x₂ = 2p₂ / (1 + mgnitude²)
    x₃ = 2p₃ / (1 + mgnitude²)
    x₄ = (-1 + mgnitude²) / (1 + mgnitude²)
    Quaternion(x₁, x₂, x₃, x₄)
end


"""
    getpointonpath(t)

Get a point on a path on S² with the given parameter `t`. t ∈ [0, 1].
"""
getpointonpath(t::Real) = begin
    t = t * 12π
    d = ℯ^cos(t) - 2cos(4t) - sin(t / 12)^5
    x, y = sin(t) * d, cos(t) * d
    ComplexLine(x + im * y)
end


"""
    getbutterflycurve(points)

Get butterfly curve by Temple H. Fay (1989) with the given number of `points`.
"""
function getbutterflycurve(points::Int)
    array = Array{ComplexLine,1}(undef, points)
    # 0 ≤ t ≤ 12π
    for i in 1:points
        t = (i - 1) / points * 12π
        d = ℯ^cos(t) - 2cos(4t) - sin(t / 12)^5
        x, y = sin(t) * d, cos(t) * d
        array[i] = ComplexLine(x + im * y)
    end
    array
end


quaternionicrgb(p::Quaternion, q::Quaternion, s::Real, v::Real) = begin
    hue = acos(dot(p, q)) / π
    hsvtorgb([hue * 360; s; v])
end


"""
    getpoints(z [, segments])

Get a circle of point in the base space with the given center `z` in the Riemann
sphere. The optional argument `segments` determines how many points should the
circle have.
"""
function getpoints(z::S²; segments::Int = 30)
    g = Geographic(z)
    r, ϕ, θ = vec(g)
    lspace = collect(range(float(-pi), stop = float(pi), length = segments))
    array = Array{Geographic,1}(undef, segments)
    for i in 1:segments
        ϕ′, θ′ = g.ϕ + factor * cos(lspace[i]), g.θ + factor * sin(lspace[i])
        array[i] = Geographic(r, ϕ′, θ′)
    end
    array
end


basemapconfig = Biquaternion(ℝ³(0, 1.1, 0))
# basemapconfig = Biquaternion(Quaternion(1, 0, 0, 0))
#basemapcolor = Makie.RGBAf0(0.75, 0.75, 0.75, 0.25)
#basemapcolor = FileIO.load("gallery/5672_mars_4k_color.jpg")
mars = Images.load("data/mars.jpg")
basemapcolor = mars
basemaptransparency = false
basemap = RGBSphere(basemapconfig,
                    scene,
                    basemapcolor,
                    radius = basemapradius,
                    segments = basemapsegments,
                    transparency = basemaptransparency)

curvepoints = getbutterflycurve(number)
solidcolors = Array{Makie.RGBAf,1}(undef, number)
ghostcolors = similar(solidcolors)
basepoints = Array{Sphere,1}(undef, number)
for i in 1:number
    config = Biquaternion(ℝ³(Cartesian(curvepoints[i])) * basemapradius)
    hue = (i - 1) / number * 360
    rgb = hsvtorgb([hue, 1, 1])
    solidcolors[i] = Makie.RGBAf(rgb..., 0.9)
    ghostcolors[i] = Makie.RGBAf(rgb..., 0.1)
    sphere = Sphere(basemapconfig * config,
                    scene,
                    radius = basepointradius,
                    segments = basepointsegments,
                    color = solidcolors[i],
                    transparency = basepointtransparency)
    basepoints[i] = sphere
end

#bundleconfig = Biquaternion(ℝ³(0, 1.25, 0))
bundleconfig = Biquaternion(ℝ³(0, -1.1, 0))
s3rotation = Quaternion(1, 0, 0, 0)
solidfibers = Array{Fiber,1}(undef, number)
ghostfibers = Array{Fiber,1}(undef, number)
α = 40 / 180 * pi
solidtop = U1(pi - 2α)
solidbottom = U1(-pi)
ghosttop = U1(pi)
ghostbottom = solidtop
for i in 1:number
    point = curvepoints[i]
    transparency = false
    solidfiber = Fiber(scene,
                       point,
                       λ⁻¹map,
                       fmap,
                       radius = radius,
                       top = solidtop,
                       bottom = solidbottom,
                       s3rotation = s3rotation,
                       config = bundleconfig,
                       segments = segments,
                       color = solidcolors[i],
                       transparency = transparency,
                       scale = scale)
    solidfibers[i] = solidfiber
    transparency = true
    ghostfiber = Fiber(scene,
                       point,
                       λ⁻¹map,
                       fmap,
                       radius = radius,
                       top = ghosttop,
                       bottom = ghostbottom,
                       s3rotation = s3rotation,
                       config = bundleconfig,
                       segments = segments,
                       color = ghostcolors[i],
                       transparency = transparency,
                       scale = scale)
    ghostfibers[i] = ghostfiber
end

basespacepoints = Array{ComplexLine,1}(undef, number)
phases = Array{U1,2}(undef, number, 4)
s3rotations = Array{Quaternion,1}(undef, number)
basespacecircles = Array{Any,1}(undef, number)

len = 0.1
width = 0.01
transparency = false
tail, head = ℝ³(rand(3)), ℝ³(rand(3))
arrows = []
for i in 1:number
    hue = (i - 1) / number * 360
    rgb = hsvtorgb([hue, 1, 1])
    color = Makie.RGBAf(rgb..., 0.9)
    push!(arrows, Arrow(tail, head, scene, width = width, color = color))
end

a, b = ComplexLine(1 + im), ComplexLine(0.5 - 1.5 * im)
c, d = ComplexLine(-0.5 + 1 * im), ComplexLine(-1 + 0.3 * im)
f(z, a, b, c, d) = (a * z + b) / (c * z + d)

videoframe = read(videoframes)

"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i::Int)
    frequencies = getdata(getfftchunk(signal, i, chunkspersecond, 3))#[indices]
    if i % 2 == 0
        try
            read!(videoframes, videoframe)
            println("Read the new video frame.")
        catch
            println("Reached the end of video stream.")
        end
    end
    basemapcolor = composeframes(videoframe, mars)
    println(basemapcolor == mars)
    update(basemap, basemapcolor)
    step = (i - 1) / frames
    step = 1 - step
    u = getpointonpath(step)
    if isnan(vec(u)[1]) || isnan(vec(u)[2])
        u = Geographic(1, 0, π/2)
    end
    τ = step * speed * 2pi
    u = ℝ³(Cartesian(u))
    q = Quaternion(τ, u)
    basemapconfig = Biquaternion(q, ℝ³(0, 1.1, 0))
    update(basemap, basemapconfig)
    a′, b′, c′, d′ = [ComplexLine(Cartesian(rotate(ℝ³(Cartesian(point)), q))).z for point in (a, b, c, d)]
    s3rotation = Quaternion(1, 0, 0, 0)
    for (index, item) in enumerate(frequencies)
        z = item
        z = ComplexLine(f(2π * z, a′, b′, c′, d′))
        if isnan(vec(z)[1]) || isnan(vec(z)[2])
            z = ComplexLine(Geographic(1, 0, -π / 2))
        end
        r, ϕ, θ = vec(Geographic(z))
        if isnan(r)
            z = ComplexLine(Geographic(1, ϕ, θ * 0.99))
        end
        
        basespacepoints[index] = z
        α = angle(z) + π
        fraction = α / 2π
        complement = 1 - fraction
        g = Quaternion(τ, ℝ³(0, 0, 1))
        q = λ⁻¹map(z)
        rgb = quaternionicrgb(g, q, 0.2 * fraction + 0.2 * rand() + 0.6, 0.2 * complement + 0.2 * rand() + 0.6)
        solidcolors[index] = Makie.RGBAf(rgb..., fraction)
        ghostcolors[index] = Makie.RGBAf(rgb..., complement)
        solidtop = U1(0)
        solidbottom = U1(α)
        ghosttop = solidbottom
        ghostbottom = U1(2π)
        phases[index, 1] = solidtop
        phases[index, 2] = solidbottom
        phases[index, 3] = ghosttop
        phases[index, 4] = ghostbottom
        #s3rotations[index] = g
    end
    for (index, item) in enumerate(basepoints)
        z = basespacepoints[index]
        p = ℝ³(Cartesian(z)) * basemapradius
        config = Biquaternion(p)
        update(item, basemapconfig * config)
        update(item, solidcolors[index])
    end
    for (index, item) in enumerate(solidfibers)
        solidtop = phases[index, 1]
        solidbottom = phases[index, 2]
        update(item, basespacepoints[index], s3rotation, radius, solidtop,
               solidbottom)
        update(item, solidcolors[index])
    end
    for (index, item) in enumerate(ghostfibers)
        ghosttop = phases[index, 3]
        ghostbottom = phases[index, 4]
        update(item, basespacepoints[index], s3rotation, radius, ghosttop,
               ghostbottom)
        update(item, ghostcolors[index])
    end

    # update tangent vectors
    for (index, item) in enumerate(arrows)
        w = basespacepoints[index]
        tail = ℝ³(Cartesian(w)) * basemapradius
        initial = ℝ³(0, 0, 1) * basemapradius
        q = getrotation(normalize(tail), normalize(initial))
        α = angle(phases[index, 2])
        factor = max(0.01, α / 2π) / 5
        head = initial + ℝ³(1, 0, 0) * factor
        head = rotate(head, q)
        q = Quaternion(α / 2, normalize(tail))
        head = rotate(head, q)
        tail, head = applyconfig([tail; head], basemapconfig)
        update(item, tail, head - tail)
        update(item, solidcolors[index])
    end

#=     z = Complex(0 + 0im)
    z = ComplexLine(f(π * z, a′, b′, c′, d′))
    z = ℝ³(Cartesian(z))

    z₀ = Complex(0 + im)
    z₀ = ComplexLine(f(π * z₀, a′, b′, c′, d′))
    z₀ = ℝ³(Cartesian(z₀)) =#

    #n = normalize(z₀ - z)
    #v = ℝ³(-1, 0, 1) * 2.5
    #v = ℝ³(-1, 0, 1) * 2.1
    #distance = norm(v)
    #v = normalize(z) * distance
    # update eye position
    # scene.camera.eyeposition.val
    #upvector = GeometryBasics.Vec3f0(vec(n)...)
    #eyeposition = GeometryBasics.Vec3f0(vec(v)...)
    #lookat = GeometryBasics.Vec3f0(0, 0, 0)
    #Makie.update_cam!(scene, eyeposition, lookat, upvector)
    #scene.center = false # prevent scene from recentering on display
end


n = ℝ³(0, 0, 1)
v = ℝ³(1, 0, 1) * 2.5
# update eye position
# scene.camera.eyeposition.val
upvector = GeometryBasics.Vec3f0(vec(n)...)
eyeposition = GeometryBasics.Vec3f0(vec(v)...)
lookat = GeometryBasics.Vec3f0(0, 0, 0)
camera = Makie.Camera3D(scene)
Makie.update_cam!(scene, camera, eyeposition, lookat, upvector)
#scene.center = false # prevent scene from recentering on display
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
    !isdir(directory) && mkdir(directory)
    directory = joinpath("gallery", modelname, audioname)
    !isdir(directory) && mkdir(directory)
    for i in startframe:frames
        start = time()
        animate(i) # animate the scene
        elapsed = time() - start
        println("Generating frame $i took $elapsed (s).")

        start = time()

        paddingnumber = length(digits(frames))
        imageid = lpad(i, paddingnumber, "0")
        imagename = "$(audioname)_$(resolution[2])p_$(FPS)fps_$imageid.jpeg"
        filepath = joinpath(directory, imagename)
        FileIO.save(filepath,
                    scene;
                    resolution = resolution,
                    pt_per_unit = 400.0,
                    px_per_unit = 400.0)
        elapsed = time() - start
        println("Saving file $filepath took $elapsed (s).")

        step = (i - 1) / frames
        println("Completed step $(100step).\n")
        sleep(1)

        stitch() = begin
            part = i ÷ (frames / 10)
            exportdir = joinpath(directory, "export")
            !isdir(exportdir) && mkdir(exportdir)
            #WxH = "$(resolution[1])x$(resolution[2])"
            WxH = "1920x1080"
            commonpart = "$(audioname)_$(resolution[2])p_$(FPS)fps"
            inputname = "$(commonpart)_%0$(paddingnumber)d.jpeg"
            inputpath = joinpath(directory, inputname)
            outputname = "$(commonpart)_$(part).mp4"
            outputpath = joinpath(exportdir, outputname)
            outputwithaudioname = "$(commonpart)_withaudio_$(part).mp4"
            outputwithaudiopath = joinpath(exportdir, outputwithaudioname)
            command1 = `ffmpeg -y -f image2 -framerate $FPS -i $inputpath -s $WxH -pix_fmt yuvj420p $outputpath`
            run(command1)
            sleep(1)
            command2 = `ffmpeg -y -i $outputpath -i $audiopath -c:v copy -map 0:v:0 -map 1:a:0 -c:a aac -b:a 192k -shortest $(outputwithaudiopath)`
            run(command2)
        end

        if isapprox(i % (frames / 10), 0)
            stitch()
            sleep(1)
        end
    end
end
