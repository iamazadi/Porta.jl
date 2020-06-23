using Test
using Porta


d = Int(floor(rand() * 5)) # dimension
dir = "./linearalgebra_tests/"

start = time()
@time @testset "The Inner Product Tests" begin
    include(dir * "innerproductreal_tests.jl") end
@time @testset "The Determinant Tests" begin include(dir * "determinant_tests.jl") end
@time @testset "The Outer Product Tests" begin
    include(dir * "outerproductreal_tests.jl") end
@time @testset "The ℝ³ Tests" begin include(dir * "real3_tests.jl") end
@time @testset "The Inner Product ℝ³ Tests" begin
    include(dir * "innerproductreal3_tests.jl") end
@time @testset "The Outer Product ℝ³ Tests" begin
    include(dir * "outerproductreal3_tests.jl") end
@time @testset "The Quaternion Tests" begin include(dir * "quaternion_tests.jl") end
@time @testset "The Inner Product Quaternion Tests" begin
    include(dir * "innerproductquaternion_tests.jl") end
@time @testset "The Abstract Algebra Utils Tests" begin
    include(dir * "abstractalgebrautils_tests.jl") end
@time @testset "The Rotations Tests" begin include("rotations_tests.jl") end
#@time @testset "The Calculus Tests" begin include("calculus_tests.jl") end
#@time @testset "The Base Map Tests" begin include("basemap_tests.jl") end
#@time @testset "The Hopf Fibration Tests" begin include("thehopffibration_tests.jl") end
elapsed = time() - start
println("Testing took", elapsed)
