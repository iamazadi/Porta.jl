using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 60
segments2 = 15
flowsegments = 60
frames_number = 360
modelname = "fig209fieldlagrangians"
totalstages = 8
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
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
arrowsize = Vec3f(0.06, 0.06, 0.09)
arrowlinewidth = 0.03
arrowscale = 0.2
fontsize = 0.3
point_colorant = :gold
triad_colorants = [:red, :green, :blue]
update_ratio = 0.01
visible = Observable(false)

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

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
basemap1 = Basemap(lscene, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene, q, gauge2, M, chart, segments, mask, transparency = true)
basemap3 = Basemap(lscene, q, gauge3, M, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene, q, gauge4, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.1)
    color2 = getcolor(boundary_nodes[i], reference, 0.2)
    color3 = getcolor(boundary_nodes[i], reference, 0.3)
    color4 = getcolor(boundary_nodes[i], reference, 0.4)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end

θ = Observable(ϵ)
ϕ = Observable(ϵ)
α = Observable(ϵ)
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
meshscatter!(lscene, point_observable, markersize = markersize, color = point_colorant, visible = visible)

point_ps = @lift([$point_observable, $point_observable, $point_observable, $point_observable, $point_observable, $point_observable])
point_ns = @lift([$k1_observable, $k2_observable, $k3_observable, $X_observable, $v_observable, $ξ_observable])
arrows!(lscene,
    point_ps, point_ns, fxaa = true, # turn on anti-aliasing
    color = [triad_colorants..., :magenta, :orange, :olive],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin, visible = visible
)

ps = @lift([$point_observable for i in 1:segments2])
ns = @lift([$(ξ_observables[1]), $(ξ_observables[2]), $(ξ_observables[3]), $(ξ_observables[4]), $(ξ_observables[5]), $(ξ_observables[6]), $(ξ_observables[7]), $(ξ_observables[8]), $(ξ_observables[9]), $(ξ_observables[10]), $(ξ_observables[11]), $(ξ_observables[12]), $(ξ_observables[13]), $(ξ_observables[14]), $(ξ_observables[15])])
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:olive for _ in 1:segments2],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin, visible = visible
)

flowcolor = Observable([GLMakie.RGBAf(convert_hsvtorgb([359.0 * float(i) / float(flowsegments); 1.0; 1.0])..., 1.0) for i in 1:flowsegments])
flowps_array = []
flowns_array = []
for index in 1:flowsegments
    flowps = Observable(Point3f.(project.([M * q * ℍ(exp(_ϕ * K(1))) for _ϕ in range(0, stop = 2π, length = flowsegments)])))
    flowns = @lift([($flowps)[i] - ($flowps)[i - 1 < 1 ? length($flowps) : i - 1] for i in eachindex($flowps)])
    push!(flowps_array, flowps)
    push!(flowns_array, flowns)
    arrows!(lscene,
        flowps, flowns, fxaa = true, # turn on anti-aliasing
        color = flowcolor,
        linewidth = arrowlinewidth / 4, arrowsize = arrowsize .* 0.25,
        align = :origin, visible = @lift(!$visible)
    )
end

v_ns = @lift([$(v_observables[1]), $(v_observables[2]), $(v_observables[3]), $(v_observables[4]), $(v_observables[5]), $(v_observables[6]), $(v_observables[7]), $(v_observables[8]), $(v_observables[9]), $(v_observables[10]), $(v_observables[11]), $(v_observables[12]), $(v_observables[13]), $(v_observables[14]), $(v_observables[15])])
X_ns = @lift([$(X_observables[1]), $(X_observables[2]), $(X_observables[3]), $(X_observables[4]), $(X_observables[5]), $(X_observables[6]), $(X_observables[7]), $(X_observables[8]), $(X_observables[9]), $(X_observables[10]), $(X_observables[11]), $(X_observables[12]), $(X_observables[13]), $(X_observables[14]), $(X_observables[15])])
arrows!(lscene,
    ps, v_ns, fxaa = true, # turn on anti-aliasing
    color = [:purple for _ in 1:segments2],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin, visible = visible
)
arrows!(lscene,
    ps, X_ns, fxaa = true, # turn on anti-aliasing
    color = [:pink for _ in 1:segments2],
    linewidth = arrowlinewidth / 2, arrowsize = arrowsize,
    align = :origin, transparency = false, visible = visible
)

titles = @lift(["p", "K₁", "K₂", "K₃", "X", "v", "ξ", "a=" * string(round(imag($connection), digits = 3)) * "𝑖"])
rotation = gettextrotation(lscene)
text!(lscene,
    @lift([$point_observable, $point_observable + $k1_observable, $point_observable + $k2_observable, $point_observable + $k3_observable,
           $point_observable + $X_observable, $point_observable + $v_observable,
           $point_observable + $ξ_observable, $point_observable + Point3f(normalize(ℝ³($X_observable + $v_observable)))]),
    text = titles,
    color = [point_colorant, triad_colorants..., :magenta, :orange, :olive, :cyan],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data, transparency = false, visible = visible
)

arcpoints = @lift([$point_observable + Point3f(normalize(α * ℝ³($X_observable) + (1 - α) * ℝ³($v_observable))) for α in range(0, stop = 1, length = segments)])
arccolors = collect(1:segments)
lines!(lscene, arcpoints, color = arccolors, linewidth = arclinewidth, colorrange = (1, segments), colormap = :prism, visible = visible)

pathpoints = Observable(Point3f[])
pathcolors = Observable(Int[])
lines!(lscene, pathpoints, color = pathcolors, linewidth = arclinewidth, colorrange = (3Int(floor(frames_number / totalstages)), frames_number), colormap = :plasma, visible = visible)

weights = collect(range(0.0, stop = 1.0, length = 10))
plane121 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[1])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane122 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[2])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane123 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[3])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane124 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[4])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane125 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[5])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane126 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[6])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane127 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[7])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane128 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[8])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane129 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[9])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane1210 = @lift(map(x -> x + ℝ³(vec($k3_observable .* weights[10])...), ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k2_observable, $point_observable + $k1_observable + $k2_observable]))))
plane13 = @lift(ℝ³.(hcat([$point_observable, $point_observable + $k1_observable], [$point_observable + $k3_observable, $point_observable + $k1_observable + $k3_observable])))
plane23 = @lift(ℝ³.(hcat([$point_observable, $point_observable + $k2_observable], [$point_observable + $k3_observable, $point_observable + $k2_observable + $k3_observable])))
white = RGBAf(1.0, 1.0, 1.0, 0.1)
_white = RGBAf(1.0, 1.0, 1.0, 0.05)
black = RGBAf(0.0, 0.0, 0.0, 0.1)
_black = RGBAf(0.0, 0.0, 0.0, 0.05)
red = RGBAf(1.0, 0.0, 0.0, 0.9)
_red = RGBAf(1.0, 0.0, 0.0, 0.2)
green = RGBAf(0.0, 1.0, 0.0, 0.9)
_green = RGBAf(0.0, 1.0, 0.0, 0.2)
blue = RGBAf(0.0, 0.0, 1.0, 0.9)
_blue = RGBAf(0.0, 0.0, 1.0, 0.2)
plane12_color = Observable([white green; red black])
_plane12_color = Observable([_white _green; _red _black])
plane13_color = Observable([white blue; red black])
_plane13_color = Observable([_white _blue; _red _black])
plane23_color = Observable([white blue; green black])
_plane23_color = Observable([_white _blue; _green _black])
plane121_observables = buildsurface(lscene, plane121, plane12_color, visible, transparency = false)
plane122_observables = buildsurface(lscene, plane122, plane12_color, visible, transparency = true)
plane123_observables = buildsurface(lscene, plane123, plane12_color, visible, transparency = true)
plane124_observables = buildsurface(lscene, plane124, plane12_color, visible, transparency = true)
plane125_observables = buildsurface(lscene, plane125, plane12_color, visible, transparency = true)
plane126_observables = buildsurface(lscene, plane126, plane12_color, visible, transparency = true)
plane127_observables = buildsurface(lscene, plane127, plane12_color, visible, transparency = true)
plane128_observables = buildsurface(lscene, plane128, plane12_color, visible, transparency = true)
plane129_observables = buildsurface(lscene, plane129, plane12_color, visible, transparency = true)
plane1210_observables = buildsurface(lscene, plane1210, plane12_color, visible, transparency = true)
plane13_observables = buildsurface(lscene, plane13, plane13_color, visible, transparency = false)
plane23_observables = buildsurface(lscene, plane23, plane23_color, visible, transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)

    if stage ∉ [1, 2, 3]
        if visible[] == false
            visible[] = true
        end
        _α = α[]
        _ϕ = ϕ[]
        _θ = θ[]
        _point = point[]
        dϕ = normalize(ℝ⁴(vec(M * q * ℍ(exp(((_ϕ + ϵ) * longitudescale) * K(1) + _θ * latitudescale * K(2)) * exp(_α * K(3))) - _point)))
        dθ = normalize(ℝ⁴(vec(M * q * ℍ(exp(_ϕ * longitudescale * K(1) + (_θ + ϵ) * latitudescale * K(2)) * exp(_α * K(3))) - _point)))
        ϕvalue = imag(calculateconnection(_point, dϕ, ϵ = ϵ)[2])
        θvalue = imag(calculateconnection(_point, dθ, ϵ = ϵ)[2])
        scale = 1.0
        if abs(ϕvalue) > abs(θvalue)
            if scale * ϕvalue > 1e-1
                scale *= 1e-1
            end
            if scale * ϕvalue < 1e-2
                scale *= 10.0
            end
        else
            if scale * θvalue > 1e-1
                scale *= 1e-1
            end
            if scale * θvalue < 1e-2
                scale *= 10.0
            end
        end
        _ϕ -= 10scale * ϕvalue
        _θ -= 10scale * θvalue
        if _ϕ < 0.0
            _ϕ = min(-ϵ, _ϕ)
        end
        if _ϕ ≥ 0.0
            _ϕ = max(ϵ, _ϕ)
        end
        if _θ < 0.0
            _θ = min(-ϵ, _θ)
        end
        if _θ ≥ 0.0
            _θ = max(ϵ, _θ)
        end
        ϕ[] = _ϕ
        θ[] = _θ
        
        push!(pathpoints[], point_observable[])
        push!(pathcolors[], frame)

        try
            γ[] = atan(ϕvalue / θvalue)
        catch e
            println(e)
        end
    end
    _q = q
    if stage == 1
        _ϕ = sin(stageprogress * π)
        for index in 1:flowsegments
            _α = index / flowsegments * 2π
            flowps_array[index][] = Point3f.(project.([M * q * ℍ(exp(_ϕ * K(1) + _θ * K(2)) * exp(_α * K(3))) for _θ in range(0, stop = 2π, length = flowsegments)]))
        end
        _q = q * ℍ(exp(_ϕ * K(1)))
    end
    if stage == 2
        _θ = sin(stageprogress * π)
        for index in 1:flowsegments
            _α = index / flowsegments * 2π
            flowps_array[index][] = Point3f.(project.([M * q * ℍ(exp(_ϕ * K(1) + _θ * K(2)) * exp(_α * K(3))) for _ϕ in range(0, stop = 2π, length = flowsegments)]))
        end
        _q = q * ℍ(exp(_θ * K(2)))
    end
    if stage == 3
        _α = sin(stageprogress * π)
        for index in 1:flowsegments
            _θ = index / flowsegments * 2π
            flowps_array[index][] = Point3f.(project.([M * q * ℍ(exp(_ϕ * K(1) + _θ * K(2)) * exp(_α * K(3))) for _ϕ in range(0, stop = 2π, length = flowsegments)]))
        end
        _q = q * ℍ(exp(_α * K(3)))
    end
    if stage ∈ [1, 2, 3]
        global points = Vector{Vector{ℍ}}()
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, _θ, _ϕ = convert_to_geographic(node)
                push!(_points, _q * ℍ(exp(_ϕ * longitudescale * K(1) + _θ * latitudescale * K(2))))
            end
            push!(points, _points)
        end
        update!(basemap1, _q, gauge1, M)
        update!(basemap2, _q, gauge2, M)
        update!(basemap3, _q, gauge3, M)
        update!(basemap4, _q, gauge4, M)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1, gauge2, M)
            update!(whirls2[i], points[i], gauge2, gauge3, M)
            update!(whirls3[i], points[i], gauge3, gauge4, M)
            update!(whirls4[i], points[i], gauge4, gauge5, M)
        end
    end
    if stage == 4
        _longitudescale = longitudescale + sin(stageprogress * π / 2) * longitudescale
        _latitudescale = latitudescale + sin(stageprogress * π / 2) * latitudescale
        global points = Vector{Vector{ℍ}}()
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, _θ, _ϕ = convert_to_geographic(node)
                push!(_points, q * ℍ(exp(_ϕ * _longitudescale * K(1) + _θ * _latitudescale * K(2))))
            end
            push!(points, _points)
        end
        update!(basemap1, q, gauge1, M)
        update!(basemap2, q, gauge2, M)
        update!(basemap3, q, gauge3, M)
        update!(basemap4, q, gauge4, M)
        chart = (-π * _latitudescale / 2, π * _latitudescale / 2, -π * _longitudescale, π * _longitudescale)
        update!(basemap1, chart)
        update!(basemap2, chart)
        update!(basemap3, chart)
        update!(basemap4, chart)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1, gauge2, M)
            update!(whirls2[i], points[i], gauge2, gauge3, M)
            update!(whirls3[i], points[i], gauge3, gauge4, M)
            update!(whirls4[i], points[i], gauge4, gauge5, M)
        end
        global eyeposition = (1 - update_ratio) * eyeposition + update_ratio * normalize(ℝ³(point_observable[])) * float(2π - stageprogress * π)
        global lookat = (1 - update_ratio) * lookat + update_ratio * ℝ³(Float64.(point_observable[] + ξ_observable[])...)
    end
    if stage == 5
        _longitudescale = 2longitudescale
        _latitudescale = 2latitudescale
        global points = Vector{Vector{ℍ}}()
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, _θ, _ϕ = convert_to_geographic(node)
                push!(_points, q * ℍ(exp(_ϕ * _longitudescale * K(1) + _θ * _latitudescale * K(2))))
            end
            push!(points, _points)
        end
        gauge = stageprogress * π / 2
        update!(basemap1, q, gauge1 + gauge, M)
        update!(basemap2, q, gauge2 + gauge, M)
        update!(basemap3, q, gauge3 + gauge, M)
        update!(basemap4, q, gauge4 + gauge, M)
        chart = (-π * _latitudescale / 2, π * _latitudescale / 2, -π * _longitudescale, π * _longitudescale)
        update!(basemap1, chart)
        update!(basemap2, chart)
        update!(basemap3, chart)
        update!(basemap4, chart)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1 + gauge, gauge2 + gauge, M)
            update!(whirls2[i], points[i], gauge2 + gauge, gauge3 + gauge, M)
            update!(whirls3[i], points[i], gauge3 + gauge, gauge4 + gauge, M)
            update!(whirls4[i], points[i], gauge4 + gauge, gauge5 + gauge, M)
        end
        global eyeposition = (1 - update_ratio) * eyeposition + update_ratio * normalize(ℝ³(point_observable[])) * float(π)
        global lookat = (1 - update_ratio) * lookat + update_ratio * ℝ³(0.0, 0.0, 0.0)
    end
    if stage == 6
        _longitudescale = 2longitudescale - stageprogress * longitudescale
        _latitudescale = 2latitudescale - stageprogress * latitudescale
        global points = Vector{Vector{ℍ}}()
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, _θ, _ϕ = convert_to_geographic(node)
                push!(_points, q * ℍ(exp(_ϕ * _longitudescale * K(1) + _θ * _latitudescale * K(2))))
            end
            push!(points, _points)
        end
        gauge = π / 2 - stageprogress * π / 2
        update!(basemap1, q, gauge1 + gauge, M)
        update!(basemap2, q, gauge2 + gauge, M)
        update!(basemap3, q, gauge3 + gauge, M)
        update!(basemap4, q, gauge4 + gauge, M)
        chart = (-π * _latitudescale / 2, π * _latitudescale / 2, -π * _longitudescale, π * _longitudescale)
        update!(basemap1, chart)
        update!(basemap2, chart)
        update!(basemap3, chart)
        update!(basemap4, chart)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1 + gauge, gauge2 + gauge, M)
            update!(whirls2[i], points[i], gauge2 + gauge, gauge3 + gauge, M)
            update!(whirls3[i], points[i], gauge3 + gauge, gauge4 + gauge, M)
            update!(whirls4[i], points[i], gauge4 + gauge, gauge5 + gauge, M)
        end
        global eyeposition = (1 - update_ratio) * eyeposition + update_ratio * normalize(ℝ³(point_observable[])) * float(π + stageprogress * π)
        global lookat = (1 - update_ratio) * lookat + update_ratio * ℝ³(0.0, 0.0, 0.0)
    end
    if stage == 7 || stage == 8
        global eyeposition = (1 - update_ratio) * eyeposition + update_ratio * normalize(ℝ³(point_observable[])) * float(2π)
        global lookat = (1 - update_ratio) * lookat + update_ratio * ℝ³(0.0, 0.0, 0.0)
    end
    
    notify(ϕ)
    notify(θ)
    notify(arcpoints)
    notify(pathpoints)
    notify(pathcolors)
    _eyeposition = rotate(eyeposition, ℍ(progress * π, ẑ))
    updatecamera!(lscene, _eyeposition, lookat, up)
    println("a = $(connection[]), Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
end


# animate(1)
# arcpoints[] = Point3f[]
# pathcolors[] = Int[]

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end