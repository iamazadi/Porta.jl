using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 360
segments2 = 15
frames_number = 360
totalstages = 8
modelname = "fig202phasespace"
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(π)
lookat1 = ℝ³(0.0, 0.0, 0.0)
lookat2 = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
mask = load("data/basemap_mask.png")
reference = load("data/basemap_color.png")
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set()
boundary_nodes = Vector{Vector{ℝ³}}()
points = Vector{Vector{ℍ}}()
indices = Dict()
T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
u = 𝕍(T, X, Y, Z)
q = ℍ(T, X, Y, Z)
tolerance = 1e-3
@assert(isnull(u, atol = tolerance), "u in not a null vector, $u.")
@assert(isapprox(norm(q), 1, atol = tolerance), "q in not a unit quaternion, $(norm(q)).")
ϵ = 1e-3
gauge1 = 0.0
gauge2 = π / 2
gauge3 = float(π)
gauge4 = 3π / 2
gauge5 = 2π
latitudescale = 1 / 2
longitudescale = 1 / 4
chart = (-π * latitudescale / 2, π * latitudescale / 2, -π * longitudescale, π * longitudescale)
M = Identity(4)
markersize = 0.03
arclinewidth = 20
arrowsize = Vec3f(0.04, 0.04, 0.05)
arrowlinewidth = 0.03
arrowscale = 0.2
fontsize = 0.3
point_colorant = :gold
triad_colorants = [:red, :green, :blue]
update_ratio = 0.95

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
lscene2 = LScene(fig[1, 2], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
while length(boundary_names) < 10
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
for i in eachindex(boundary_nodes)
    _points = Vector{ℍ}()
    for node in boundary_nodes[i]
        r, θ, ϕ = convert_to_geographic(node)
        push!(_points, q * ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(2))))
    end
    push!(points, _points)
end
basemap1 = Basemap(lscene1, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene1, q, gauge2, M, chart, segments, mask, transparency = true)
basemap3 = Basemap(lscene2, q, gauge3, M, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene2, q, gauge4, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.25)
    color2 = getcolor(boundary_nodes[i], reference, 0.5)
    color3 = getcolor(boundary_nodes[i], reference, 0.25)
    color4 = getcolor(boundary_nodes[i], reference, 0.5)
    whirl1 = Whirl(lscene1, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene1, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene2, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene2, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end


θ = Observable(0.0)
ϕ = Observable(0.0)
α = Observable(0.0)
point = @lift(M * q * ℍ(exp($ϕ * longitudescale * K(1) + $θ * latitudescale * K(2)) * exp($α * K(3))))
γ = Observable(0.0)
X = @lift(normalize(ℝ⁴(vec(M * q * ℍ(exp(($ϕ + ϵ * sin($γ)) * longitudescale * K(1) + ($θ + ϵ * cos($γ)) * latitudescale * K(2)) * exp($α * K(3))) - $point))))
v = @lift(calculateconnection($point, $X, ϵ = ϵ)[1])
connection = @lift(calculateconnection($point, $X, ϵ = ϵ)[2])
k1 = @lift(M * (q * ℍ(exp(($ϕ + ϵ) * longitudescale * K(1)) * exp($α * K(3))) - q * ℍ(exp($ϕ * longitudescale * K(1)) * exp($α * K(3)))))
k2 = @lift(M * (q * ℍ(exp(($θ + ϵ) * latitudescale * K(2)) * exp($α * K(3))) - q * ℍ(exp($θ * latitudescale * K(2)) * exp($α * K(3)))))
k3 = @lift(M * (q * ℍ(exp($ϕ * longitudescale * K(1) + $θ * latitudescale * K(2)) * exp(($α + ϵ) * K(3))) - q * ℍ(exp($ϕ * longitudescale * K(1) + $θ * latitudescale * K(2)) * exp($α * K(3)))))
a = @lift(calculateconnection($point, normalize(ℝ⁴(vec(M * q * ℍ(exp(($ϕ + ϵ) * longitudescale * K(1) + $θ * latitudescale * K(2)) * exp($α * K(3))) - $point))), ϵ = ϵ)[2])
b = @lift(calculateconnection($point, normalize(ℝ⁴(vec(M * q * ℍ(exp($ϕ * longitudescale * K(1) + ($θ + ϵ) * latitudescale * K(2)) * exp($α * K(3))) - $point))), ϵ = ϵ)[2])
c = @lift(calculateconnection($point, normalize(ℝ⁴(vec(M * q * ℍ(exp($ϕ * longitudescale * K(1) + $θ * latitudescale * K(2)) * exp(($α + ϵ) * K(3))) - $point))), ϵ = ϵ)[2])
ξ = @lift(imag(calculateconnection($point, $X, ϵ = ϵ)[2]) * $X)
γspace = range(0, stop = 2π, length = segments2)
directions = []
ξs = []
vs = []
connections = []
ξ_observables = []
v_observables = []
X_observables = []
for _γ in γspace
    _X = @lift(normalize(ℝ⁴(vec(M * q * ℍ(exp(($ϕ + ϵ * sin(_γ)) * longitudescale * K(1) + ($θ + ϵ * cos(_γ)) * latitudescale * K(2)) * exp($α * K(3))) - $point))))
    _ξ = @lift(imag(calculateconnection($point, $_X, ϵ = ϵ)[2]) * $_X)
    _ξ_observable = @lift(Point3f(project($_ξ)))
    _v = @lift(calculateconnection($point, $_X, ϵ = ϵ)[1])
    _v_observable = @lift(Point3f(project($_v)))
    _connection = @lift(calculateconnection($point, $_X, ϵ = ϵ)[2])
    _X_observable = @lift(Point3f(project($_X)))
    push!(X_observables, _X_observable)
    push!(connections, _connection)
    push!(vs, _v)
    push!(v_observables, _v_observable)
    push!(directions, _X)
    push!(ξs, _ξ)
    push!(ξ_observables, _ξ_observable)
end

q₁ = @lift($point * ℍ(exp(ϵ * K(1))))
q₂ = @lift($q₁ * ℍ(exp(ϵ * K(2))))
q₃ = @lift($point * ℍ(exp(ϵ * K(2))))
q₄ = @lift($q₃ * ℍ(exp(ϵ * K(1))))
liebracket = @lift(($q₂ - $q₄) * (1.0 / (ϵ * ϵ)))

point_observable = @lift(Point3f(project(normalize($point))))
X_observable = @lift(Point3f(normalize(project($X))))
v_observable = @lift(Point3f(normalize(project($v))))
k1_observable = @lift(Point3f(project(normalize($k1))))
k2_observable = @lift(Point3f(project(normalize($k2))))
k3_observable = @lift(Point3f(project(normalize($k3))))
ξ_observable = @lift(Point3f(project($ξ)))
liebracket_observable = @lift(Point3f(project($liebracket)))
meshscatter!(lscene1, point_observable, markersize = markersize, color = point_colorant)
meshscatter!(lscene2, point_observable, markersize = markersize, color = point_colorant)

point_ps1 = @lift([$point_observable, $point_observable, $point_observable, $point_observable, $point_observable])
point_ns1 = @lift([$k1_observable, $k2_observable, $k3_observable, $X_observable, $ξ_observable])
point_ps2 = @lift([$point_observable, $point_observable, $point_observable])
point_ns2 = @lift([$X_observable, $v_observable, $ξ_observable])
arrows!(lscene1,
    point_ps1, point_ns1, fxaa = true, # turn on anti-aliasing
    color = [triad_colorants..., :magenta, :olive],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)
arrows!(lscene2,
    point_ps2, point_ns2, fxaa = true, # turn on anti-aliasing
    color = [:magenta, :orange, :olive],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)


ps = @lift([$point_observable for i in 1:segments2])
ns = @lift([$(ξ_observables[1]), $(ξ_observables[2]), $(ξ_observables[3]), $(ξ_observables[4]), $(ξ_observables[5]), $(ξ_observables[6]), $(ξ_observables[7]), $(ξ_observables[8]), $(ξ_observables[9]), $(ξ_observables[10]), $(ξ_observables[11]), $(ξ_observables[12]), $(ξ_observables[13]), $(ξ_observables[14]), $(ξ_observables[15])])
arrows!(lscene1,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:black for _ in 1:segments2],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

v_ns = @lift([$(v_observables[1]), $(v_observables[2]), $(v_observables[3]), $(v_observables[4]), $(v_observables[5]), $(v_observables[6]), $(v_observables[7]), $(v_observables[8]), $(v_observables[9]), $(v_observables[10]), $(v_observables[11]), $(v_observables[12]), $(v_observables[13]), $(v_observables[14]), $(v_observables[15])])
X_ns = @lift([$(X_observables[1]), $(X_observables[2]), $(X_observables[3]), $(X_observables[4]), $(X_observables[5]), $(X_observables[6]), $(X_observables[7]), $(X_observables[8]), $(X_observables[9]), $(X_observables[10]), $(X_observables[11]), $(X_observables[12]), $(X_observables[13]), $(X_observables[14]), $(X_observables[15])])
arrows!(lscene2,
    ps, v_ns, fxaa = true, # turn on anti-aliasing
    color = [:black for _ in 1:segments2],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)
arrows!(lscene2,
    ps, X_ns, fxaa = true, # turn on anti-aliasing
    color = [:pink for _ in 1:segments2],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

titles1 = @lift(["p", "K₁", "K₂", "K₃", "X", "ξ=" * string(round(norm($ξ), digits = 3))])
titles2 = @lift(["p", "X", "v", "a=" * string(round(imag($connection), digits = 3)) * "𝑖"])
rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)
text!(lscene1,
    @lift([$point_observable, $point_observable + $k1_observable, $point_observable + $k2_observable, $point_observable + $k3_observable,
           $point_observable + $X_observable,
           $point_observable + $ξ_observable]),
    text = titles1,
    color = [point_colorant, triad_colorants..., :magenta, :olive],
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data, transparency = false
)
text!(lscene2,
    @lift([$point_observable,
           $point_observable + $X_observable, $point_observable + $v_observable,
           $point_observable + Point3f(normalize(ℝ³($X_observable + $v_observable)))]),
    text = titles2,
    color = [point_colorant, :magenta, :orange, :purple],
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data, transparency = false
)

arcpoints = @lift([$point_observable + Point3f(normalize(α * ℝ³($X_observable) + (1 - α) * ℝ³($v_observable))) for α in range(0, stop = 1, length = segments)])
arccolors = collect(1:segments)
lines!(lscene2, arcpoints, color = arccolors, linewidth = 2arclinewidth, colorrange = (1, segments), colormap = :prism)

arcpointsarray = []
for i in 1:segments2
    _arcpoints = @lift([$point_observable + Point3f(normalize(α * ℝ³($(X_observables[i])) + (1 - α) * ℝ³($(v_observables[i])))) for α in range(0, stop = 1, length = segments)])
    push!(arcpointsarray, _arcpoints)
    lines!(lscene2, _arcpoints, color = arccolors, linewidth = arclinewidth, colorrange = (1, segments), colormap = :prism)
end

pathpoints = Observable(Point3f[])
pathcolors = Observable(Int[])
lines!(lscene1, pathpoints, color = pathcolors, linewidth = arclinewidth / 2, colorrange = (1, frames_number), colormap = :rainbow)
lines!(lscene2, pathpoints, color = pathcolors, linewidth = arclinewidth / 2, colorrange = (1, frames_number), colormap = :rainbow)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    if stage == 1
        γ[] = stageprogress * float(π / 2)
    end
    if stage == 2
        ψ = stageprogress * float(π / 2)
        θ[] = cos(2ψ) * π / 2
        ϕ[] = sin(4ψ) * π
        α[] = ψ
        push!(pathpoints[], point_observable[])
        push!(pathcolors[], frame)
    end
    if stage == 3
        γ[] = float(π / 2) + stageprogress * float(π / 2)
    end
    if stage == 4
        ψ = float(π / 2) + stageprogress * float(π / 2)
        θ[] = cos(2ψ) * π / 2
        ϕ[] = sin(4ψ) * π
        α[] = ψ
        push!(pathpoints[], point_observable[])
        push!(pathcolors[], frame)
    end
    if stage == 5
        γ[] = float(π) + stageprogress * float(π / 2)
    end
    if stage == 6
        ψ = float(π) + stageprogress * float(π / 2)
        θ[] = cos(2ψ) * π / 2
        ϕ[] = sin(4ψ) * π
        α[] = ψ
        push!(pathpoints[], point_observable[])
        push!(pathcolors[], frame)
    end
    if stage == 7
        γ[] = float(π + π / 2) + stageprogress * float(π / 2)
    end
    if stage == 8
        ψ = float(π + π / 2) + stageprogress * float(π / 2)
        θ[] = cos(2ψ) * π / 2
        ϕ[] = sin(4ψ) * π
        α[] = ψ
        push!(pathpoints[], point_observable[])
        push!(pathcolors[], frame)
    end
    notify(arcpoints)
    notify(pathpoints)
    notify(pathcolors)

    # global up = ℝ³(k3_observable[])
    if frame == 1
        update_ratio = 0.0
    else
        update_ratio = 0.95
    end
    global lookat1 = update_ratio * lookat1 + (1.0 - update_ratio) * ℝ³(point_observable[] + ξ_observable[])
    global lookat2 = update_ratio * lookat2 + (1.0 - update_ratio) * ℝ³(point_observable[] + v_observable[])
    updatecamera!(lscene1, eyeposition, lookat1, up)
    updatecamera!(lscene2, eyeposition, lookat2, up)
end


# animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end