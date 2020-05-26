using Test

start = time()
@time @testset "The Base Map Tests" begin include("basemap_tests.jl") end
@time @testset "The Hopf Fibration Tests" begin include("thehopffibration_tests.jl") end
elapsed = time() - start
println("Testing took", elapsed)
