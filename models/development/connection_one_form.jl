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


modelname = "connection_one_form"
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
eyeposition_distance = float(π) * 0.7
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
transparency = 0.7
ϵ = 1e-3
ϵ4 = 0.01
progress = 0.0

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
lscene2 = LScene(fig[1, 2], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :white))
lscene3 = LScene(fig[2, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :white))
lscene4 = LScene(fig[2, 2], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)
rotation3 = gettextrotation(lscene3)
rotation4 = gettextrotation(lscene4)

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
P1 = Observable(P[])
P_observable = @lift(Point3f(project($P)))

meshscatter!(lscene1, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene2, Point3f(O), markersize = markersize, color = :black)
meshscatter!(lscene3, Point3f(O), markersize = markersize, color = :black)
meshscatter!(lscene4, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene1, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene2, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene3, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene4, P_observable, markersize = markersize, color = :gold)
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
	color = [:black, :gold],
	rotation = rotation2,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
text!(lscene3,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable])...]),
	text = titles,
	color = [:black, :gold],
	rotation = rotation3,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
text!(lscene4,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable])...]),
	text = titles,
	color = [:white, :gold],
	rotation = rotation4,
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
arrows3d!(lscene3,
	K1_points, K1_vectors, fxaa = true, # turn on anti-aliasing
	color = :red,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene3,
	K2_points, K2_vectors, fxaa = true, # turn on anti-aliasing
	color = :green,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene3,
	K3_points, K3_vectors, fxaa = true, # turn on anti-aliasing
	color = :blue,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene4,
	K1_points, K1_vectors, fxaa = true, # turn on anti-aliasing
	color = :red,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene4,
	K2_points, K2_vectors, fxaa = true, # turn on anti-aliasing
	color = :green,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene4,
	K3_points, K3_vectors, fxaa = true, # turn on anti-aliasing
	color = :blue,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)

K1_direction = @lift(ℍ(exp(ϵ * K(1))) * $P)
K2_direction = @lift(ℍ(exp(ϵ * K(2))) * $P)
K3_direction = @lift(ℍ(exp(ϵ * K(3))) * $P)
K1_observable = @lift(Point3f(normalize(project($K1_direction) - ℝ³($P_observable))))
K2_observable = @lift(Point3f(normalize(project($K2_direction) - ℝ³($P_observable))))
K3_observable = @lift(Point3f(normalize(project($K3_direction) - ℝ³($P_observable))))
vector_field_ps = @lift([$P_observable, $P_observable, $P_observable])
vector_field_ns = @lift([$K1_observable, $K2_observable, $K3_observable])
arrows3d!(lscene3,
	vector_field_ps, vector_field_ns, fxaa = true, # turn on anti-aliasing
	color = [:red, :green, :blue],
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
titles = ["K1", "K2", "K3"]
text!(lscene3,
	@lift([map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable + $K1_observable, $P_observable + $K2_observable, $P_observable + $K3_observable])...]),
	text = titles,
	color = [:red, :green, :blue],
	rotation = rotation3,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
K1K3_color_observable = fill(RGBAf(1.0, 0.0, 1.0, transparency / 3.0), 2, 2)
K1K3_surface = @lift([ℝ³($P_observable - $K1_observable - $K3_observable) ℝ³($P_observable - $K1_observable + $K3_observable); ℝ³($P_observable + $K1_observable - $K3_observable) ℝ³($P_observable + $K1_observable + $K3_observable)])
buildsurface(lscene3, K1K3_surface, K1K3_color_observable, transparency = true)
buildsurface(lscene4, K1K3_surface, K1K3_color_observable, transparency = true)

for ϵ₁ in range(-1.0, stop = 1.0, length = segments)
	_K1_direction = @lift(ℍ(exp(ϵ₁ * K(1))) * $P)
	_K2_direction = @lift(ℍ(exp(ϵ₁ * K(2))) * $P)
	_K3_direction = @lift(ℍ(exp(ϵ₁ * K(3))) * $P)
	_K1_observable = @lift(Point3f(project($_K1_direction) - ℝ³($P_observable)))
	_K2_observable = @lift(Point3f(project($_K2_direction) - ℝ³($P_observable)))
	_K3_observable = @lift(Point3f(project($_K3_direction) - ℝ³($P_observable)))
	# K1K2_color = RGBAf(1.0, 1.0, 0.0, 0.05)
	# K2K3_color = RGBAf(0.0, 1.0, 1.0, 0.05)
	# K1K2_color_observable = fill(K1K2_color, 2, 2)
	# K2K3_color_observable = fill(K2K3_color, 2, 2)
	# K1K2_surface = @lift(
	# 	[
	# 		ℝ³($P_observable + $_K3_observable - $_K1_observable - $_K2_observable) ℝ³($P_observable + $_K3_observable - $_K1_observable + $_K2_observable);
	# 		ℝ³($P_observable + $_K3_observable + $_K1_observable - $_K2_observable) ℝ³($P_observable + $_K3_observable + $_K1_observable + $_K2_observable)
	# 	]
	# )
	# K2K3_surface = @lift(
	# 	[
	# 		ℝ³($P_observable + $_K1_observable - $_K2_observable - $_K3_observable) ℝ³($P_observable + $_K1_observable - $_K2_observable + $_K3_observable);
	# 		ℝ³($P_observable + $_K1_observable + $_K2_observable - $_K3_observable) ℝ³($P_observable + $_K1_observable + $_K2_observable + $_K3_observable)
	# 	]
	# )
	# buildsurface(lscene1, K1K2_surface, K1K2_color_observable, transparency = true)
	# buildsurface(lscene1, K2K3_surface, K2K3_color_observable, transparency = true)
	meshscatter!(lscene3, @lift($P_observable + $_K2_observable), markersize = markersize, color = RGBAf(0.0, 1.0, 0.0, transparency))
	meshscatter!(lscene3, @lift($P_observable + $_K3_observable), markersize = markersize, color = RGBAf(0.0, 0.0, 1.0, transparency))
	meshscatter!(lscene3, @lift($P_observable + $_K1_observable), markersize = markersize, color = RGBAf(1.0, 0.0, 0.0, transparency))
end

ϵ2 = 0.01
sphere_ϵ = 0.5
lspace1 = range(-π, stop = float(π), length = Int(floor(segments / 2)))
lspace2 = range(-π / 2, stop = π / 2, length = Int(floor(segments / 2)))
for θ in lspace2
	for ϕ in lspace1
		x, y, z = vec(convert_to_cartesian([1.0; θ; ϕ]))
		adjacent_point = @lift(ℍ(exp(ϵ2 * x * K(1) + ϵ2 * y * K(2) + ϵ2 * z * K(3))) * $P)
		end_point_observable = @lift(Point3f(project(ℍ(exp(x * sphere_ϵ * K(1) + y * sphere_ϵ * K(2) + z * sphere_ϵ * K(3))) * $P)))
		adjacent_color = @lift(RGBAf(convert_hsvtorgb([max(0.0, min(359.0, compute_connection_A($P, $adjacent_point) * 359.0)); 1.0; 1.0])..., 1.0))
		adjacent_title = @lift([string(round(compute_connection_A($P, $adjacent_point), digits = 2))])
		meshscatter!(lscene1, end_point_observable, markersize = markersize / 3.0, color = adjacent_color)
		text!(lscene4,
			@lift([$end_point_observable]),
			text = adjacent_title,
			color = @lift([$adjacent_color]),
			rotation = rotation4,
			align = (:left, :baseline),
			fontsize = fontsize / 3.0,
			markerspace = :data,
			transparency = false,
		)
		linesegment = @lift([Point3f(project(ℍ(exp(ϵ3 * x * K(1) + ϵ3 * y * K(2) + ϵ3 * z * K(3))) * $P)) for ϵ3 in range(0, stop = sphere_ϵ, length = segments)])
		lines!(lscene4, linesegment, linewidth = linewidth / 3.0, color = adjacent_color, transparency = true)
	end
end
lspace11 = range(-π, stop = float(π), length = 2segments)
lspace22 = range(-π / 2, stop = π / 2, length = 2segments)
sphere = @lift([
	ℝ³(vec(Point3f(project(ℍ(exp(vec(convert_to_cartesian([1.0; θ; ϕ]))[1] * sphere_ϵ * K(1) + vec(convert_to_cartesian([1.0; θ; ϕ]))[2] * sphere_ϵ * K(2) + vec(convert_to_cartesian([1.0; θ; ϕ]))[3] * sphere_ϵ * K(3))) * $P)))) for θ in lspace22,
	ϕ in lspace11
])
sphere_color_array_observable = @lift([
	RGBAf(
		convert_hsvtorgb(
			[
				max(
					0.0,
					min(
						359.0,
						compute_connection_A($P, ℍ(exp(vec(convert_to_cartesian([1.0; θ; ϕ]))[1] * sphere_ϵ * K(1) + vec(convert_to_cartesian([1.0; θ; ϕ]))[2] * sphere_ϵ * K(2) + vec(convert_to_cartesian([1.0; θ; ϕ]))[3] * sphere_ϵ * K(3))) * $P) * 359.0,
					),
				)
				1.0;
				1.0
			],
		)...,
		transparency / 2.0,
	) for θ in lspace2, ϕ in lspace1
])
sphereobservable = buildsurface(lscene1, sphere, sphere_color_array_observable, transparency = true)

z₀ = @lift(complexvec($P)[1])
z₁ = @lift(complexvec($P)[2])
z̅₀ = @lift(conj(complexvec($P)[1]))
z̅₁ = @lift(conj(complexvec($P)[2]))
dz₀ = @lift(ℍ([$z₀ + ϵ; $z₁]) - $P)
dz₁ = @lift(ℍ([$z₀; $z₁ + ϵ]) - $P)
dz̅₀ = @lift(ℍ([$z̅₀ + ϵ; $z̅₁]) - $P)
dz̅₁ = @lift(ℍ([$z̅₀; $z̅₁ + ϵ]) - $P)
@assert(isapprox(abs(conj(z₀[]) * complexvec(dz₀[])[1] + conj(z₁[]) * complexvec(dz₁[])[2]), 0.0, atol = 10ϵ), "The horizontal tangent vector X at P must be perpendicular to the position vector z: z̅₀ X₀ + z̅₁ X₁ = 0.")


K1_observable = @lift(Point3f(project($K1)))
K2_observable = @lift(Point3f(project($K2)))
K3_observable = @lift(Point3f(project($K3)))
X_observable = @lift(Point3f(project($X)))
arrow_colorants = [:red, :green, :blue, :gold]
arrows3d!(lscene,
	@lift([$P_observable, $P_observable, $P_observable, $P_observable, $P_observable]),
	@lift([$K1_observable, $K2_observable, $K3_observable, $X_observable]),
	fxaa = true, # turn on anti-aliasing
	color = arrow_colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
text!(lscene,
	@lift(map(x -> x + $P_observable, [$K1_observable, $K2_observable, $K3_observable, $X_observable])),
	text = ["K1", "K2", "K3", "X"],
	color = arrow_colorants,
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

trace_created = false
trace_linecolors = Observable([1])
colorrange = collect(1:frames_number)
trace = Observable([P_observable[]])
directions = [K(1), K(3), -K(1), -K(3)]


animate(frame::Int) = begin
	progress = Float64(frame / frames_number)
	stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
	stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
	println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $(round(stageprogress, digits = 3))")

	P1[] = P[]
	if stage == 1
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 2
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 3
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 4
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	elseif stage == 5
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 6
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 7
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 8
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	elseif stage == 9
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 10
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 11
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 12
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	elseif stage == 13
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 14
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 15
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 16
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	elseif stage == 17
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 18
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 19
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 20
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	elseif stage == 21
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 22
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 23
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 24
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	elseif stage == 25
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 26
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 27
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 28
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	elseif stage == 29
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 30
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 31
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 32
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	elseif stage == 33
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[1])) * P1[]
	elseif stage == 34
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[2])) * P1[]
	elseif stage == 35
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[3])) * P1[]
	elseif stage == 36
		P[] = ℍ(exp(stageprogress * ϵ4 * directions[4])) * P1[]
	end

	push!(trace[], P_observable[])
	push!(trace_linecolors[], trace_linecolors[][end] + 1)
	notify(trace_linecolors)
	notify(trace)
	if length(trace[]) > 1 && trace_created == false
		lines!(lscene1, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
		lines!(lscene2, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
		lines!(lscene3, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
		lines!(lscene4, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
		global trace_created = true
	end

	lookat = ℝ³(P_observable[])
	_eyeposition = rotate(eyeposition, ℍ(progress * 4π, ℝ³(0.0, 0.0, 1.0)))
	updatecamera!(lscene1, _eyeposition, lookat, up)
	updatecamera!(lscene2, _eyeposition, lookat, up)
	updatecamera!(lscene3, _eyeposition, lookat, up)
	updatecamera!(lscene4, _eyeposition, lookat, up)
end


# animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
	animate(frame)
end