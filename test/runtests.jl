using Test

start = time()
@time @testset "Hopf Tests" begin include("hopf_tests.jl") end
elapsed = time() - start
println("Testing took", elapsed)
