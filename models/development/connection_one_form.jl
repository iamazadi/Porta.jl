using FileIO
using GLMakie
using LinearAlgebra
using Porta


ω(t, x, y, z, s) = [0; s] - (im / √2) .* [t+z x+im*y; x-im*y t-z] * [0; 1]


complexvec(q::ℍ) = begin
    a, b, c, d = vec(q)
    [a + im * b; c + im * d]
end


# to_quaternion(v::Vector{ComplexF64}) = ℍ(real(v[1]), imag(v[1]), real(v[2]), imag(v[2]))


# s := 0.5 Zᵝ Z̅ᵦ = 0.5 (ωᴬ π̅ ₐ + πₐₚ ω̅ ᴬ′)
# x² + y² + (z - τ)² - (√2)³ s (x sin(ϕ) + y cos(ϕ)) tan(θ) = 2s²
# z - τ = (x cos(ϕ) - y sin(ϕ)) tan(θ)
modelname = "complex_structure"
totalstages = 4
figuresize = (1920, 1080)
frames_number = 360 * 3
segments = 30
tiplength = 0.03
tipradius = 0.015
shaftradius = 0.005
linewidth = 5
markersize = 0.02
fontsize = 0.1
# camera configuration
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * float(π)
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
q = normalize(ℍ(1.0, 1.0, 1.0, 1.0))
M = Identity(4)
color = GLMakie.RGBAf(0.0, 1.0, 0.0, 0.75)
reference_point = ℍ(exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q
mask = load("data/basemap_mask.png")
α = 0.75

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis = false, scenekw = (lights = [pl, al], clear = true, backgroundcolor = :black))
rotation = gettextrotation(lscene)

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

whirl = Whirl(lscene, points[1], gauge1, gauge5, M, segments, getcolor(boundary_nodes[1], mask, α), transparency = true)
whirl2 = Whirl(lscene, points[2], gauge1, gauge5, M, segments, getcolor(boundary_nodes[2], mask, α), transparency = true)
whirl3 = Whirl(lscene, points[3], gauge1, gauge5, M, segments, getcolor(boundary_nodes[3], mask, α), transparency = true)
basemap0 = Basemap(lscene, reference_point, 0.0, M, chart, segments, mask, transparency = true)
basemap = Basemap(lscene, reference_point, gauge5, M, chart, segments, mask, transparency = true)

O = ℝ³(0.0, 0.0, 0.0)
s = Observable(rand())
λ = Observable(rand())
μ = @lift($s / $λ)
@assert(isapprox(λ[] * μ[], s[]), "The real part of the multiplication of λ and μ̅ is not equal to helicity s.")
P = Observable(points[1][1])
Z = @lift(ℍ(0.0, $s, 0.0, 1.0))
@assert(isapprox(det(mat(Z[])), 2 * s[], atol = 1e-1), "The inner product of Zᵅ with Z̅ₐ is not equal to twice the helicity s.")
# TODO: Use eigen decomposition to construct ℍ directly from a complex matrix with respect to a basis, (ℍ(mat(ℍ)))
X = @lift(ℍ($λ, -$s, $μ, 1.0))
Q = @lift(ℍ(ω(vec($P)..., $s)))
P_observable = @lift(Point3f(project($P)))
Z_observable = @lift(Point3f(project($Z)))
X_observable = @lift(Point3f(project($X)))
Q_observable = @lift(Point3f(project($Q)))
meshscatter!(lscene, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene, Z_observable, markersize = markersize, color = :blue)
meshscatter!(lscene, X_observable, markersize = markersize, color = :pink)
meshscatter!(lscene, Q_observable, markersize = markersize, color = :green)
titles = ["O", "P", "Z", "X", "Q"]
text!(lscene,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable, $Z_observable, $X_observable, $Q_observable])...]),
	text = titles,
	color = [:white, :gold, :blue, :pink, :green],
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

ps = @lift([Point3f(O), $P_observable])
ns = @lift([normalize($P_observable), normalize($Q_observable - $P_observable)])
arrows3d!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:gold, :green],
    shaftradius = shaftradius, tipradius = tipradius,
    tiplength = tiplength,
    align = :tail,
)

ZX_linesegment = @lift([Point3f(O), $Z_observable, $X_observable, Point3f(O)])
lines!(lscene, ZX_linesegment, linewidth = linewidth, color = :purple, transparency = true)

# TODO: this complexvec does not work with the constructor of ℍ accepting a complex vector (correct the basis in the constructor)
z₀ = @lift(complexvec($P)[1])
z₁ = @lift(complexvec($P)[2])
ϵ = 0.01
# add a combination of K(1) and K(3) for zero 1-form A, and K(3) for non-zero 1-form A
P1 = @lift(ℍ(exp(ϵ * K(1))) * $P)
P1_observable = @lift(Point3f(normalize(project($P1) - project($P))))
meshscatter!(lscene, @lift($P_observable + $P1_observable), markersize = markersize, color = :gold)
P1_linesegment = @lift([$P_observable, $P_observable + $P1_observable])
lines!(lscene, P1_linesegment, linewidth = linewidth, color = :gold, transparency = true)
X1₀ = @lift(complexvec(normalize(ℍ(vec($P1) - vec($P))))[1])
X1₁ = @lift(complexvec(normalize(ℍ(vec($P1) - vec($P))))[2])
@assert(isapprox(abs(conj(z₀[]) * X1₀[] + conj(z₁[]) * X1₁[]), 0.0, atol = 1e-2), "The horizontal tangent vectors X at z must be perpendicular to the radial vector z: z̅₀ X₀ + z̅₁ X₁ = 0.")
# 1-forms
α₀ = X1₀
α₁ = X1₁
A = @lift(0.5 * (conj($z₀) * $α₀ - $z₀ * conj($α₀) + conj($z₁) * $α₁ - $z₁ * conj($α₁)))

titles = @lift(["A = " * string(round(imag($A), digits = 3))])
text!(lscene,
	@lift([$P_observable + $P1_observable]),
	text = titles,
	color = [:gold],
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

X0 = @lift(normalize(ℍ([complexvec(normalize(ℍ(vec($P1) - vec($P))))[1]; 0.0 + im * 0.0])))
X1 = @lift(normalize(ℍ([0.0; complexvec(normalize(ℍ(vec($P1) - vec($P))))[2]])))
X0conj = @lift(normalize(ℍ([conj(complexvec(normalize(ℍ(vec($P1) - vec($P))))[1]); 0.0 + im * 0.0])))
X1conj = @lift(normalize(ℍ([0.0 + im * 0.0; conj(complexvec(normalize(ℍ(vec($P1) - vec($P))))[2])])))
X0_observable = @lift(Point3f(project($X0)))
X1_observable = @lift(Point3f(project($X1)))
X0conj_observable = @lift(Point3f(project($X0conj)))
X1conj_observable = @lift(Point3f(project($X1conj)))
oneform_ps = @lift([$P_observable, $P_observable, $P_observable, $P_observable])
oneform_ns = @lift([$X0_observable, $X1_observable, $X0conj_observable, $X1conj_observable])
arrows3d!(lscene,
    oneform_ps, oneform_ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :silver, :magenta, :brown],
    shaftradius = shaftradius, tipradius = tipradius,
    tiplength = tiplength,
    align = :tail,
)
titles = ["α₀", "α₁", "α̅₀", "α̅₁"]
text!(lscene,
	@lift([$P_observable + $X0_observable, $P_observable + $X1_observable, $P_observable + $X0conj_observable, $P_observable + $X1conj_observable]),
	text = titles,
	color = [:red, :silver, :magenta, :brown],
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
# draw the oriented area made by the wdge product of a pair of one-forms
color = fill(GLMakie.RGBAf(0.5, 0.5, 0.5, α), 2, 2)
X0X0conj = [ℝ³(P_observable[]) ℝ³(P_observable[] + X0_observable[]); ℝ³(P_observable[] + X0conj_observable[]) ℝ³(P_observable[] + X0conj_observable[] + X0_observable[])]
X0X0conj_observable = buildsurface(lscene, X0X0conj, color, transparency = true)
X1X1conj = [ℝ³(P_observable[]) ℝ³(P_observable[] + X1_observable[]); ℝ³(P_observable[] + X1conj_observable[]) ℝ³(P_observable[] + X1conj_observable[] + X1_observable[])]
X1X1conj_observable = buildsurface(lscene, X1X1conj, color, transparency = true)

animate(frame::Int) = begin
	progress = Float64(frame / frames_number)
	stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
	stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
	println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    if stage == 1
        P[] = ℍ(exp(0.0 * K(2)) * exp(sin(stageprogress * 2π) * longitudescale * K(1) + cos(stageprogress * 2π) * latitudescale * K(3))) * q
    end
    if stage == 2
        P[] = ℍ(exp(stageprogress * 2π * K(2)) * exp(sin(stageprogress * 2π) * longitudescale * K(1) + cos(stageprogress * 2π) * latitudescale * K(3))) * q
    end
    if stage == 3
        P[] = ℍ(exp(stageprogress * 2π * K(2)) * exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q
    end
    if stage == 4
        global q = normalize(ℍ(1.0, 1.0, 1.0, 1.0)) * ℍ(exp(stageprogress * K(1)))
        global reference_point = ℍ(exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q
        stage_points = []
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, θ, ϕ = convert_to_geographic(node)
                push!(_points, ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(3))) * q)
            end
            push!(stage_points, _points)
        end
        Porta.update!(basemap, reference_point, 0.0, M, chart)
        gauge = stageprogress * 2π
        Porta.update!(basemap0, reference_point, gauge, M, chart)
        Porta.update!(whirl, stage_points[1], gauge1, gauge5, M)
        Porta.update!(whirl2, stage_points[2], gauge1, gauge5, M)
        Porta.update!(whirl3, stage_points[3], gauge1, gauge5, M)
        P[] = ℍ(exp(0.0 * K(2)) * exp(sin(stageprogress * 2π) * longitudescale * K(1) + cos(stageprogress * 2π) * latitudescale * K(3))) * q
        P1[] = ℍ(exp(stageprogress * ϵ * K(2)) * exp(cos(stageprogress * 2π) * ϵ * K(1) + sin(stageprogress * 2π) * ϵ * K(3))) * P[]
    end
    if stage != 4
        P1[] = ℍ(exp(stageprogress * ϵ * K(2)) * exp(cos(stageprogress * 2π) * ϵ * K(1) + sin(stageprogress * 2π) * ϵ * K(3))) * P[]
        gauge = stageprogress * 2π
        Porta.update!(basemap, reference_point, gauge, M, chart)
    end
    X0X0conj = [ℝ³(P_observable[]) ℝ³(P_observable[] + X0_observable[]); ℝ³(P_observable[] + X0conj_observable[]) ℝ³(P_observable[] + X0conj_observable[] + X0_observable[])]
    X1X1conj = [ℝ³(P_observable[]) ℝ³(P_observable[] + X1_observable[]); ℝ³(P_observable[] + X1conj_observable[]) ℝ³(P_observable[] + X1conj_observable[] + X1_observable[])]
    updatesurface!(X0X0conj, X0X0conj_observable)
    updatesurface!(X1X1conj, X1X1conj_observable)

    global lookat = ℝ³(P_observable[] +  + P1_observable[])
    global eyeposition = float(π) * normalize(ℝ³(P_observable[]))
	updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
	animate(frame)
end