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
totalstages = 30
figuresize = (1920, 1080)
frames_number = 1440
segments = 30
tiplength = 0.04
tipradius = 0.02
shaftradius = 0.01
linewidth = 5
linewidth2 = linewidth / 2.0
linewidth3 = linewidth / 3.0
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
transparency = 0.6
ϵ = 1e-3
ϵ4 = 0.02
_ψ = rand() * 2π
progress = 0.0
x̂ = ℝ³(1.0, 0.0, 0.0)
ŷ = ℝ³(0.0, 1.0, 0.0)
ẑ = ℝ³(0.0, 0.0, 1.0)

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene1 = LScene(fig[1, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :white))
lscene2 = LScene(fig[1:2, 2], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :white))
lscene3 = LScene(fig[2, 1], show_axis = true, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :white))
rotation1 = gettextrotation(lscene1)
rotation2 = gettextrotation(lscene2)
rotation3 = gettextrotation(lscene3)

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
P = Observable(q)
P′ = Observable(P[])
P_observable = @lift(Point3f(project($P)))

meshscatter!(lscene1, Point3f(O), markersize = markersize, color = :black)
meshscatter!(lscene2, Point3f(O), markersize = markersize, color = :black)
meshscatter!(lscene3, Point3f(O), markersize = markersize, color = :black)
meshscatter!(lscene1, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene2, P_observable, markersize = markersize, color = :gold)
titles = ["O", "P"]
text!(lscene1,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable])...]),
	text = titles,
	color = [:black, :gold],
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
	[Point3f(O)],
	text = ["P"],
	color = [:black],
	rotation = rotation3,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

z₀ = @lift(complexvec($P)[1])
z₁ = @lift(complexvec($P)[2])
z̅₀ = @lift(conj(complexvec($P)[1]))
z̅₁ = @lift(conj(complexvec($P)[2]))
ψ = Observable(_ψ)
# The tangent spaces of the unit sphere in ℂ²: TS³ = { (X₀, X₁) ∈ ℂ² | z̅₀ X₀ + z̅₁ X₁ = 0 }
X′ = @lift(ℍ(exp(sin($ψ) * ϵ * K(1) + cos($ψ) * ϵ * K(3))) * $P - $P)
X = @lift(normalize($X′))
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

F¹ = @lift(ℍ([$α₀; $α̅₀]))
F² = @lift(ℍ([$α₁; $α̅₁]))
Fᴬ_magnitude = @lift(norm($F¹ + $F²))
Fᴬ = @lift(-normalize($F¹ + $F²))
F¹_observable = @lift(Point3f(project($F¹))- $P_observable)
F²_observable = @lift(Point3f(project($F²))- $P_observable)
Fᴬ_observable = @lift(Point3f(project($Fᴬ))- $P_observable)
X_observable = @lift(normalize(Point3f(project($X′))))
twoform_colorants = [:orange, :cyan, :black, :purple]
arrows3d!(lscene1,
	@lift([$P_observable, $P_observable, $P_observable, $P_observable]),
	@lift([$F¹_observable, $F²_observable, $Fᴬ_observable, $X_observable]),
	fxaa = true, # turn on anti-aliasing
	color = twoform_colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
arrows3d!(lscene2,
	@lift([$P_observable, $P_observable, $P_observable, $P_observable]),
	@lift([$F¹_observable, $F²_observable, $Fᴬ_observable, $X_observable]),
	fxaa = true, # turn on anti-aliasing
	color = twoform_colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
twoform_titles = @lift(["α₀ ^ α̅₀", "α₁ ^ α̅₁", "Fᴬ = " * string(round($Fᴬ_magnitude, digits = 3)), "X"])
text!(lscene1,
	@lift(map(x -> x + $P_observable, [$F¹_observable, $F²_observable, $Fᴬ_observable, $X_observable])),
	text = twoform_titles,
	color = twoform_colorants,
	rotation = rotation1,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
text!(lscene2,
	@lift(map(x -> x + $P_observable, [$F¹_observable, $F²_observable, $Fᴬ_observable, $X_observable])),
	text = twoform_titles,
	color = twoform_colorants,
	rotation = rotation2,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

twoform_color = fill(RGBAf(0.0, 0.0, 0.0, transparency), 2, 2)
twoform_plane = @lift([ℝ³($P_observable) ℝ³($P_observable + $F¹_observable); ℝ³($P_observable + $F²_observable) ℝ³($P_observable + $F¹_observable + $F²_observable)])
buildsurface(lscene1, twoform_plane, twoform_color, transparency = false)
buildsurface(lscene2, twoform_plane, twoform_color, transparency = false)

K1_observable = @lift(Point3f(normalize(project($P1) - ℝ³($P_observable))))
K2_observable = @lift(Point3f(normalize(project($P2) - ℝ³($P_observable))))
K3_observable = @lift(Point3f(normalize(project($P3) - ℝ³($P_observable))))
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
	text = ["K1", "K2", "K3"],
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

v1_K1K2 = @lift(dot($F¹, $K1) * $K1 + dot($F¹, $K2) * $K2)
v1_K1K3 = @lift(dot($F¹, $K1) * $K1 + dot($F¹, $K3) * $K3)
v1_K2K3 = @lift(dot($F¹, $K2) * $K2 + dot($F¹, $K3) * $K3)
v2_K1K2 = @lift(dot($F², $K1) * $K1 + dot($F², $K2) * $K2)
v2_K1K3 = @lift(dot($F², $K1) * $K1 + dot($F², $K3) * $K3)
v2_K2K3 = @lift(dot($F², $K2) * $K2 + dot($F², $K3) * $K3)
v1_K1K2_observable = @lift(Point3f(ℝ³(dot($F¹, $K1) * $K1_observable + dot($F¹, $K2) * $K2_observable)))
v1_K1K3_observable = @lift(Point3f(ℝ³(dot($F¹, $K1) * $K1_observable + dot($F¹, $K3) * $K3_observable)))
v1_K2K3_observable = @lift(Point3f(ℝ³(dot($F¹, $K2) * $K2_observable + dot($F¹, $K3) * $K3_observable)))
v2_K1K2_observable = @lift(Point3f(ℝ³(dot($F², $K1) * $K1_observable + dot($F², $K2) * $K2_observable)))
v2_K1K3_observable = @lift(Point3f(ℝ³(dot($F², $K1) * $K1_observable + dot($F², $K3) * $K3_observable)))
v2_K2K3_observable = @lift(Point3f(ℝ³(dot($F², $K2) * $K2_observable + dot($F², $K3) * $K3_observable)))
v_K1K2_color = fill(RGBAf(1.0, 1.0, 0.5, transparency), 2, 2)
v_K1K3_color = fill(RGBAf(1.0, 0.5, 1.0, transparency), 2, 2)
v_K2K3_color = fill(RGBAf(0.5, 1.0, 1.0, transparency), 2, 2)
K1K2_projection = @lift([ℝ³($P_observable) ℝ³($P_observable + $v1_K1K2_observable); ℝ³($P_observable + $v2_K1K2_observable) ℝ³($P_observable + $v1_K1K2_observable + $v2_K1K2_observable)])
K1K3_projection = @lift([ℝ³($P_observable) ℝ³($P_observable + $v1_K1K3_observable); ℝ³($P_observable + $v2_K1K3_observable) ℝ³($P_observable + $v1_K1K3_observable + $v2_K1K3_observable)])
K2K3_projection = @lift([ℝ³($P_observable) ℝ³($P_observable + $v1_K2K3_observable); ℝ³($P_observable + $v2_K2K3_observable) ℝ³($P_observable + $v1_K2K3_observable + $v2_K2K3_observable)])
buildsurface(lscene1, K1K2_projection, v_K1K2_color, transparency = true)
buildsurface(lscene1, K1K3_projection, v_K1K3_color, transparency = true)
buildsurface(lscene1, K2K3_projection, v_K2K3_color, transparency = true)
K1K2_area = @lift(map(x -> x + $P_observable, [Point3f(O), $v1_K1K2_observable, $v1_K1K2_observable + $v2_K1K2_observable, $v2_K1K2_observable, Point3f(O)]))
K1K3_area = @lift(map(x -> x + $P_observable, [Point3f(O), $v1_K1K3_observable, $v1_K1K3_observable + $v2_K1K3_observable, $v2_K1K3_observable, Point3f(O)]))
K2K3_area = @lift(map(x -> x + $P_observable, [Point3f(O), $v1_K2K3_observable, $v1_K2K3_observable + $v2_K2K3_observable, $v2_K2K3_observable, Point3f(O)]))
colorrange = collect(1:6)
lines!(lscene1, K1K2_area, linewidth = linewidth, color = v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, K1K3_area, linewidth = linewidth, color = v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, K2K3_area, linewidth = linewidth, color = v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)

v1_K1K2_segment = @lift([$P_observable + $F¹_observable, $P_observable + $v1_K1K2_observable])
v1_K1K3_segment = @lift([$P_observable + $F¹_observable, $P_observable + $v1_K1K3_observable])
v1_K2K3_segment = @lift([$P_observable + $F¹_observable, $P_observable + $v1_K2K3_observable])
v2_K1K2_segment = @lift([$P_observable + $F²_observable, $P_observable + $v2_K1K2_observable])
v2_K1K3_segment = @lift([$P_observable + $F²_observable, $P_observable + $v2_K1K3_observable])
v2_K2K3_segment = @lift([$P_observable + $F²_observable, $P_observable + $v2_K2K3_observable])
v12_K1K2_segment = @lift([$P_observable + $F¹_observable + $F²_observable, $P_observable + $v1_K1K2_observable + $v2_K1K2_observable])
v12_K1K3_segment = @lift([$P_observable + $F¹_observable + $F²_observable, $P_observable + $v1_K1K3_observable + $v2_K1K3_observable])
v12_K2K3_segment = @lift([$P_observable + $F¹_observable + $F²_observable, $P_observable + $v1_K2K3_observable + $v2_K2K3_observable])
lines!(lscene1, v1_K1K2_segment, linewidth = linewidth2, color = v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, v1_K1K3_segment, linewidth = linewidth2, color = v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, v1_K2K3_segment, linewidth = linewidth2, color = v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, v2_K1K2_segment, linewidth = linewidth2, color = v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, v2_K1K3_segment, linewidth = linewidth2, color = v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, v2_K2K3_segment, linewidth = linewidth2, color = v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, v12_K1K2_segment, linewidth = linewidth2, color = v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, v12_K1K3_segment, linewidth = linewidth2, color = v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene1, v12_K2K3_segment, linewidth = linewidth2, color = v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)

# scene 3: 2-form basis

_K1K2_surface = [(-x̂ - ŷ) (-x̂ + ŷ); (x̂ - ŷ) (x̂ + ŷ)]
_K1K3_surface = [(-x̂ - ẑ) (-x̂ + ẑ); (x̂ - ẑ) (x̂ + ẑ)]
_K2K3_surface = [(-ŷ - ẑ) (-ŷ + ẑ); (ŷ - ẑ) (ŷ + ẑ)]
buildsurface(lscene3, _K1K2_surface, K1K2_color, transparency = true)
buildsurface(lscene3, _K1K3_surface, K1K3_color, transparency = true)
buildsurface(lscene3, _K2K3_surface, K2K3_color, transparency = true)

_v1_K1K2_observable = @lift(Point3f(dot($F¹, $K1) * x̂ + dot($F¹, $K2) * ŷ))
_v1_K1K3_observable = @lift(Point3f(dot($F¹, $K1) * x̂ + dot($F¹, $K3) * ẑ))
_v1_K2K3_observable = @lift(Point3f(dot($F¹, $K2) * ŷ + dot($F¹, $K3) * ẑ))
_v2_K1K2_observable = @lift(Point3f(dot($F², $K1) * x̂ + dot($F², $K2) * ŷ))
_v2_K1K3_observable = @lift(Point3f(dot($F², $K1) * x̂ + dot($F², $K3) * ẑ))
_v2_K2K3_observable = @lift(Point3f(dot($F², $K2) * ŷ + dot($F², $K3) * ẑ))
_v_K1K2_color = fill(RGBAf(1.0, 1.0, 0.0, transparency), 2, 2)
_v_K1K3_color = fill(RGBAf(1.0, 0.0, 1.0, transparency), 2, 2)
_v_K2K3_color = fill(RGBAf(0.0, 1.0, 1.0, transparency), 2, 2)
_K1K2_projection = @lift([ℝ³(0.0, 0.0, 0.0) ℝ³($_v1_K1K2_observable); ℝ³($_v2_K1K2_observable) ℝ³($_v1_K1K2_observable + $_v2_K1K2_observable)])
_K1K3_projection = @lift([ℝ³(0.0, 0.0, 0.0) ℝ³($_v1_K1K3_observable); ℝ³($_v2_K1K3_observable) ℝ³($_v1_K1K3_observable + $_v2_K1K3_observable)])
_K2K3_projection = @lift([ℝ³(0.0, 0.0, 0.0) ℝ³($_v1_K2K3_observable); ℝ³($_v2_K2K3_observable) ℝ³($_v1_K2K3_observable + $_v2_K2K3_observable)])
buildsurface(lscene3, _K1K2_projection, _v_K1K2_color, transparency = true)
buildsurface(lscene3, _K1K3_projection, _v_K1K3_color, transparency = true)
buildsurface(lscene3, _K2K3_projection, _v_K2K3_color, transparency = true)
_K1K2_area = @lift([Point3f(O), $_v1_K1K2_observable, $_v1_K1K2_observable + $_v2_K1K2_observable, $_v2_K1K2_observable, Point3f(O)])
_K1K3_area = @lift([Point3f(O), $_v1_K1K3_observable, $_v1_K1K3_observable + $_v2_K1K3_observable, $_v2_K1K3_observable, Point3f(O)])
_K2K3_area = @lift([Point3f(O), $_v1_K2K3_observable, $_v1_K2K3_observable + $_v2_K2K3_observable, $_v2_K2K3_observable, Point3f(O)])
colorrange = collect(1:6)
lines!(lscene3, _K1K2_area, linewidth = linewidth, color = _v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _K1K3_area, linewidth = linewidth, color = _v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _K2K3_area, linewidth = linewidth, color = _v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)

_F¹ = @lift(Point3f(dot($F¹, $K1) * x̂ + dot($F¹, $K2) * ŷ + dot($F¹, $K3) * ẑ))
_F² = @lift(Point3f(dot($F², $K1) * x̂ + dot($F², $K2) * ŷ + dot($F², $K3) * ẑ))
_Fᴬ = @lift(Point3f(dot($Fᴬ, $K1) * x̂ + dot($Fᴬ, $K2) * ŷ + dot($Fᴬ, $K3) * ẑ))
_X = @lift(Point3f(dot($X, $K1) * x̂ + dot($X, $K2) * ŷ + dot($X, $K3) * ẑ))
_v1_K1K2_segment = @lift([$_F¹, $_v1_K1K2_observable])
_v1_K1K3_segment = @lift([$_F¹, $_v1_K1K3_observable])
_v1_K2K3_segment = @lift([$_F¹, $_v1_K2K3_observable])
_v2_K1K2_segment = @lift([$_F², $_v2_K1K2_observable])
_v2_K1K3_segment = @lift([$_F², $_v2_K1K3_observable])
_v2_K2K3_segment = @lift([$_F², $_v2_K2K3_observable])
_v12_K1K2_segment = @lift([$_F¹ + $_F², $_v1_K1K2_observable + $_v2_K1K2_observable])
_v12_K1K3_segment = @lift([$_F¹ + $_F², $_v1_K1K3_observable + $_v2_K1K3_observable])
_v12_K2K3_segment = @lift([$_F¹ + $_F², $_v1_K2K3_observable + $_v2_K2K3_observable])
lines!(lscene3, _v1_K1K2_segment, linewidth = linewidth3, color = _v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _v1_K1K3_segment, linewidth = linewidth3, color = _v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _v1_K2K3_segment, linewidth = linewidth3, color = _v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _v2_K1K2_segment, linewidth = linewidth3, color = _v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _v2_K1K3_segment, linewidth = linewidth3, color = _v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _v2_K2K3_segment, linewidth = linewidth3, color = _v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _v12_K1K2_segment, linewidth = linewidth3, color = _v_K1K2_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _v12_K1K3_segment, linewidth = linewidth3, color = _v_K1K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
lines!(lscene3, _v12_K2K3_segment, linewidth = linewidth3, color = _v_K2K3_color[1], colorrange = colorrange, colormap = :rainbow, transparency = true)
_v1v2_area = @lift([Point3f(O), $_F¹, $_F¹ + $_F², $_F², Point3f(O)])
lines!(lscene3, _v1v2_area, linewidth = linewidth, color = twoform_color[1], colorrange = colorrange, colormap = :rainbow, transparency = false)

arrows3d!(lscene3,
	[Point3f(O), Point3f(O), Point3f(O)],
	[Point3f(x̂), Point3f(ŷ), Point3f(ẑ)],
	fxaa = true, # turn on anti-aliasing
	color = arrow_colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
text!(lscene3,
	map(x -> Point3f(x) + Point3f(O), [x̂, ŷ, ẑ]),
	text = ["K1", "K2", "K3"],
	color = arrow_colorants,
	rotation = rotation3,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

_twoform_color = fill(RGBAf(0.25, 0.25, 0.25, transparency), 2, 2)
_twoform_plane = @lift([ℝ³(0.0, 0.0, 0.0) ℝ³($_F¹); ℝ³($_F²) ℝ³($_F¹ + $_F²)])
buildsurface(lscene3, _twoform_plane, _twoform_color, transparency = false)
arrows3d!(lscene3,
	[Point3f(0.0, 0.0, 0.0), Point3f(0.0, 0.0, 0.0), Point3f(0.0, 0.0, 0.0), Point3f(0.0, 0.0, 0.0)],
	@lift([$_F¹, $_F², $_Fᴬ, $_X]),
	fxaa = true, # turn on anti-aliasing
	color = twoform_colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
text!(lscene3,
	@lift([$_F¹, $_F², $_Fᴬ, $_X]),
	text = twoform_titles,
	color = twoform_colorants,
	rotation = rotation3,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

trace_created = false
trace_linecolors = Observable([1])
colorrange = collect(1:frames_number)
trace = Observable([P_observable[]])
stage_sprites = []


animate(frame::Int) = begin
	progress = Float64(frame / frames_number)
	stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
	stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
	println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $(round(stageprogress, digits = 3))")

	ψ[] = progress * 2π
	global ϵ5 = ϵ4 + sin(progress * 2π) * ϵ4 / 3.0
	
	P′[] = P[]
	P[] = ℍ(exp(sin(stageprogress * 2π) * ϵ5 * K(1) + cos(stageprogress * 2π) * ϵ5 * K(3))) * P′[]

	push!(trace[], P_observable[])
	push!(trace_linecolors[], trace_linecolors[][end] + 1)
	notify(trace_linecolors)
	notify(trace)
	if length(trace[]) > 1 && trace_created == false
		lines!(lscene1, trace, linewidth = linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
		lines!(lscene2, trace, linewidth = linewidth, color = trace_linecolors, colorrange = colorrange, colormap = :rainbow, transparency = false)
		global trace_created = true
	end

	if stage ∉ stage_sprites
		color = RGBAf(convert_hsvtorgb([max(0.0, min(359.0, progress * 359.0)); 1.0; 1.0])..., transparency / 2.0)
		arrows3d!(lscene2,
			[P_observable[], P_observable[], P_observable[]],
			[0.3 * F¹_observable[], 0.3 * F²_observable[], 0.3 * Fᴬ_observable[]],
			fxaa = true, # turn on anti-aliasing
			color = twoform_colorants,
			shaftradius = shaftradius / 3, tipradius = tipradius / 3,
			tiplength = tiplength / 3,
			align = :tail,
		)
		_twoform_plane = [ℝ³(P_observable[]) ℝ³(P_observable[] + 0.3 * F¹_observable[]); ℝ³(P_observable[] + 0.3 * F²_observable[]) ℝ³(P_observable[] + 0.3 * F¹_observable[] + 0.3 * F²_observable[])]
		_twoform_color = fill(color, 2, 2)
		buildsurface(lscene2, _twoform_plane, _twoform_color, transparency = true)
		push!(stage_sprites, stage)
	end

	lookat = ℝ³(P_observable[])
	_eyeposition = rotate(eyeposition, ℍ(progress * 4π, ℝ³(0.0, 0.0, 1.0)))
	updatecamera!(lscene1, _eyeposition, lookat, up)
	updatecamera!(lscene2, _eyeposition, lookat, up)
	updatecamera!(lscene3, _eyeposition, ℝ³(0.0, 0.0, 0.0), up)
end


# animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
	animate(frame)
end