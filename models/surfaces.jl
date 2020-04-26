using LinearAlgebra
using FileIO
using Makie


const TOLERANCE = 1e-7
N = 51
ϵ = 1e-7


"""
get_rotation_axis(i, n)

Calculates a unit quaternion corresponding to the axis of a 3D rotation with
the given initial and end unit vectors.
"""
function get_rotation_axis(i, n)
    u = normalize(cross(i, n))
    # The angle of rotation
    θ = acos(dot(i, n))
    u, θ/2
end


"""
build_surface(scene, points, color; transparency, shading)

Builds a surface with the given scene, points, color, transparency
and shading.
"""
function build_surface(
    scene,
    points,
    color;
    transparency = true,
    shading = false,
)
    surface!(
        scene,
        @lift($points[:, :, 1]),
        @lift($points[:, :, 2]),
        @lift($points[:, :, 3]),
        color = color,
        transparency = transparency,
        shading = shading,
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
    E = Matrix{Float64}(I, cols, cols) .* ϵ
    for (i, v) in enumerate(eachrow(A))
        P = repeat(v, 1, cols)
        P′ = P + E
        D[i, :] .= (f(transpose(P′)) - f(transpose(P))) ./ ϵ
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

lspace = range(-2, stop = 2, length = N)
points = f(lspace, lspace)

universe = surface(lspace,
                   lspace,
                   f(lspace, lspace),
                   colormap = :rainbow,
                   show_axis = false,
                   resolution = (360, 360),
                   backgroundcolor = :royalblue)
xm, ym, zm = minimum(scene_limits(universe))

slu, olu = textslider(-2.0:0.01:2.0, "u", start = -0.5)
slv, olv = textslider(-2.0:0.01:2.0, "v", start = -0.09)
slξ, olξ = textslider(0.0:0.01:2pi, "ξ", start = 0)

tangent_tail(x) =
    [Point3f0(x[i, 1], x[i, 2], f(x[i, 1], x[i, 2])) for i = 1:size(x, 1)]
tangent_head(x, f, ξ) = [
    Point3f0(
        ξ[1] * ϵ,
        ξ[2] * ϵ,
        f(x[i, 1] + ξ[1] * ϵ, x[i, 2] + ξ[2] * ϵ) - f(x[i, 1], x[i, 2]),
    ) ./ ϵ for i = 1:size(x, 1)
]
stiff_tail(x) = [Point3f0(x[i, 1], x[i, 2], zm) for i = 1:size(x, 1)]
stiff_head(x, f, ξ) = begin
    derivative = ξΦ(f, ξ, x)
    [
        Point3f0(derivative[i, 1], derivative[i, 2], 0)
        for i = 1:size(x, 1)
    ]
end
normal(x, f) = begin
    tx = tangent_head(x, f, [1; 0])
    ty = tangent_head(x, f, [0; 1])
    [normalize(cross(tx[i], ty[i])) for i = 1:size(x, 1)]
end
plane(x, f, ξ) = begin
    t = tangent_tail(x)
    tx = tangent_head(x, f, [ξ[1]*0.1+1; 0])
    ty = tangent_head(x, f, [0; ξ[2]*0.1+1])
    surf(i) = begin
        p = Array{Float64}(undef, 2, 2, 3)
        p[1, 1, :] = normalize(tx[i] + ty[i] .+ 1e-5 * rand()) + t[i]
        p[1, 2, :] = normalize(-tx[i] + ty[i] .+ 1e-5 * rand()) + t[i]
        p[2, 1, :] = normalize(tx[i] - ty[i] .+ 1e-5 * rand()) + t[i]
        p[2, 2, :] = normalize(-tx[i] - ty[i] .+ 1e-5 * rand()) + t[i]
        p
    end
    [surf(i) for i = 1:size(x, 1)]
end
number = 1
P = @lift([$olu $olv])
tangent_arrowtail = @lift(tangent_tail($P))
tangent_arrowhead = @lift(tangent_head($P, f, [cos($olξ); sin($olξ)]))
yconst_tangent_arrowhead = @lift(tangent_head($P, f, [cos($olξ); 0]))
xconst_tangent_arrowhead = @lift(tangent_head($P, f, [0; sin($olξ)]))
normal_arrowhead = @lift(normal($P, f))
stiff_arrowtail = @lift(stiff_tail($P))
ξarrowhead = @lift(stiff_head($P, f, [cos($olξ); sin($olξ)]))
yconst_stiff_arrowhead = @lift(stiff_head($P, f, [cos($olξ); 0]))
xconst_stiff_arrowhead = @lift(stiff_head($P, f, [0; sin($olξ)]))

arrowmesh = load("data/boquarrow.obj")
arrow = mesh!(universe, arrowmesh, color = :gold)[end]
scale!(arrow, 0.02, 0.02, 0.02)
on(olu) do val
    i = [0; 1; 0]
    n = normalize(to_value(normal_arrowhead)[1])
    u, θ = get_rotation_axis(i, n)
    rotate!(arrow, Quaternionf0((sin(θ).*u)..., cos(θ)))
    x = to_value(olu)
    y = to_value(olv)
    z = f(x, y)
    translate!(arrow, Vec3f0(x, y, z))
end

on(olv) do val
    i = [0; 1; 0]
    n = normalize(to_value(normal_arrowhead)[1])
    u, θ = get_rotation_axis(i, n)
    #rotate!(arrow, Vec3f0(u...), θ)
    rotate!(arrow, Quaternionf0((sin(θ).*u)..., cos(θ)))
    x = to_value(olu)
    y = to_value(olv)
    z = f(x, y)
    translate!(arrow, Vec3f0(x, y, z))
end

# Instantiate a horizontal box for holding the visuals and the controls
#box = vbox(slu, slv, slξ)
#scene = hbox(universe, box, parent = Scene(resolution = (1920, 1080)))
contour!(
    universe,
    lspace,
    lspace,
    f(lspace, lspace),
    levels = 15,
    linewidth = 2,
    transformation = (:xy, zm),
    colormap = :cinferno,
)
wireframe!(
    universe,
    lspace,
    lspace,
    f(lspace, lspace),
    overdraw = true,
    transparency = true,
    color = (:black, 0.1),
)
image = load("gallery/porta.jpg")
for i in 1:number
    build_surface(universe,
                  @lift(plane($P, f, [cos($olξ); sin($olξ)])[i]),
                  image)
end
arrows!(
    universe,
    tangent_arrowtail,
    tangent_arrowhead,
    arrowsize = 0.1,
    linecolor = (:white, 2.0),
    linewidth = 3,
)
arrows!(
    universe,
    tangent_arrowtail,
    xconst_tangent_arrowhead,
    arrowsize = 0.1,
    linecolor = (:red, 2.0),
    linewidth = 3,
)
arrows!(
    universe,
    tangent_arrowtail,
    yconst_tangent_arrowhead,
    arrowsize = 0.1,
    linecolor = (:green, 2.0),
    linewidth = 3,
)

arrows!(
    universe,
    stiff_arrowtail,
    ξarrowhead,
    arrowsize = 0.1,
    linecolor = (:white, 2.0),
    linewidth = 3,
)
arrows!(
    universe,
    stiff_arrowtail,
    xconst_stiff_arrowhead,
    arrowsize = 0.1,
    linecolor = (:red, 2.0),
    linewidth = 3
)
arrows!(
    universe,
    stiff_arrowtail,
    yconst_stiff_arrowhead,
    arrowsize = 0.1,
    linecolor = (:green, 2.0),
    linewidth = 3,
)
center!(universe) # center the Scene on the display
# update eye position
eye_position, lookat = Vec3f0(3, 3, 3), Vec3f0(0)
update_cam!(universe, eye_position, lookat)
universe.center = false # prevent scene from recentering on display
#Makie.save("gallery/surfaces.jpg", scene)
display(universe)

record(universe, "gallery/surfaces.gif") do io
    frames = 90
    for i = 1:frames
        progress = i / frames
        olu[] = cos(progress * 2pi + pi/2)
        olv[] = sin(progress * 2pi + pi/2)
        olξ[] = progress * 2pi # animate scene
        eye_position = Vec3f0(1 - sin(progress * 2pi),
                              1 - sin(progress * 2pi),
                              1 + sin(progress * 2pi)) .* 3 .+ 0.00001
        update_cam!(universe, eye_position, to_value(tangent_arrowtail)[1])
        recordframe!(io) # record a new frame
    end
end
