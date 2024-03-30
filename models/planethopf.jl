import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (1920, 1080)
segments = 60
basemapsegments = 60
modelname = "planethopf"
frames_number = 1440
indices = Dict()
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(1.0, 0.0, 0.0))

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask.png")
## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
selectionindices = Int.(floor.(collect(range(1, stop = length(countries["name"]), length = 100))))
boundary_names = countries["name"][selectionindices]
if "Antarctica" ∉ boundary_names
    push!(boundary_names, "Antarctica")
end
# boundary_names = ["United States of America", "Antarctica", "Iran", "Australia", "Argentina", "Canada", "Russia", "Chile", "Turkey", "Russia", "South Africa", "Pakistan"]
boundary_nodes = Vector{Vector{ℝ³}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
            println(name)
            indices[name] = length(boundary_nodes)
        end
    end
end

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

θ1 = float(π)
q = Quaternion(ℝ⁴(0.0, 0.0, 1.0, 0.0))
chart = (-π / 2, π / 2, -π / 2, π / 2)
M = rand(4, 4)
_f(x::Quaternion) = normalize(M * x)
basemap1 = Basemap(lscene, q, _f, chart, basemapsegments, basemap_color, transparency = true)
basemap2 = Basemap(lscene, q, _f, chart, basemapsegments, basemap_color, transparency = true)
basemap3 = Basemap(lscene, q, _f, chart, basemapsegments, basemap_color, transparency = true)
basemap4 = Basemap(lscene, q, _f, chart, basemapsegments, basemap_color, transparency = true)

whirls = []
_whirls = []
for i in eachindex(boundary_nodes)
    color = getcolor(boundary_nodes[i], colorref, 0.1)
    _color = getcolor(boundary_nodes[i], colorref, 0.05)
    w = _f.([σmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])])
    whirl = Whirl(lscene, w, 0.0, θ1, _f, segments, color, transparency = true)
    _whirl = Whirl(lscene, w, θ1, 2π, _f, segments, _color, transparency = true)
    push!(whirls, whirl)
    push!(_whirls, _whirl)
end


function animate_fourscrew(progress::Float64, status::Int)
    if status == 1 # roation
        w = 1.0
        ϕ = log(w) # rapidity
        ψ = progress * 2π
    end
    if status == 2 # boost
        w = max(1e-4, abs(cos(progress * 2π)))
        ϕ = log(w) # rapidity
        ψ = 0.0
    end
    if status == 3 # four-screw
        w = max(1e-4, abs(cos(progress * 2π)))
        ϕ = log(w) # rapidity
        ψ = progress * 4π
    end
    X, Y, Z = vec(ℝ³(0.0, 1.0, 0.0))
    T = 1.0
    u = 𝕍(ℝ⁴(T, X, Y, Z))
    @assert(isnull(u), "u in not null, $u.")
    q = normalize(Quaternion(T, X, Y, Z))
    f(x::Quaternion) = begin
        T, X, Y, Z = vec(x)
        X̃ = X * cos(ψ) - Y * sin(ψ)
        Ỹ = X * sin(ψ) + Y * cos(ψ)
        Z̃ = Z * cosh(ϕ) + T * sinh(ϕ)
        T̃ = Z * sinh(ϕ) + T * cosh(ϕ)
        Quaternion(T̃, X̃, Ỹ, Z̃)
    end
    r₁ = f(Quaternion(1.0, 0.0, 0.0, 0.0))
    r₂ = f(Quaternion(0.0, 1.0, 0.0, 0.0))
    r₃ = f(Quaternion(0.0, 0.0, 1.0, 0.0))
    r₄ = f(Quaternion(0.0, 0.0, 0.0, 1.0))
    M = reshape([vec(r₁); vec(r₂); vec(r₃); vec(r₄)], (4, 4))
    F = LinearAlgebra.eigen(M)
    λ = LinearAlgebra.normalize(F.values) # normalize eigenvalues for a unimodular transformation
    Λ = [λ[1] 0.0 0.0 0.0; 0.0 λ[2] 0.0 0.0; 0.0 0.0 λ[3] 0.0; 0.0 0.0 0.0 λ[4]]
    M′ = F.vectors * Λ * LinearAlgebra.inv(F.vectors)
    N = real.(M′)
    f′(x::Quaternion) = normalize(N * x)

    s = SpinVector(u)
    T̃, X̃, Ỹ, Z̃ = vec(f′(Quaternion(u.a)))
    v = 𝕍(ℝ⁴(T̃, X̃, Ỹ, Z̃))
    @assert(isnull(v), "v in not null, $v.")
    s′ = SpinVector(v)
    ζ = w * exp(im * ψ) * s.ζ
    ζ′ = s′.ζ
    if (ζ′ == Inf)
        ζ = real(ζ)
    end
    @assert(isapprox(ζ, ζ′), "The transformation induced on the Argand plane is not correct, $ζ != $ζ′.")
   
    update!(basemap1, q, f′)
    update!(basemap2, q , x -> f′(exp(K(3) * π / 2) * x))
    update!(basemap3, q, x -> f′(exp(K(3) * π) * x))
    update!(basemap4, q, x -> f′(exp(K(3) * 3π / 2) * x))
    for i in eachindex(boundary_nodes)
        points = Quaternion[]
        for node in boundary_nodes[i]
            r, θ, ϕ = convert_to_geographic(node)
            push!(points, exp(ϕ / 2 * K(1) + θ * K(2)) * q)
        end
        update!(whirls[i], points, θ1, 2π, f′)
        update!(_whirls[i], points, 0.0, θ1, f′)
    end
end


function animate_nullrotation(progress::Float64)
    a = sin(progress * 2π)
    X, Y, Z = vec(ℝ³(0.0, 1.0, 0.0))
    T = 1.0
    u = 𝕍(ℝ⁴(T, X, Y, Z))
    @assert(isnull(u), "u in not null, $u.")
    q = normalize(Quaternion(T, X, Y, Z))
    f(x::Quaternion) = begin
        T, X, Y, Z = vec(x)
        X̃ = X 
        Ỹ = Y + a * (T - Z)
        Z̃ = Z + a * Y + 0.5 * a^2 * (T - Z)
        T̃ = T + a * Y + 0.5 * a^2 * (T - Z)
        normalize(Quaternion(T̃, X̃, Ỹ, Z̃))
    end

    s = SpinVector(u)
    T̃, X̃, Ỹ, Z̃ = vec(f(Quaternion(u.a)))
    v = 𝕍(ℝ⁴(T̃, X̃, Ỹ, Z̃))
    @assert(isnull(v), "v in not null, $v.")
    s′ = SpinVector(v)
    β = Complex(im)
    ζ = a * s.ζ + β
    ζ′ = s′.ζ
    if (ζ′ == Inf)
        ζ = real(ζ)
    end
    @assert(isapprox(ζ, ζ′), "The transformation induced on the Argand plane is not correct, $ζ != $ζ′.")

    update!(basemap1, q, f)
    update!(basemap2, q , x -> f(exp(K(3) * π / 2) * x))
    update!(basemap3, q, x -> f(exp(K(3) * π) * x))
    update!(basemap4, q, x -> f(exp(K(3) * 3π / 2) * x))
    for i in eachindex(boundary_nodes)
        points = Quaternion[]
        for node in boundary_nodes[i]
            r, θ, ϕ = convert_to_geographic(node)
            push!(points, exp(ϕ / 2 * K(1) + θ * K(2)) * q)
        end
        update!(whirls[i], points, θ1, 2π, f)
        update!(_whirls[i], points, 0.0, θ1, f)
    end
end


updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


write(frame::Int) = begin
    progress = frame / frames_number
    totalstages = 4
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    if stage == 1
        animate_fourscrew(stageprogress, 1)
    elseif stage == 2
        animate_fourscrew(stageprogress, 2)
    elseif stage == 3
        animate_fourscrew(stageprogress, 3)
    elseif stage == 4
        animate_nullrotation(stageprogress)
    end
    updatecamera()
end


write(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    write(frame)
end