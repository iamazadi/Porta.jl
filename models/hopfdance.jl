import FileIO
import GeometryBasics
import Observables
import AbstractPlotting
import GLMakie

using Porta

startframe = 1
FPS = 24
resolution = (360, 360)
segments = 60
speed = 1
#number = 360 * 5
factor = 0.0025
scale = 1.0
basemapradius = 1.025
basemapsegments = segments
basepointradius = 0.025
basepointsegments = 10
basepointtransparency = true
exportmode = ["gif", "frames", "video"]
exportmode = exportmode[1]
modelname = "hopfdance"


# Loping Sting by Kevin MacLeod is licensed under a Creative Commons Attribution
# 4.0 license. https://creativecommons.org/licenses/by/4.0/

# Source: http://incompetech.com/music/royalty-free/index.html?isrc=USUAN1200014

# Artist: http://incompetech.com/

audioname = "audio"
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

# The scene object that contains other visual objects
AbstractPlotting.reasonable_resolution() = (800, 800)
AbstractPlotting.primary_resolution() = resolution
scene = AbstractPlotting.Scene(backgroundcolor = :black,
                               show_axis = false,
                               resolution = resolution)


fmap(b::S²) = b


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
    rgb = hsvtorgb([hue * 360; s; v])
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


#basemapconfig = Biquaternion(ℝ³(0, -1.25, 0))
basemapconfig = Biquaternion(ℝ³(0, 0, 0))
basemapcolor = AbstractPlotting.RGBAf0(0.75, 0.75, 0.75, 0.25)
basemaptransparency = true
basemap = Sphere(basemapconfig,
                 scene,
                 radius = basemapradius,
                 segments = basemapsegments,
                 color = basemapcolor,
                 transparency = basemaptransparency)

curvepoints = getbutterflycurve(number)
solidcolors = Array{AbstractPlotting.RGBAf0,1}(undef, number)
ghostcolors = similar(solidcolors)
basepoints = Array{Sphere,1}(undef, number)
for i in 1:number
    config = Biquaternion(ℝ³(Cartesian(curvepoints[i])) * basemapradius)
    hue = (i - 1) / number * 360
    rgb = hsvtorgb([hue, 1, 1])
    solidcolors[i] = AbstractPlotting.RGBAf0(rgb..., 0.9)
    ghostcolors[i] = AbstractPlotting.RGBAf0(rgb..., 0.1)
    sphere = Sphere(basemapconfig * config,
                    scene,
                    radius = basepointradius,
                    segments = basepointsegments,
                    color = solidcolors[i],
                    transparency = basepointtransparency)
    basepoints[i] = sphere
end

#bundleconfig = Biquaternion(ℝ³(0, 1.25, 0))
bundleconfig = Biquaternion(ℝ³(0, 0, 0))
s3rotation = Quaternion(1, 0, 0, 0)
solidwhirls = Array{Whirl,1}(undef, number)
ghostwhirls = Array{Whirl,1}(undef, number)
α = 40 / 180 * pi
solidtop = U1(pi - 2α)
solidbottom = U1(-pi)
ghosttop = U1(pi)
ghostbottom = solidtop
for i in 1:number
    base = curvepoints[i]
    points = getpoints(base, segments = basepointsegments)
    transparency = false
    solidwhirl = Whirl(scene,
                       points,
                       τmap,
                       fmap,
                       top = solidtop,
                       bottom = solidbottom,
                       s3rotation = s3rotation,
                       config = bundleconfig,
                       segments = segments,
                       color = solidcolors[i],
                       transparency = transparency,
                       scale = scale)
    solidwhirls[i] = solidwhirl
    transparency = true
    ghostwhirl = Whirl(scene,
                       points,
                       τmap,
                       fmap,
                       top = ghosttop,
                       bottom = ghostbottom,
                       s3rotation = s3rotation,
                       config = bundleconfig,
                       segments = segments,
                       color = ghostcolors[i],
                       transparency = transparency,
                       scale = scale)
    ghostwhirls[i] = ghostwhirl
end

#a, b, c, d = [ComplexLine((float(i) + im)^i) for i in (-5, -2, 3, 7)]
a, b = ComplexLine(1 + im), ComplexLine(0.5 - 1.5 * im)
c, d = ComplexLine(-2 + 3 * im), ComplexLine(-1 + 0 * im)
basespacepoints = Array{ComplexLine,1}(undef, number)
phases = Array{U1,2}(undef, number, 4)
s3rotations = Array{Quaternion,1}(undef, number)
basespacecircles = Array{Any,1}(undef, number)


f(z, a, b, c, d) = (a * z + b) / (c * z + d)


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i::Int)
    frequencies = getdata(getfftchunk(signal, i, chunkspersecond, 3))#[indices]
    step = (i - 1) / frames
    τ = -step * speed * 4pi
    u = ℝ³(0, 1, 0)
    q = Quaternion(τ, u)
    a′, b′, c′, d′ = [ComplexLine(Cartesian(rotate(ℝ³(Cartesian(point)), q))).z
                      for point in (a, b, c, d)]
    point = getpointonpath(step)
    #println("ComplexLine(f(point.z, a′, b′, c′, d′)) = ", ComplexLine(f(point.z, a′, b′, c′, d′)))
    point = ComplexLine(f(point.z, a′, b′, c′, d′))
    if isnan(vec(point)[1]) || isnan(vec(point)[2])
        point = Geographic(1, 0, π/2)
    end
    point = Cartesian(point)
    for (index, item) in enumerate(frequencies)
        z = item
        z = ComplexLine(f(π * z, a′, b′, c′, d′))
        basespacepoints[index] = z
        #println("z = ", z)
        z′ = z
        if isnan(vec(z)[1]) || isnan(vec(z)[2])
            z′ = Geographic(1, 0, π/2)
        end
        basespacecircles[index] = getpoints(z′, segments = basepointsegments)
        realpart = real(item)
        imaginarypart = imag(item)
        magnitude = abs(item)
        α = magnitude * 2π
        s = U1(α)
        g = Quaternion(α, ℝ³(Cartesian(z)))
        h = S¹action(τmap(point), s) * g
        rgb = quaternionicrgb(h, q, 0.1 * abs(realpart) + 0.1 * rand() + 0.8,
                              0.1 * abs(imaginarypart) + 0.1 * rand() + 0.8)
        solidcolors[index] = AbstractPlotting.RGBAf0(rgb..., abs(realpart))
        ghostcolors[index] = AbstractPlotting.RGBAf0(rgb..., abs(imaginarypart))
        solidtop = U1(pi - 2α)
        ghostbottom = solidtop
        phases[index, 1] = solidtop
        phases[index, 2] = solidbottom
        phases[index, 3] = ghosttop
        phases[index, 4] = ghostbottom
        s3rotations[index] = g
    end
    for (index, item) in enumerate(basepoints)
        z = basespacepoints[index]
        p = ℝ³(Cartesian(z)) * basemapradius
        config = Biquaternion(p)
        update(item, basemapconfig * config)
        update(item, solidcolors[index])
    end
    for (index, item) in enumerate(solidwhirls)
        solidtop = phases[index, 1]
        solidbottom = phases[index, 2]
        update(item, basespacecircles[index], s3rotations[index], solidtop,
               solidbottom)
        update(item, solidcolors[index])
    end
    for (index, item) in enumerate(ghostwhirls)
        ghosttop = phases[index, 3]
        ghostbottom = phases[index, 4]
        update(item, basespacecircles[index], s3rotations[index], ghosttop,
               ghostbottom)
        update(item, ghostcolors[index])
    end

    z = Complex(0 + 0im)
    z = ComplexLine(f(π * z, a′, b′, c′, d′))
    z = ℝ³(Cartesian(z))

    z₀ = Complex(0 + im)
    z₀ = ComplexLine(f(π * z₀, a′, b′, c′, d′))
    z₀ = ℝ³(Cartesian(z₀))

    n = normalize(z₀ - z)
    #v = ℝ³(-1, 0, 1) * 2.5
    v = ℝ³(-1, 0, 1) * 2.1
    distance = norm(v)
    v = normalize(z) * distance
    # update eye position
    # scene.camera.eyeposition.val
    upvector = GeometryBasics.Vec3f0(vec(n)...)
    eyeposition = GeometryBasics.Vec3f0(vec(v)...)
    lookat = GeometryBasics.Vec3f0(0, 0, 0)
    AbstractPlotting.update_cam!(scene, eyeposition, lookat, upvector)
    scene.center = false # prevent scene from recentering on display
end


n = ℝ³(0, 0, 1)
#v = ℝ³(-1, 0, 1) * 2.5
v = ℝ³(-1, 0, 1) * 2.1
# update eye position
# scene.camera.eyeposition.val
upvector = GeometryBasics.Vec3f0(vec(n)...)
eyeposition = GeometryBasics.Vec3f0(vec(v)...)
lookat = GeometryBasics.Vec3f0(0, 0, 0)
AbstractPlotting.update_cam!(scene, eyeposition, lookat, upvector)
scene.center = false # prevent scene from recentering on display
if exportmode ∈ ["gif", "video"]
    outputextension = exportmode == "gif" ? "gif" : "mkv"
    AbstractPlotting.record(scene, "gallery/$modelname.$outputextension",
                            framerate = FPS) do io
        for i in startframe:frames
            animate(i) # animate the scene
            AbstractPlotting.recordframe!(io) # record a new frame
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
