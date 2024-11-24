using FileIO
using GLMakie
using Porta


scalarfield(z::Float64, z̅::Float64) = begin
    p = convert_to_cartesian([1.0; (z + π / 2) / 2; z̅])
    vec(p)[3]
end


f(θ::Float64, ϕ::Float64, k::Float64) = begin
    z = θ + ϕ * im
    A = im * k * z
    ℝ³([θ; ϕ; scalarfield(real(z - A), imag(z - A))])
end


figuresize = (4096, 2160)
segments = 100
frames_number = 360
modelname = "fig1519localpathdependence"
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
section2 = [f(-θ, ϕ, k) + ẑ for θ in lspace2, ϕ in lspace1]
section3 = [f(-θ, ϕ, k) + 2ẑ for θ in lspace2, ϕ in lspace1]
section4 = [f(-θ, ϕ, k) + 3ẑ for θ in lspace2, ϕ in lspace1]
section5 = [f(-θ, ϕ, k) + 4ẑ for θ in lspace2, ϕ in lspace1]
section6 = [f(-θ, ϕ, k) + 5ẑ for θ in lspace2, ϕ in lspace1]
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

unitcircle = [Point3f(cos(α), sin(α), -0.5) for α in range(0, stop = 2π, length = segments)]
path = Observable(Point3f[])
basepath = Observable(Point3f[])
colors = Observable(Int[])
lines!(lscene, path, color = colors, linewidth = linewidth, colorrange = (1, colorrange), colormap = :rainbow)
lines!(lscene, basepath, color = colors, linewidth = linewidth, colorrange = (1, colorrange), colormap = :darkrainbow)
lines!(lscene, unitcircle, color = colors, linewidth = linewidth, colorrange = (1, colorrange), colormap = :lightrainbow)

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


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    if stage < totalstages
        α = progress * 2π * totalstages
        p = exp(im * α)
        z = real(p)
        z̅ = imag(p)
        basepoint = ℝ³(z, z̅, 0.0)
        phase = (stage - 1) + stageprogress * vec(f(z, z̅, k))[3]
        uppoint = f(z, z̅, k) + k * ℝ³(0.0, 0.0, phase)
        uptail[] = Point3f(uppoint)
        basetail[] = Point3f(basepoint)
        baseheadx[] = Point3f(x̂)
        baseheady[] = Point3f(ŷ)

        x = (f(z + ϵ, z̅, k) - f(z, z̅, k)) * (1 / ϵ)
        y = (f(z, z̅ + ϵ, k) - f(z, z̅, k)) * (1 / ϵ)
        upheadx[] = Point3f(x)
        upheady[] = Point3f(y)
        spawn = true
        if spawn && frame % 5 == 0
            _ps = [uptail[], uptail[], basetail[], basetail[]]
            _ns = [upheadx[], upheady[], baseheadx[], baseheady[]]
            colorants = [:red, :green]
            arrows!(lscene,
                _ps, _ns, fxaa = true, # turn on anti-aliasing
                color = [colorants..., colorants...],
                linewidth = arrowlinewidth * arrowscale, arrowsize = arrowsize .* arrowscale,
                align = :origin, transparency = true
            )
            meshscatter!(lscene, uptail[], markersize = markersize * arrowscale, color = :black)
            meshscatter!(lscene, basetail[], markersize = markersize * arrowscale, color = :black)
        end
        push!(basepath[], basetail[])
        push!(path[], uptail[])
        push!(colors[], frame % colorrange)
        notify(basepath)
        notify(path)
        notify(colors)
        lookat = ℝ³(uptail[])
        updatecamera!(lscene, eyeposition + ℝ³(0.0, 0.0, phase), lookat, up)
    else
        lookat = (1 - stageprogress) * ℝ³(0.0, 0.0, vec(ℝ³(uptail[]))[3])
        updatecamera!(lscene, -2ẑ * stageprogress + rotate(eyeposition + (1 - stageprogress) * ℝ³(0.0, 0.0, vec(ℝ³(uptail[]))[3]), ℍ(stageprogress * -π, ẑ)), lookat, up)
    end
end


# animate(1)

# path[] = Point3f[]
# basepath[] = Point3f[]
# for i in 1:frames_number
#     animate(i)
# end

path[] = Point3f[]
basepath[] = Point3f[]
record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end