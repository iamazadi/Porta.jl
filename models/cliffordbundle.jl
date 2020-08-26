import Observables
import AbstractPlotting
import GLMakie
using Porta


plane = ComplexPlane(Quaternion(rand(), ℝ³(rand(3)))) # Construct a unit Quaternion
w, z = plane.z₁, plane.z₂
B = Complex(10rand(), 10rand())
clifford = Clifford(w, z, B)


center = ℝ³(0, 0, 0)
q = Biquaternion(center)
radius = 1.0
scene = AbstractPlotting.Scene(center = false, show_axis = false)
segments = 36
color = AbstractPlotting.RGBAf0(0.9, 0.9, 0.9, 0.3)
transparency = false
sphere = Sphere(q,
                scene,
                radius = radius,
                segments = segments,
                color = color,
                transparency = transparency)


center = ℝ³(Cartesian(clifford.base))
q = Biquaternion(center)
radius = 0.05
color = AbstractPlotting.RGBAf0(0.1, 0.1, 0.1, 0.7)
transparency = false
point = Sphere(q,
               scene,
               radius = radius,
               segments = segments,
               color = color,
               transparency = transparency)


tail, head = ℝ³(0, 0, 0), ℝ³(1, 0, 0)
width = 3
color = :gold
arrow = Arrow(tail,
              head,
              scene,
              width = width,
              color = color)

lspaceα = range(float(0), stop = float(pi / 2), length = 100)
lspaceϕ₁ = range(float(0), stop = float(2pi), length = 100)
lspaceϕ₂ = range(float(0), stop = float(4pi), length = 100)
sliderα, valα = AbstractPlotting.textslider(lspaceα, "α", start = 0)
sliderϕ₁, valϕ₁ = AbstractPlotting.textslider(lspaceϕ₁, "ϕ₁", start = 0)
sliderϕ₂, valϕ₂ = AbstractPlotting.textslider(lspaceϕ₂, "ϕ₂", start = 0)
sliders = [sliderα, sliderϕ₁, sliderϕ₂]

for slider in sliders
    Observables.on(slider[end].value) do x
        α = Observables.to_value(valα)
        ϕ₁ = Observables.to_value(valϕ₁)
        ϕ₂ = Observables.to_value(valϕ₂)
        q = Quaternion(cos((ϕ₁ + ϕ₂) / 2) * sin(α),
                       sin((ϕ₁ + ϕ₂) / 2) * sin(α),
                       cos((ϕ₂ - ϕ₁) / 2) * cos(α),
                       sin((ϕ₂ - ϕ₁) / 2) * cos(α))
        u, v, x, y = vec(q)
        cp = ComplexPlane(q)
        w, z = cp.z₁, cp.z₂
        B = w / z
        global clifford = Clifford(w, z, B)
        bq = Biquaternion(q, ℝ³(Cartesian(ComplexLine(B))))
        update(point, bq)
        tail = gettranslation(bq)
        head = ℝ³(4(x * y - u * v), 2 - 4(v^2 + y^2), -4(v * x + u * y))
        update(arrow, tail, head)
    end
end


parentscene = AbstractPlotting.Scene(resolution = (800, 600))
leftpanel = AbstractPlotting.hbox(sliders...)
AbstractPlotting.vbox(leftpanel,
                      scene,
                      parent = parentscene)
