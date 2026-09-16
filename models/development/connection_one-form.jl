using FileIO
using GLMakie
using LinearAlgebra
using Porta


modelname = "connection_one_form"
totalstages = 36
figuresize = (1920, 1080)
frames_number = 1440
segments = 30
tiplength = 0.03
tipradius = 0.015
shaftradius = 0.005
linewidth = 5
markersize = 0.02
fontsize = 0.1
# camera configuration
eyeposition_distance = float(π) * 0.65
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
# q = normalize(ℍ(rand(4)))
q = normalize(ℍ(0.5, 0.5, 0.5, 0.5))
M = Identity(4)
color = GLMakie.RGBAf(0.0, 1.0, 0.0, 0.75)
reference_point = ℍ(exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q
mask = load("data/basemap_mask.png")
α = 0.75

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
lscene2 = LScene(fig[1, 2], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
lscene3 = LScene(fig[2, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
lscene4 = LScene(fig[2, 2], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)
rotation3 = gettextrotation(lscene3)
rotation4 = gettextrotation(lscene4)

# Natural Earth comma-separated values
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
boundary_names = Set()
boundary_nodes = Vector{Vector{ℝ³}}()
points = Vector{Vector{ℍ}}()
indices = Dict()
## Load the Natural Earth data
countries = loadcountries(attributespath, nodespath)
# boundary_names = ["Iran"]
boundary_names = ["Iran", "United States of America", "China"]
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

# TODO: add a handedness field to Whirl and Basemap to show orthogonal complement planes through the origin in the tangent space at P
whirl11 = Whirl(lscene1, points[1], gauge1, gauge3, M, segments, getcolor(boundary_nodes[1], mask, α / 4), transparency = true)
whirl12 = Whirl(lscene1, points[1], gauge3, gauge5, M, segments, getcolor(boundary_nodes[1], mask, α / 2), transparency = true)
whirl21 = Whirl(lscene1, points[2], gauge1, gauge3, M, segments, getcolor(boundary_nodes[2], mask, α / 4), transparency = true)
whirl22 = Whirl(lscene1, points[2], gauge3, gauge5, M, segments, getcolor(boundary_nodes[2], mask, α / 2), transparency = true)
whirl31 = Whirl(lscene1, points[3], gauge1, gauge3, M, segments, getcolor(boundary_nodes[3], mask, α / 4), transparency = true)
whirl32 = Whirl(lscene1, points[3], gauge3, gauge5, M, segments, getcolor(boundary_nodes[3], mask, α / 2), transparency = true)
basemap1 = Basemap(lscene1, reference_point, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene1, reference_point, gauge3, M, chart, segments, mask, transparency = true)

O = ℝ³(0.0, 0.0, 0.0)
# original_point = ℍ(complexvec(points[2][1]) .* exp(im * gauge2))
original_point = points[2][1]
P = Observable(original_point)
P_observable = @lift(Point3f(project($P)))

meshscatter!(lscene1, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene2, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene3, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene1, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene2, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene3, P_observable, markersize = markersize, color = :gold)
titles = ["O", "P"]
text!(lscene1,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable])...]),
	text = titles,
	color = [:white, :gold, :blue, :green],
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
text!(lscene3,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable])...]),
	text = titles,
	color = [:white, :gold],
	rotation = rotation3,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

z₀ = @lift(complexvec($P)[1])
z₁ = @lift(complexvec($P)[2])
ϵ = 0.01
# add a combination of K(1) and K(3) for zero 1-form A, and K(3) for non-zero 1-form A
# TODO: plot the right multiplication to see the wdge product of the 1-forms
P1 = @lift(ℍ(exp(ϵ * K(1))) * $P)
P1_observable = @lift(Point3f(0.5 * normalize(project($P1) - project($P))))
P1_linesegment = @lift([$P_observable, $P_observable + normalize($P1_observable)])
X₀ = @lift(complexvec(normalize(ℍ(vec($P1) - vec($P))))[1])
X₁ = @lift(complexvec(normalize(ℍ(vec($P1) - vec($P))))[2])
@assert(isapprox(abs(conj(z₀[]) * X₀[] + conj(z₁[]) * X₁[]), 0.0, atol = 1e-2), "The horizontal tangent vectors X at z must be perpendicular to the radial vector z: z̅₀ X₀ + z̅₁ X₁ = 0.")
# 1-forms
α₀ = X₀
α₁ = X₁
A = @lift(0.5 * (conj($z₀) * $α₀ - $z₀ * conj($α₀) + conj($z₁) * $α₁ - $z₁ * conj($α₁)))

titles = @lift(["A = " * string(round(imag($A), digits = 3))])
color_observable = @lift(RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($A) * 359.0)); 1.0; 1.0])..., 1.0))
text!(lscene3,
	@lift([$P_observable + normalize($P1_observable)]),
	text = titles,
	color = @lift([$color_observable]),
	rotation = rotation1,
	align = (:left, :baseline),
	fontsize = 2fontsize,
	markerspace = :data,
)
lines!(lscene3, P1_linesegment, linewidth = linewidth, color = color_observable, transparency = true)
meshscatter!(lscene3, @lift($P_observable + normalize($P1_observable)), markersize = 2markersize, color = color_observable)

X0 = @lift(ℍ([complexvec(normalize(ℍ(vec($P1) - vec($P))))[1]; 0.0 + im * 0.0]))
X1 = @lift(ℍ([0.0; complexvec(normalize(ℍ(vec($P1) - vec($P))))[2]]))
X0conj = @lift(ℍ([conj(complexvec(normalize(ℍ(vec($P1) - vec($P))))[1]); 0.0 + im * 0.0]))
X1conj = @lift(ℍ([0.0 + im * 0.0; conj(complexvec(normalize(ℍ(vec($P1) - vec($P))))[2])]))
X0_observable = @lift(Point3f(project($X0)))
X1_observable = @lift(Point3f(project($X1)))
X0conj_observable = @lift(Point3f(project($X0conj)))
X1conj_observable = @lift(Point3f(project($X1conj)))
oneform_ps = @lift([$P_observable, $P_observable, $P_observable, $P_observable])
oneform_ns = @lift([$X0_observable, $X1_observable, $X0conj_observable, $X1conj_observable])
arrows3d!(lscene1,
	oneform_ps, oneform_ns, fxaa = true, # turn on anti-aliasing
	color = [:red, :silver, :magenta, :brown],
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
titles = ["α₀", "α₁", "α̅₀", "α̅₁"]
text!(lscene1,
	@lift([$P_observable + $X0_observable, $P_observable + $X1_observable, $P_observable + $X0conj_observable, $P_observable + $X1conj_observable]),
	text = titles,
	color = [:red, :silver, :magenta, :brown],
	rotation = rotation1,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
# draw the oriented area made by the wdge product of a pair of one-forms
color_array_observable = @lift(fill(RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($A) * 359.0)); 1.0; 1.0])..., α), 2, 2))
X0X0conj = @lift([ℝ³($P_observable) ℝ³($P_observable + $X0_observable); ℝ³($P_observable + $X0conj_observable) ℝ³($P_observable + $X0conj_observable + $X0_observable)])
X0X0conj_observable = buildsurface(lscene1, X0X0conj, color_array_observable, transparency = true)
X1X1conj = @lift([ℝ³($P_observable) ℝ³($P_observable + $X1_observable); ℝ³($P_observable + $X1conj_observable) ℝ³($P_observable + $X1conj_observable + $X1_observable)])
X1X1conj_observable = buildsurface(lscene1, X1X1conj, color_array_observable, transparency = true)

compute_connection_A(point::ℍ, adjacentpoint::ℍ) = begin
	_z₀, _z₁ = complexvec(point)
	_X₀ = complexvec(normalize(ℍ(vec(adjacentpoint) - vec(point))))[1]
	_X₁ = complexvec(normalize(ℍ(vec(adjacentpoint) - vec(point))))[2]
	_α₀ = _X₀
	_α₁ = _X₁
	abs(0.5 * (conj(_z₀) * _α₀ - _z₀ * conj(_α₀) + conj(_z₁) * _α₁ - _z₁ * conj(_α₁)))
end

ϵ2 = 0.01
sphere_ϵ = 0.5
lspace1 = range(-π, stop = float(π), length = Int(floor(segments / 3)))
lspace2 = range(-π / 2, stop = π / 2, length = Int(floor(segments / 3)))
lspace11 = range(-π, stop = float(π), length = segments)
lspace22 = range(-π / 2, stop = π / 2, length = segments)
adjacent_points = []
adjacent_titles = []
adjacent_colors = []
adjacent_A = []
for θ in lspace2
	for ϕ in lspace1
		x, y, z = vec(convert_to_cartesian([1.0; θ; ϕ]))
		adjacent_point = @lift(ℍ(exp(ϵ2 * x * K(1) + ϵ2 * y * K(2) + ϵ2 * z * K(3))) * $P)
		adjacent_p_observable = @lift(Point3f(project($adjacent_point)))
		end_point_observable = @lift(Point3f(project(ℍ(exp(x * sphere_ϵ * K(1) + y * sphere_ϵ * K(2) + z * sphere_ϵ * K(3))) * $P)))
		push!(adjacent_points, adjacent_point)
		_X₀ = @lift(complexvec(normalize(ℍ(vec($adjacent_point) - vec($P))))[1])
		_X₁ = @lift(complexvec(normalize(ℍ(vec($adjacent_point) - vec($P))))[2])
		_α₀ = _X₀
		_α₁ = _X₁
		_A = @lift(0.5 * (conj($z₀) * $_α₀ - $z₀ * conj($_α₀) + conj($z₁) * $_α₁ - $z₁ * conj($_α₁)))
		push!(adjacent_A, _A)
		adjacent_color = @lift(RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($_A) * 359.0)); 1.0; 1.0])..., 1.0))
		push!(adjacent_colors, adjacent_color)
		adjacent_title = @lift([string(round(imag($_A), digits = 2))])
		push!(adjacent_titles, adjacent_title)
		meshscatter!(lscene1, end_point_observable, markersize = markersize / 2.0, color = adjacent_color)
		meshscatter!(lscene2, end_point_observable, markersize = markersize / 2.0, color = adjacent_color)
		meshscatter!(lscene3, end_point_observable, markersize = markersize / 2.0, color = adjacent_color)
		text!(lscene2,
			@lift([$end_point_observable]),
			text = adjacent_title,
			color = @lift([$adjacent_color]),
			rotation = rotation2,
			align = (:left, :baseline),
			fontsize = fontsize / 3.0,
			markerspace = :data,
			transparency = false,
		)
		linesegment = @lift([Point3f(project(ℍ(exp(ϵ3 * x * K(1) + ϵ3 * y * K(2) + ϵ3 * z * K(3))) * $P)) for ϵ3 in range(0, stop = sphere_ϵ, length = segments)])
		lines!(lscene2, linesegment, linewidth = linewidth / 4.0, color = adjacent_color, transparency = true)

		_X0 = @lift(ℍ([complexvec(normalize(ℍ(vec($adjacent_point) - vec($P))))[1]; 0.0 + im * 0.0]))
		_X1 = @lift(ℍ([0.0; complexvec(normalize(ℍ(vec($adjacent_point) - vec($P))))[2]]))
		_X0conj = @lift(ℍ([conj(complexvec(normalize(ℍ(vec($adjacent_point) - vec($P))))[1]); 0.0 + im * 0.0]))
		_X1conj = @lift(ℍ([0.0 + im * 0.0; conj(complexvec(normalize(ℍ(vec($adjacent_point) - vec($P))))[2])]))
		_X0_observable = @lift(Point3f(project($_X0)))
		_X1_observable = @lift(Point3f(project($_X1)))
		_X0conj_observable = @lift(Point3f(project($_X0conj)))
		_X1conj_observable = @lift(Point3f(project($_X1conj)))
		_oneform_ps = @lift([$P_observable, $P_observable, $P_observable, $P_observable])
		_oneform_ns = @lift([$_X0_observable, $_X1_observable, $_X0conj_observable, $_X1conj_observable])
		arrows3d!(lscene3,
			_oneform_ps, _oneform_ns, fxaa = true, # turn on anti-aliasing
			color = [:red, :silver, :magenta, :brown],
			shaftradius = shaftradius, tipradius = tipradius,
			tiplength = tiplength,
			align = :tail,
			transparency = true
		)
		titles = ["α₀", "α₁", "α̅₀", "α̅₁"]
		text!(lscene3,
			@lift([$P_observable + $_X0_observable, $P_observable + $_X1_observable, $P_observable + $_X0conj_observable, $P_observable + $_X1conj_observable]),
			text = titles,
			color = [:red, :silver, :magenta, :brown],
			rotation = rotation3,
			align = (:left, :baseline),
			fontsize = fontsize / 3.0,
			markerspace = :data,
			transparency = true
		)
		# draw the oriented area made by the wdge product of a pair of one-forms
		_color_array_observable = @lift(fill(RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($_A) * 359.0)); 1.0; 1.0])..., α / 3.0), 2, 2))
		_X0X0conj = @lift([ℝ³($P_observable) ℝ³($P_observable + $_X0_observable); ℝ³($P_observable + $_X0conj_observable) ℝ³($P_observable + $_X0conj_observable + $_X0_observable)])
		X0X0conj_observable = buildsurface(lscene3, _X0X0conj, _color_array_observable, transparency = true)
		_X1X1conj = @lift([ℝ³($P_observable) ℝ³($P_observable + $_X1_observable); ℝ³($P_observable + $_X1conj_observable) ℝ³($P_observable + $_X1conj_observable + $_X1_observable)])
		X1X1conj_observable = buildsurface(lscene3, _X1X1conj, _color_array_observable, transparency = true)
	end
end

sphere = @lift([ℝ³(vec(Point3f(project(ℍ(exp(vec(convert_to_cartesian([1.0; θ; ϕ]))[1] * sphere_ϵ * K(1) + vec(convert_to_cartesian([1.0; θ; ϕ]))[2] * sphere_ϵ * K(2) + vec(convert_to_cartesian([1.0; θ; ϕ]))[3] * sphere_ϵ * K(3))) * $P)))) for θ in lspace22, ϕ in lspace11])
sphere_color_array_observable = @lift([
	RGBAf(
		convert_hsvtorgb(
			[max(0.0, min(359.0, compute_connection_A($P, ℍ(exp(vec(convert_to_cartesian([1.0; θ; ϕ]))[1] * sphere_ϵ * K(1) + vec(convert_to_cartesian([1.0; θ; ϕ]))[2] * sphere_ϵ * K(2) + vec(convert_to_cartesian([1.0; θ; ϕ]))[3] * sphere_ϵ * K(3))) * $P) * 359.0)); 1.0; 1.0],
		)...,
		0.2,
	) for θ in lspace2, ϕ in lspace1
])
sphereobservable = buildsurface(lscene1, sphere, sphere_color_array_observable, transparency = true)
sphereobservable = buildsurface(lscene2, sphere, sphere_color_array_observable, transparency = true)
sphereobservable = buildsurface(lscene3, sphere, sphere_color_array_observable, transparency = true)

# Plot the Hopf fiber of the point P
linecolors = collect(1:segments)
fiber = @lift([Point3f(project(ℍ(exp(α * K(2))) * $P)) for α in range(0, stop = 2π, length = segments)])
lines!(lscene1, fiber, linewidth = 4linewidth, color = linecolors, colorrange = (1, segments), colormap = :lightrainbow)
lines!(lscene2, fiber, linewidth = 4linewidth, color = linecolors, colorrange = (1, segments), colormap = :lightrainbow)
lines!(lscene3, fiber, linewidth = 4linewidth, color = linecolors, colorrange = (1, segments), colormap = :lightrainbow)

trace_linecolors = Observable([1, 2])
colorrange = collect(1:frames_number)
trace = Observable([Point3f(O), P_observable[]])
lines!(lscene1, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
lines!(lscene2, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
lines!(lscene3, trace, linewidth = 2linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)

K1_direction = @lift(ℍ(exp(ϵ * K(1))) * $P)
K2_direction = @lift(ℍ(exp(ϵ * K(2))) * $P)
K3_direction = @lift(ℍ(exp(ϵ * K(3))) * $P)
K1_observable = @lift(Point3f(0.5 * normalize(project($K1_direction) - ℝ³($P_observable))))
K2_observable = @lift(Point3f(0.5 * normalize(project($K2_direction) - ℝ³($P_observable))))
K3_observable = @lift(Point3f(0.5 * normalize(project($K3_direction) - ℝ³($P_observable))))
vector_filed_ps = @lift([$P_observable, $P_observable, $P_observable])
vector_field_ns = @lift([$K1_observable, $K2_observable, $K3_observable])
arrows3d!(lscene1,
	vector_filed_ps, vector_field_ns, fxaa = true, # turn on anti-aliasing
	color = [:pink, :orange, :cyan],
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene2,
	vector_filed_ps, vector_field_ns, fxaa = true, # turn on anti-aliasing
	color = [:pink, :orange, :cyan],
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene3,
	vector_filed_ps, vector_field_ns, fxaa = true, # turn on anti-aliasing
	color = [:pink, :orange, :cyan],
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
titles = ["K1", "K2", "K3"]
text!(lscene1,
	@lift([map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable + $K1_observable, $P_observable + $K2_observable, $P_observable + $K3_observable])...]),
	text = titles,
	color = [:pink, :orange, :cyan],
	rotation = rotation1,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
text!(lscene2,
	@lift([map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable + $K1_observable, $P_observable + $K2_observable, $P_observable + $K3_observable])...]),
	text = titles,
	color = [:pink, :orange, :cyan],
	rotation = rotation2,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
text!(lscene3,
	@lift([map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable + $K1_observable, $P_observable + $K2_observable, $P_observable + $K3_observable])...]),
	text = titles,
	color = [:pink, :orange, :cyan],
	rotation = rotation3,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
K1K3_color_observable = fill(RGBAf(0.5, 0.5, 0.5, α / 2.0), 2, 2)
K1K3_surface = @lift([ℝ³($P_observable - $K1_observable - $K3_observable) ℝ³($P_observable - $K1_observable + $K3_observable); ℝ³($P_observable + $K1_observable - $K3_observable) ℝ³($P_observable + $K1_observable + $K3_observable)])
buildsurface(lscene1, K1K3_surface, K1K3_color_observable, transparency = true)
buildsurface(lscene2, K1K3_surface, K1K3_color_observable, transparency = true)
buildsurface(lscene3, K1K3_surface, K1K3_color_observable, transparency = true)

##### Scene 4

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
origin = Observable(Point3f(ℝ³(0.0, 0.0, 0.0)))
# c2point = @lift(Point3f((ℝ³(abs($z₀), abs($z₁), 0.0))))
# c2point_adjacent = @lift(Point3f((ℝ³(abs(complexvec($P1)[1]), abs(complexvec($P1)[2]), 0.0))))
c2point = @lift(Point3f(ℝ³(abs($z₀) * sign(real($z₀)), abs($z₁) * sign(real($z₁)), 0.0)))
c2point_adjacent = @lift(Point3f((ℝ³(abs(complexvec($P1)[1]) * sign(real(complexvec($P1)[1])), abs(complexvec($P1)[2]) * sign(real(complexvec($P1)[2])), 0.0))))
X_c2 = @lift(normalize($c2point_adjacent - $c2point))
meshscatter!(lscene4, origin, markersize = markersize, color = :white)
meshscatter!(lscene4, c2point, markersize = markersize, color = :gold)
circle_linecolors = collect(1:segments)
circle = [Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)]
lines!(lscene4, circle, color = circle_linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :inferno)
w = Observable(ℍ([1.0 + im * 0.0; 0.0 + im * 0.0]))
z = Observable(ℍ([0.0 + im * 0.0; 1.0 + im * 0.0]))
whead = @lift(Point3f((ℝ³(abs(complexvec($w)[1]) * sign(real(complexvec($w)[1])), abs(complexvec($w)[2]) * sign(real(complexvec($w)[2])), 0.0))))
zhead = @lift(Point3f((ℝ³(abs(complexvec($z)[1]) * sign(real(complexvec($z)[1])), abs(complexvec($z)[2]) * sign(real(complexvec($z)[2])), 0.0))))
c2_ps = @lift([$origin, $origin, $origin, $c2point])
c2_ns = @lift([$whead, $zhead, $c2point, $X_c2])
colorants2 = @lift([:white, :white, :gold, RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($A) * 359.0)); 1.0; 1.0])..., α)])
arrows3d!(lscene4,
    c2_ps, c2_ns, fxaa = true, # turn on anti-aliasing
    color = colorants2,
    shaftradius = shaftradius, tipradius = tipradius,
    tiplength = tiplength,
    align = :tail,
)
titles2 = @lift(["O", "w ∈ ℂ²", "z ∈ ℂ²", "P", "$($P)", "X ∈ TS³"])
colorants2 = @lift([:white, :white, :white, :gold, :gold, RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($A) * 359.0)); 1.0; 1.0])..., α)])
text!(lscene4,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$origin, $whead, $zhead, $c2point, 0.5 * $c2point, $c2point + $X_c2])),
    text = titles2,
    color = colorants2,
    rotation = rotation4,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data
)


ϵ4 = 0.5 / (frames_number / totalstages)
# ϵ4 = 0.1
progress = 0.0
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
	notify(trace)
	notify(trace_linecolors)

	# eyeposition = normalize(ℝ³(P_observable[])) + normalize(cross(ℝ³(K1_observable[]), ℝ³(K3_observable[]))) + normalize(ℝ³(K2_observable[]))
	# eyeposition = rotate(eyeposition, ℍ(-π, ℝ³(0.0, 0.0, 1.0)))
	lookat = ℝ³(P_observable[])
	lookat4 = ℝ³(c2point[])
	# up = rotate(ℝ³(0.0, 0.0, 1.0), ℍ(-π / 4, normalize(eyeposition - lookat)))
	eyeposition4 = normalize(eyeposition + ℝ³(whead[] + zhead[])) * eyeposition_distance
	_eyeposition = rotate(eyeposition, ℍ(progress * 2π, ℝ³(0.0, 0.0, 1.0)))
	_eyeposition4 = rotate(eyeposition4, ℍ(progress * 2π, ℝ³(0.0, 0.0, 1.0)))
	updatecamera!(lscene1, _eyeposition, lookat, up)
	updatecamera!(lscene2, _eyeposition, lookat, up)
	updatecamera!(lscene3, _eyeposition, lookat, up)
	updatecamera!(lscene4, _eyeposition4, lookat4, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
	animate(frame)
end