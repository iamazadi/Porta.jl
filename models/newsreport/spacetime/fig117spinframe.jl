using FileIO
using GLMakie
import LinearAlgebra
using Porta


figuresize = (4096, 2160)
segments = 360
frames_number = 360
modelname = "fig117spinframe"
M = Identity(4)
x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
eyeposition = normalize(ℝ³(1.0, 1.0, 1.0)) * π
lookat = ℝ³(0.0, 0.0, 0.0)
up = normalize(ℝ³(0.0, 0.0, 1.0))
mask = load("data/basemap_mask.png")

makefigure() = Figure(size = figuresize)
fig = with_theme(makefigure, theme_black())
pl = PointLight(Point3f(0), RGBf(0.0862, 0.0862, 0.0862))
al = AmbientLight(RGBf(0.9, 0.9, 0.9))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], clear=true, backgroundcolor = :white))

timesign = -1
ο = SpinVector([Complex(1.0); Complex(0.0)], timesign)
ι = SpinVector([Complex(0.0); Complex(1.0)], timesign)
@assert(isapprox(dot(ο, ι), 1.0), "The inner product of spin vectors $ι and $ο is not unity.")
@assert(isapprox(dot(ι, ο), -1.0), "The inner product of spin vectors $ι and $ο is not unity.")

t = 𝕍( 1.0, 0.0, 0.0, 0.0)
x = 𝕍( 0.0, 1.0, 0.0, 0.0)
y = 𝕍( 0.0, 0.0, 1.0, 0.0)
z = 𝕍( 0.0, 0.0, 0.0, 1.0)

οv = 𝕍( LinearAlgebra.normalize(vec(𝕍(ο))))
ιv = 𝕍( LinearAlgebra.normalize(vec(𝕍(ι))))

generate() = 2rand() - 1 + im * (2rand() - 1)
κ = SpinVector(generate(), generate(), timesign)
@assert(isapprox(dot(κ, ι), vec(κ)[1]), "The first component of the spin vector $κ is not equal to the inner product of $κ and $ι.")
@assert(isapprox(dot(κ, ο), -vec(κ)[2]), "The second component of the spin vector $κ is not equal to minus the inner product of $κ and $ο.")

οflagpole = (1 / √2) * (t + z)
ιflagpole = (1 / √2) * (t - z)

@assert(isapprox(-οflagpole, οv), "the ο flagpole representation in Minkowski vector space mut be equal to -(t + z) / √2.")
@assert(isapprox(-ιflagpole, ιv), "the ι flagpole representation in Minkowski vector space mut be equal to -(t - z) / √2.")

arrowsize = Vec3f(0.06, 0.08, 0.1)
linewidth = 0.04
tail = Observable(Point3f(0.0, 0.0, 0.0))
thead = Observable(Point3f(vec(project(ℍ(vec(t))))...))
xhead = Observable(Point3f(vec(project(ℍ(vec(x))))...))
yhead = Observable(Point3f(vec(project(ℍ(vec(y))))...))
zhead = Observable(Point3f(vec(project(ℍ(vec(z))))...))
οhead = Observable(Point3f(vec(project(ℍ(vec(οv))))...))
ιhead = Observable(Point3f(vec(project(ℍ(vec(ιv))))...))
ps = @lift([$tail, $tail, $tail, $tail, $tail, $tail])
ns = @lift([$thead, $xhead, $yhead, $zhead, $οhead, $ιhead])
colorants = [:red, :blue, :green, :orange, :black, :silver]
arrows!(lscene,
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
    _οlinepoints = Observable(Point3f[])
    _ιlinepoints = Observable(Point3f[])
    _οlinecolors = Observable(Int[])
    _ιlinecolors = Observable(Int[])
    for (j, scale2) in enumerate(collection)
        οvector = LinearAlgebra.normalize(vec(scale1 * οv + scale2 * x))
        ιvector = LinearAlgebra.normalize(vec(scale1 * ιv + scale2 * -x))
        οpoint = Point3f(vec(project(ℍ(οvector)))...)
        ιpoint = Point3f(vec(project(ℍ(ιvector)))...)
        push!(_οlinepoints[], οpoint)
        push!(_ιlinepoints[], ιpoint)
        push!(_οlinecolors[], i + j)
        push!(_ιlinecolors[], 2segments + i + j)
    end
    push!(οlinepoints, _οlinepoints)
    push!(ιlinepoints, _ιlinepoints)
    push!(οlinecolors, _οlinecolors)
    push!(ιlinecolors, _ιlinecolors)
    οline = lines!(lscene, οlinepoints[i], color = οlinecolors[i], linewidth = linewidth, colorrange = (1, 4segments))
    ιline = lines!(lscene, ιlinepoints[i], color = ιlinecolors[i], linewidth = linewidth, colorrange = (1, 4segments))
    push!(οlines, οline)
    push!(ιlines, ιline)
end

titles = ["t", "x", "y", "z", "ο", "ι"]
rotation = gettextrotation(lscene)
text!(lscene,
    @lift(map(x -> Point3f(vec((isnan(x) ? ẑ : x))), [$thead, $xhead, $yhead, $zhead, $οhead, $ιhead])),
    text = titles,
    color = colorants,
    rotation = rotation,
    align = (:left, :baseline),
    fontsize = 0.25,
    markerspace = :data
)

spherematrix = makesphere(M, Float64(timesign), compressedprojection = true, segments = segments)
sphereobservable = buildsurface(lscene, spherematrix, mask, transparency = true)

οflagplanematrix = makeflagplane(οv, x, Float64(timesign), compressedprojection = true, segments = segments)
οflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.8), segments, segments))
οflagplaneobservable = buildsurface(lscene, οflagplanematrix, οflagplanecolor, transparency = true)
ιflagplanematrix = makeflagplane(ιv, -x, Float64(timesign), compressedprojection = true, segments = segments)
ιflagplanecolor = Observable(fill(RGBAf(0.5, 0.5, 0.5, 0.8), segments, segments))
ιflagplaneobservable = buildsurface(lscene, ιflagplanematrix, ιflagplanecolor, transparency = true)


animate(frame::Int) = begin
    progress = frame / frames_number
    println("Frame: $frame, Progress: $progress")
    M = compute_fourscrew(progress, 3) * compute_nullrotation(progress)
    ϵ = 1e-3
    t_transformed = M * ℍ(vec(t))
    x_transformed = M * ℍ(vec(x))
    y_transformed = M * ℍ(vec(y))
    z_transformed = M * ℍ(vec(z))
    οv_transformed = M * ℍ(vec(οv))
    ιv_transformed = M * ℍ(vec(ιv))
    ο′v_transformed = M * ℍ(vec(οv + ϵ * x))
    ι′v_transformed = M * ℍ(vec(ιv - ϵ * x))

    thead[] = Point3f(vec(project(t_transformed))...)
    xhead[] = Point3f(vec(project(x_transformed))...)
    yhead[] = Point3f(vec(project(y_transformed))...)
    zhead[] = Point3f(vec(project(z_transformed))...)
    οhead[] = Point3f(vec(project(οv_transformed))...)
    ιhead[] = Point3f(vec(project(ιv_transformed))...)

    οv_transformed = 𝕍( vec( οv_transformed))
    ιv_transformed = 𝕍( vec( ιv_transformed))
    ο′v_transformed = 𝕍( vec( ο′v_transformed))
    ι′v_transformed = 𝕍( vec( ι′v_transformed))

    for (i, scale1) in enumerate(collection)
        _οlinepoints = Point3f[]
        _ιlinepoints = Point3f[]
        _οlinecolors = Int[]
        _ιlinecolors = Int[]
        for (j, scale2) in enumerate(collection)
            οvector = normalize(ℍ(vec(scale1 * οv_transformed + scale2 * 𝕍(LinearAlgebra.normalize(vec(οv_transformed - ο′v_transformed))))))
            ιvector = normalize(ℍ(vec(scale1 * ιv_transformed + scale2 * 𝕍(LinearAlgebra.normalize(vec(ιv_transformed - ι′v_transformed))))))
            οpoint = Point3f(vec(project(οvector))...)
            ιpoint = Point3f(vec(project(ιvector))...)
            push!(_οlinepoints, οpoint)
            push!(_ιlinepoints, ιpoint)
            push!(_οlinecolors, i + j)
            push!(_ιlinecolors, 2segments + i + j)
        end
        οlinepoints[i][] = _οlinepoints
        ιlinepoints[i][] = _ιlinepoints
        οlinecolors[i][] = _οlinecolors
        ιlinecolors[i][] = _ιlinecolors
        notify(οlinepoints[i])
        notify(ιlinepoints[i])
        notify(οlinecolors[i])
        notify(ιlinecolors[i])
    end

    spherematrix = makesphere(M, Float64(timesign))
    updatesurface!(spherematrix, sphereobservable)

    οflagplanematrix = makeflagplane(οv_transformed, 𝕍(LinearAlgebra.normalize(vec(ο′v_transformed - οv_transformed))), Float64(timesign), compressedprojection = true, segments = segments)
    ιflagplanematrix = makeflagplane(ιv_transformed, 𝕍(LinearAlgebra.normalize(vec(ι′v_transformed - ιv_transformed))), Float64(timesign), compressedprojection = true, segments = segments)
    updatesurface!(οflagplanematrix, οflagplaneobservable)
    updatesurface!(ιflagplanematrix, ιflagplaneobservable)
    οflagplanecolor[] = fill(RGBAf(convert_hsvtorgb([progress * 360.0; 1.0; 1.0])..., 0.8), segments, segments)
    ιflagplanecolor[] = fill(RGBAf(convert_hsvtorgb([360.0 - (progress * 360.0); 1.0; 1.0])..., 0.8), segments, segments)

    updatecamera!(lscene, eyeposition, lookat, up)
end


animate(1)


record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    animate(frame)
end