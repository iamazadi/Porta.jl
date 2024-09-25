import FileIO
import GLMakie
import LinearAlgebra
using Porta


GLMakie.Quaternion(q::Porta.Quaternion) = GLMakie.Quaternion(vec(q)[2:4]..., vec(q)[1])


function makesphere(M::Matrix{Float64})
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    [project(M * Quaternion(0.0, vec(convert_to_cartesian([1.0; θ; ϕ]))...)) for θ in lspace2, ϕ in lspace1]
end


function makenullcone(M::Matrix{Float64}; timesign::Int = -1)
    lspace1 = range(-π, stop = float(π), length = segments)
    lspace2 = range(-π / 2, stop = π / 2, length = segments)
    [project(M * Quaternion(𝕍(SpinVector(convert_to_cartesian([1.0; θ; ϕ]), timesign)).a)) for θ in lspace2, ϕ in lspace1]
end


figuresize = (4096, 2160)
# figuresize = (1920, 1080)
segments = 30
frames_number = 1440
modelname = "scalarmultiplication"
indices = Dict()
T, X, Y, Z = vec(normalize(ℝ⁴(1.0, 0.0, 1.0, 0.0)))
u = 𝕍(T, X, Y, Z)
q = Quaternion(T, X, Y, Z)
tolerance = 1e-3
@assert(isnull(u, atol = tolerance), "u in not a null vector, $u.")
@assert(isapprox(norm(q), 1, atol = tolerance), "q in not a unit quaternion, $(norm(q)).")
origin = 𝕍(0.0, 0.0, 0.0, 0.0)
tetrad = Tetrad(ℝ⁴(1.0, 0.0, 0.0, 0.0), ℝ⁴(0.0, -1.0, 0.0, 0.0), ℝ⁴(0.0, 0.0, -1.0, 0.0), ℝ⁴(0.0, 0.0, 0.0, -1.0))
gauge1 = 0.0
gauge2 = π / 2
gauge3 = float(π)
gauge4 = 3π / 2
gauge5 = 2π
chart = (-π / 4, π / 4, -π / 4, π / 4)
M = I(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
totalstages = 4

## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_names = ["United States of America", "Iran", "China", "Chile", "South Africa", "New Zealand"]
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

timesign = -1
# timesign = rand([1; -1])
ο = SpinVector([Complex(1.0); Complex(0.0)], timesign)
ι = SpinVector([Complex(0.0); Complex(1.0)], timesign)
@assert(isapprox(dot(ο, ι), 1.0), "The inner product of spin vectors $ι and $ο is not unity.")
@assert(isapprox(dot(ι, ο), -1.0), "The inner product of spin vectors $ι and $ο is not unity.")

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
@assert(isapprox(dot(κ, ι), vec(κ)[1]), "The first component of the spin vector $κ is not equal to the inner product of $κ and $ι.")
@assert(isapprox(dot(κ, ο), -vec(κ)[2]), "The second component of the spin vector $κ is not equal to minus the inner product of $κ and $ο.")

t = 𝕍(1.0, 0.0, 0.0, 0.0)

x = 𝕍(0.0, 1.0, 0.0, 0.0)

y = 𝕍(0.0, 0.0, 1.0, 0.0)

z = 𝕍(0.0, 0.0, 0.0, 1.0)

οflagpole = √2 * (t + z)
ιflagpole = √2 * (t - z)

arrowsize = GLMakie.Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
tail = GLMakie.Observable(GLMakie.Point3f(0.0, 0.0, 0.0))
thead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(t))))...))
xhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(x))))...))
yhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(y))))...))
zhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(z))))...))
οhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(οflagpole))))...))
ιhead = GLMakie.Observable(GLMakie.Point3f(vec(project(Quaternion(vec(ιflagpole))))...))
ps = GLMakie.@lift([$tail, $tail, $tail, $tail, $tail, $tail])
ns = GLMakie.@lift([$thead, $xhead, $yhead, $zhead, $οhead, $ιhead])
colorants = [:red, :blue, :green, :orange, :black, :silver]
GLMakie.arrows!(lscene,
    ps, ns, fxaa = true, # turn on anti-aliasing
    color = colorants,
    linewidth = linewidth, arrowsize = arrowsize,
    align = :origin
)
linewidth = 20
collection = collect(range(0.0, stop = 1.0, length = segments))
οlinepoints = []
ιlinepoints = []
οlinecolors = []
ιlinecolors = []
οlines = []
ιlines = []
for (i, scale1) in enumerate(collection)
    _οlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _ιlinepoints = GLMakie.Observable(GLMakie.Point3f[])
    _οlinecolors = GLMakie.Observable(Int[])
    _ιlinecolors = GLMakie.Observable(Int[])
    for (j, scale2) in enumerate(collection)
        οvector = LinearAlgebra.normalize(vec(scale1 * οflagpole + scale2 * x))
        ιvector = LinearAlgebra.normalize(vec(scale1 * ιflagpole + scale2 * -x))
        οpoint = GLMakie.Point3f(vec(project(Quaternion(οvector)))...)
        ιpoint = GLMakie.Point3f(vec(project(Quaternion(ιvector)))...)
        push!(_οlinepoints[], οpoint)
        push!(_ιlinepoints[], ιpoint)
        push!(_οlinecolors[], i + j)
        push!(_ιlinecolors[], 2segments + i + j)
    end
    push!(οlinepoints, _οlinepoints)
    push!(ιlinepoints, _ιlinepoints)
    push!(οlinecolors, _οlinecolors)
    push!(ιlinecolors, _ιlinecolors)
    οline = GLMakie.lines!(lscene, οlinepoints[i], color = οlinecolors[i], linewidth = linewidth, colorrange = (1, 4segments))
    ιline = GLMakie.lines!(lscene, ιlinepoints[i], color = ιlinecolors[i], linewidth = linewidth, colorrange = (1, 4segments))
    push!(οlines, οline)
    push!(ιlines, ιline)
end

titles = ["t", "x", "y", "z", "ο", "ι"]
eyeposition_observable = lscene.scene.camera.eyeposition
lookat_observable = lscene.scene.camera.lookat
rotationaxis = GLMakie.@lift(normalize(ℝ³(Float64.([vec($eyeposition_observable)...] - [vec($lookat_observable)...])...)))
rotationangle = GLMakie.@lift(Float64(π / 2 + atan(($eyeposition_observable)[2], ($eyeposition_observable)[1])))
rotation1 = GLMakie.@lift(Porta.Quaternion(getrotation(ẑ, $rotationaxis)...))
rotation2 = GLMakie.@lift(Porta.Quaternion($rotationangle, $rotationaxis))
rotation = GLMakie.@lift(GLMakie.Quaternion($rotation2 * $rotation1))
GLMakie.text!(lscene,
    GLMakie.@lift(map(x -> GLMakie.Point3f(vec((isnan(x) ? ẑ : x))), [$thead, $xhead, $yhead, $zhead, $οhead, $ιhead])),
    text = titles,
    color = colorants,
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

spherematrix = makesphere(M)
spherecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.7, 0.7, 0.7, 0.3), segments, segments))
sphereobservable = buildsurface(lscene, spherematrix, spherecolor, transparency = true)

nullconematrix = makenullcone(M, timesign = timesign)
nullconecolor = GLMakie.Observable(fill(GLMakie.RGBAf(0.7, 0.7, 0.7, 0.3), segments, segments))
nullconeobservable = buildsurface(lscene, nullconematrix, nullconecolor, transparency = true)


function compute_fourscrew(progress::Float64, status::Int)
    if status == 1 # roation
        w = 1.0
        ϕ = log(w) # rapidity
        ψ = progress * 2π
    end
    if status == 2 # boost
        w = max(1e-4, abs(cos(progress * π)))
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
    # λ = LinearAlgebra.normalize(decomposition.values) # normalize eigenvalues for a unimodular transformation
    λ = decomposition.values
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
        if Complex(s) == Inf # A Float64 number (the point at infinity)
            ζ = Complex(s)
        else # A Complex number
            ζ = w * exp(im * ψ) * Complex(s)
        end
        ζ′ = Complex(s′)
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
        ζ = α * Complex(s) + β
        ζ′ = Complex(s′)
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
        M = compute_nullrotation(stageprogress)
    elseif stage == 2
        M = compute_fourscrew(stageprogress, 1)
    elseif stage == 3
        M = compute_fourscrew(stageprogress, 2)
    elseif stage == 4
        M = compute_fourscrew(stageprogress, 3)
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

    t_transformed = M * Quaternion(vec(t))
    x_transformed = M * Quaternion(vec(x))
    y_transformed = M * Quaternion(vec(y))
    z_transformed = M * Quaternion(vec(z))
    οflagpolez_transformed = M * Quaternion(vec(οflagpole))
    ιflagpole_transformed = M * Quaternion(vec(ιflagpole))


    thead[] = GLMakie.Point3f(vec(project(t_transformed))...)
    xhead[] = GLMakie.Point3f(vec(project(x_transformed))...)
    yhead[] = GLMakie.Point3f(vec(project(y_transformed))...)
    zhead[] = GLMakie.Point3f(vec(project(z_transformed))...)
    οhead[] = GLMakie.Point3f(vec(project(οflagpolez_transformed))...)
    ιhead[] = GLMakie.Point3f(vec(project(ιflagpole_transformed))...)

    οflagpolez_transformed = 𝕍(vec(οflagpolez_transformed))
    ιflagpole_transformed = 𝕍(vec(ιflagpole_transformed))

    for (i, scale1) in enumerate(collection)
        _οlinepoints = GLMakie.Point3f[]
        _ιlinepoints = GLMakie.Point3f[]
        _οlinecolors = Int[]
        _ιlinecolors = Int[]
        for (j, scale2) in enumerate(collection)
            οvector = normalize(Quaternion(vec(scale1 * οflagpolez_transformed + scale2 * 𝕍(vec(x_transformed)))))
            ιvector = normalize(Quaternion(vec(scale1 * ιflagpole_transformed + scale2 * 𝕍(vec(-x_transformed)))))
            οpoint = GLMakie.Point3f(vec(project(οvector))...)
            ιpoint = GLMakie.Point3f(vec(project(ιvector))...)
            push!(_οlinepoints, οpoint)
            push!(_ιlinepoints, ιpoint)
            push!(_οlinecolors, i + j)
            push!(_ιlinecolors, 2segments + i + j)
        end
        οlinepoints[i][] = _οlinepoints
        ιlinepoints[i][] = _ιlinepoints
        οlinecolors[i][] = _οlinecolors
        ιlinecolors[i][] = _ιlinecolors
        GLMakie.notify(οlinepoints[i])
        GLMakie.notify(ιlinepoints[i])
        GLMakie.notify(οlinecolors[i])
        GLMakie.notify(ιlinecolors[i])
    end

    spherematrix = makesphere(M)
    nullconematrix = makenullcone(M)
    updatesurface!(spherematrix, sphereobservable)
    updatesurface!(nullconematrix, nullconeobservable)
    hue = Float64(frame) / Float64(frames_number) * 360.0
    spherecolor[] = fill(GLMakie.RGBAf(convert_hsvtorgb([hue; 1.0; 1.0])..., 0.4), segments, segments)
    nullconecolor[] = fill(GLMakie.RGBAf(convert_hsvtorgb([360.0 - hue; 1.0; 1.0])..., 0.4), segments, segments)

    updatecamera()
end


animate(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end