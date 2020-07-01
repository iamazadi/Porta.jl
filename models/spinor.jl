using Makie
using Porta


const segments = 30
const radius = 1.0
const center = [0.0; 0.0; 0.0]
const pradius = 0.05
const color = [1.0; 0.0; 0.0; 1.0]


Φ(p) = Geographic(Cartesian(p)).a
Φ⁻¹(p) = Cartesian(Geographic(p)).a


getS²surface(center, radius, segments, rgba) = begin
    lspace = [i for i in range(0; stop = 2pi, length = segments)]
    points = Cartesian.([Spherical([radius; ϕ; θ / 2]) for ϕ in lspace, θ in lspace])
    color = fill(RGBAf0(rgba...), segments, segments)
    x = [p.a[1] for p in points] .+ center[1]
    y = [p.a[2] for p in points] .+ center[2]
    z = [p.a[3] for p in points] .+ center[3]
    x, y, z, color
end


x, y, z, c = getS²surface(center, radius, segments, [0.5; 0.5; 0.5; 0.5])


sϕ, oϕ = textslider(float(-pi):0.01:float(pi), "ϕ", start = 0)
sθ, oθ = textslider(-pi/2:0.01:pi/2, "θ", start = 0)
scene = Scene(center = false, show_axis = false)
surface!(scene, x, y, z, color = c, transparency = true)
p = @lift(Φ⁻¹([$oϕ; $oθ]))
surfacepointscolor = @lift(getS²surface($p, pradius, Int(segments ÷ 3), color))
surfacex = @lift($surfacepointscolor[1])
surfacey = @lift($surfacepointscolor[2])
surfacez = @lift($surfacepointscolor[3])
surfacec = @lift($surfacepointscolor[4])
surface!(scene, surfacex, surfacey, surfacez, color = surfacec)


sξ, oξ = textslider(0:0.01:2pi, "ξ", start = 0)
tail = @lift([Point3f0($p)])
head = @lift begin
    covector = dΦ(Φ, $p)
    v = [cos($oξ); sin($oξ)]
    magnitude = dΦξ(Φ, v, $p)
    [Point3f0(Φ⁻¹(covector)) + $tail[1]]
end
arrows!(scene, tail, head, arrowsize = 0.1, linecolor = (:white, 2.0), linewidth = 3)


parent = Scene(resolution = (1000, 500))
vbox(hbox(sξ, sθ, sϕ), scene, parent = parent)
