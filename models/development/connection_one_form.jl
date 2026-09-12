using FileIO
using GLMakie
using LinearAlgebra
using Porta


ω(t, x, y, z, s) = [0; s] - (im / √2) .* [t+z x+im*y; x-im*y t-z] * [0; 1]


complexvec(q::ℍ) = begin
    a, b, c, d = vec(q)
    [a + im * b; c + im * d]
end


# s := 0.5 Zᵝ Z̅ᵦ = 0.5 (ωᴬ π̅ ₐ + πₐₚ ω̅ ᴬ′)
# x² + y² + (z - τ)² - (√2)³ s (x sin(ϕ) + y cos(ϕ)) tan(θ) = 2s²
# z - τ = (x cos(ϕ) - y sin(ϕ)) tan(θ)
modelname = "connection_one_form"
totalstages = 4
figuresize = (1920, 1080)
frames_number = 360 * 4
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
q = normalize(ℍ(rand(4)))
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
rotation = gettextrotation(lscene1)

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

whirl = Whirl(lscene1, points[1], gauge1, gauge5, M, segments, getcolor(boundary_nodes[1], mask, α / 2), transparency = true)
whirl2 = Whirl(lscene1, points[2], gauge1, gauge5, M, segments, getcolor(boundary_nodes[2], mask, α / 2), transparency = true)
whirl3 = Whirl(lscene1, points[3], gauge1, gauge5, M, segments, getcolor(boundary_nodes[3], mask, α / 2), transparency = true)
basemap0 = Basemap(lscene1, reference_point, 0.0, M, chart, segments, mask, transparency = true)
basemap = Basemap(lscene1, reference_point, gauge5, M, chart, segments, mask, transparency = true)
basemap1 = Basemap(lscene1, reference_point, float(π), M, chart, segments, mask, transparency = true)

O = ℝ³(0.0, 0.0, 0.0)
s = Observable(rand())
λ = Observable(rand())
μ = @lift($s / $λ)
@assert(isapprox(λ[] * μ[], s[]), "The real part of the multiplication of λ and μ̅ is not equal to helicity s.")
P = Observable(points[1][1])
Z = @lift(ℍ(0.0, $s, 0.0, 1.0))
# @assert(isapprox(det(mat(Z[])), 2 * s[], atol = 1e-1), "The inner product of Zᵅ with Z̅ₐ is not equal to twice the helicity s.")
# TODO: Use eigen decomposition to construct ℍ directly from a complex matrix with respect to a basis, (ℍ(mat(ℍ)))
X = @lift(ℍ($λ, -$s, $μ, 1.0))
Q = @lift(ℍ(ω(vec($P)..., $s)))
P_observable = @lift(Point3f(project($P)))
Z_observable = @lift(Point3f(project($Z)))
X_observable = @lift(Point3f(project($X)))
Q_observable = @lift(Point3f(project($Q)))
meshscatter!(lscene1, Point3f(O), markersize = markersize, color = :white)
meshscatter!(lscene1, P_observable, markersize = markersize, color = :gold)
meshscatter!(lscene1, Z_observable, markersize = markersize, color = :blue)
# meshscatter!(lscene1, X_observable, markersize = markersize, color = :pink)
meshscatter!(lscene1, Q_observable, markersize = markersize, color = :green)
# titles = ["O", "P", "Z", "X", "Q"]
# text!(lscene1,
# 	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable, $Z_observable, $X_observable, $Q_observable])...]),
# 	text = titles,
# 	color = [:white, :gold, :blue, :pink, :green],
# 	rotation = rotation,
# 	align = (:left, :baseline),
# 	fontsize = fontsize,
# 	markerspace = :data,
# )
titles = ["O", "P", "Z", "Q"]
text!(lscene1,
	@lift([Point3f(O), map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$P_observable, $Z_observable, $Q_observable])...]),
	text = titles,
	color = [:white, :gold, :blue, :green],
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)

ps = @lift([Point3f(O), $P_observable])
ns = @lift([normalize($P_observable), normalize($Q_observable - $P_observable)])
arrows3d!(lscene1,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:gold, :green],
    shaftradius = shaftradius, tipradius = tipradius,
    tiplength = tiplength,
    align = :tail,
)

# ZX_linesegment = @lift([Point3f(O), $Z_observable, $X_observable, Point3f(O)])
# lines!(lscene1, ZX_linesegment, linewidth = linewidth, color = :purple, transparency = true)

z₀ = @lift(complexvec($P)[1])
z₁ = @lift(complexvec($P)[2])
ϵ = 0.01
# add a combination of K(1) and K(3) for zero 1-form A, and K(3) for non-zero 1-form A
P1 = @lift(ℍ(exp(ϵ * K(1))) * $P)
P1_observable = @lift(Point3f(normalize(project($P1) - project($P))))
P1_linesegment = @lift([$P_observable, $P_observable + $P1_observable])
X₀ = @lift(complexvec(normalize(ℍ(vec($P1) - vec($P))))[1])
X₁ = @lift(complexvec(normalize(ℍ(vec($P1) - vec($P))))[2])
@assert(isapprox(abs(conj(z₀[]) * X₀[] + conj(z₁[]) * X₁[]), 0.0, atol = 1e-2), "The horizontal tangent vectors X at z must be perpendicular to the radial vector z: z̅₀ X₀ + z̅₁ X₁ = 0.")
# 1-forms
α₀ = X₀
α₁ = X₁
A = @lift(0.5 * (conj($z₀) * $α₀ - $z₀ * conj($α₀) + conj($z₁) * $α₁ - $z₁ * conj($α₁)))

titles = @lift(["A = " * string(round(imag($A), digits = 3))])
color_observable = @lift(RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($A) * 359.0)); 1.0; 1.0])..., 1.0))
text!(lscene1,
	@lift([$P_observable + $P1_observable]),
	text = titles,
	color = @lift([$color_observable]),
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = 2fontsize,
	markerspace = :data,
)
lines!(lscene1, P1_linesegment, linewidth = linewidth, color = color_observable, transparency = true)
meshscatter!(lscene1, @lift($P_observable + $P1_observable), markersize = 2markersize, color = color_observable)

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
	rotation = rotation,
	align = (:left, :baseline),
	fontsize = fontsize,
	markerspace = :data,
)
# draw the oriented area made by the wdge product of a pair of one-forms
color_array_observable = @lift(fill(RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($A) * 359.0)); 1.0; 1.0])..., α), 2, 2))
X0X0conj = [ℝ³(P_observable[]) ℝ³(P_observable[] + X0_observable[]); ℝ³(P_observable[] + X0conj_observable[]) ℝ³(P_observable[] + X0conj_observable[] + X0_observable[])]
X0X0conj_observable = buildsurface(lscene1, X0X0conj, color_array_observable, transparency = true)
X1X1conj = [ℝ³(P_observable[]) ℝ³(P_observable[] + X1_observable[]); ℝ³(P_observable[] + X1conj_observable[]) ℝ³(P_observable[] + X1conj_observable[] + X1_observable[])]
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
lspace1 = range(-π, stop = float(π), length = segments)
lspace2 = range(-π / 2, stop = π / 2, length = segments)
adjacent_points = []
adjacent_titles = []
adjacent_colors = []
adjacent_A = []
for θ in lspace2
    for ϕ in lspace1
        x, y, z = vec(convert_to_cartesian([1.0; θ; ϕ]))
        adjacent_point = @lift(ℍ(exp(ϵ2 * x * K(1) + ϵ2 * y * K(2) + ϵ2 * z * K(3))) * $P)
        adjacent_p_observable = @lift(Point3f(normalize(project($adjacent_point) - project($P))))
        push!(adjacent_points, adjacent_point)
        _X₀ = @lift(complexvec(normalize(ℍ(vec($adjacent_point) - vec($P))))[1])
        _X₁ = @lift(complexvec(normalize(ℍ(vec($adjacent_point) - vec($P))))[2])
        _α₀ = _X₀
        _α₁ = _X₁
        _A = @lift(0.5 * (conj($z₀) * $_α₀ - $z₀ * conj($_α₀) + conj($z₁) * $_α₁ - $z₁ * conj($_α₁)))
        push!(adjacent_A, _A)
        adjacent_color = @lift(RGBAf(convert_hsvtorgb([max(0.0, min(359.0, abs($_A) * 359.0)); 1.0; 1.0])..., 1.0))
        push!(adjacent_colors, color)
        adjacent_title = @lift([string(round(imag($_A), digits = 2))])
        push!(adjacent_titles, adjacent_title)
        meshscatter!(lscene1, @lift($P_observable + $adjacent_p_observable), markersize = markersize / 2.0, color = adjacent_color)
        text!(lscene1,
            @lift([$P_observable + $adjacent_p_observable]),
            text = adjacent_title,
            color = @lift([$adjacent_color]),
            rotation = rotation,
            align = (:left, :baseline),
            fontsize = fontsize / 2.0,
            markerspace = :data,
        )
    end
end

sphere = @lift([ℝ³(vec($P_observable)) + ℝ³(vec(Point3f(normalize(project(ℍ(exp(ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[1] * K(1) + ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[2] * K(2) + ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[3] * K(3))) * $P) - project($P))))) for θ in lspace2, ϕ in lspace1])
sphere_color_array_observable = @lift([RGBAf(convert_hsvtorgb([max(0.0, min(359.0, compute_connection_A($P, ℍ(exp(ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[1] * K(1) + ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[2] * K(2) + ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[3] * K(3))) * $P) * 359.0)); 1.0; 1.0])..., α / 4) for θ in lspace2, ϕ in lspace1])
sphereobservable = buildsurface(lscene1, sphere, sphere_color_array_observable, transparency = true)

for _ϵ in range(0.1, stop = 0.9, length = 9)
    sphere2 = @lift([ℝ³(vec($P_observable)) + ℝ³(vec(Point3f(project(ℍ(exp(_ϵ * vec(convert_to_cartesian([1.0; θ; ϕ]))[1] * K(1) + _ϵ * vec(convert_to_cartesian([1.0; θ; ϕ]))[2] * K(2) + _ϵ * vec(convert_to_cartesian([1.0; θ; ϕ]))[3] * K(3))) * $P) - project($P)))) for θ in lspace2, ϕ in lspace1])
    sphere2_color_array_observable = @lift([RGBAf(convert_hsvtorgb([max(0.0, min(359.0, compute_connection_A($P, ℍ(exp(ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[1] * K(1) + ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[2] * K(2) + ϵ2 * vec(convert_to_cartesian([1.0; θ; ϕ]))[3] * K(3))) * $P) * 359.0)); 1.0; 1.0])..., α / 4) for θ in lspace2, ϕ in lspace1])
    sphere2observable = buildsurface(lscene1, sphere2, sphere2_color_array_observable, transparency = true)
end

# Plot the Hopf fiber of the point P
linecolors = collect(1:segments)
fiber = @lift([Point3f(project($P)) for α in range(0, stop = 2π, length = segments)])
lines!(lscene1, fiber, linewidth = linewidth, color = linecolors, colorrange = (1, segments), colormap = :plasma)

x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
origin = Observable(Point3f(ℝ³(0.0, 0.0, 0.0)))
# c2point = @lift(Point3f((ℝ³(abs($z₀), abs($z₁), 0.0))))
# c2point_adjacent = @lift(Point3f((ℝ³(abs(complexvec($P1)[1]), abs(complexvec($P1)[2]), 0.0))))
c2point = @lift(Point3f(ℝ³(abs($z₀) * sign(real($z₀)), abs($z₁) * sign(real($z₁)), 0.0)))
c2point_adjacent = @lift(Point3f((ℝ³(abs(complexvec($P1)[1]) * sign(real(complexvec($P1)[1])), abs(complexvec($P1)[2]) * sign(real(complexvec($P1)[2])), 0.0))))
X_c2 = @lift(normalize($c2point_adjacent - $c2point))
meshscatter!(lscene2, origin, markersize = markersize, color = :white)
meshscatter!(lscene2, c2point, markersize = markersize, color = :gold)
circle = [Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)]
lines!(lscene2, circle, color = linecolors, linewidth = linewidth, colorrange = (1, segments), colormap = :rainbow)
w = Observable(ℍ([1.0 + im * 0.0; 0.0 + im * 0.0]))
z = Observable(ℍ([0.0 + im * 0.0; 1.0 + im * 0.0]))
whead = @lift(Point3f((ℝ³(abs(complexvec($w)[1]) * sign(real(complexvec($w)[1])), abs(complexvec($w)[2]) * sign(real(complexvec($w)[2])), 0.0))))
zhead = @lift(Point3f((ℝ³(abs(complexvec($z)[1]) * sign(real(complexvec($z)[1])), abs(complexvec($z)[2]) * sign(real(complexvec($z)[2])), 0.0))))
c2_ps = @lift([$origin, $origin, $origin, $c2point])
c2_ns = @lift([$whead, $zhead, $c2point, $X_c2])
colorants2 = @lift([:white, :white, :gold, $color_observable])
arrows3d!(lscene2,
    c2_ps, c2_ns, fxaa = true, # turn on anti-aliasing
    color = colorants2,
    shaftradius = shaftradius, tipradius = tipradius,
    tiplength = tiplength,
    align = :tail,
)
titles2 = @lift(["w ∈ ℂ²", "z ∈ ℂ²", "P = $($P)", "X ∈ TS³"])
rotation2 = gettextrotation(lscene2)
text!(lscene2,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$whead, $zhead, $c2point, $c2point + $X_c2])),
    text = titles2,
    color = colorants2,
    rotation = rotation2,
    align = (:left, :baseline),
    fontsize = fontsize,
    markerspace = :data
)


animate(frame::Int) = begin
	progress = Float64(frame / frames_number)
	stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
	stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
	println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    if stage == 1
        g = ℍ(exp(0.0 * K(1)))
        global reference_point = ℍ(exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q * g
        stage_points = []
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, θ, ϕ = convert_to_geographic(node)
                push!(_points, ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(3))) * q * g)
            end
            push!(stage_points, _points)
        end
        Porta.update!(basemap, reference_point, 0.0, M, chart)
        Porta.update!(basemap1, reference_point, float(π), M, chart)
        gauge = stageprogress * 2π
        Porta.update!(basemap0, reference_point, gauge, M, chart)
        Porta.update!(whirl, stage_points[1], gauge1, gauge5, M)
        Porta.update!(whirl2, stage_points[2], gauge1, gauge5, M)
        Porta.update!(whirl3, stage_points[3], gauge1, gauge5, M)
        P[] = ℍ(exp(0.0 * K(2) + sin(stageprogress * 2π) * 2π * K(1) + 0.0 * K(3))) * q
        w[] = ℍ([1.0 + im * 0.0; 0.0 + im * 0.0]) * q * g
        z[] = ℍ([0.0 + im * 0.0; 1.0 + im * 0.0]) * q * g
    elseif stage == 2
        g = ℍ(exp(0.0 * K(1)))
        P[] = ℍ(exp(0.0 * K(2) + 0.0 * K(1) + sin(stageprogress * 2π) * 2π * K(3))) * q
        w[] = ℍ([1.0 + im * 0.0; 0.0 + im * 0.0]) * q * g
        z[] = ℍ([0.0 + im * 0.0; 1.0 + im * 0.0]) * q * g
        global reference_point = ℍ(exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q * g
        stage_points = []
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, θ, ϕ = convert_to_geographic(node)
                push!(_points, ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(3))) * q * g)
            end
            push!(stage_points, _points)
        end
        Porta.update!(basemap, reference_point, 0.0, M, chart)
        Porta.update!(basemap1, reference_point, float(π), M, chart)
        gauge = stageprogress * 2π
        Porta.update!(basemap0, reference_point, gauge, M, chart)
        Porta.update!(whirl, stage_points[1], gauge1, gauge5, M)
        Porta.update!(whirl2, stage_points[2], gauge1, gauge5, M)
        Porta.update!(whirl3, stage_points[3], gauge1, gauge5, M)
    elseif stage == 3
        g = ℍ(exp(0.0 * K(1)))
        global reference_point = ℍ(exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q * g
        stage_points = []
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, θ, ϕ = convert_to_geographic(node)
                push!(_points, ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(3))) * q * g)
            end
            push!(stage_points, _points)
        end
        Porta.update!(basemap, reference_point, 0.0, M, chart)
        Porta.update!(basemap1, reference_point, float(π), M, chart)
        gauge = stageprogress * 2π
        Porta.update!(basemap0, reference_point, gauge, M, chart)
        Porta.update!(whirl, stage_points[1], gauge1, gauge5, M)
        Porta.update!(whirl2, stage_points[2], gauge1, gauge5, M)
        Porta.update!(whirl3, stage_points[3], gauge1, gauge5, M)
        P[] = ℍ(exp(sin(stageprogress * 2π) * 2π * K(2) + 0.0 * K(1) + 0.0 * K(3))) * q
        w[] = ℍ([1.0 + im * 0.0; 0.0 + im * 0.0]) * q * g
        z[] = ℍ([0.0 + im * 0.0; 1.0 + im * 0.0]) * q * g
    elseif stage == 4
        g = ℍ(exp(sin(stageprogress * 2π) * 2π * K(1)))
        global reference_point = ℍ(exp(0.0 * longitudescale * K(1) + 0.0 * latitudescale * K(3))) * q * g
        stage_points = []
        for i in eachindex(boundary_nodes)
            _points = Vector{ℍ}()
            for node in boundary_nodes[i]
                r, θ, ϕ = convert_to_geographic(node)
                push!(_points, ℍ(exp(ϕ * longitudescale * K(1) + θ * latitudescale * K(3))) * q * g)
            end
            push!(stage_points, _points)
        end
        Porta.update!(basemap, reference_point, 0.0, M, chart)
        Porta.update!(basemap1, reference_point, float(π), M, chart)
        gauge = stageprogress * 2π
        Porta.update!(basemap0, reference_point, gauge, M, chart)
        Porta.update!(whirl, stage_points[1], gauge1, gauge5, M)
        Porta.update!(whirl2, stage_points[2], gauge1, gauge5, M)
        Porta.update!(whirl3, stage_points[3], gauge1, gauge5, M)
        P[] = ℍ(exp(0.0 * K(2) + 0.0 * K(1) + 0.0 * K(3))) * q * g
        w[] = ℍ([1.0 + im * 0.0; 0.0 + im * 0.0]) * q * g
        z[] = ℍ([0.0 + im * 0.0; 1.0 + im * 0.0]) * q * g
    end
    
    P1[] = ℍ(exp(progress * 2π * ϵ * K(2) + cos(progress * 2π) * 2π * ϵ * K(1) + sin(progress * 2π) * 2π * ϵ * K(3))) * P[]
    X0X0conj = [ℝ³(P_observable[]) ℝ³(P_observable[] + X0_observable[]); ℝ³(P_observable[] + X0conj_observable[]) ℝ³(P_observable[] + X0conj_observable[] + X0_observable[])]
    X1X1conj = [ℝ³(P_observable[]) ℝ³(P_observable[] + X1_observable[]); ℝ³(P_observable[] + X1conj_observable[]) ℝ³(P_observable[] + X1conj_observable[] + X1_observable[])]
    updatesurface!(X0X0conj, X0X0conj_observable)
    updatesurface!(X1X1conj, X1X1conj_observable)

    _lookat = 0.5 * ℝ³(P_observable[] + P1_observable[])
    global lookat = any(map(x -> isnan(x), vec(_lookat))) ? lookat : _lookat
    # global eyeposition = float(π) * normalize(normalize(ℝ³(P_observable[])) + normalize(cross(ℝ³(X1_observable[]), ℝ³(X1conj_observable[]))))
    # global up = ℝ³(X1conj_observable[]) - ℝ³(X1_observable[])
	updatecamera!(lscene1, eyeposition, lookat, up)
    _lookat = 0.5 * ℝ³(c2point[] + X_c2[])
    global lookat = any(map(x -> isnan(x), vec(_lookat))) ? lookat : _lookat
    updatecamera!(lscene2, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
	animate(frame)
end