using LinearAlgebra
using Makie

ϵ = 1e-1
f(x,y) = (-x .* exp.(-x .^ 2 .- (y') .^ 2)) .* 4
f(A) = begin
    x , y = eachcol(A)
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
θ = pi/4
ξ = [cos(θ); sin(θ)]
ξΦ(Φ, ξ, A) = begin
    derivative = d(Φ, A)
    D = similar(derivative)
    for (i, v) in enumerate(eachrow(derivative))
        D[i, :] .= v .* ξ
    end
    D
end

N = 51
lspace = range(-2, stop = 2, length = N)
points = f(lspace, lspace)

universe = surface(lspace,
                   lspace,
                   f(lspace, lspace),
                   colormap = :cinferno)
xm, ym, zm = minimum(scene_limits(universe))

slu, olu = textslider(-2.0:0.01:2.0, "u", start = -0.5)
slv, olv = textslider(-2.0:0.01:2.0, "v", start = -0.09)
slξ, olξ = textslider(0.0:0.01:2pi, "ξ", start = 0)

tail(x) = [Point3f0(x[i, 1], x[i, 2], f(x[i, 1], x[i, 2])) for i in 1:size(x, 1)]
head(x, f, ξ) = begin
    derivative = ξΦ(f, ξ, x)
    magnitude = dot(derivative[1, :], ξ)
    [Point3f0(ξ[1]*ϵ, ξ[2]*ϵ, f(ξ[1]*ϵ, ξ[2]*ϵ)) .* magnitude for i in 1:size(x, 1)]
end
P = @lift([$olu $olv])
arrowtail = @lift(tail($P))
arrowhead = @lift(head($P, f, [cos($olξ); sin($olξ)]))

# Instantiate a horizontal box for holding the visuals and the controls
box = vbox(slu, slv, slξ)
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
#Makie.save("gallery/surfaces.jpg", scene)
display(scene)

record(scene, "gallery/surfaces.gif") do io
    frames = 90
    for i = 1:frames
        progress = i / frames
        olξ[] = progress * 2pi # animate scene
        recordframe!(io) # record a new frame
    end
end
