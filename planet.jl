using LinearAlgebra
using AbstractPlotting
using Makie
using ReferenceFrameRotations
using CSV
using StatsBase
using Porta

"""
construct(p₁, p₂, p₃, N)

Constructs a surface with the given points
and the number of points along the fiber circle.
The points are expressed as arrays of x, y and z in the base space.
"""
function construct(p₁, p₂, p₃, N)
    lspace = range(0, stop = 2pi, length = N)
    x = Array{Float64}(undef, N, length(p₁))
    y = Array{Float64}(undef, N, length(p₁))
    z = Array{Float64}(undef, N, length(p₁))
    for i in 1:length(p₁)
        # Find 3 points on the circle
        A, B, C = points!([p₁[i], p₂[i], p₃[i]])
        # Get the circle center point
        Q = Porta.center!(A, B, C)
        # Find the small and big radii
        radius = Float64(LinearAlgebra.norm(A - Q))
        x₁ = (Q[1] .+ [radius * cos(j) for j in lspace]) ./ radius
        x₂ = (Q[2] .+ [radius * sin(j) for j in lspace]) ./ radius
        x₃ = [Q[3] for j in lspace] ./ radius
        # Find the normal to the plane containing the points
        n = LinearAlgebra.cross(A - Q, B - Q)
        n = n / LinearAlgebra.norm(n)
        # Find the normal to the circle
        circle_normal = [0.0, 0.0, 1.0]
        # The axis of rotation
        u = LinearAlgebra.cross(n, circle_normal)
        u = u / LinearAlgebra.norm(u)
        # The angle of rotation
        ψ = acos(LinearAlgebra.dot(n, circle_normal)) / 2
        q = ReferenceFrameRotations.Quaternion(cos(ψ), 
                                               sin(ψ)*u[1],
                                               sin(ψ)*u[2],
                                               sin(ψ)*u[3])
        M = [x₁ x₂ x₃]
        # Rotate the points
        for j in 1:size(M, 1)
            x[j, i], y[j, i], z[j, i] = ReferenceFrameRotations.vect(q\M[j, :]*q)
        end
    end
    x, y, z
end

"""
rotate(x₁, x₂, x₃, g)

Rotates points in the total space with the given arrays of
x₁, x₂, x₃ coordinates and the unit quaternion.
"""
function rotate_array(x₁, x₂, x₃, g)
    x = similar(x₁)
    y = similar(x₂)
    z = similar(x₃)
    for i in 1:length(x₁)
        x[i], y[i], z[i] = rotate([x₁[i], x₂[i], x₃[i]], g)
    end
    x, y, z
end

universe = Scene(show_axis = false, backgroundcolor = :black)
# Using 3 Sliders for controlling the rotation axis and angle
sg₁, og₁ = textslider(-2pi:0.01:2pi, "g₁", start = 1)
sg₂, og₂ = textslider(-2pi:0.01:2pi, "g₂", start = 1)
sg₃, og₃ = textslider(-2pi:0.01:2pi, "g₃", start = 1)
g = @lift(ReferenceFrameRotations.Quaternion(cos($og₁), 
                                             sin($og₁) * cos($og₂) * cos($og₃),
                                             sin($og₁) * cos($og₂) * sin($og₃),
                                             sin($og₁) * sin($og₂)))

points = []
countries = Dict("iran" => RGBAf0(1.0, 1.0, 1.0, 1.0), # white
                 "us" => RGBAf0(0.0, 1.0, 1.0, 1.0), # blue
                 "australia" => RGBAf0(0.0, 0.0, 1.0, 1.0), # cyan
                 "ukraine" => RGBAf0(1.0, 1.0, 0.0, 1.0), # yellow
                 "germany" => RGBAf0(1.0, 0.0, 1.0, 1.0), # magenta
                 "israel" => RGBAf0(0.0, 1.0, 0.0, 1.0), # green
                 "china" => RGBAf0(1.0, 0.0, 0.0, 1.0)) # red
# Made with Natural Earth.
# Free vector and raster map data @ naturalearthdata.com.
path = "data/natural_earth_vector"
for country in countries
    dataframe = CSV.read(joinpath(path, "$(country[1])-nodes.csv"))
    color = country[2]
    θ = dataframe[dataframe[:shapeid] .< 0.1, 2] ./ 180 .* pi
      ϕ = dataframe[dataframe[:shapeid] .< 0.1, 3] ./ 180 .* pi
    max = 300
    θreduced = Array{Float64}(undef, max)
      ϕreduced = Array{Float64}(undef, max)
    if length(θ) > max
        sample!(θ, θreduced, replace=false, ordered=true)
        sample!(ϕ, ϕreduced, replace=false, ordered=true)
        θ = θreduced
            ϕ = ϕreduced
    end
    x₁ = similar(θ)
    x₂ = similar(θ)
    x₃ = similar(θ)
    for i in 1:length(θ)
        x₁[i], x₂[i], x₃[i] = locate(θ[i], ϕ[i])
    end
    rotated = @lift(rotate_array(x₁, x₂, x₃, $g))
    N = 30
    xyz = @lift(construct($rotated[1], $rotated[2], $rotated[3], N))
    push!(points, xyz)
    surface!(universe,
             @lift($xyz[1]),
             @lift($xyz[2]),
             @lift($xyz[3]),
             color = [color for i in 1:N, j in 1:size(x₁, 2)])
end

eyepos = Vec3f0(3, 3, 3)
lookat = Vec3f0(0)
update_cam!(universe, eyepos, lookat)
universe.center = false # prevent scene from recentering on display
scene = hbox(universe, vbox(sg₁, sg₂, sg₃), parent = Scene(resolution = (500, 500)))
"""
record(universe, "planet.gif") do io
    for i in 1:100
        og₁[] = 2pi*i/100 # animate scene
        recordframe!(io) # record a new frame
    end
end
"""

