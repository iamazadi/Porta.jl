using GLMakie
export TangentBundle


"""
    Represents a point in manifold M together with a tangent vector to M there.

field: name, origin, tangenttail, tangenthead, a, b, c, d, raya, rayb, rayc, rayd, fiber,
    tangentcircle, basepath, pathcolors, pathsegments and segments.
"""
struct TangentBundle
    name::String
    origin::Observable{Point3f}
    tangenttail::Observable{Point3f}
    tangenthead::Observable{Point3f}
    a::Observable{Point3f}
    b::Observable{Point3f}
    c::Observable{Point3f}
    d::Observable{Point3f}
    raya::Observable{Vector{Point3f}}
    rayb::Observable{Vector{Point3f}}
    rayc::Observable{Vector{Point3f}}
    rayd::Observable{Vector{Point3f}}
    fiber::Observable{Vector{Point3f}}
    tangentcircle::Observable{Vector{Point3f}}
    basepath::Observable{Vector{Point3f}}
    pathcolors::Observable{Vector{Int}}
    pathsegments::Int
    segments::Int
    TangentBundle(lscene::LScene, name::String; segments::Int = 30, pathsegments::Int = 360, transparency::Bool = false,
        markersize::Float64 = 0.05, linewidth::Int = 20, color::Symbol = :black, colormap::Symbol = :rainbow,
        arrowsize::Vec3f = Vec3f(0.06, 0.08, 0.1), arrowlinewidth::Float64 = 0.04, fontsize::Float64 = 0.25) = begin
        _zero = Point3f(0.0, 0.0, 0.0)
        origin = Observable(_zero)
        tangenttail = Observable(_zero)
        tangenthead = Observable(Point3f(1.0, 0.0, 0.0))
        a = Observable(_zero)
        b = Observable(_zero)
        c = Observable(_zero)
        d = Observable(_zero)
        raya = @lift([$a, $tangenttail])
        rayb = @lift([$b, $tangenttail])
        rayc = @lift([$c, $tangenttail])
        rayd = @lift([$d, $tangenttail])
        colors = Observable(collect(1:segments))
        fiber = Observable([Point3f(ℝ³(real(exp(im * α)), imag(exp(im * α)), 0.0)) for α in range(0, stop = 2π, length = segments)])
        basepath = Observable(Point3f[])
        pathcolors = Observable(Int[])
        tangentcircle = Observable(Point3f[])
        # Instantiate graphical components
        meshscatter!(lscene, origin, markersize = markersize, color = color, transparency = transparency)
        meshscatter!(lscene, a, markersize = markersize, color = color, transparency = transparency)
        meshscatter!(lscene, b, markersize = markersize, color = color, transparency = transparency)
        meshscatter!(lscene, c, markersize = markersize, color = color, transparency = transparency)
        meshscatter!(lscene, d, markersize = markersize, color = color, transparency = transparency)
        meshscatter!(lscene, tangenttail, markersize = markersize, color = color, transparency = transparency)
        lines!(lscene, raya, color = colors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap, transparency = transparency)
        lines!(lscene, rayb, color = colors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap, transparency = transparency)
        lines!(lscene, rayc, color = colors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap, transparency = transparency)
        lines!(lscene, rayd, color = colors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap, transparency = transparency)
        lines!(lscene, fiber, color = colors, linewidth = 2linewidth, colorrange = (1, segments), colormap = colormap, transparency = transparency)
        lines!(lscene, basepath, color = colors, linewidth = linewidth / 2, colorrange = (1, pathsegments), colormap = colormap, transparency = transparency)
        lines!(lscene, tangentcircle, color = colors, linewidth = linewidth, colorrange = (1, segments), colormap = colormap, transparency = transparency)
        ps = @lift([$origin, $origin, $tangenttail])
        ns = @lift([$a, $c, $tangenthead])
        arrows!(lscene,
            ps, ns, fxaa = true, # turn on anti-aliasing
            color = color,
            linewidth = arrowlinewidth, arrowsize = arrowsize,
            align = :origin, transparency = transparency
        )
        titles = ["O", name, "-$name", "π($name)"]
        rotation = gettextrotation(lscene)
        text!(lscene,
            @lift([$origin, $a, $c, $tangenttail]),
            text = titles,
            color = [color for _ in eachindex(titles)],
            rotation = rotation,
            align = (:left, :baseline),
            fontsize = fontsize,
            markerspace = :data, transparency = transparency
        )
        new(name, origin, tangenttail, tangenthead, a, b, c, d, raya, rayb, rayc, rayd, fiber,
            tangentcircle, basepath, pathcolors, pathsegments, segments)
    end
end