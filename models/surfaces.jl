using Makie

ϵ = Node(1e-2)
N = 51
lspace = range(-2, stop = 2, length = N)
f(x,y) = (-x .* exp.(-x .^ 2 .- (y') .^ 2)) .* 4
Φ(p) = f(p[1], p[2])
struct dΦ
    u::Float64
    v::Float64
end
struct ξ
    a::Float64
    b::Float64
end
vect(dΦ) = [dΦ.u; dΦ.v]
vect(ξ) = [ξ.a; ξ.b]
dΦ(p::Array{Float64,1}) = dΦ((Φ([p[1] + ϵ, p[2]]) - Φ(p)) / ϵ,
                             (Φ([p[1], p[2] + ϵ]) - Φ(p)) / ϵ)
ξ(Φ, p) = vect(dΦ(p)) * vect(ξ(p))

universe = surface(lspace, lspace, f(lspace, lspace), colormap = :cinferno)
xm, ym, zm = minimum(scene_limits(universe))

p = Point2f0(-0.5, 0.5)

sl, ol = textslider(0.001:0.01:1.0, "ϵ", start = 0.01)
p′ = @lift([Point2f0(p[1] + $ol, p[2])])

arrowstart = Point3f0(p[1], p[2], f(p[1], p[2]))
arrowend = @lift([Point3f0($p′[1][1], $p′[1][2], f($p′[1][1], $p′[1][2]))-Point3f0(p[1], p[2], f(p[1], p[2]))])

contourarrowstart = Point3f0(p[1], p[2], -2)
contourarrowend = @lift([Point3f0($p′[1][1], $p′[1][2], -2)-Point3f0(p[1], p[2], -2)])

# Instantiate a horizontal box for holding the visuals and the controls
scene = hbox(universe, vbox(sl), parent = Scene(resolution = (360, 360)))
contour!(universe, lspace, lspace, f(lspace, lspace), levels = 15, linewidth = 2, transformation = (:xy, zm), colormap = :cinferno)
wireframe!(universe, lspace, lspace, f(lspace, lspace), overdraw = true, transparency = true, color = (:black, 0.1))
arrows!(universe, [arrowstart], arrowend, arrowsize = 0.1, linecolor = (:white, 1.0), linewidth = 5)
arrows!(universe, [contourarrowstart], contourarrowend, arrowsize = 0.1, linecolor = (:white, 1.0), linewidth = 5)
center!(universe) # center the Scene on the display
Makie.save("gallery/surfaces.png", scene)
display(scene)
