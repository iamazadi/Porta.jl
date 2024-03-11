u¹, u², u³ = rand(3)
u⁰ = √(u¹^2 + u²^2 + u³^2)
u = 𝕍(u⁰, u¹, u², u³)

v¹, v², v³ = [u¹; u²; u³] .* (rand() + 0.01)
v⁰ = √(v¹^2 + v²^2 + v³^2)
v = 𝕍(v⁰, v¹, v², v³)

vector1 = SpinVector(u)
vector2 = SpinVector(v)

@test !isapprox(vector1, vector2)


futurepast = rand([-1, +1])
v = normalize(ℝ³(rand(3)))
vector = SpinVector(v, futurepast)

@test isnull(vector.a)
