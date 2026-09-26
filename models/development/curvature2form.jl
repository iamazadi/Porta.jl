using FileIO
using GLMakie
using LinearAlgebra
using Porta


ϕ(p::ℍ, u::Matrix; ϵ::Float64 = 1e-3) = begin
	z₀, z₁ = complexvec(p)
	p′ = ℍ(exp(ϵ * u)) * p
	dp = normalize(ℍ(vec(p′) - vec(p)))
	X₀ = complexvec(dp)[1]
	X₁ = complexvec(dp)[2]
	α₀ = X₀
	α₁ = X₁
	abs(0.5 * (conj(z₀) * α₀ - z₀ * conj(α₀) + conj(z₁) * α₁ - z₁ * conj(α₁)))
end



modelname = "curvature2form"
totalstages = 30
figuresize = (1920, 1080)
frames_number = 1440
segments = 30
tiplength = 0.02
tipradius = 0.01
shaftradius = 0.005
linewidth = 5
markersize = 0.01
fontsize = 0.1
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
transparency = 0.7
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
lscene = LScene(fig[1, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :white))
rotation = gettextrotation(lscene)

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
		r, θ, _ϕ = convert_to_geographic(node)
		push!(_points, ℍ(exp(_ϕ * longitudescale * K(1) + θ * latitudescale * K(3))) * q)
	end
	push!(points, _points)
end

whirls = []
for i in eachindex(points)
	# TODO: add a handedness field to Whirl and Basemap to show orthogonal complement planes through the origin in the tangent space at P
	whirl1 = Whirl(lscene, points[i], gauge1, gauge3, M, segments, getcolor(boundary_nodes[i], mask, transparency / 5), transparency = true)
	whirl2 = Whirl(lscene, points[i], gauge3, gauge5, M, segments, getcolor(boundary_nodes[i], mask, transparency / 2), transparency = true)
	push!(whirls, whirl1)
	push!(whirls, whirl2)
end
basemap1 = Basemap(lscene, reference_point, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene, reference_point, gauge3, M, chart, segments, mask, transparency = true)

O = ℝ³(0.0, 0.0, 0.0)
P = Observable(q)
P′ = Observable(P[])
P_observable = @lift(Point3f(project($P)))

meshscatter!(lscene, Point3f(O), markersize = markersize, color = :black)
meshscatter!(lscene, P_observable, markersize = markersize, color = :gold)
titles = ["O", "P"]
text!(lscene,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable])...]),
	text = titles,
	color = [:black, :gold],
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

u = Observable(K(1))
v = Observable(K(3))
ϕᵤ = @lift(ϕ($P, $u))
ϕᵥ = @lift(ϕ($P, $v))
∇ᵤ = @lift((1.0 / ϵ) * (ϕ(ℍ(exp(ϵ * $u)) * $P, $v) - $ϕᵥ))
∇ᵥ = @lift((1.0 / ϵ) * (ϕ(ℍ(exp(ϵ * $v)) * $P, $u) - $ϕᵤ))
pᵤ = @lift(ℍ(exp(ϵ * $u)) * $P)
pᵥ = @lift(ℍ(exp(ϵ * $v)) * $P)
pᵤᵥ = @lift(ℍ(exp(ϵ * $v)) * $pᵤ)
pᵥᵤ = @lift(ℍ(exp(ϵ * $u)) * $pᵥ)
pᵤᵥ_ᵤ = @lift(ℍ(exp(ϵ * -$u)) * $pᵤᵥ)
pᵤᵥ_ᵤᵥ = @lift(ℍ(exp(ϵ * -$v)) * $pᵤᵥ_ᵤ)
commutator = @lift(ϕ($P, mat4($pᵤᵥ_ᵤᵥ - $P)))
dϕ = @lift($∇ᵤ - $∇ᵥ - $commutator)

u_observable = @lift(Point3f(normalize(project($pᵤ) - project($P))))
v_observable = @lift(Point3f(normalize(project($pᵥ) - project($P))))
uv_observable = @lift(Point3f(normalize(project($pᵤᵥ) - project($pᵤ))))
vu_observable = @lift(Point3f(normalize(project($pᵥᵤ) - project($pᵥ))))
uv_u_observable = @lift(Point3f(normalize(project($pᵤᵥ_ᵤ) - project($pᵤᵥ))))
uv_uv_observable = @lift(Point3f(normalize(project($pᵤᵥ_ᵤᵥ) - project($pᵤᵥ_ᵤ))))
commutator_observable = @lift(Point3f(normalize(project($pᵤᵥ_ᵤᵥ) - project($P))))
final_point = @lift(Point3f(project($pᵤᵥ_ᵤᵥ)))

titles = @lift(["ϕ(u) = " * string(round($ϕᵤ, digits = 2)), "ϕ(v) = " * string(round($ϕᵥ, digits = 2)),
	"∇ᵤ(v) = " * string(round($∇ᵤ, digits = 2)), "∇ᵥ(u) = " * string(round($∇ᵥ, digits = 2)),
	"ϕ([u, v]) = " * string(round($commutator, digits = 2)), "dϕ = " * string(round($dϕ, digits = 2))])
colorants = [:red, :green, :blue, :yellow, :black]
arrows3d!(lscene,
	@lift([$P_observable, $P_observable, $P_observable + $v_observable, $P_observable + $u_observable, $final_point]),
	@lift([$u_observable, $v_observable, $vu_observable, $uv_observable, $commutator_observable]),
	fxaa = true, # turn on anti-aliasing
	color = colorants,
	shaftradius = shaftradius, tipradius = tipradius,
	tiplength = tiplength,
	align = :tail,
)
text!(lscene,
	@lift([$P_observable + 0.5 * $u_observable, $P_observable + 0.5 * $v_observable, $P_observable + $v_observable + 0.5 * $vu_observable, $P_observable + $u_observable + 0.5 * $uv_observable, $final_point + $commutator_observable]),
	text = titles,
	color = [colorants; :silver],
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

make_pentagon(p::Observable{ℍ}) = begin
    p_observable = @lift(Point3f(project($p)))
	u = Observable(K(1))
	v = Observable(K(3))
	ϕᵤ = @lift(ϕ($p, $u))
	ϕᵥ = @lift(ϕ($p, $v))
	∇ᵤ = @lift((1.0 / ϵ) * (ϕ(ℍ(exp(ϵ * $u)) * $p, $v) - $ϕᵥ))
	∇ᵥ = @lift((1.0 / ϵ) * (ϕ(ℍ(exp(ϵ * $v)) * $p, $u) - $ϕᵤ))
	pᵤ = @lift(ℍ(exp(ϵ * $u)) * $p)
	pᵥ = @lift(ℍ(exp(ϵ * $v)) * $p)
	pᵤᵥ = @lift(ℍ(exp(ϵ * $v)) * $pᵤ)
	pᵥᵤ = @lift(ℍ(exp(ϵ * $u)) * $pᵥ)
	pᵤᵥ_ᵤ = @lift(ℍ(exp(ϵ * -$u)) * $pᵤᵥ)
	pᵤᵥ_ᵤᵥ = @lift(ℍ(exp(ϵ * -$v)) * $pᵤᵥ_ᵤ)
	commutator = @lift(ϕ($p, mat4($pᵤᵥ_ᵤᵥ - $p)))
	dϕ = @lift($∇ᵤ - $∇ᵥ - $commutator)

	u_observable = @lift(Point3f(normalize(project($pᵤ) - project($p))))
	v_observable = @lift(Point3f(normalize(project($pᵥ) - project($p))))
	uv_observable = @lift(Point3f(normalize(project($pᵤᵥ) - project($pᵤ))))
	vu_observable = @lift(Point3f(normalize(project($pᵥᵤ) - project($pᵥ))))
	uv_u_observable = @lift(Point3f(normalize(project($pᵤᵥ_ᵤ) - project($pᵤᵥ))))
	uv_uv_observable = @lift(Point3f(normalize(project($pᵤᵥ_ᵤᵥ) - project($pᵤᵥ_ᵤ))))
	commutator_observable = @lift(Point3f(normalize(project($pᵤᵥ_ᵤᵥ) - project($p))))
	final_point = @lift(Point3f(project($pᵤᵥ_ᵤᵥ)))

	titles = @lift(["ϕ(u) = " * string(round($ϕᵤ, digits = 2)), "ϕ(v) = " * string(round($ϕᵥ, digits = 2)),
		"∇ᵤ(v) = " * string(round($∇ᵤ, digits = 2)), "∇ᵥ(u) = " * string(round($∇ᵥ, digits = 2)),
		"ϕ([u, v]) = " * string(round($commutator, digits = 2))])
	colorants = [:red, :green, :blue, :yellow, :black]
	arrows3d!(lscene,
		@lift([$p_observable, $p_observable, $p_observable + $v_observable, $p_observable + $u_observable, $final_point]),
		@lift([$u_observable, $v_observable, $vu_observable, $uv_observable, $commutator_observable]),
		fxaa = true, # turn on anti-aliasing
		color = colorants,
		shaftradius = shaftradius, tipradius = tipradius,
		tiplength = tiplength,
		align = :tail,
	)
	text!(lscene,
		@lift([$p_observable + $u_observable, $p_observable + $v_observable, $p_observable + $u_observable + $vu_observable, $p_observable + $u_observable + $uv_observable, $final_point + $commutator_observable]),
		text = titles,
		color = colorants,
		rotation = rotation,
		align = (:left, :baseline),
		fontsize = fontsize,
		markerspace = :data,
	)
    meshscatter!(lscene, p_observable, markersize = markersize, color = :gold)
end
lspace1 = range(-π / 2, stop = π / 2, length = Int(floor(segments / 3)))
lspace2 = range(-π, stop = π, length = Int(floor(segments / 3)))
for θ in lspace1
	for _ϕ in lspace2
		point = ℍ(exp(_ϕ * longitudescale * K(1) + θ * latitudescale * K(3))) * q
		make_pentagon(Observable(point))
	end
end