import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (1920, 1080)
segments = 30
frames_number = 1440
modelname = "planethopf"
indices = Dict()
T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
u = 𝕍(T, X, Y, Z)
q = Quaternion(T, X, Y, Z)
tolerance = 1e-3
@assert(isnull(u, atol = tolerance), "u in not a null vector, $u.")
@assert(isapprox(norm(q), 1, atol = tolerance), "q in not a unit quaternion, $(norm(q)).")
gauge1 = 0.0
gauge2 = π / 2
gauge3 = float(π)
gauge4 = 3π / 2
gauge5 = 2π
chart = (-π / 4, π / 4, -π / 4, π / 4)
M = I(4)
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π * 0.8
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(1.0, 0.0, 0.0))
totalstages = 4

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = ["United States of America", "Antarctica", "Australia", "Iran", "Canada", "Turkey", "New Zealand", "Mexico", "Pakistan", "Russia"]
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

points = Vector{Quaternion}[]
for i in eachindex(boundary_nodes)
    _points = Quaternion[]
    for node in boundary_nodes[i]
        r, θ, ϕ = convert_to_geographic(node)
        push!(_points, q * Quaternion(exp(ϕ / 4 * K(1) + θ / 2 * K(2))))
    end
    push!(points, _points)
end

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

reference = FileIO.load("data/basemap_color.png")
mask = FileIO.load("data/basemap_mask.png")
basemap1 = Basemap(lscene, q, gauge1, M, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene, q, gauge2, M, chart, segments, mask, transparency = true)
basemap3 = Basemap(lscene, q, gauge3, M, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene, q, gauge4, M, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.1)
    color2 = getcolor(boundary_nodes[i], reference, 0.2)
    color3 = getcolor(boundary_nodes[i], reference, 0.3)
    color4 = getcolor(boundary_nodes[i], reference, 0.4)
    whirl1 = Whirl(lscene, points[i], gauge1, gauge2, M, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, points[i], gauge2, gauge3, M, segments, color2, transparency = true)
    whirl3 = Whirl(lscene, points[i], gauge3, gauge4, M, segments, color3, transparency = true)
    whirl4 = Whirl(lscene, points[i], gauge4, gauge5, M, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end


function compute_fourscrew(progress::Float64, status::Int)
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
        ψ = progress * 2π
    end
    transform(x::Quaternion) = begin
        T, X, Y, Z = vec(x)
        X̃ = X * cos(ψ) - Y * sin(ψ)
        Ỹ = X * sin(ψ) + Y * cos(ψ)
        Z̃ = Z * cosh(ϕ) + T * sinh(ϕ)
        T̃ = Z * sinh(ϕ) + T * cosh(ϕ)
        Quaternion(T̃, X̃, Ỹ, Z̃)
    end
    r₁ = transform(Quaternion(1.0, 0.0, 0.0, 0.0))
    r₂ = transform(Quaternion(0.0, 1.0, 0.0, 0.0))
    r₃ = transform(Quaternion(0.0, 0.0, 1.0, 0.0))
    r₄ = transform(Quaternion(0.0, 0.0, 0.0, 1.0))
    _M = reshape([vec(r₁); vec(r₂); vec(r₃); vec(r₄)], (4, 4))
    decomposition = LinearAlgebra.eigen(_M)
    λ = LinearAlgebra.normalize(decomposition.values) # normalize eigenvalues for a unimodular transformation
    Λ = [λ[1] 0.0 0.0 0.0; 0.0 λ[2] 0.0 0.0; 0.0 0.0 λ[3] 0.0; 0.0 0.0 0.0 λ[4]]
    M = real.(decomposition.vectors * Λ * LinearAlgebra.inv(decomposition.vectors))

    u₁ = 𝕍(1.0, 1.0, 0.0, 0.0)
    u₂ = 𝕍(1.0, 0.0, 1.0, 0.0)
    u₃ = 𝕍(1.0, 0.0, 0.0, 1.0)
    for u in [u₁, u₂, u₃]
        v = 𝕍(vec(M * Quaternion(u.a)))
        @assert(isnull(v, atol = tolerance), "v ∈ 𝕍 in not null, $v.")
        s = SpinVector(u)
        s′ = SpinVector(v)
        if s.ζ == Inf # A Float64 number (the point at infinity)
            ζ = s.ζ
        else # A Complex number
            ζ = w * exp(im * ψ) * s.ζ
        end
        ζ′ = s′.ζ
        if ζ′ == Inf
            ζ = real(ζ)
        end
        @assert(isapprox(ζ, ζ′, atol = tolerance), "The transformation induced on Argand plane is not correct, $ζ != $ζ′.")
    end
    
    M
end


function compute_nullrotation(progress::Float64)
    a = sin(progress * 2π)
    transform(x::Quaternion) = begin
        T, X, Y, Z = vec(x)
        X̃ = X 
        Ỹ = Y + a * (T - Z)
        Z̃ = Z + a * Y + 0.5 * a^2 * (T - Z)
        T̃ = T + a * Y + 0.5 * a^2 * (T - Z)
        Quaternion(T̃, X̃, Ỹ, Z̃)
    end
    r₁ = transform(Quaternion(1.0, 0.0, 0.0, 0.0))
    r₂ = transform(Quaternion(0.0, 1.0, 0.0, 0.0))
    r₃ = transform(Quaternion(0.0, 0.0, 1.0, 0.0))
    r₄ = transform(Quaternion(0.0, 0.0, 0.0, 1.0))
    _M = reshape([vec(r₁); vec(r₂); vec(r₃); vec(r₄)], (4, 4))
    decomposition = LinearAlgebra.eigen(_M)
    λ = decomposition.values
    Λ = [λ[1] 0.0 0.0 0.0; 0.0 λ[2] 0.0 0.0; 0.0 0.0 λ[3] 0.0; 0.0 0.0 0.0 λ[4]]
    M = real.(decomposition.vectors * Λ * LinearAlgebra.inv(decomposition.vectors))

    u₁ = 𝕍(1.0, 1.0, 0.0, 0.0)
    u₂ = 𝕍(1.0, 0.0, 1.0, 0.0)
    u₃ = 𝕍(1.0, 0.0, 0.0, 1.0)
    for u in [u₁, u₂, u₃]
        v = 𝕍(vec(M * Quaternion(u.a)))
        @assert(isnull(v, atol = tolerance), "v ∈ 𝕍 in not a null vector, $v.")
        s = SpinVector(u) # TODO: visualize the spin-vectors as frames on S⁺
        s′ = SpinVector(v)
        β = Complex(im * a)
        α = 1.0
        ζ = α * s.ζ + β
        ζ′ = s′.ζ
        if ζ′ == Inf
            ζ = real(ζ)
        end
        @assert(isapprox(ζ, ζ′, atol = tolerance), "The transformation induced on Argand plane is not correct, $ζ != $ζ′.")
    end

    v₁ = 𝕍(normalize(ℝ⁴(1.0, 0.0, 0.0, 1.0)))
    v₂ = 𝕍(vec(M * Quaternion(vec(v₁))))
    @assert(isnull(v₁, atol = tolerance), "vector t + z in not null, $v₁.")
    @assert(isapprox(v₁, v₂, atol = tolerance), "The null vector t + z is not invariant under the null rotation, $v₁ != $v₂.")

    M
end


updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


animate(frame::Int) = begin
    progress = frame / frames_number
    stage = min(totalstages - 1, Int(floor(totalstages * progress))) + 1
    stageprogress = totalstages * (progress - (stage - 1) * 1.0 / totalstages)
    println("Frame: $frame, Stage: $stage, Total Stages: $totalstages, Progress: $stageprogress")
    if stage == 1
        M = compute_fourscrew(stageprogress, 1)
    elseif stage == 2
        M = compute_fourscrew(stageprogress, 2)
    elseif stage == 3
        M = compute_fourscrew(stageprogress, 3)
    elseif stage == 4
        M = compute_nullrotation(stageprogress)
    end
    update!(basemap1, q, gauge1, M)
    update!(basemap2, q, gauge2, M)
    update!(basemap3, q, gauge3, M)
    update!(basemap4, q, gauge4, M)
    for i in eachindex(whirls1)
        update!(whirls1[i], points[i], gauge1, gauge2, M)
        update!(whirls2[i], points[i], gauge2, gauge3, M)
        update!(whirls3[i], points[i], gauge3, gauge4, M)
        update!(whirls4[i], points[i], gauge4, gauge5, M)
    end
    updatecamera()
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end