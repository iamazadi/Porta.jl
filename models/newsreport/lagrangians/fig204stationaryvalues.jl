import LinearAlgebra
using FileIO
using GLMakie
using Porta


"""
build_surface(scene, points, color; transparency, shading)

Builds a surface with the given scene, points, color, transparency
and shading.
"""
function build_surface(
    scene,
    points,
    color;
    transparency = true
)
    surface!(
        scene,
        @lift($points[:, :, 1]),
        @lift($points[:, :, 2]),
        @lift($points[:, :, 3]),
        color = color,
        transparency = transparency
    )
end


f(x, y) = (-x .* exp.(-x .^ 2 .- (y') .^ 2)) .* 4


f(A) = begin
    x, y = eachcol(A)
    (-x .* exp.(-x .^ 2 .- y .^ 2)) .* 4
end


d(Φ, A) = begin
    rows, cols = size(A)
    D = Matrix{Float64}(undef, rows, cols)
    E = Matrix{Float64}(LinearAlgebra.I, cols, cols) .* ϵ
    for (i, v) in enumerate(eachrow(A))
        P = repeat(v, 1, cols)
        P′ = P + E
        D[i, :] .= (f(transpose(P)) - f(transpose(P′))) ./ ϵ
    end
    D
end


ξΦ(Φ, ξ, A) = begin
    derivative = d(Φ, A)
    D = similar(derivative)
    for (i, v) in enumerate(eachrow(derivative))
        D[i, :] .= v .* ξ
    end
    D
end


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig204stationaryvalues"
totalstages = 5
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(0.0, 1.0, 1.0)) * float(π)
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
mask = load("data/basemap_color.png")
markersize = 0.1
ϵ = 1e-7
N = 51
arrowlinewidth = 0.1
arrowsize = Vec3f(0.15, 0.15, 0.2)
pathlinewidth = 9
scale = 0.71

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=true, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
zm = -1.0

lspace = range(-2, stop = 2, length = N)
points = f(lspace, lspace)

tangent_tail(x) = [Point3f(x[i, 1], x[i, 2], f(x[i, 1], x[i, 2])) for i = 1:size(x, 1)]
tangent_head(x, f, ξ) = [
    Point3f(
        ξ[1] * ϵ,
        ξ[2] * ϵ,
        f(x[i, 1] + ξ[1] * ϵ, x[i, 2] + ξ[2] * ϵ) - f(x[i, 1], x[i, 2]),
    ) ./ ϵ for i = 1:size(x, 1)
]
stiff_tail(x) = [Point3f(x[i, 1], x[i, 2], zm) for i = 1:size(x, 1)]
stiff_head(x, f, ξ) = begin
    derivative = ξΦ(f, ξ, x)
    [Point3f(derivative[i, 1], derivative[i, 2], 0) for i = 1:size(x, 1)]
end
normal(x, f) = begin
    tx = tangent_head(x, f, [1; 0])
    ty = tangent_head(x, f, [0; 1])
    [LinearAlgebra.normalize(LinearAlgebra.cross(tx[i], ty[i])) for i = 1:size(x, 1)]
end
plane(x, f, ξ) = begin
    t = tangent_tail(x)
    tx = tangent_head(x, f, [ξ[1]*0.1+1; 0])
    ty = tangent_head(x, f, [0; ξ[2]*0.1+1])
    surf(i) = begin
        p = Array{Float64}(undef, 2, 2, 3)
        p[1, 1, :] = LinearAlgebra.normalize(tx[i] + ty[i] .+ ϵ * rand()) + t[i]
        p[1, 2, :] = LinearAlgebra.normalize(-tx[i] + ty[i] .+ ϵ * rand()) + t[i]
        p[2, 1, :] = LinearAlgebra.normalize(tx[i] - ty[i] .+ ϵ * rand()) + t[i]
        p[2, 2, :] = LinearAlgebra.normalize(-tx[i] - ty[i] .+ ϵ * rand()) + t[i]
        p
    end
    [surf(i) for i = 1:size(x, 1)]
end
number = 1
u_observable = Observable(0.0)
v_observable = Observable(0.0)
ξ_observable = Observable(0.0)
P = @lift([$u_observable $v_observable])
tangent_arrowtail = @lift(tangent_tail($P))
tangent_arrowhead = @lift(tangent_head($P, f, [cos($ξ_observable); sin($ξ_observable)]))
yconst_tangent_arrowhead = @lift(tangent_head($P, f, [cos($ξ_observable); 0]))
xconst_tangent_arrowhead = @lift(tangent_head($P, f, [0; sin($ξ_observable)]))
normal_arrowhead = @lift(normal($P, f))
stiff_arrowtail = @lift(stiff_tail($P))
ξarrowhead = @lift(stiff_head($P, f, [cos($ξ_observable); sin($ξ_observable)]))
yconst_stiff_arrowhead = @lift(stiff_head($P, f, [cos($ξ_observable); 0]))
xconst_stiff_arrowhead = @lift(stiff_head($P, f, [0; sin($ξ_observable)]))

ps = @lift([($stiff_arrowtail)[1], ($stiff_arrowtail)[1], ($tangent_arrowtail)[1], ($stiff_arrowtail)[1], ($tangent_arrowtail)[1], ($tangent_arrowtail)[1], ($tangent_arrowtail)[1]])
ns = @lift([($xconst_stiff_arrowhead)[1], ($yconst_stiff_arrowhead)[1], ($normal_arrowhead)[1], ($ξarrowhead)[1], ($tangent_arrowhead)[1], ($xconst_tangent_arrowhead)[1], ($yconst_tangent_arrowhead)[1]])
arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = [:red, :green, :blue, :orange, :magenta, :red, :green],
    linewidth = arrowlinewidth, arrowsize = arrowsize,
    align = :origin
)

contour!(
    lscene,
    lspace,
    lspace,
    f(lspace, lspace),
    levels = 15,
    linewidth = 2,
    transformation = (:xy, zm),
    colormap = :cinferno,
)
wireframe!(
    lscene,
    lspace,
    lspace,
    f(lspace, lspace),
    overdraw = true,
    transparency = true,
    color = (:black, 0.5),
)

for i in 1:number
    build_surface(lscene, @lift(plane($P, f, [cos($ξ_observable); sin($ξ_observable)])[i]), mask)
end

tangentpathpoints = Observable(Point3f[])
stiffpathpoints = Observable(Point3f[])
pathcolors = Observable(Int[])
lines!(lscene, tangentpathpoints, color = pathcolors, linewidth = pathlinewidth, colorrange = (1, frames_number), colormap = :rainbow)
lines!(lscene, stiffpathpoints, color = pathcolors, linewidth = pathlinewidth, colorrange = (1, frames_number), colormap = :rainbow)
meshscatter!(lscene, @lift(($tangent_arrowtail)[1]), markersize = markersize, color = :gold)
meshscatter!(lscene, Point3f(0.0, 0.0, f(0.0, 0.0)), markersize = markersize, color = :gold)
meshscatter!(lscene, Point3f(1.0 * scale, 0.0, f(1.0 * scale, 0.0)), markersize = markersize, color = :gold)
meshscatter!(lscene, Point3f(-1.0 * scale, 0.0, f(-1.0 * scale, 0.0)), markersize = markersize, color = :gold)
meshscatter!(lscene, Point3f(0.0, 1.0 * scale, f(0.0, 1.0 * scale)), markersize = markersize, color = :gold)
meshscatter!(lscene, Point3f(0.0, -1.0 * scale, f(0.0, -1.0 * scale)), markersize = markersize, color = :gold)
build_surface(lscene, @lift(plane([0.0 0.0], f, [cos($ξ_observable); sin($ξ_observable)])[1]), mask)
build_surface(lscene, @lift(plane([1.0 * scale 0.0], f, [cos($ξ_observable); sin($ξ_observable)])[1]), mask)
build_surface(lscene, @lift(plane([-1.0 * scale 0.0], f, [cos($ξ_observable); sin($ξ_observable)])[1]), mask)
build_surface(lscene, @lift(plane([0.0 1.0 * scale], f, [cos($ξ_observable); sin($ξ_observable)])[1]), mask)
build_surface(lscene, @lift(plane([0.0 -1.0 * scale], f, [cos($ξ_observable); sin($ξ_observable)])[1]), mask)


animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    if stage == 1
        ξ_observable[] = 0.0
        u_observable[] = stageprogress * cos(stageprogress * 2pi) * scale
        v_observable[] = stageprogress * sin(stageprogress * 2pi) * scale
    end
    if stage == 2
        ξ_observable[] = stageprogress * 2pi # animate scene
        u_observable[] = cos(stageprogress * 2pi) * scale
        v_observable[] = sin(stageprogress * 2pi) * scale
    end
    if stage == 3
        ξ_observable[] = stageprogress * 2pi # animate scene
        u_observable[] = (1 - stageprogress) * cos(2π) * scale
        v_observable[] = (1 - stageprogress) * sin(2π) * scale
    end
    if stage == 4
        ξ_observable[] = stageprogress * 2pi # animate scene
        u_observable[] = sin(stageprogress * 2π) * scale
        v_observable[] = 0.0
    end
    if stage == 5
        ξ_observable[] = stageprogress * 2pi # animate scene
        u_observable[] = 0.0
        v_observable[] = sin(stageprogress * 2π) * scale
    end

    notify(ξ_observable)
    notify(u_observable)
    notify(v_observable)

    push!(tangentpathpoints[], tangent_arrowtail[][])
    push!(stiffpathpoints[], stiff_arrowtail[][])
    push!(pathcolors[], frame)
    notify(tangentpathpoints)
    notify(stiffpathpoints)
    notify(pathcolors)
    
    global eyeposition = ℝ³(1 - sin(progress * 2pi), 1 - sin(progress * 2pi), 1 + sin(progress * 2pi)) * 3.0
    global lookat = ℝ³(tangent_arrowtail[][])

    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end