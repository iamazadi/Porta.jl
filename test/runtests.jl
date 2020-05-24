using Test

start = time()
@time @testset "The Hopf Fibration Tests" begin include("thehopffibration_tests.jl") end
elapsed = time() - start
println("Testing took", elapsed)
