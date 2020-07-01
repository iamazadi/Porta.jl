using LinearAlgebra
using GeometryBasics
using Makie
using Porta


samples = 36
segments = 36
radius = 0.015
const FPS = 24 # frames per second
basemapcenter = [-sqrt(2); sqrt(2); 0.0]
θ = Node(0.0)

function makebasemap(scene, center)
    function colormesh((geometry, color))
        mesh1 = normal_mesh(geometry)
        npoints = length(GeometryBasics.coordinates(mesh1))
        return GeometryBasics.pointmeta(mesh1; color=fill(color, npoints))
    end
    basemapradius = 0.5
    baselen = 0.05 * basemapradius; dirlen = 0.8 * basemapradius
    rectangles = [
        (Rect(Vec3f0(center...), Vec3f0(dirlen, baselen, baselen)), RGBAf0(0.3,0,0,0.3)),
        (Rect(Vec3f0(center...), Vec3f0(baselen, dirlen, baselen)), RGBAf0(0,0.3,0,0.3)),
        (Rect(Vec3f0(center...), Vec3f0(baselen, baselen, dirlen)), RGBAf0(0,0,0.3,0.3))
    ]
    meshes = map(colormesh, rectangles)
    mesh!(scene, merge(meshes))
    markerradius = 0.03 * basemapradius
    basecolor = [0.3; 0.3; 0.3]
    baseradius = 0.5
    markercenter = [rand(samples) rand(samples) rand(samples)]
    markercolor = [rand(samples) rand(samples) rand(samples)]
    basemap = 🌐(center, basecolor, baseradius, markercenter, markercolor, markerradius, 36)
    surface!(scene,
             basemap.basemanifold[:, :, 1],
             basemap.basemanifold[:, :, 2],
             basemap.basemanifold[:, :, 3],
             color = RGBAf0.(basemap.basecolor[:, :, 1],
                             basemap.basecolor[:, :, 2],
                             basemap.basecolor[:, :, 3],
                             0.3),
             transparency = true)
    surfacesx = []
    surfacesy = []
    surfacesz = []
    colors = []
    for i in 1:samples
        surfacex = Node(basemap.markermanifold[i, :, :, 1])
        surfacey = Node(basemap.markermanifold[i, :, :, 2])
        surfacez = Node(basemap.markermanifold[i, :, :, 3])
        color = Node(RGBAf0.(basemap.markercolor[i, :, :, 1],
                             basemap.markercolor[i, :, :, 2],
                             basemap.markercolor[i, :, :, 3],
                             0.9))
        push!(surfacesx, surfacex)
        push!(surfacesy, surfacey)
        push!(surfacesz, surfacez)
        push!(colors, color)
        surface!(scene, surfacex, surfacey, surfacez, color = color, transparency = true)
    end
    surfacesx, surfacesy, surfacesz, colors
end

function makehopf(scene, offset)
    lspace = range(0, stop = 2pi, length = samples)
    basepoints = convert(Array{Complex}, Complex.(cos.(lspace), sin.(lspace)))
    fiberactions = [fill(0.0, samples) fill(2pi, samples)]
    q = ℍ([cos(0); sin(0) .* [sqrt(3)/3; sqrt(3)/3; sqrt(3)/3]])
    h = ⭕(basepoints, fiberactions, segments, radius, q, offset)
    surfacesx = []
    surfacesy = []
    surfacesz = []
    colors = []
    for i in 1:samples
        surfacex = Node(h.m[i, :, :, 1])
        surfacey = Node(h.m[i, :, :, 2])
        surfacez = Node(h.m[i, :, :, 3])
        color = Node(RGBAf0.(h.c[i, :, :, 1],
                             h.c[i, :, :, 2],
                             h.c[i, :, :, 3],
                             0.9))
        push!(surfacesx, surfacex)
        push!(surfacesy, surfacey)
        push!(surfacesz, surfacez)
        push!(colors, color)
        surface!(scene, surfacex, surfacey, surfacez, color = color, transparency = true)
    end
    surfacesx, surfacesy, surfacesz, colors
end

name = "audio"
signal = Signal("test/data" * "/" * name * ".wav")
total_samples = Integer(fps(signal) ÷ FPS) - 2
indices = convert(Array{Int64}, floor.(range(2, stop=total_samples-1, length=samples)))
frames = chunks(signal, FPS)
q = @lift(ℍ([cos($θ); sin($θ) .* [sqrt(3)/3; sqrt(3)/3; sqrt(3)/3]]))

function animate(i,
                 hsurfacesx,
                 hsurfacesy,
                 hsurfacesz,
                 hcolors,
                 bsurfacesx,
                 bsurfacesy,
                 bsurfacesz,
                 bcolors)
    sₜ = chunk(signal, i, FPS)
    f = fft(sₜ)[indices]
    basepoints = convert(Array{Complex}, f)
    fiberactions = [fill(0.0, samples) tanh.(Base.abs.(basepoints)) .* 2pi]
    h = ⭕(basepoints, fiberactions, segments, radius, to_value(q), [0.0; 0.0; 0.0])
    basecolor = [0.3; 0.3; 0.3]
    baseradius = 0.5
    markercenter = ℝ³(basepoints)
    markercolor = [h.c[:, 1, 1, 1] h.c[:, 1, 1, 2] h.c[:, 1, 1, 3]]
    markerradius = 0.04 * baseradius
    basemap = 🌐(basemapcenter,
                 basecolor,
                 baseradius,
                 markercenter,
                 markercolor,
                 markerradius,
                 36)
    for j in 1:samples
        bsurfacesx[j][] = basemap.markermanifold[j, :, :, 1]
        bsurfacesy[j][] = basemap.markermanifold[j, :, :, 2]
        bsurfacesz[j][] = basemap.markermanifold[j, :, :, 3]
        bcolors[j][] = RGBAf0.(basemap.markercolor[j, :, :, 1],
                               basemap.markercolor[j, :, :, 2],
                               basemap.markercolor[j, :, :, 3],
                               0.9)
        hsurfacesx[j][] = h.m[j, :, :, 1]
        hsurfacesy[j][] = h.m[j, :, :, 2]
        hsurfacesz[j][] = h.m[j, :, :, 3]
        hcolors[j][] = RGBAf0.(h.c[j, :, :, 1],
                               h.c[j, :, :, 2],
                               h.c[j, :, :, 3],
                               0.9)
    end
    θ[] = 2pi * (i - 1) / frames
end

function preparescene(scene)
    eyeposition, lookat = Vec3f0(2, 2, 2), Vec3f0(0)
    update_cam!(scene, eyeposition, lookat)
    scene.center = false # prevent scene from recentering on display
end

scene = Scene(backgroundcolor = :white, show_axis=false, resolution=(720, 360))
hsurfacesx, hsurfacesy, hsurfacesz, hcolors = makehopf(scene, [0.0; 0.0; 0.0])
bsurfacesx, bsurfacesy, bsurfacesz, bcolors = makebasemap(scene, basemapcenter)

preparescene(scene)
record(scene, "gallery" * "/" * name * ".gif") do io
    for i in 1:frames
        sleep(1)
        @show (i / frames) * 100
        animate(i,
                hsurfacesx,
                hsurfacesy,
                hsurfacesz,
                hcolors,
                bsurfacesx,
                bsurfacesy,
                bsurfacesz,
                bcolors)
        recordframe!(io) # record a new frame
    end
end
