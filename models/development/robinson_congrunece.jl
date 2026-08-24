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


ω(t, x, y, z, s) = [0; s] - (im / √2) .* [t + z x + im * y; x - im * y t - z] * [0; 1]


# s := 0.5 Zᵝ Z̅ᵦ = 0.5 (ωᴬ π̅ ₐ + πₐₚ ω̅ ᴬ′)
# x² + y² + (z - τ)² - (√2)³ s (x sin(ϕ) + y cos(ϕ)) tan(θ) = 2s²
# z - τ = (x cos(ϕ) - y sin(ϕ)) tan(θ)
# s = 0.88
# t = 0.65
modelname = "robinson_congrunece"
totalstages = 5
figuresize = (1920, 1080)
frames_number = 1440
segments = 90
segments2 = 90
segments3 = 30
compressedprojection = true
# τ = rand()
M = Identity(4)
θ = rand()
ϕ = rand()
ψ = rand()
transformation = SpinTransformation(θ, ϕ, ψ)
T = 1
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

## Load the Natural Earth data
# countries = loadcountries(attributespath, nodespath)
# boundary_name = "Iran"
# colormapslist = :jet
# boundary_nodes = []
# for i in eachindex(countries["name"])
#     if countries["name"][i] == boundary_name
#         push!(boundary_nodes, countries["nodes"][i])
#     end
# end

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(RGBf(0.0862, 0.0862, 0.0862), Point3f(0))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))
rotation = gettextrotation(lscene)

# planematrix = makestereographicprojectionplane(M, T = float(-T), segments = segments)
# planeobservable2 = buildsurface(lscene, planematrix, mask, transparency = true)

# origin = Observable(Point3f(0.0, 0.0, 0.0))
northpole = Observable(Point3f(0.0, 0.0, 1.0))
meshscatter!(lscene, northpole, markersize = markersize, color = :gold)
# meshscatter!(lscene, origin, markersize = markersize, color = :gold)
# titles = ["O", "N"]
title = Observable("s, τ, θ, ϕ, ψ")
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$northpole])),
    text = title,
    color = [:gold],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

lspace1 = range(-π, stop = float(π), length = segments3)
lspace2 = range(-π / 2, stop = π / 2, length = segments3)
sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]

##### Set 1
s1 = rand()
τ = rand()
t1 = τ
T1 = sign(t1)

twosurface = map(x -> 𝕍(t1, vec(T1 * √abs(t1) * x)...), sphere)
spinvectors = map(x -> SpinVector(vec(ω(vec(x)..., s1))..., Int(T1)), twosurface)
spinvectorpairs_set1 = map(x -> calculatespinvectorpairs(x, Int(T1)), spinvectors)
vectorpairs_set1 = map(x -> (𝕍(x[1]), 𝕍(x[2])), spinvectorpairs_set1)

tails_set1 = []
heads_set1 = []
tails1_set1 = []
heads1_set1 = []
flagplanes_set1 = []
fibers = []
for (index, pair) in enumerate(vectorpairs_set1)
    color = RGBAf(convert_hsvtorgb([float(index) / float(length(vectorpairs_set1)) * 359.0; 1.0; 1.0])..., 1.0)
    tail = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[2])))))...))
    head = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[1])))))...))
    tail1 = Observable(Point3f(projectontoplane(pair[2])))
    head1 = Observable(Point3f(projectontoplane(pair[1])))
    push!(tails_set1, tail)
    push!(heads_set1, head)
    push!(tails1_set1, tail1)
    push!(heads1_set1, head1)
    ps = @lift([$head, $head1])
    ns = @lift([normalize($tail - $head), normalize($tail1 - $head1)])
    # ns = @lift([$tail - $head, $tail1 - $head1])
    arrows3d!(lscene,
        ps, ns, fxaa = true, # turn on anti-aliasing
        # color = [colorants1..., colorants2...],
        color = [color, color],
        shaftradius = shaftradius, tipradius = tipradius,
        tiplength = tiplength,
        align = :tail
    )
    # flagplanematrix = makeflagplane(pair[1], pair[2] - pair[1], float(T1), segments = 9)
    # flagplanecolor = fill(color, 9, 9)
    # flagplaneobservable = buildsurface(lscene, flagplanematrix, flagplanecolor, transparency = false)
    # push!(flagplanes_set1, flagplaneobservable)
    # meshscatter!(lscene, head, markersize = markersize, color = color)
    # meshscatter!(lscene, tail, markersize = markersize, color = color)
    # meshscatter!(lscene, head1, markersize = markersize, color = color)
    # meshscatter!(lscene, tail1, markersize = markersize, color = color)
    # segmentP = @lift([$northpole, $head, $head1])
    # lines!(lscene, segmentP, linewidth = linewidth, color = segmentcolors, colormap = :plasma, colorrange = (1, 3), transparency = true)
    segmentP = @lift([$head, $head1])
    # lines!(lscene, segmentP, linewidth = linewidth, color = segmentcolors, colormap = :sun, colorrange = (1, 2), transparency = true)
    lines!(lscene, segmentP, linewidth = linewidth, color = color, transparency = true)

    fiber = Observable([Point3f(project(normalize((ℍ(vec(pair[1])) * ℍ(exp(K(3) * α)))))) for α in range(0, stop = 2π, length = segments3)])
    lines!(lscene, fiber, linewidth = linewidth, color = color)
    push!(fibers, fiber)
end

planematrix = makestereographicprojectionplane(M, T = float(T), segments = segments)
planeobservable1 = buildsurface(lscene, planematrix, mask, transparency = true)
lspace1 = range(-π, stop = float(π), length = segments2)
lspace2 = range(-π / 2, stop = π / 2, length = segments2)
sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
twosurface = map(x -> 𝕍(t1, vec(sign(t1) * √abs(t1) * x)...), sphere)
twosurface_projection = map(x -> projectionmap(M * normalize(ℍ(vec(x)))), twosurface)
sphereobservable1 = buildsurface(lscene, twosurface_projection, mask, transparency = true)


##### Set 2
# s2 = rand()
# τ = -rand()
# t2 = τ
# T2 = sign(t2)

# twosurface = map(x -> 𝕍(t2, vec(T2 * √abs(t2) * x)...), sphere)
# spinvectors = map(x -> SpinVector(vec(ω(vec(x)..., s2))..., Int(T2)), twosurface)
# spinvectorpairs_set2 = map(x -> calculatespinvectorpairs(x, Int(T2)), spinvectors)
# vectorpairs_set2 = map(x -> (𝕍(x[1]), 𝕍(x[2])), spinvectorpairs_set2)

# tails_set2 = []
# heads_set2 = []
# tails1_set2 = []
# heads1_set2 = []
# flagplanes_set2 = []
# for (index, pair) in enumerate(vectorpairs_set2)
#     color = RGBAf(convert_hsvtorgb([90.0 + float(index) / float(length(vectorpairs_set2)) * 90.0; 1.0; 1.0])..., 1.0)
#     tail = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[2])))))...))
#     head = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[1])))))...))
#     tail1 = Observable(Point3f(projectontoplane(pair[2])))
#     head1 = Observable(Point3f(projectontoplane(pair[1])))
#     push!(tails_set2, tail)
#     push!(heads_set2, head)
#     push!(tails1_set2, tail1)
#     push!(heads1_set2, head1)
#     ps = @lift([$head, $head1])
#     ns = @lift([normalize($tail - $head), normalize($tail1 - $head1)])
#     # ns = @lift([$tail - $head, $tail1 - $head1])
#     arrows3d!(lscene,
#         ps, ns, fxaa = true, # turn on anti-aliasing
#         color = [color, color],
#         shaftradius = shaftradius, tipradius = tipradius,
#         tiplength = tiplength,
#         align = :tail
#     )
#     segmentP = @lift([$head, $head1])
#     lines!(lscene, segmentP, linewidth = linewidth, color = segmentcolors, colormap = :jet, colorrange = (1, 2), transparency = true)
# end


# ##### Set 3
# s3 = rand()
# τ = rand()
# t3 = τ
# T3 = sign(t3)

# twosurface = map(x -> 𝕍(t3, vec(T3 * √abs(t3) * x)...), sphere)
# spinvectors = map(x -> SpinVector(vec(ω(vec(x)..., s3))..., Int(T3)), twosurface)
# spinvectors = map(x -> SpinVector(conj.(vec(x)), Int(T3)), spinvectors)
# spinvectorpairs_set3 = map(x -> calculatespinvectorpairs(x, Int(T3)), spinvectors)
# vectorpairs_set3 = map(x -> (𝕍(x[1]), 𝕍(x[2])), spinvectorpairs_set3)

# tails_set3 = []
# heads_set3 = []
# tails1_set3 = []
# heads1_set3 = []
# flagplanes_set3 = []
# for (index, pair) in enumerate(vectorpairs_set3)
#     color = RGBAf(convert_hsvtorgb([180.0 + float(index) / float(length(vectorpairs_set3)) * 90.0; 1.0; 1.0])..., 1.0)
#     tail = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[2])))))...))
#     head = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[1])))))...))
#     tail1 = Observable(Point3f(projectontoplane(pair[2])))
#     head1 = Observable(Point3f(projectontoplane(pair[1])))
#     push!(tails_set3, tail)
#     push!(heads_set3, head)
#     push!(tails1_set3, tail1)
#     push!(heads1_set3, head1)
#     ps = @lift([$head, $head1])
#     ns = @lift([normalize($tail - $head), normalize($tail1 - $head1)])
#     # ns = @lift([$tail - $head, $tail1 - $head1])
#     arrows3d!(lscene,
#         ps, ns, fxaa = true, # turn on anti-aliasing
#         color = [color, color],
#         shaftradius = shaftradius, tipradius = tipradius,
#         tiplength = tiplength,
#         align = :tail
#     )
#     segmentP = @lift([$head, $head1])
#     lines!(lscene, segmentP, linewidth = linewidth, color = segmentcolors, colormap = :inferno, colorrange = (1, 2), transparency = true)
# end

# ##### Set 4
# s4 = -rand()
# τ = rand()
# t4 = τ
# T4 = sign(t4)

# twosurface = map(x -> 𝕍(t4, vec(T4 * √abs(t4) * x)...), sphere)
# spinvectors = map(x -> SpinVector(vec(ω(vec(x)..., s4))..., Int(T4)), twosurface)
# spinvectors = map(x -> SpinVector(conj.(vec(x)), Int(T4)), spinvectors)
# spinvectorpairs_set4 = map(x -> calculatespinvectorpairs(x, Int(T4)), spinvectors)
# vectorpairs_set4 = map(x -> (𝕍(x[1]), 𝕍(x[2])), spinvectorpairs_set4)

# tails_set4 = []
# heads_set4 = []
# tails1_set4 = []
# heads1_set4 = []
# flagplanes_set4 = []
# for (index, pair) in enumerate(vectorpairs_set4)
#     color = RGBAf(convert_hsvtorgb([270.0 + float(index) / float(length(vectorpairs_set4)) * 89.0; 1.0; 1.0])..., 1.0)
#     tail = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[2])))))...))
#     head = Observable(Point3f(vec(project(normalize(ℍ(vec(pair[1])))))...))
#     tail1 = Observable(Point3f(projectontoplane(pair[2])))
#     head1 = Observable(Point3f(projectontoplane(pair[1])))
#     push!(tails_set4, tail)
#     push!(heads_set4, head)
#     push!(tails1_set4, tail1)
#     push!(heads1_set4, head1)
#     ps = @lift([$head, $head1])
#     ns = @lift([normalize($tail - $head), normalize($tail1 - $head1)])
#     # ns = @lift([$tail - $head, $tail1 - $head1])
#     arrows3d!(lscene,
#         ps, ns, fxaa = true, # turn on anti-aliasing
#         color = [color, color],
#         shaftradius = shaftradius, tipradius = tipradius,
#         tiplength = tiplength,
#         align = :tail
#     )
#     segmentP = @lift([$head, $head1])
#     lines!(lscene, segmentP, linewidth = linewidth, color = segmentcolors, colormap = :sun, colorrange = (1, 2), transparency = true)
# end

Z1 = ℝ⁴(0.0, s1, 0.0, 1.0)
# Z2 = ℝ⁴(0.0, s2, 0.0, 1.0)
# Z3 = ℝ⁴(0.0, s3, 0.0, 1.0)
# Z4 = ℝ⁴(0.0, s4, 0.0, 1.0)
Zobservable1 = Observable(Point3f(projectionmap(M * normalize(ℍ(vec(Z1))))))
# Zobservable2 = Observable(Point3f(projectionmap(M * normalize(ℍ(vec(Z2))))))
# Zobservable3 = Observable(Point3f(projectionmap(M * normalize(ℍ(vec(Z3))))))
# Zobservable4 = Observable(Point3f(projectionmap(M * normalize(ℍ(vec(Z4))))))
meshscatter!(lscene, Zobservable1, markersize = markersize, color = :blue)
# meshscatter!(lscene, Zobservable2, markersize = markersize, color = :red)
# meshscatter!(lscene, Zobservable3, markersize = markersize, color = :green)
# meshscatter!(lscene, Zobservable4, markersize = markersize, color = :yellow)
# titles = ["Z₁", "Z₂", "Z₃", "Z₄"]
titles = ["Z"]
# text!(lscene,
#     @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$Zobservable1, $Zobservable2, $Zobservable3, $Zobservable4])),
#     text = titles,
#     color = [:blue, :red, :green, :yellow],
#     rotation = rotation,
#     align = (:left, :baseline),
#     fontsize = 0.25,
#     markerspace = :data
# )
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$Zobservable1])),
    text = titles,
    color = [:blue],
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

# z₁ = vec(Z1)[1] + im * vec(Z1)[2]
# z₂ = vec(Z1)[3] + im * vec(Z1)[4]
# h₁ = conj(z₁)
# h₂ = conj(z₂)

# z = SpinVector([z₁; z₂], Int(T1))
# h = SpinVector([h₂; h₁], Int(T1))
# magnitude = dot(z, h)
# @assert(isapprox(magnitude, 2s1), "The inner product of the twistor Z1 with its conjugate is not equal to 2s.")

referencet = 1.0
references = 1.0
θ = 0.0
ϕ = 0.0
ψ = 0.0

animate(frame::Int) = begin
    progress = Float64(frame / frames_number)
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")

    if stage == 1
        global s1 = cos(2π * stageprogress)
        global τ = 1.0
        global θ = 0.0
        global ϕ = 0.0
        global ψ = 0.0
        title[] = "helicity = $(round(s1, digits = 3))"
    end
    if stage == 2
        global s1 = 1.0
        global τ = cos(2π * stageprogress)
        global θ = 0.0
        global ϕ = 0.0
        global ψ = 0.0
        title[] = "time = $(round(τ, digits = 3))"
    end
    if stage == 3
        global s1 = 1.0
        global τ = 1.0
        global θ = 0.0
        global ϕ = sin(stageprogress * 2π) * π
        global ψ = 0.0
        title[] = "K1 = $(round(ϕ, digits = 3))"
    end
    if stage == 4
        global s1 = 1.0
        global τ = 1.0
        global θ = sin(stageprogress * 2π) * π
        global ϕ = 0.0
        global ψ = 0.0
        title[] = "K2 = $(round(θ, digits = 3))"
    end
    if stage == 5
        global s1 = 1.0
        global τ = 1.0
        global θ = 0.0
        global ϕ = 0.0
        global ψ = sin(stageprogress * 2π) * π
        title[] = "K3 = $(round(ψ, digits = 3))"
    end

    lspace1 = range(-π, stop = float(π), length = segments3)
    lspace2 = range(-π / 2, stop = π / 2, length = segments3)
    sphere = [convert_to_cartesian([1.0; θ; ϕ]) for θ in lspace2, ϕ in lspace1]
    
    t1 = τ
    T1 = sign(t1)

    twosurface = map(x -> 𝕍(t1, vec(T1 * √abs(t1) * x)...), sphere)
    spinvectors = map(x -> SpinVector(vec(ω(vec(x)..., s1))..., Int(T1)), twosurface)
    spinvectorpairs_set1 = map(x -> calculatespinvectorpairs(x, Int(T1)), spinvectors)
    # vectorpairs_set1 = map(x -> (𝕍(x[1]), 𝕍(x[2])), spinvectorpairs_set1)

    # spintransform = SpinTransformation(θ, ϕ, ψ)
    q = ℍ(exp(ϕ * K(1) + θ * K(2)) + ψ * K(3))
    spintransform = SpinTransformation(mat(q))
    spherematrix = makesphere(spintransform, T1, segments = segments2)
    planematrix = makestereographicprojectionplane(spintransform, T = T1, segments = segments)
    updatesurface!(spherematrix, sphereobservable1)
    updatesurface!(planematrix, planeobservable1)

    # spherematrix = makesphere(spintransform, float(-T), segments = segments)
    # planematrix = makestereographicprojectionplane(spintransform, T = float(-T), segments = segments)
    # updatesurface!(spherematrix, sphereobservable2)
    # updatesurface!(planematrix, planeobservable2)

    Z1 = ℝ⁴(0.0, s1, 0.0, 1.0)
    Zobservable1[] = Point3f(projectionmap(spintransform * normalize(Z1)))
    # Zobservable2[] = Point3f(projectionmap(spintransform * normalize(Z2)))
    # Zobservable3[] = Point3f(projectionmap(spintransform * normalize(Z3)))
    # Zobservable4[] = Point3f(projectionmap(spintransform * normalize(Z4)))

    for (index, pair) in enumerate(spinvectorpairs_set1)
        κ = 𝕍(spintransform * pair[1])
        κ′ = 𝕍(spintransform * pair[2])
        # flagplanematrix = makeflagplane(κ, 𝕍(normalize(vec(κ′ - κ))), float(T1), segments = 9)
        # updatesurface!(flagplanematrix, flagplanes_set1[index])
        heads_set1[index][] = Point3f(project(ℍ(normalize(vec(κ)))))
        tails_set1[index][] = Point3f(project(normalize(ℍ(vec(κ′)))))
        tails1_set1[index][] = Point3f(projectontoplane(κ′))
        heads1_set1[index][] = Point3f(projectontoplane(κ))

        # fibers[index][] = [Point3f(project(q * normalize(ℍ(vec(pair[1])) * ℍ(exp(K(3) * α))))) for α in range(0, stop = 2π, length = segments3)]
        fibers[index][] = [Point3f(project(ℍ(exp(K(3) * α)) * normalize(ℍ(vec(κ))))) for α in range(0, stop = 2π, length = segments3)]
    end
    # for (index, pair) in enumerate(spinvectorpairs_set2)
    #     κ = 𝕍(spintransform * pair[1])
    #     κ′ = 𝕍(spintransform * pair[2])
    #     heads_set2[index][] = Point3f(project(ℍ(normalize(vec(κ)))))
    #     tails_set2[index][] = Point3f(project(normalize(ℍ(vec(κ′)))))
    #     tails1_set2[index][] = Point3f(projectontoplane(κ′))
    #     heads1_set2[index][] = Point3f(projectontoplane(κ))
    # end
    # for (index, pair) in enumerate(spinvectorpairs_set3)
    #     κ = 𝕍(spintransform * pair[1])
    #     κ′ = 𝕍(spintransform * pair[2])
    #     heads_set3[index][] = Point3f(project(ℍ(normalize(vec(κ)))))
    #     tails_set3[index][] = Point3f(project(normalize(ℍ(vec(κ′)))))
    #     tails1_set3[index][] = Point3f(projectontoplane(κ′))
    #     heads1_set3[index][] = Point3f(projectontoplane(κ))
    # end
    # for (index, pair) in enumerate(spinvectorpairs_set4)
    #     κ = 𝕍(spintransform * pair[1])
    #     κ′ = 𝕍(spintransform * pair[2])
    #     heads_set4[index][] = Point3f(project(ℍ(normalize(vec(κ)))))
    #     tails_set4[index][] = Point3f(project(normalize(ℍ(vec(κ′)))))
    #     tails1_set4[index][] = Point3f(projectontoplane(κ′))
    #     heads1_set4[index][] = Point3f(projectontoplane(κ))
    # end
    # global eyeposition = normalize(cross(normalize(ℝ³(Float64.(vec(Zobservable1[]))...)), normalize(ℝ³(Float64.(vec(Zobservable4[]))...)))) * float(π)
    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)

record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end