using FileIO
using GLMakie
using Porta


figuresize = (4096, 2160)
segments = 36
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
markersize = 0.05
arclinewidth = 20
arrowsize = Vec3f(0.06, 0.06, 0.09)
arrowlinewidth = 0.03
arrowscale = 0.2
fontsize = 0.3
point_colorant = :black
triad_colorants = [:red, :green, :blue]
update_ratio = 0.01
visible = Observable(false)
points_colorants = [:orange, :cyan, :purple, :gold]

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
basemap3 = Basemap(lscene1, q, gauge3, M, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene1, q, gauge4, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.1)
    color2 = getcolor(boundary_nodes[i], reference, 0.2)
    color3 = getcolor(boundary_nodes[i], reference, 0.3)
    color4 = getcolor(boundary_nodes[i], reference, 0.4)
    whirl1 = Whirl(lscene1, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene1, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene1, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene1, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end

θ = Observable(ϵ)
ϕ = Observable(ϵ)
α = Observable(ϵ)
point = Observable(M * q * ℍ(exp(ϕ[] * longitudescale * K(1) + θ[] * latitudescale * K(2)) * exp(α[] * K(3))))
k1 = Observable(M * (q * ℍ(exp((ϕ[] + ϵ) * longitudescale * K(1)) * exp(α[] * K(3))) - q * ℍ(exp(ϕ[] * longitudescale * K(1)) * exp(α[] * K(3)))))
k2 = Observable(M * (q * ℍ(exp((θ[] + ϵ) * latitudescale * K(2)) * exp(α[] * K(3))) - q * ℍ(exp(θ[] * latitudescale * K(2)) * exp(α[] * K(3)))))
k3 = Observable(M * (q * ℍ(exp(ϕ[] * longitudescale * K(1) + θ[] * latitudescale * K(2)) * exp((α[] + ϵ) * K(3))) - q * ℍ(exp(ϕ[] * longitudescale * K(1) + θ[] * latitudescale * K(2)) * exp(α[] * K(3)))))
Ω = Observable(0.0)

point_observable = @lift(Point3f(project(normalize($point))))
pointa_observable = Observable(Point3f(project(normalize(point[]))))
pointb_observable = Observable(Point3f(project(normalize(point[]))))
pointc_observable = Observable(Point3f(project(normalize(point[]))))
pointd_observable = Observable(Point3f(project(normalize(point[]))))
k1_observable = @lift(Point3f(project(normalize($k1))))
k2_observable = @lift(Point3f(project(normalize($k2))))
k3_observable = @lift(Point3f(project(normalize($k3))))
ϵu_observable = Observable(k1_observable[])
ϵv_observable = Observable(k2_observable[])
ϕ_a_observable = Observable(k3_observable[])
ϕ_b_observable = Observable(k3_observable[])
ϕ_c_observable = Observable(k3_observable[])
ϕ_d_observable = Observable(k3_observable[])
meshscatter!(lscene1, point_observable, markersize = markersize, color = point_colorant)
meshscatter!(lscene2, point_observable, markersize = markersize * ϵ, color = point_colorant)
meshscatter!(lscene2, pointa_observable, markersize = markersize * ϵ, color = points_colorants[1])
meshscatter!(lscene2, pointb_observable, markersize = markersize * ϵ, color = points_colorants[2])
meshscatter!(lscene2, pointc_observable, markersize = markersize * ϵ, color = points_colorants[3])
meshscatter!(lscene2, pointd_observable, markersize = markersize * ϵ, color = points_colorants[4])

point_ps = @lift([$point_observable, $point_observable, $point_observable])
point_ns = @lift([$k1_observable, $k2_observable, $k3_observable])
arrows!(lscene1,
    point_ps, point_ns, fxaa = true, # turn on anti-aliasing
    color = triad_colorants,
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin, visible = visible
)

points_ps = @lift([$point_observable, $point_observable, $pointa_observable, $pointb_observable, $pointc_observable, $pointd_observable])
points_ns = @lift([$ϵu_observable, $ϵv_observable, $ϕ_a_observable, $ϕ_b_observable, $ϕ_c_observable, $ϕ_d_observable])
arrows!(lscene2,
    points_ps, points_ns, fxaa = true, # turn on anti-aliasing
    color = [triad_colorants[1:2]..., points_colorants...],
    linewidth = arrowlinewidth * ϵ, arrowsize = arrowsize .* ϵ,
    align = :origin
)

flowcolor = Observable([GLMakie.RGBAf(convert_hsvtorgb([359.0 * float(i) / float(segments); 1.0; 1.0])..., 1.0) for i in 1:segments])
flowps_array = []
flowns_array = []
for index in 1:segments
    flowps = Observable(Point3f.(project.([M * q * ℍ(exp(_ϕ * K(1))) for _ϕ in range(0, stop = 2π, length = segments)])))
    flowns = @lift([($flowps)[i] - ($flowps)[i - 1 < 1 ? length($flowps) : i - 1] for i in eachindex($flowps)])
    push!(flowps_array, flowps)
    push!(flowns_array, flowns)
    arrows!(lscene1,
        flowps, flowns, fxaa = true, # turn on anti-aliasing
        color = flowcolor,
        linewidth = arrowlinewidth / 4, arrowsize = arrowsize .* 0.25,
        align = :origin, visible = @lift(!$visible)
    )
end


titles1 = ["K₁", "K₂", "K₃"]
titles2 = @lift(["p", "a", "b", "c", "d", "ϵu", "ϵv",  "Ω =" * string(round($Ω, digits = 3)) * "𝑖"])
rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)

text!(lscene1,
    @lift([$point_observable + $k1_observable, $point_observable + $k2_observable, $point_observable + $k3_observable]),
    text = titles1,
    color = triad_colorants,
    rotation = rotation1,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data, transparency = false, visible = visible
)
text!(lscene2,
    @lift([$point_observable, $pointa_observable, $pointb_observable, $pointc_observable, $pointd_observable, $point_observable + $ϵu_observable, $point_observable + $ϵv_observable, $point_observable + $ϵu_observable + $ϵv_observable]),
    text = titles2,
    color = [point_colorant, points_colorants..., triad_colorants[1:2]..., :olive],
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = fontsize * ϵ,
    markerspace = :data, transparency = false
)

pathpoints = Observable(Point3f[])
pathcolors = Observable(Int[])
lines!(lscene1, pathpoints, color = pathcolors, linewidth = arclinewidth / 2, colorrange = (1, frames_number), colormap = :plasma, visible = visible)
lines!(lscene2, pathpoints, color = pathcolors, linewidth = arclinewidth / 4, colorrange = (1, frames_number), colormap = :plasma)

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
abcdplane = @lift(ℝ³.(hcat([$pointa_observable, $pointd_observable], [$pointb_observable, $pointc_observable])))
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
abcdplanecolor = Observable([points_colorants[1] points_colorants[2]; points_colorants[4] points_colorants[3]])
abcdplane_observables = buildsurface(lscene2, abcdplane, abcdplanecolor, transparency = true)
plane121_observables = buildsurface(lscene1, plane121, plane12_color, transparency = false)
plane122_observables = buildsurface(lscene1, plane122, plane12_color, transparency = true)
plane123_observables = buildsurface(lscene1, plane123, plane12_color, transparency = true)
plane124_observables = buildsurface(lscene1, plane124, plane12_color, transparency = true)
plane125_observables = buildsurface(lscene1, plane125, plane12_color, transparency = true)
plane126_observables = buildsurface(lscene1, plane126, plane12_color, transparency = true)
plane127_observables = buildsurface(lscene1, plane127, plane12_color, transparency = true)
plane128_observables = buildsurface(lscene1, plane128, plane12_color, transparency = true)
plane129_observables = buildsurface(lscene1, plane129, plane12_color, transparency = true)
plane1210_observables = buildsurface(lscene1, plane1210, plane12_color, transparency = true)
plane13_observables = buildsurface(lscene1, plane13, plane13_color, transparency = false)
plane23_observables = buildsurface(lscene1, plane23, plane23_color, transparency = false)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Ω = $(Ω[]), Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    if stage ∉ [1, 2, 3]
        if visible[] == false
            visible[] = true
        end
    end

    lengths = length.(boundary_nodes)
    N, boundary_index = findmax(lengths)
    nodes = boundary_nodes[boundary_index]
    index = max(1, Int(floor(progress * N)))
    p = nodes[index]
    _, θ[], ϕ[] = convert_to_geographic(p)

    _q = q
    _longitudescale = longitudescale
    _latitudescale = latitudescale
    if stage == 1
        _ϕ = sin(stageprogress * π)
        for index in 1:segments
            _α = index / segments * 2π
            flowps_array[index][] = Point3f.(project.([M * q * ℍ(exp(_ϕ * K(1) + _θ * K(2)) * exp(_α * K(3))) for _θ in range(0, stop = 2π, length = segments)]))
        end
        _q = q * ℍ(exp(_ϕ * K(1)))
    end
    if stage == 2
        _θ = sin(stageprogress * π)
        for index in 1:segments
            _α = index / segments * 2π
            flowps_array[index][] = Point3f.(project.([M * q * ℍ(exp(_ϕ * K(1) + _θ * K(2)) * exp(_α * K(3))) for _ϕ in range(0, stop = 2π, length = segments)]))
        end
        _q = q * ℍ(exp(_θ * K(2)))
    end
    if stage == 3
        _α = sin(stageprogress * π)
        for index in 1:segments
            _θ = index / segments * 2π
            flowps_array[index][] = Point3f.(project.([M * q * ℍ(exp(_ϕ * K(1) + _θ * K(2)) * exp(_α * K(3))) for _ϕ in range(0, stop = 2π, length = segments)]))
        end
        _q = q * ℍ(exp(_α * K(3)))
    end

    if stage == 4
        _longitudescale = longitudescale + sin(stageprogress * π / 2) * longitudescale
        _latitudescale = latitudescale + sin(stageprogress * π / 2) * latitudescale
        global eyeposition = normalize(ℝ³(point_observable[])) * float(2π - stageprogress * π)
    end
    if stage == 5
        _longitudescale = 2longitudescale
        _latitudescale = 2latitudescale
        global eyeposition = normalize(ℝ³(point_observable[])) * float(π)
    end
    if stage == 6
        _longitudescale = 2longitudescale - stageprogress * longitudescale
        _latitudescale = 2latitudescale - stageprogress * latitudescale
        global eyeposition = normalize(ℝ³(point_observable[])) * float(π + stageprogress * π)
    end
    if stage == 7
        global eyeposition = normalize(ℝ³(point_observable[])) * float(2π)
    end
    if stage == 8
        global eyeposition = normalize(ℝ³(point_observable[])) * float(2π)
    end

    if stage ∈ [1, 2, 3, 4, 5, 6]
        global points = Vector{Vector{ℍ}}()
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, _θ, _ϕ = convert_to_geographic(node)
                push!(_points, _q * ℍ(exp(_ϕ * _longitudescale * K(1) + _θ * _latitudescale * K(2))))
            end
            push!(points, _points)
        end
        _chart = (-π * _latitudescale / 2, π * _latitudescale / 2, -π * _longitudescale, π * _longitudescale)
        update!(basemap1, _q, gauge1, M, _chart)
        update!(basemap2, _q, gauge2, M, _chart)
        update!(basemap3, _q, gauge3, M, _chart)
        update!(basemap4, _q, gauge4, M, _chart)
        for i in eachindex(whirls1)
            update!(whirls1[i], points[i], gauge1, gauge2, M)
            update!(whirls2[i], points[i], gauge2, gauge3, M)
            update!(whirls3[i], points[i], gauge3, gauge4, M)
            update!(whirls4[i], points[i], gauge4, gauge5, M)
        end
    end

    _α = α[]
    _ϕ = ϕ[]
    _θ = θ[]
    k1[] = M * (_q * ℍ(exp((ϕ[] + ϵ) * _longitudescale * K(1)) * exp(α[] * K(3))) - q * ℍ(exp(ϕ[] * _longitudescale * K(1)) * exp(α[] * K(3))))
    k2[] = M * (_q * ℍ(exp((θ[] + ϵ) * _latitudescale * K(2)) * exp(α[] * K(3))) - q * ℍ(exp(θ[] * _latitudescale * K(2)) * exp(α[] * K(3))))
    k3[] = M * (_q * ℍ(exp(ϕ[] * _longitudescale * K(1) + θ[] * _latitudescale * K(2)) * exp((α[] + ϵ) * K(3))) - q * ℍ(exp(ϕ[] * _longitudescale * K(1) + θ[] * _latitudescale * K(2)) * exp(α[] * K(3))))
    point[] = M * _q * ℍ(exp(_ϕ * _longitudescale * K(1) + _θ * _latitudescale * K(2)) * exp(_α * K(3)))
    pointa = normalize(ℝ⁴(vec(M * _q * ℍ(exp((_ϕ * _longitudescale + ϵ / 2) * K(1) + _θ * _latitudescale * K(2)) * exp(_α * K(3))))))
    pointb = normalize(ℝ⁴(vec(M * _q * ℍ(exp((_ϕ * _longitudescale + ϵ) * K(1) + (_θ * _latitudescale + ϵ / 2) * K(2)) * exp(_α * K(3))))))
    pointc = normalize(ℝ⁴(vec(M * _q * ℍ(exp((_ϕ * _longitudescale + ϵ / 2) * K(1) + (_θ * _latitudescale + ϵ) * K(2)) * exp(_α * K(3))))))
    pointd = normalize(ℝ⁴(vec(M * _q * ℍ(exp(_ϕ * _longitudescale * K(1) + (_θ * _latitudescale + ϵ / 2) * K(2)) * exp(_α * K(3))))))
    ϵu = ℝ⁴(vec(M * _q * ℍ(exp((_ϕ * _longitudescale + ϵ) * K(1) + _θ * _latitudescale * K(2)) * exp(_α * K(3))) - point[]))
    ϵv = ℝ⁴(vec(M * _q * ℍ(exp(_ϕ * _longitudescale * K(1) + (_θ * _latitudescale + ϵ) * K(2)) * exp(_α * K(3))) - point[]))
    ϕa_u = imag(calculateconnection(ℍ(pointa), normalize(ϵu), ϵ = ϵ)[2])
    ϕb_v = imag(calculateconnection(ℍ(pointb), normalize(ϵv), ϵ = ϵ)[2])
    ϕc_u = imag(calculateconnection(ℍ(pointc), normalize(-ϵu), ϵ = ϵ)[2])
    ϕd_v = imag(calculateconnection(ℍ(pointd), normalize(-ϵv), ϵ = ϵ)[2])
    Ω[] = imag((ϕb_v - ϕd_v) - (ϕc_u - ϕa_u))
    notify(Ω)

    ϕ_a = normalize(ℝ⁴(vec(M * _q * ℍ(exp((_ϕ * _longitudescale + ϵ / 2) * K(1) + _θ * _latitudescale * K(2)) * exp((_α + ϵ) * K(3))))) - pointa)
    ϕ_b = normalize(ℝ⁴(vec(M * _q * ℍ(exp((_ϕ * _longitudescale + ϵ) * K(1) + (_θ * _latitudescale + ϵ / 2) * K(2)) * exp((_α + ϵ) * K(3))))) - pointb)
    ϕ_c = normalize(ℝ⁴(vec(M * _q * ℍ(exp((_ϕ * _longitudescale + ϵ / 2) * K(1) + (_θ * _latitudescale + ϵ) * K(2)) * exp((_α + ϵ) * K(3))))) - pointc)
    ϕ_d = normalize(ℝ⁴(vec(M * _q * ℍ(exp(_ϕ * _longitudescale * K(1) + (_θ * _latitudescale + ϵ / 2) * K(2)) * exp((_α + ϵ) * K(3))))) - pointd)
    pointa_observable[] = Point3f(project(pointa))
    pointb_observable[] = Point3f(project(pointb))
    pointc_observable[] = Point3f(project(pointc))
    pointd_observable[] = Point3f(project(pointd))
    ϵu_observable[] = Point3f(project(ϵu))
    ϵv_observable[] = Point3f(project(ϵv))
    ϕ_a_observable[] = Point3f(project(ϕ_a) * ϵ)
    ϕ_b_observable[] = Point3f(project(ϕ_b) * ϵ)
    ϕ_c_observable[] = Point3f(project(ϕ_c) * ϵ)
    ϕ_d_observable[] = Point3f(project(ϕ_d) * ϵ)
    
    push!(pathpoints[], point_observable[])
    push!(pathcolors[], frame)
    
    notify(ϕ)
    notify(θ)
    notify(pathpoints)
    notify(pathcolors)
    global lookat = ℝ³(Float64.(point_observable[])...)
    _eyeposition = rotate(eyeposition, ℍ(progress * 2π, ẑ))
    updatecamera!(lscene1, _eyeposition, lookat, up)
    lookat2 = ℝ³(pointa_observable[] + pointb_observable[] + pointc_observable[] + pointd_observable[]) * 0.25
    eyeposition2 = lookat2 + normalize(x̂ + ŷ + ẑ) * π * ϵ
    global up2 = normalize(cross(ℝ³(ϵv_observable[]), ℝ³(ϵu_observable[])))
    updatecamera!(lscene2, eyeposition2, lookat2, up2)
end


# animate(1)
# pathpoints[] = Point3f[]
# pathcolors[] = Int[]

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end