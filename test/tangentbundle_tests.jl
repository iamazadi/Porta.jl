using GLMakie

segments = 30
pathsegments = 360
markersize = 0.05
linewidth = 20
transparency = rand() > 0.5 ? true : false
color = :black
colormap = :rainbow
arrowsize = Vec3f(0.06, 0.08, 0.1)
arrowlinewidth = 0.04
fontsize = 0.25
fig = GLMakie.Figure()
lscene = GLMakie.LScene(fig[1, 1])
name = "q₁"
tangentbundle = TangentBundle(lscene, name, segments = segments, pathsegments = pathsegments, transparency = transparency,
        markersize = markersize, linewidth = linewidth, color = color, colormap = colormap, arrowsize = arrowsize,
        arrowlinewidth = arrowlinewidth, fontsize = fontsize)