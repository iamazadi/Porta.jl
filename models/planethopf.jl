import FileIO
import DataFrames
import CSV
import GLMakie
using Porta


figuresize = (1080, 1920)
segments = 30
basemapsegments = 30
modelname = "planethopf"
boundary_names = ["United States of America", "Australia", "Iran", "Canda", "Mexico", "Chile", "Brazil", "Turkey", "Pakistan", "India", "Russia", "China", "Antarctica"]
frames_number = 720 # 360 * length(boundary_names)
indices = Dict()
ratio = 0.999
x̂ = ℝ³(1.0, 0.0, 0.0)
ŷ = ℝ³(0.0, 1.0, 0.0)
ẑ = ℝ³(0.0, 0.0, 1.0)
arrowsize = GLMakie.Vec3f(0.02, 0.02, 0.04)
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(1.0, 0.0, 0.0))

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask.png")
## Load the Natural Earth data
attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"
countries = loadcountries(attributespath, nodespath)
boundary_nodes = Vector{Vector{ℝ³}}()
for i in eachindex(countries["name"])
    for name in boundary_names
        if countries["name"][i] == name
            push!(boundary_nodes, countries["nodes"][i])
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
chart = (-π / 4, π / 4, -π / 4, π / 4)
basemap1 = Basemap(lscene, q, chart, basemapsegments, basemap_color, transparency = true)
basemap2 = Basemap(lscene, q, chart, basemapsegments, basemap_color, transparency = true)

whirls = []
_whirls = []
for i in eachindex(boundary_nodes)
    color = getcolor(boundary_nodes[i], colorref, 0.5)
    _color = getcolor(boundary_nodes[i], colorref, 0.1)
    w = [σmap(boundary_nodes[i][j]) for j in eachindex(boundary_nodes[i])]
    whirl = Whirl(lscene, w, 0.0, θ1, segments, color, transparency = true)
    _whirl = Whirl(lscene, w, θ1, 2π, segments, _color, transparency = true)
    push!(whirls, whirl)
    push!(_whirls, _whirl)
end


function animate(progress::Float64)
    w = abs(sin(progress * 2π))
    ϕ = log(w) # rapidity
    ψ = progress * 2π
    # α = exp(im * ψ / 2.0)
    # β = Complex(0.0)
    # γ = Complex(0.0)
    # δ = exp(-im * ψ / 2.0)
    # transform = SpinTransformation(α, β, γ, δ)
    # q = transform * SpinVector(θ , ϕ, timesign)
    # timesign = 1
    # s = SpinVector(ℝ³(0.0, 1.0, 0.0), timesign)
    # X, Y, Z = vec(s.cartesian)
    # T = float(timesign)
    # ζ = w * exp(im * ψ) * s.ζ
    # s′ = SpinVector(ζ, timesign)
    # q = Quaternion(s′)
    # X̃, Ỹ, Z̃ = vec(s′.cartesian)
    # T̃ = float(timesign)
    # atol = 1e-2
    # @assert(isapprox(X̃, X * cos(ψ) - Y * sin(ψ), atol = atol), "The X̃ value is not correct, $X != $(X̃).")
    # @assert(isapprox(Ỹ, X * sin(ψ) + Y * cos(ψ), atol = atol), "The Ỹ value is not correct, $Y != $(Ỹ).")
    # @assert(isapprox(Z̃, Z * cosh(ϕ) + T * sinh(ϕ), atol = atol), "The Z̃ value is not correct, $Z != $(Z̃).")
    # @assert(isapprox(T̃, Z * sinh(ϕ) + T * cosh(ϕ), atol = atol), "The T̃ value is not correct, $T != $(T̃).")
    X, Y, Z = vec(ℝ³(0.0, 1.0, 0.0))
    T = 1.0
    X̃ = X * cos(ψ) - Y * sin(ψ)
    Ỹ = X * sin(ψ) + Y * cos(ψ)
    Z̃ = Z * cosh(ϕ) + T * sinh(ϕ)
    T̃ = Z * sinh(ϕ) + T * cosh(ϕ)
    q = normalize(Quaternion(T̃, X̃, Ỹ, Z̃))
    update!(basemap1, q)
    update!(basemap2, G(θ1, q))
    # update!(basemap1, chart)
    # update!(basemap2, chart)
    for i in eachindex(boundary_nodes)
        points = Quaternion[]
        for node in boundary_nodes[i]
            r, θ, ϕ = convert_to_geographic(node)
            push!(points, exp(ϕ / 4 * K(1) + θ / 2 * K(2)) * q)
        end
        update!(whirls[i], points, θ1, 2π)
        update!(_whirls[i], points, 0.0, θ1)
    end
end

updatecamera() = begin
    GLMakie.update_cam!(lscene.scene, GLMakie.Vec3f(vec(eyeposition)...), GLMakie.Vec3f(vec(lookat)...), GLMakie.Vec3f(vec(up)...))
end


write(frame::Int) = begin
    progress = frame / frames_number
    println("Frame: $frame, Progress: $progress")
    animate(progress)
    updatecamera()
end


write(1)


GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    write(frame)
end