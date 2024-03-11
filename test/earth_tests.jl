import FileIO
import GLMakie


point = ℝ³(rand(3))
line = Line(ℝ³(rand(3)), ℝ³(rand(3)))
distance = getdistance(point, line)

@test distance < 2

N = rand(5:10)
points = [ℝ³(rand(3)) for i in 1:N]
ϵ = rand() * 1e-3
_points = decimate(points, ϵ)

@test length(points) ≤ length(_points)

point = normalize(ℝ³(rand(3)))
_point = convert_to_geographic(point)

@test isapprox(_point[1], 1.0)
@test -π ≤ _point[2] ≤ π
@test -π / 2 ≤ _point[3] ≤ π / 2

α = rand()
basemap = FileIO.load("../data/basemap_color.png")
color = getcolor(points, basemap, α)

@test isapprox(color.alpha, α)

a = Point(rand(), rand())
b = Point(rand(), rand())
e = Edge((a, b))
p = Point(rand(), rand())
result = rayintersectseg(p, e)

@test typeof(result) <: Bool

N = rand(5:10)
poly = Vector{Tuple{Point{Float64}, Point{Float64}}}(undef, N)
for i in 1:N
    _a = Point(rand(2)...)
    _b = Point(rand(2)...)
    poly[i] = (_a, _b)
end
result = isinside(poly, p)

@test typeof(result) <: Bool

geographic = [1.0; rand() * 2π - π; rand() * π - π / 2]

cartesian = convert_to_cartesian(geographic)

@test isapprox(norm(cartesian), 1.0)

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