using FileIO
using GLMakie


point = ℝ³(rand(3))
line = Line(ℝ³(rand(3)), ℝ³(rand(3)))
distance = getdistance(point, line)

@test distance < 2

N = rand(5:10)
points = [normalize(ℝ³(rand(3))) for i in 1:N]
ϵ = rand() * 1e-3
_points = decimate(points, ϵ)

@test length(points) ≤ length(_points)

point = normalize(ℝ³(rand(3)))
_point = convert_to_geographic(point)

@test isapprox(_point[1], 1.0)
@test -π / 2 ≤ _point[2] ≤ π / 2
@test -π ≤ _point[3] ≤ π

geographic = [1.0; rand() * 2π - π; rand() * π - π / 2]

cartesian = convert_to_cartesian(geographic)

@test isapprox(norm(cartesian), 1.0)
cartesian = normalize(ℝ³(rand(3)))
point = convert_to_geographic(cartesian)
@test isapprox(convert_to_cartesian(convert_to_geographic(convert_to_cartesian(point))), cartesian)

α = rand()
basemap = FileIO.load("../data/basemap_color.png")
color = getcolor(points, basemap, α)
@test isapprox(color.alpha, α)

a = ℝ²(rand(), rand())
b = ℝ²(rand(), rand())
e = Edge((a, b))
p = ℝ²(rand(), rand())
@test typeof(rayintersectseg(p, e)) <: Bool
N = rand(5:10)
poly = Vector{Tuple{ℝ², ℝ²}}(undef, N)
for i in 1:N
    _a = ℝ²(rand(2)...)
    _b = ℝ²(rand(2)...)
    poly[i] = (_a, _b)
end
@test typeof(isinside(poly, p)) <: Bool

curve = getbutterflycurve(N)

@test length(curve) == N

attributes_path = "../data/naturalearth/geometry-attributes.csv"
nodes_path = "../data/naturalearth/geometry-nodes.csv"

countries = loadcountries(attributes_path, nodes_path)
i = rand(1:length(countries["nodes"]))
j = rand(1:length(countries["nodes"][i]))

@test length(countries["nodes"]) > 100
@test length(countries["nodes"]) == length(countries["name"])
@test isapprox(1.0, norm(countries["nodes"][i][j]))


index = rand(1:length(countries["nodes"]))
nodes = countries["nodes"][index]
center = getcenter(nodes)
@test isapprox(norm(center), 1)


points = [convert_to_cartesian([1.0; 0.1 * cos(θ); 0.1 * sin(θ)]) for θ in range(0, stop = 2π, length = 30)] # the circle is centered at (0, 0)
point = convert_to_cartesian([1.0; 0.0; 0.0]) # the center of the circle at (0, 0)
@test isinside(point, points)
point = convert_to_cartesian([1.0; π / 2; 0.0]) # a point outside of the circle
@test !isinside(point, points)