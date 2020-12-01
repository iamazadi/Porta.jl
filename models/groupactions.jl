import GeometryBasics
import Observables
import GLMakie
import AbstractPlotting

using Porta

# This model is inspired by exercise 3.12.3 from Mark J.D. Hamilton (2017)
# The best description at the moment is: the orbit of SU(2)×U(1) acting on the vacuum vector
# of the Higgs field


×(a::SU2, b::U1) = SU2(b.z .* a.a)
gaction(A::SU2, u::U1, v::ComplexPlane) = ComplexPlane((A × u).a * vec(v))

orbit(α::Float64, v₀::Float64, segments::Int) = begin
    array = Array{ℝ³,2}(undef, segments, segments)
    colors = Array{ℝ³,2}(undef, segments, segments)
    θlspace = range(-π/2, stop = π/2, length = segments)
    ϕlspace = range(-π, stop = π, length = segments)
    τ₁ = SU2([0im -im/2; -im/2 0im])
    τ₂ = SU2([0im -1/2; 1/2 0im])
    τ₃ = SU2([-im/2 0im; 0im im/2])
    p = ComplexPlane([0im; v₀ + 0im])
    q = Quaternion(p)
    u1 = U1(α)
    for (i, ϕ) in enumerate(ϕlspace)
        for (j, θ) in enumerate(θlspace)
            u = ℝ³(Cartesian(Geographic(1.0, ϕ, θ)))
            u₁, u₂, u₃ = vec(u)
            A = u₁ * τ₁ + u₂ * τ₂ + u₃ * τ₃
            p′ = gaction(A, u1, p)
            q′ = Quaternion(p′)
            normalized = normalize(q′)
            r3 = compressedλmap(normalized)
            scale = norm(q′)
            array[i, j] = r3 * scale * sign(v₀)
            hue = acos(dot(normalize(q), normalized)) / π * 360
            colors[i, j] = ℝ³(hsvtorgb([hue; 1.0; 1.0]))
        end
    end
    array, colors
end

interactive = false
segments = 60
frames = 240

scene3d = AbstractPlotting.Scene(camera = AbstractPlotting.cam3d_cad!)

v₀linspace = AbstractPlotting.LinRange(-1, 1, 100)
αlinsapce = AbstractPlotting.LinRange(-π, π, 100)
v₀slider, v₀observable = AbstractPlotting.textslider(v₀linspace, "v₀", raw = true,
                                                     camera = AbstractPlotting.campixel!,
                                                     start = 1)
αslider, αobservable = AbstractPlotting.textslider(αlinsapce, "α", raw = true,
                                                   camera = AbstractPlotting.campixel!,
                                                   start = 0)
transparency = true
α = π / 4
v₀ = 1.0
p = ComplexPlane([0im; v₀ + 0im])
r3 = compressedλmap(p)
config = Biquaternion(r3)
radius = 0.05
color = AbstractPlotting.RGBAf0(1.0, 0.2705, 0.0, 0.5)
sprite = sphere = Sphere(config, scene3d, radius = radius, segments = segments,
                         color = color, transparency = transparency)
array, colors = orbit(α, v₀, segments)
colorarray = Observables.Observable(map(x -> AbstractPlotting.RGBAf0(vec(x)..., 0.9),
                                        colors))
#color = AbstractPlotting.RGBAf0(1.0, 0.2705, 0.0, 0.5)
#colorarray = Observables.Observable(fill(color, segments, segments))
observable = buildsurface(scene3d, array, colorarray, transparency = transparency)

Observables.on(v₀observable) do x
    α = Observables.to_value(αobservable)
    v₀ = Observables.to_value(v₀observable)
    array, colors = orbit(α, v₀, segments)
    updatesurface(array, observable)
    colorarray[] = map(x -> AbstractPlotting.RGBAf0(vec(x)..., 0.9), colors)
    p = ComplexPlane([0im; v₀ + 0im])
    r3 = compressedλmap(p)
    config = Biquaternion(r3)
    update(sprite, config)
    q = normalize(Quaternion(p))
    hue = acos(dot(q, Quaternion(0, 0, 0, 1))) / π * 360
    color = AbstractPlotting.RGBAf0(hsvtorgb([hue; 1.0; 1.0])..., 0.5)
    update(sprite, color)
end

Observables.on(αobservable) do x
    α = Observables.to_value(αobservable)
    v₀ = Observables.to_value(v₀observable)
    array, colors = orbit(α, v₀, segments)
    updatesurface(array, observable)
    colorarray[] = map(x -> AbstractPlotting.RGBAf0(vec(x)..., 0.9), colors)
    p = ComplexPlane([0im; v₀ + 0im])
    r3 = compressedλmap(p)
    config = Biquaternion(r3)
    update(sprite, config)
    q = normalize(Quaternion(p))
    hue = acos(dot(q, Quaternion(0, 0, 0, 1))) / π * 360
    color = AbstractPlotting.RGBAf0(hsvtorgb([hue; 1.0; 1.0])..., 0.5)
    update(sprite, color)
end

final = AbstractPlotting.hbox(scene3d, AbstractPlotting.vbox(αslider, v₀slider),
                              parent = AbstractPlotting.Scene(resolution = (500, 500)))

n = ℝ³(0, 0, 1)
v = ℝ³(1, 1, 0.1) * 2
# update eye position
# scene.camera.eyeposition.val
upvector = GeometryBasics.Vec3f0(vec(n)...)
eyeposition = GeometryBasics.Vec3f0(vec(v)...)
lookat = GeometryBasics.Vec3f0(0, 0, 0)
AbstractPlotting.update_cam!(scene3d, eyeposition, lookat, upvector)
scene3d.center = false # prevent scene from recentering on display

animate(i) = begin
    t = (i - 1) / frames
    if i < frames / 2
        t = 2t
        α = t * 2π - π
        αobservable[] = α
        rangeindex = max(1, Int(100(α + π) ÷ 2pi))
        rangeindex = min(100, rangeindex)
        AbstractPlotting.move!(αslider[end], rangeindex)
    else
        t = 2(t - 0.5)
        v₀ = 2(t - 0.5)
        v₀observable[] = v₀
        rangeindex = max(1, Int(100(v₀ + 1) ÷ 2))
        rangeindex = min(100, rangeindex)
        AbstractPlotting.move!(v₀slider[end], rangeindex)
    end
end


if interactive
    path = joinpath("gallery", "interactions", "groupactions.mp4")
    AbstractPlotting.record(final, path; framerate = 30) do io
        for i = 1:900        # sampling time
            sleep(0.05)       # sampling rate
            AbstractPlotting.recordframe!(io) # record a new frame
        end
    end
else
    path = joinpath("gallery", "groupactions.gif")
    AbstractPlotting.record(final, path) do io
        for i in 1:frames
            animate(i) # animate the scene
            AbstractPlotting.recordframe!(io) # record a new frame
        end
    end
end
