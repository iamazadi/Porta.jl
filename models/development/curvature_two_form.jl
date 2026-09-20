using FileIO
using GLMakie
using LinearAlgebra
using Porta


compute_connection_A(point::ℍ, adjacentpoint::ℍ) = begin
	_z₀, _z₁ = complexvec(point)
	_X₀ = complexvec(normalize(ℍ(vec(adjacentpoint) - vec(point))))[1]
	_X₁ = complexvec(normalize(ℍ(vec(adjacentpoint) - vec(point))))[2]
	_α₀ = _X₀
	_α₁ = _X₁
	abs(0.5 * (conj(_z₀) * _α₀ - _z₀ * conj(_α₀) + conj(_z₁) * _α₁ - _z₁ * conj(_α₁)))
end


modelname = "curvature_two_form"
totalstages = 36
figuresize = (1920, 1080)
frames_number = 1440
segments = 30
tiplength = 0.04
tipradius = 0.02
shaftradius = 0.01
linewidth = 5
markersize = 0.02
fontsize = 0.2
# camera configuration
eyeposition_distance = float(π) * 0.8
eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * eyeposition_distance
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
# bundle settings
gauge1 = 0.0
gauge2 = π / 2
gauge3 = float(π)
gauge4 = 3π / 2
gauge5 = 2π
latitudescale = 1 / 2
longitudescale = 1 / 4
chart = (-π * latitudescale / 2, π * latitudescale / 2, -π * longitudescale, π * longitudescale)
q = ℍ(0.5, 0.5, 0.5, 0.5)
M = Identity(4)
color = GLMakie.RGBAf(0.0, 1.0, 0.0, 0.75)
reference_point = ℍ(exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q
mask = load("data/basemap_mask.png")
transparency = 0.6
ϵ = 1e-3
ϵ4 = 0.01
progress = 0.0

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
lscene2 = LScene(fig[1, 2], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)

# Natural Earth comma-separated values
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set{String}()
boundary_nodes = Vector{Vector{ℝ³}}()
points = Vector{Vector{ℍ}}()
indices = Dict()
## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
# boundary_names = ["Iran", "United States of America", "China"]
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
		push!(_points, ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(3))) * q)
	end
	push!(points, _points)
end

whirls = []
for i in eachindex(points)
	# TODO: add a handedness field to Whirl and Basemap to show orthogonal complement planes through the origin in the tangent space at P
	whirl1 = Whirl(lscene2, points[i], gauge1, gauge3, M, segments, getcolor(boundary_nodes[i], mask, transparency / 5), transparency = true)
	whirl2 = Whirl(lscene2, points[i], gauge3, gauge5, M, segments, getcolor(boundary_nodes[i], mask, transparency / 2), transparency = true)
	push!(whirls, whirl1)
	push!(whirls, whirl2)
end
basemap1 = Basemap(lscene2, reference_point, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene2, reference_point, gauge3, M, chart, segments, mask, transparency = true)

O = ℝ³(0.0, 0.0, 0.0)
original_point = points[2][1]
P = Observable(original_point)
P′ = Observable(P[])
P_observable = @lift(Point3f(project($P)))

meshscatter!(lscene1, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene2, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene1, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene2, P_observable, markersize = markersize, color = :gold)
titles = ["O", "P"]
text!(lscene1,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable])...]),
	text = titles,
	color = [:white, :gold],
	rotation = rotation1,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
text!(lscene2,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable])...]),
	text = titles,
	color = [:white, :gold],
	rotation = rotation2,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

z₀ = @lift(complexvec($P)[1])
z₁ = @lift(complexvec($P)[2])
z̅₀ = @lift(conj(complexvec($P)[1]))
z̅₁ = @lift(conj(complexvec($P)[2]))
ψ = Observable(rand() * 2π)
# The tangent spaces of the unit sphere in ℂ²: TS³ = { (X₀, X₁) ∈ ℂ² | z̅₀ X₀ + z̅₁ X₁ = 0 }
X = @lift(normalize(ℍ(exp(sin($ψ) * ϵ * K(1) + cos($ψ) * ϵ * K(3))) * $P - $P))
X₀ = @lift(complexvec($X)[1])
X₁ = @lift(complexvec($X)[2])
X̅₀ = @lift(conj($X₀))
X̅₁ = @lift(conj($X₁))
@assert(isapprox(abs(z̅₀[] * X₀[] + z̅₁[] * X₁[]), 0.0, atol = ϵ), "The horizontal tangent vector X at P must be perpendicular to the position vector z: TS³ = { (X₀, X₁) ∈ ℂ² | z̅₀ X₀ + z̅₁ X₁ = 0 }.")
α₀ = X₀
α₁ = X₁
α̅₀ = X̅₀
α̅₁ = X̅₁
A = @lift(0.5 * ($z̅₀ * $α₀ - $z₀ * $α̅₀ + $z̅₁ * $α₁ - $z₁ * $α̅₁))
P1 = @lift(ℍ(exp(ϵ * K(1))) * $P)
P2 = @lift(ℍ(exp(ϵ * K(2))) * $P)
P3 = @lift(ℍ(exp(ϵ * K(3))) * $P)
K1 = @lift(normalize($P1 - $P))
K2 = @lift(normalize($P2 - $P))
K3 = @lift(normalize($P3 - $P))
# dA = @lift(compute_connection_A($P, $P1) * $K1 + compute_connection_A($P, $P2) * $K2 + compute_connection_A($P, $P3) * $K3)

K1_observable = @lift(Point3f(project($K1)))
K2_observable = @lift(Point3f(project($K2)))
K3_observable = @lift(Point3f(project($K3)))
arrow_colorants = [:red, :green, :blue]
arrows3d!(lscene1,
	@lift([$P_observable, $P_observable, $P_observable]),
	@lift([$K1_observable, $K2_observable, $K3_observable]),
	fxaa = true, # turn on anti-aliasing
	color = arrow_colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
text!(lscene1,
	@lift(map(x -> x + $P_observable, [$K1_observable, $K2_observable, $K3_observable])),
	text = @lift(["K1 = " * string(round(compute_connection_A($P, $K1), digits = 2)), "K2 = " * string(round(compute_connection_A($P, $K2), digits = 2)), "K3 = " * string(round(compute_connection_A($P, $K3), digits = 2))]),
	color = arrow_colorants,
	rotation = rotation1,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

lspace = range(0.0, stop = 2π, length = segments)
K1_points = @lift([Point3f(project(ℍ(exp(ψ * K(1))) * $P)) for ψ in lspace])
K2_points = @lift([Point3f(project(ℍ(exp(ψ * K(2))) * $P)) for ψ in lspace])
K3_points = @lift([Point3f(project(ℍ(exp(ψ * K(3))) * $P)) for ψ in lspace])
K1_vectors = @lift([$K1_points[i + 1 > segments ? 1 : i + 1] - $K1_points[i] for i in eachindex($K1_points)])
K2_vectors = @lift([$K2_points[i + 1 > segments ? 1 : i + 1] - $K2_points[i] for i in eachindex($K2_points)])
K3_vectors = @lift([$K3_points[i + 1 > segments ? 1 : i + 1] - $K3_points[i] for i in eachindex($K3_points)])
arrows3d!(lscene1,
	K1_points, K1_vectors, fxaa = true, # turn on anti-aliasing
	color = :red,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene1,
	K2_points, K2_vectors, fxaa = true, # turn on anti-aliasing
	color = :green,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene1,
	K3_points, K3_vectors, fxaa = true, # turn on anti-aliasing
	color = :blue,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)

K1K2_color = fill(RGBAf(0.5, 0.5, 0.0, transparency / 2.0), 2, 2)
K1K3_color = fill(RGBAf(0.5, 0.0, 0.5, transparency / 2.0), 2, 2)
K2K3_color = fill(RGBAf(0.0, 0.5, 0.5, transparency / 2.0), 2, 2)
K1K2_surface = @lift([ℝ³($P_observable - $K1_observable - $K2_observable) ℝ³($P_observable - $K1_observable + $K2_observable); ℝ³($P_observable + $K1_observable - $K2_observable) ℝ³($P_observable + $K1_observable + $K2_observable)])
K1K3_surface = @lift([ℝ³($P_observable - $K1_observable - $K3_observable) ℝ³($P_observable - $K1_observable + $K3_observable); ℝ³($P_observable + $K1_observable - $K3_observable) ℝ³($P_observable + $K1_observable + $K3_observable)])
K2K3_surface = @lift([ℝ³($P_observable - $K2_observable - $K3_observable) ℝ³($P_observable - $K2_observable + $K3_observable); ℝ³($P_observable + $K2_observable - $K3_observable) ℝ³($P_observable + $K2_observable + $K3_observable)])
buildsurface(lscene1, K1K2_surface, K1K2_color, transparency = true)
buildsurface(lscene1, K1K3_surface, K1K3_color, transparency = true)
buildsurface(lscene1, K2K3_surface, K2K3_color, transparency = true)

ϕ₁ = Observable(rand() * 2π - π)
θ₁ = Observable(rand() * π - π / 2)
ϕ₂ = Observable(rand() * 2π - π)
θ₂ = Observable(rand() * π - π / 2)
direction1 = @lift(convert_to_cartesian([1.0; $θ₁; $ϕ₁]))
direction2 = @lift(convert_to_cartesian([1.0; $θ₂; $ϕ₂]))
P′1 = @lift(exp(vec($direction1)[1] * ϵ * K(1) + vec($direction1)[2] * ϵ * K(2) + vec($direction1)[3] * ϵ * K(3)) * $P)
P′2 = @lift(exp(vec($direction2)[1] * ϵ * K(1) + vec($direction2)[2] * ϵ * K(2) + vec($direction2)[3] * ϵ * K(3)) * $P)
v1 = @lift(normalize($P′1 - $P))
v2 = @lift(normalize($P′2 - $P))
A1 = @lift(compute_connection_A($P, $P′1))
A2 = @lift(compute_connection_A($P, $P′2))
# P′1_observable = @lift(Point3f(project($v1)))
# P′2_observable = @lift(Point3f(project($v2)))
P′1_observable = @lift(Point3f(normalize(project($P′1) - project($P))))
P′2_observable = @lift(Point3f(normalize(project($P′2) - project($P))))
v1v2_colorants = [:magenta, :cyan]
arrows3d!(lscene1,
	@lift([$P_observable, $P_observable]),
	@lift([$P′1_observable, $P′2_observable]),
	fxaa = true, # turn on anti-aliasing
	color = v1v2_colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene2,
	@lift([$P_observable, $P_observable]),
	@lift([$P′1_observable, $P′2_observable]),
	fxaa = true, # turn on anti-aliasing
	color = v1v2_colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
text!(lscene1,
	@lift(map(x -> x + $P_observable, [$P′1_observable, $P′2_observable])),
	text = @lift(["v₁ = " * string(round($A1, digits = 2)), "v₂ = " * string(round($A2, digits = 2))]),
	color = v1v2_colorants,
	rotation = rotation1,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
text!(lscene2,
	@lift(map(x -> x + $P_observable, [$P′1_observable, $P′2_observable])),
	text = ["v₁", "v₂"],
	color = v1v2_colorants,
	rotation = rotation2,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
v1v2_color = fill(RGBAf(1.0, 1.0, 1.0, transparency), 2, 2)
v1v2_surface = @lift([ℝ³($P_observable) ℝ³($P_observable + $P′1_observable); ℝ³($P_observable + $P′2_observable) ℝ³($P_observable + $P′1_observable + $P′2_observable)])
buildsurface(lscene1, v1v2_surface, v1v2_color, transparency = true)
buildsurface(lscene2, v1v2_surface, v1v2_color, transparency = true)

v1_K1K2 = @lift(dot($v1, $K1) * $K1 + dot($v1, $K2) * $K2)
v1_K1K3 = @lift(dot($v1, $K1) * $K1 + dot($v1, $K3) * $K3)
v1_K2K3 = @lift(dot($v1, $K2) * $K2 + dot($v1, $K3) * $K3)
v2_K1K2 = @lift(dot($v2, $K1) * $K1 + dot($v2, $K2) * $K2)
v2_K1K3 = @lift(dot($v2, $K1) * $K1 + dot($v2, $K3) * $K3)
v2_K2K3 = @lift(dot($v2, $K2) * $K2 + dot($v2, $K3) * $K3)
v1_K1K2_observable = @lift(Point3f(project($v1_K1K2)))
v1_K1K3_observable = @lift(Point3f(project($v1_K1K3)))
v1_K2K3_observable = @lift(Point3f(project($v1_K2K3)))
v2_K1K2_observable = @lift(Point3f(project($v2_K1K2)))
v2_K1K3_observable = @lift(Point3f(project($v2_K1K3)))
v2_K2K3_observable = @lift(Point3f(project($v2_K2K3)))
v_K1K2_color = fill(RGBAf(1.0, 1.0, 0.5, transparency), 2, 2)
v_K1K3_color = fill(RGBAf(1.0, 0.5, 1.0, transparency), 2, 2)
v_K2K3_color = fill(RGBAf(0.5, 1.0, 1.0, transparency), 2, 2)
K1K2_projection = @lift([ℝ³($P_observable) ℝ³($P_observable + $v1_K1K2_observable); ℝ³($P_observable + $v2_K1K2_observable) ℝ³($P_observable + $v1_K1K2_observable + $v2_K1K2_observable)])
K1K3_projection = @lift([ℝ³($P_observable) ℝ³($P_observable + $v1_K1K3_observable); ℝ³($P_observable + $v2_K1K3_observable) ℝ³($P_observable + $v1_K1K3_observable + $v2_K1K3_observable)])
K2K3_projection = @lift([ℝ³($P_observable) ℝ³($P_observable + $v1_K2K3_observable); ℝ³($P_observable + $v2_K2K3_observable) ℝ³($P_observable + $v1_K2K3_observable + $v2_K2K3_observable)])
buildsurface(lscene1, K1K2_projection, v_K1K2_color, transparency = true)
buildsurface(lscene1, K1K3_projection, v_K1K3_color, transparency = true)
buildsurface(lscene1, K2K3_projection, v_K2K3_color, transparency = true)
buildsurface(lscene2, K1K2_projection, v_K1K2_color, transparency = true)
buildsurface(lscene2, K1K3_projection, v_K1K3_color, transparency = true)
buildsurface(lscene2, K2K3_projection, v_K2K3_color, transparency = true)
K1K2_area = @lift(map(x -> x + $P_observable, [Point3f(O), $v1_K1K2_observable, $v1_K1K2_observable + $v2_K1K2_observable, $v2_K1K2_observable, Point3f(O)]))
K1K3_area = @lift(map(x -> x + $P_observable, [Point3f(O), $v1_K1K3_observable, $v1_K1K3_observable + $v2_K1K3_observable, $v2_K1K3_observable, Point3f(O)]))
K2K3_area = @lift(map(x -> x + $P_observable, [Point3f(O), $v1_K2K3_observable, $v1_K2K3_observable + $v2_K2K3_observable, $v2_K2K3_observable, Point3f(O)]))
colorrange = collect(1:4)
lines!(lscene1, K1K2_area, linewidth = linewidth, color = v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = false)
lines!(lscene1, K1K3_area, linewidth = linewidth, color = v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = false)
lines!(lscene1, K2K3_area, linewidth = linewidth, color = v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = false)
lines!(lscene2, K1K2_area, linewidth = linewidth, color = v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = false)
lines!(lscene2, K1K3_area, linewidth = linewidth, color = v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = false)
lines!(lscene2, K2K3_area, linewidth = linewidth, color = v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = false)

trace_created = false
trace_linecolors = Observable([1])
colorrange = collect(1:frames_number)
trace = Observable([P_observable[]])
directions = @lift([vec($direction1)[1] * K(1) + vec($direction1)[2] * K(2) + vec($direction1)[3] * K(3),
                    vec($direction2)[1] * K(1) + vec($direction2)[2] * K(2) + vec($direction2)[3] * K(3),
					-(vec($direction1)[1] * K(1) + vec($direction1)[2] * K(2) + vec($direction1)[3] * K(3)),
					-(vec($direction2)[1] * K(1) + vec($direction2)[2] * K(2) + vec($direction2)[3] * K(3))])


animate(frame::Int) = begin
	progress = Float64(frame / frames_number)
	stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
	stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
	println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $(round(stageprogress, digits = 3))")

	P′[] = P[]
	if stage == 1
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 2
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 3
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 4
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	elseif stage == 5
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 6
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 7
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 8
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	elseif stage == 9
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 10
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 11
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 12
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	elseif stage == 13
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 14
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 15
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 16
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	elseif stage == 17
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 18
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 19
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 20
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	elseif stage == 21
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 22
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 23
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 24
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	elseif stage == 25
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 26
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 27
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 28
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	elseif stage == 29
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 30
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 31
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 32
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	elseif stage == 33
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][1])) * P′[]
	elseif stage == 34
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][2])) * P′[]
	elseif stage == 35
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][3])) * P′[]
	elseif stage == 36
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[][4])) * P′[]
	end

	push!(trace[], P_observable[])
	push!(trace_linecolors[], trace_linecolors[][end] + 1)
	notify(trace_linecolors)
	notify(trace)
	if length(trace[]) > 1 && trace_created == false
		lines!(lscene1, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
		lines!(lscene2, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
		global trace_created = true
	end


	lookat = ℝ³(P_observable[])
	_eyeposition = rotate(eyeposition, ℍ(progress * 4π, ℝ³(0.0, 0.0, 1.0)))
	updatecamera!(lscene1, _eyeposition, lookat, up)
	updatecamera!(lscene2, _eyeposition, lookat, up)
end


# animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
	animate(frame)
end