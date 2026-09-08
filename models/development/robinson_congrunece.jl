using FileIO
using GLMakie
using LinearAlgebra
using Porta


function calculatespinvectorpairs(κ::SpinVector, T::Int; ϵ = 0.1)
	ζ = Complex(κ)
	ζ′ = ζ - (1.0 / √2) * ϵ * (1.0 / κ.a[2]^2)
	κ = SpinVector(ζ, T)
	κ′ = SpinVector(ζ′, T)
	κ, κ′
end


ω(t, x, y, z, s) = [0; s] - (im / √2) .* [t+z x+im*y; x-im*y t-z] * [0; 1]


# s := 0.5 Zᵝ Z̅ᵦ = 0.5 (ωᴬ π̅ ₐ + πₐₚ ω̅ ᴬ′)
# x² + y² + (z - τ)² - (√2)³ s (x sin(ϕ) + y cos(ϕ)) tan(θ) = 2s²
# z - τ = (x cos(ϕ) - y sin(ϕ)) tan(θ)
modelname = "robinson_congrunece"
totalstages = 5
figuresize = (1920, 1080)
frames_number = 360
segments = 30
segments2 = 30
segments3 = 30
compressedprojection = true
M = Identity(4)
θ = rand()
ϕ = rand()
ψ = rand()
transformation = SpinTransformation(θ, ϕ, ψ)
tiplength = 0.01
tipradius = 0.005
shaftradius = 0.001
linewidth = 2
markersize = 0.04
colorants1 = [:red, :green]
colorants2 = [:blue, :yellow]
segmentcolors = collect(1:2)
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
mask = load("data/basemap_mask.png")
projectionmap = compressedprojection ? project : projectnocompression

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :white))
rotation = gettextrotation(lscene)

northpole = Observable(Point3f(0.0, 0.0, 1.0))
meshscatter!(lscene, northpole, markersize = markersize, color = :gold)
title = Observable("s, τ, θ, ϕ, ψ")
text!(lscene,
	@lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$northpole])),
	text = title,
	color = [:gold],
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = 0.25,
	markerspace = :data,
)

lspace1 = range(-π, stop = float(π), length = segments3)
lspace2 = range(-π / 2, stop = π / 2, length = segments3)
sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]

s = rand()
τ = rand()
t = τ
T = sign(t)

twosurface = map(x -> 𝕍(t, vec(T * √abs(t) * x)...), sphere)
spinvectors = map(x -> SpinVector(vec(ω(vec(x)..., s))..., Int(T)), twosurface)
spinvectorpairs = map(x -> calculatespinvectorpairs(x, Int(T)), spinvectors)
vectorpairs = map(x -> (𝕍(x[1]), 𝕍(x[2])), spinvectorpairs)

tails = []
heads = []
tails1 = []
heads1 = []
for (index, pair) in enumerate(vectorpairs)
	color = RGBAf(convert_hsvtorgb([float(index) / float(length(vectorpairs)) * 359.0; 1.0; 1.0])..., 1.0)
	tail = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[2])))))...))
	head = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[1])))))...))
	tail1 = Observable(Point3f(projectontoplane(pair[2])))
	head1 = Observable(Point3f(projectontoplane(pair[1])))
	push!(tails, tail)
	push!(heads, head)
	push!(tails1, tail1)
	push!(heads1, head1)
	ps = @lift([$head, $head1])
	ns = @lift([normalize($tail - $head), normalize($tail1 - $head1)])
	arrows3d!(lscene,
		ps, ns, fxaa = true, # turn on anti-aliasing
		color = [color, color],
		shaftradius = shaftradius, tipradius = tipradius,
		tiplength = tiplength,
		align = :tail,
	)
	segmentP = @lift([$head, $head1])
	lines!(lscene, segmentP, linewidth = linewidth, color = color, transparency = true)
end

planematrix = makestereographicprojectionplane(M, T = float(T), segments = segments)
planeobservable = buildsurface(lscene, planematrix, mask, transparency = true)
lspace1 = range(-π, stop = float(π), length = segments2)
lspace2 = range(-π / 2, stop = π / 2, length = segments2)
sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
twosurface = map(x -> 𝕍(t, vec(sign(t) * √abs(t) * x)...), sphere)
twosurface_projection = map(x -> projectionmap(M * normalize(ℍ(vec(x)))), twosurface)
sphereobservable = buildsurface(lscene, twosurface_projection, mask, transparency = true)

Z = ℝ⁴(0.0, s, 0.0, 1.0)
Zobservable = Observable(Point3f(projectionmap(M * normalize(ℍ(vec(Z))))))
meshscatter!(lscene, Zobservable, markersize = markersize, color = :blue)
titles = ["Z"]
text!(lscene,
	@lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$Zobservable])),
	text = titles,
	color = [:blue],
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = 0.25,
	markerspace = :data,
)


animate(frame::Int) = begin
	progress = Float64(frame / frames_number)
	stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
	stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
	println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

	if stage == 1
		global s = cos(2π * stageprogress)
		global τ = 1.0
		global θ = 0.0
		global ϕ = 0.0
		global ψ = 0.0
		title[] = "s = $(round(s, digits = 3))"
	end
	if stage == 2
		global s = 1.0
		global τ = cos(2π * stageprogress)
		global θ = 0.0
		global ϕ = 0.0
		global ψ = 0.0
		title[] = "τ = $(round(τ, digits = 3))"
	end
	if stage == 3
		global s = 1.0
		global τ = 1.0
		global θ = sin(stageprogress * 2π) * π
		global ϕ = 0.0
		global ψ = 0.0
		title[] = "θ = $(round(θ, digits = 3))"
	end
	if stage == 4
		global s = 1.0
		global τ = 1.0
		global θ = 0.0
		global ϕ = sin(stageprogress * 2π) * π
		global ψ = 0.0
		title[] = "ϕ = $(round(ϕ, digits = 3))"
	end
	if stage == 5
		global s = 1.0
		global τ = 1.0
		global θ = 0.0
		global ϕ = 0.0
		global ψ = sin(stageprogress * 2π) * π
		title[] = "ψ = $(round(ψ, digits = 3))"
	end

	lspace1 = range(-π, stop = float(π), length = segments3)
	lspace2 = range(-π / 2, stop = π / 2, length = segments3)
	sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]

	t = τ
	T = sign(t)

	twosurface = map(x -> 𝕍(t, vec(T * √abs(t) * x)...), sphere)
	spinvectors = map(x -> SpinVector(vec(ω(vec(x)..., s))..., Int(T)), twosurface)
	spinvectorpairs = map(x -> calculatespinvectorpairs(x, Int(T)), spinvectors)

	spintransform = SpinTransformation(θ, ϕ, ψ)
	spherematrix = makesphere(spintransform, T, segments = segments2)
	planematrix = makestereographicprojectionplane(spintransform, T = T, segments = segments)
	updatesurface!(spherematrix, sphereobservable)
	updatesurface!(planematrix, planeobservable)

	Z = ℝ⁴(0.0, s, 0.0, 1.0)
	Zobservable[] = Point3f(projectionmap(spintransform * normalize(Z)))

	for (index, pair) in enumerate(spinvectorpairs)
		κ = 𝕍(spintransform * pair[1])
		κ′ = 𝕍(spintransform * pair[2])
        heads[index][] = Point3f(project(ℍ(normalize(vec(κ)))))
        tails[index][] = Point3f(project(normalize(ℍ(vec(κ′)))))
        tails1[index][] = Point3f(projectontoplane(κ′))
        heads1[index][] = Point3f(projectontoplane(κ))
	end
	updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
	animate(frame)
end
