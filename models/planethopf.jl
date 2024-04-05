import FileIO
import GLMakie
import LinearAlgebra
using Porta


figuresize = (1920, 1080)
segments = 120
frames_number = 1440
modelname = "planethopf"
indices = Dict()
q = Quaternion(ℝ⁴(0.0, 0.0, 1.0, 0.0))
chart = (-π / 4, π / 4, -π / 4, π / 4)
θ1 = 0.0
θ2 = π / 2
θ3 = float(π)
θ4 = 3π / 2
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
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

makefigure() = GLMakie.Figure(size = figuresize)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(0.0862, 0.0862, 0.0862))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

reference = FileIO.load("data/basemap_color.png")
mask = FileIO.load("data/basemap_mask.png")
basemap1 = Basemap(lscene, q, x -> x, chart, segments, mask, transparency = true)
basemap2 = Basemap(lscene, q, x -> x, chart, segments, mask, transparency = true)
basemap3 = Basemap(lscene, q, x -> x, chart, segments, mask, transparency = true)
basemap4 = Basemap(lscene, q, x -> x, chart, segments, mask, transparency = true)

whirls1 = []
whirls2 = []
whirls3 = []
whirls4 = []
for i in eachindex(boundary_nodes)
    color1 = getcolor(boundary_nodes[i], reference, 0.1)
    color2 = getcolor(boundary_nodes[i], reference, 0.2)
    color3 = getcolor(boundary_nodes[i], reference, 0.3)
    color4 = getcolor(boundary_nodes[i], reference, 0.4)
    w = [σmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])]
    whirl1 = Whirl(lscene, w, θ1, θ2, x -> x, segments, color1, transparency = true)
    whirl2 = Whirl(lscene, w, θ2, θ3, x -> x, segments, color2, transparency = true)
    whirl3 = Whirl(lscene, w, θ3, θ4, x -> x, segments, color3, transparency = true)
    whirl4 = Whirl(lscene, w, θ4, 2π, x -> x, segments, color4, transparency = true)
    push!(whirls1, whirl1)
    push!(whirls2, whirl2)
    push!(whirls3, whirl3)
    push!(whirls4, whirl4)
end


function animate_fourscrew(progress::Float64, status::Int)
    if status == 1 # roation
        w = 1.0
        ϕ = log(w) # rapidity
        ψ = progress * 2π
    end
    if status == 2 # boost
        w = abs(cos(progress * 2π))
        ϕ = log(w) # rapidity
        ψ = 0.0
    end
    if status == 3 # four-screw
        w = abs(cos(progress * 2π))
        ϕ = log(w) # rapidity
        ψ = progress * 2π
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

    u₁ = 𝕍(1.0, 1.0, 0.0, 0.0)
    u₂ = 𝕍(1.0, 0.0, 1.0, 0.0)
    u₃ = 𝕍(1.0, 0.0, 0.0, 1.0)
    for u in [u₁, u₂, u₃, -u₁, -u₂, -u₃]
        v = 𝕍(vec(f′(Quaternion(u.a))))
        @assert(isnull(v), "v ∈ 𝕍 in not null, $v.")
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
        @assert(isapprox(ζ, ζ′, atol = 1e-7), "The transformation induced on Argand plane is not correct, $ζ != $ζ′.")
    end
   
    γ = progress * 4π
    update!(basemap1, q, x -> f′(exp(K(3) * (γ + θ1)) * x))
    update!(basemap2, q, x -> f′(exp(K(3) * (γ + θ2)) * x))
    update!(basemap3, q, x -> f′(exp(K(3) * (γ + θ3)) * x))
    update!(basemap4, q, x -> f′(exp(K(3) * (γ + θ4)) * x))
    for i in eachindex(boundary_nodes)
        points = Quaternion[]
        for node in boundary_nodes[i]
            r, θ, ϕ = convert_to_geographic(node)
            push!(points, exp(ϕ / 4 * K(1) + θ / 2 * K(2)) * q)
        end
        update!(whirls1[i], points, θ1 + γ, θ2 + γ, f′)
        update!(whirls2[i], points, θ2 + γ, θ3 + γ, f′)
        update!(whirls3[i], points, θ3 + γ, θ4 + γ, f′)
        update!(whirls4[i], points, θ4 + γ, 2π + γ, f′)
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
        Quaternion(T̃, X̃, Ỹ, Z̃)
    end

    u₁ = 𝕍(1.0, 1.0, 0.0, 0.0)
    u₂ = 𝕍(1.0, 0.0, 1.0, 0.0)
    u₃ = 𝕍(1.0, 0.0, 0.0, 1.0)
    for u in [u₁, u₂, u₃, -u₁, -u₂, -u₃]
        v = 𝕍(vec(f(Quaternion(u.a))))
        @assert(isnull(v), "v ∈ 𝕍 in not null, $v.")
        s = SpinVector(u) # TODO: visualize the spin-vectors as frames on S⁺
        s′ = SpinVector(v)
        β = Complex(im * a)
        α = 1.0
        ζ = α * s.ζ + β
        ζ′ = s′.ζ
        if ζ′ == Inf
            ζ = real(ζ)
        end
        @assert(isapprox(ζ, ζ′, atol = 1e-7), "The transformation induced on Argand plane is not correct, $ζ != $ζ′.")
    end

    v₁ = 𝕍(normalize(ℝ⁴(1.0, 0.0, 0.0, 1.0)))
    v₂ = 𝕍(vec(f(Quaternion(vec(v₁)))))
    @assert(isnull(v₁), "vector t + z in not null, $v₁.")
    @assert(isapprox(v₁, v₂), "The null vector t + z is not invariant under the null rotation, $v₁ != $v₂.")

    γ = progress * 4π
    update!(basemap1, q, x -> f(exp(K(3) * (γ + θ1)) * x))
    update!(basemap2, q, x -> f(exp(K(3) * (γ + θ2)) * x))
    update!(basemap3, q, x -> f(exp(K(3) * (γ + θ3)) * x))
    update!(basemap4, q, x -> f(exp(K(3) * (γ + θ4)) * x))
    for i in eachindex(boundary_nodes)
        points = Quaternion[]
        for node in boundary_nodes[i]
            r, θ, ϕ = convert_to_geographic(node)
            push!(points, exp(ϕ / 4 * K(1) + θ / 2 * K(2)) * q)
        end
        update!(whirls1[i], points, θ1 + γ, θ2 + γ, f)
        update!(whirls2[i], points, θ2 + γ, θ3 + γ, f)
        update!(whirls3[i], points, θ3 + γ, θ4 + γ, f)
        update!(whirls4[i], points, θ4 + γ, 2π + γ, f)
    end
end


updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


write(frame::Int) = begin
    progress = frame / frames_number
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