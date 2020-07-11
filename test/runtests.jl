using Test
using Porta


d = Int(floor(rand() * 5)) # dimension
latestsdir = "./linearalgebra_tests/"
geotestsdir = "./geometry_tests/"
ematestsdir = "./ema_tests/"
pokerdir = "./poker_tests"


start = time()
@time @testset "The Inner Product Tests" begin
    include(latestsdir * "innerproductreal_tests.jl") end
@time @testset "The Determinant Tests" begin
    include(latestsdir * "determinant_tests.jl") end
@time @testset "The Outer Product Tests" begin
    include(latestsdir * "outerproductreal_tests.jl") end
@time @testset "The ℝ³ Tests" begin include(latestsdir * "real3_tests.jl") end
@time @testset "The Inner Product ℝ³ Tests" begin
    include(latestsdir * "innerproductreal3_tests.jl") end
@time @testset "The Outer Product ℝ³ Tests" begin
    include(latestsdir * "outerproductreal3_tests.jl") end
@time @testset "The Quaternion Tests" begin include(latestsdir * "quaternion_tests.jl") end
@time @testset "The Inner Product Quaternion Tests" begin
    include(latestsdir * "innerproductquaternion_tests.jl") end
@time @testset "The Abstract Algebra Utils Tests" begin
    include(latestsdir * "abstractalgebrautils_tests.jl") end
@time @testset "The Riemann Sphere Tests" begin
    include(geotestsdir * "riemannsphere_tests.jl") end
@time @testset "The Rotations Tests" begin include("rotations_tests.jl") end
@time @testset "The Calculus Tests" begin include("calculus_tests.jl") end
@time @testset "The Data Tests" begin include(ematestsdir * "data_tests.jl") end
@time @testset "The Body Tests" begin include(ematestsdir * "body_tests.jl") end
@time @testset "The Card Tests" begin include(joinpath(pokerdir, "card_tests.jl")) end
@time @testset "The Card Set Tests" begin
    include(joinpath(pokerdir, "cardset_tests.jl")) end
@time @testset "The Hands Tests" begin include(joinpath(pokerdir, "hands_tests.jl")) end
elapsed = time() - start
println("Testing took", elapsed)
