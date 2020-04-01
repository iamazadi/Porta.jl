using Makie
using Porta


"""
get_manifold(points, segments, start, finish)

Calculates a grid of points in R³ for constructing a surface in a specific way
with the given points in the base space, the number of segments, and the start
and finish angles that determine where to cut.
"""
function get_manifold(points, segments, start, finish)
    samples = size(points, 1)
    manifold = Array{Float64}(undef, segments, samples, 3)
    for i in 1:samples
            ϕ, θ = points[i, :]
        f = θ / (pi / 2)
        α = -(finish - start) / (segments - 1) / f
        p = S¹action(-start / f - pi/2, λ⁻¹map(convert_to_cartesian([ϕ, θ])))
        for j in 1:segments
            x₁, x₂, x₃ = λmap(p)
            manifold[j, i, :] = [x₁, x₂, x₃]
            p = S¹action(α, p)
        end
    end
    manifold
end


"""
build_surface(scene, points, color; transparency, shading)

Builds a surface with the given scene, points, color, transparency and shading.
"""
function build_surface(scene,
                       points,
                       color;
                       transparency = false,
                       shading = true)
    surface!(scene,
             @lift($points[:, :, 1]),
             @lift($points[:, :, 2]),
             @lift($points[:, :, 3]),
             color = color,
             transparency = transparency,
             shading = shading)
end


# The scene object that contains other visual objects
universe = Scene(backgroundcolor = :orange, show_axis=false)
# Use a slider for rotating the base space in an interactive way
sg, og = textslider(0:0.05:2pi, "g", start = 0)
segments = 100
samples = 100
# Construct a manifold for each country in the dictionary
latitudes = [pi/12, pi/6, pi/4, pi/3, 5pi/12]
for l in 1:length(latitudes)
    latitude = latitudes[l]
    # Sample a circle of points
    points = Array{Float64}(undef, samples, 2)
    for i in 1:samples
        longitude = i * 2pi / (samples - 1)
        points[i, :] = [longitude, latitude]
    end
    if (-1) ^ l > 0
        color = fill(RGBAf0(0.0, 0.0, 1.0, 1.0), segments, samples)
    else
        color = fill(RGBAf0(0.0, 0.0, 0.75, 1.0), segments, samples)
    end
    for i in range(1, stop = samples, step = 10)
        color[:, i] = fill(RGBAf0(rand(), rand(), rand(), 1.0), segments)
    end
    # Rotate the points by adding to the longitudes
    rotated = @lift begin
        R = similar(points)
        for i in 1:samples
                  ϕ, θ = points[i, :]
            R[i, :] = [ϕ + $og, θ]
        end
        R
    end
    start = -latitude
    finish = latitude
    manifold = @lift(get_manifold($rotated,
                                  segments,
                                  start,
                                  finish))
    build_surface(universe, manifold, color)
end

# Instantiate a horizontal box for holding the visuals and the controls
scene = hbox(universe,
             vbox(sg),
             parent = Scene(resolution = (360, 360)))

# update eye position
eye_position, lookat, upvector = Vec3f0(-2, 0, 2), Vec3f0(0), Vec3f0(0, 0, 1.0)
update_cam!(universe, eye_position, lookat)
universe.center = false # prevent scene from recentering on display
rotate_cam!(universe, 0.0, 0.0, pi/2)

# Add stars to the scene to fill the background with something
stars = 100_000
scatter!(
    universe,
    map(i-> (randn(Point3f0) .- 0.5) .* 10, 1:stars),
    glowwidth = 1, glowcolor = (:white, 0.1), color = rand(stars),
    colormap = [(:white, 0.4), (:blue, 0.4), (:gold, 0.4)],
    markersize = rand(range(0.0001, stop = 0.025, length = 100), stars),
    show_axis = false, transparency = true
)


record(universe, "londontsai.gif") do io
    frames = 180
    for i in 1:frames
        og[] = i*2pi/frames # animate scene
        rotate_cam!(universe, 0.0, 2pi/frames, 0.0)
        recordframe!(io) # record a new frame
    end
end


