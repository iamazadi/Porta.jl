using FileIO
using GLMakie
using Porta


scalarfield(x::Float64, y::Float64) = vec(convert_to_cartesian([1.0; (x + π / 2) / 2; y]))[3]


f(θ::Float64, ϕ::Float64, k::Float64) = begin
    z = θ + ϕ * im
    A = im * k * z
    ℝ³([θ; ϕ; k * scalarfield(real(z - A), imag(z - A))])
end


figuresize = (4096, 2160)
segments = 100
frames_number = 360
modelname = "fig1520stretchbyrealnumbers"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 0.0, 0.5)) * float(2π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
linewidth = 20
distance = float(2π)
radius = x̂ * float(π)
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set{String}()
boundary_nodes = Vector{Vector{ℝ³}}()
indices = Dict{String,Int}()
reference = load("data/basemap_color.png")
mask = load("data/basemap_mask.png")
markersize = 0.05
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
arrowscale = 0.5
k = 1.0
ϵ = 1e-3
totalstages = 6
colorrange = frames_number / totalstages
spawn = true
interpolation = 1.0
strain_intensity = 1.0

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
while length(boundary_names) < 30
    push!(boundary_names, rand(countries["name"]))
end
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            println(name)
            indices[name] = length(boundary_nodes)
        end
    end
end

lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
section1 = [ℝ³([-θ; ϕ; 0.0]) for θ in lspace2, ϕ in lspace1]
section2 = [f(-θ, ϕ, k) + k * ẑ for θ in lspace2, ϕ in lspace1]
section3 = [f(-θ, ϕ, k) + 2k * ẑ for θ in lspace2, ϕ in lspace1]
section4 = [f(-θ, ϕ, k) + 3k * ẑ for θ in lspace2, ϕ in lspace1]
section5 = [f(-θ, ϕ, k) + 4k * ẑ for θ in lspace2, ϕ in lspace1]
section6 = [f(-θ, ϕ, k) + 5k * ẑ for θ in lspace2, ϕ in lspace1]
sectionobservable1 = buildsurface(lscene, section1, mask, transparency = true)
sectionobservable2 = buildsurface(lscene, section2, mask, transparency = true)
sectionobservable3 = buildsurface(lscene, section3, mask, transparency = true)
sectionobservable4 = buildsurface(lscene, section4, mask, transparency = true)
sectionobservable5 = buildsurface(lscene, section5, mask, transparency = true)
sectionobservable6 = buildsurface(lscene, section6, mask, transparency = true)

fibersobservables = []
lspace = range(0.0, stop = distance, length = segments)
for index in 1:length(boundary_names)
    boundary = convert_to_geographic.(boundary_nodes[index])
    fiber = [ℝ³(vec(boundary[i])[2:3]..., _distance) for i in eachindex(boundary), _distance in lspace]
    color = fill(getcolor(boundary_nodes[index], reference, 0.5), length(boundary), segments)
    push!(fibersobservables, buildsurface(lscene, fiber, color, transparency = true))
end

path = Observable(Point3f[])
basepath = Observable(Point3f[])
colors = Observable(Int[])
lines!(lscene, path, color = colors, linewidth = linewidth, colorrange = (1, colorrange), colormap = :plasma)
lines!(lscene, basepath, color = colors, linewidth = linewidth, colorrange = (1, colorrange), colormap = :plasma)

uptail = Observable(Point3f(x̂))
upheadx = Observable(Point3f(x̂))
upheady = Observable(Point3f(ŷ))
basetail = Observable(Point3f(x̂))
baseheadx = Observable(Point3f(x̂))
baseheady = Observable(Point3f(ŷ))
ps = @lift([$uptail, $uptail, $basetail, $basetail])
ns = @lift([$upheadx, $upheady, $baseheadx, $baseheady])
colorants = [:red, :green]
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [colorants..., colorants...],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin, transparency = false
)
meshscatter!(lscene, uptail, markersize = markersize, color = :black)
meshscatter!(lscene, basetail, markersize = markersize, color = :black)

spawnframe = []
spawnps = []
spawnns = []
spawnupball = []
spawnbaseball = []


calculateframe(frame::Int, k::Float64) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    α = progress * 2π * totalstages
    p = exp(im * α)
    x = real(p)
    y = imag(p)
    _basepoint = ℝ³(x, y, 0.0)
    height = k * (stage - 1) + stageprogress * vec(f(x, y, k))[3]
    _uppoint = f(x, y, k) + ℝ³(0.0, 0.0, height)
    _uptail = Point3f(_uppoint)
    _basetail = Point3f(_basepoint)
    _baseheadx = Point3f(x̂)
    _baseheady = Point3f(ŷ)
    _upheadx = Point3f((f(x + ϵ, y, k) - f(x, y, k)) * (1 / ϵ))
    _upheady = Point3f((f(x, y + ϵ, k) - f(x, y, k)) * (1 / ϵ))
    _basetail, _baseheadx, _baseheady, _uptail, _upheadx, _upheady, height
end


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    if stage < totalstages
        global k = abs(cos(progress * 2π))
        section1 = [ℝ³([-θ; ϕ; 0.0]) for θ in lspace2, ϕ in lspace1]
        section2 = [f(-θ, ϕ, k) + k * ẑ for θ in lspace2, ϕ in lspace1]
        section3 = [f(-θ, ϕ, k) + 2k * ẑ for θ in lspace2, ϕ in lspace1]
        section4 = [f(-θ, ϕ, k) + 3k * ẑ for θ in lspace2, ϕ in lspace1]
        section5 = [f(-θ, ϕ, k) + 4k * ẑ for θ in lspace2, ϕ in lspace1]
        section6 = [f(-θ, ϕ, k) + 5k * ẑ for θ in lspace2, ϕ in lspace1]
        updatesurface!(section1, sectionobservable1)
        updatesurface!(section2, sectionobservable2)
        updatesurface!(section3, sectionobservable3)
        updatesurface!(section4, sectionobservable4)
        updatesurface!(section5, sectionobservable5)
        updatesurface!(section6, sectionobservable6)

        basetail[], baseheadx[], baseheady[], uptail[], upheadx[], upheady[], height = calculateframe(frame, k)
        spawn = true
        if spawn && frame % 5 == 0
            _ps = Observable([uptail[], uptail[], basetail[], basetail[]])
            _ns = Observable([upheadx[], upheady[], baseheadx[], baseheady[]])
            colorants = [:red, :green]
            arrows!(lscene,
                _ps, _ns, fxaa = true, # turn on anti-aliasing
                color = [colorants..., colorants...],
                linewidth = arrowlinewidth * arrowscale, arrowsize = arrowsize .* arrowscale,
                align = :origin, transparency = true
            )
            upball = Observable(uptail[])
            baseball = Observable(basetail[])
            meshscatter!(lscene, upball, markersize = markersize * arrowscale, color = :black)
            meshscatter!(lscene, baseball, markersize = markersize * arrowscale, color = :black)
            push!(spawnps, _ps)
            push!(spawnns, _ns)
            push!(spawnupball, upball)
            push!(spawnbaseball, baseball)
            push!(spawnframe, frame)
        end
        push!(basepath[], basetail[])
        push!(path[], uptail[])
        push!(colors[], frame % colorrange)
        for index in 1:frame - 1
            _basetail, _baseheadx, _baseheady, _uptail, _upheadx, _upheady, _height = calculateframe(index, k)
            basepath[][index] = _basetail
            path[][index] = _uptail
        end
        for index in eachindex(spawnframe)
            _basetail, _baseheadx, _baseheady, _uptail, _upheadx, _upheady, _height = calculateframe(spawnframe[index], k)
            spawnps[index][] = [_uptail, _uptail, _basetail, _basetail]
            spawnns[index][] = [_upheadx, _upheady, _baseheadx, _baseheady]
            spawnbaseball[index][] = _basetail
            spawnupball[index][] = _uptail
        end
        notify(basepath)
        notify(path)
        notify(colors)
        lookat = ℝ³(uptail[])
        updatecamera!(lscene, eyeposition + ℝ³(0.0, 0.0, height), lookat, up)
    else
        lookat = (1 - stageprogress) * ℝ³(0.0, 0.0, vec(ℝ³(uptail[]))[3])
        updatecamera!(lscene, -2ẑ * stageprogress + rotate(eyeposition + (1 - stageprogress) * ℝ³(0.0, 0.0, vec(ℝ³(uptail[]))[3]), ℍ(stageprogress * 2π, ẑ)), lookat, up)
    end
end


# animate(1)

# path[] = Point3f[]
# basepath[] = Point3f[]
# colors[] = Int[]
# for i in 1:frames_number
#     animate(i)
# end

path[] = Point3f[]
basepath[] = Point3f[]
colors[] = Int[]
record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end