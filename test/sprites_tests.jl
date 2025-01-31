segments = rand(5:10)
smallradius = rand()
bigradius = rand()
configuration = Dualquaternion(ℝ³(0.0, 0.0, 0.0))
torus = constructtorus(configuration, smallradius, bigradius, segments = segments)
@test typeof(torus) <: Matrix{ℝ³}
@test size(torus) == (segments, segments)

radius = rand()
sphere = constructsphere(configuration, radius, segments = segments)
@test typeof(sphere) <: Matrix{ℝ³}
@test size(sphere) == (segments, segments)