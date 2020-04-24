using LinearAlgebra
using Makie


f(x,y) = (-x .* exp.(-x .^ 2 .- (y') .^ 2)) .* 4
#Φ(p) = f(p[1], p[2])
#struct dΦ
#    u::Float64
#    v::Float64
#end
#struct ξ
#    a::Float64
#    b::Float64
#end
#vect(dΦ) = [dΦ.u; dΦ.v]
#vect(ξ) = [ξ.a; ξ.b]
#dΦ(p::Array{Float64,1}) = dΦ((Φ([p[1] + ϵ, p[2]]) - Φ(p)) / ϵ,
#                             (Φ([p[1], p[2] + ϵ]) - Φ(p)) / ϵ)
#ξ(Φ, p) = vect(dΦ(p)) * vect(ξ(p))

∂(i, p, ϵ) = begin
    p′ = similar(p)
    p′ .= p
    p′[i] = p[i] + ϵ
    (f(p′[1], p′[2]) - f(p[1], p[2])) / ϵ
end

N = 51
lspace = range(-2, stop = 2, length = N)
universe = surface(lspace, lspace, f(lspace, lspace), colormap = :cinferno)
xm, ym, zm = minimum(scene_limits(universe))

slϵ, olϵ = textslider(0.0001:0.01:1.0, "ϵ", start = 0.0001)
slx, olx = textslider(-2.0:0.01:2.0, "x", start = 0.5)
sly, oly = textslider(-2.0:0.01:2.0, "y", start = 0.5)
slθ, olθ = textslider(0.0:0.01:pi/2, "θ", start = pi/4)
p(x, y) = [x y]
ξ(x) = [cos(x) sin(x)]
tail(x) = Point3f0(x[1], x[2], zm)
head(p, ξ, ϵ) = Point3f0(ξ[1] * ∂(1, p, ϵ), ξ[2] * ∂(2, p, ϵ), 0)
arrowtail = @lift([tail(p($olx, $oly))])
arrowhead = @lift([head(p($olx, $oly), ξ($olθ), $olϵ)])

# Instantiate a horizontal box for holding the visuals and the controls
box = vbox(slϵ, slx, sly, slθ)
scene = hbox(universe, box, parent = Scene(resolution = (360, 360)))
contour!(universe,
         lspace,
         lspace,
         f(lspace, lspace),
         levels = 15,
         linewidth = 2,
         transformation = (:xy, zm),
         colormap = :cinferno)
wireframe!(universe,
           lspace,
           lspace,
           f(lspace, lspace),
           overdraw = true,
           transparency = true,
           color = (:black, 0.1))
arrows!(universe,
        arrowtail,
        arrowhead,
        arrowsize = 0.1,
        linecolor = (:black, 2.0),
        linewidth = 3)
center!(universe) # center the Scene on the display
Makie.save("gallery/surfaces.jpg", scene)
display(scene)
