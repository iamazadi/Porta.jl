using Test
using Porta


logicdir = "logic_tests"
linearalgebradir = "linearalgebra_tests"
geometrydir = "geometry_tests"


start = time()


@time @testset "The Propositional Logic Tests" begin
    include(joinpath(logicdir, "propositionallogic_tests.jl")) end
@time @testset "The Predicate Logic Tests" begin
    include(joinpath(logicdir, "predicatelogic_tests.jl")) end


@time @testset "The Determinant Tests" begin
    include(joinpath(linearalgebradir, "determinant_tests.jl")) end
@time @testset "The ℝ³ Tests" begin
    include(joinpath(linearalgebradir, "real3_tests.jl")) end
@time @testset "The Quaternions Tests" begin
    include(joinpath(linearalgebradir, "quaternion_tests.jl")) end


@time @testset "The Riemann Sphere Tests" begin
    include(joinpath(geometrydir, "riemannsphere_tests.jl")) end
@time @testset "The Stereographic Projection Tests" begin
    include(joinpath(geometrydir, "stereographicprojection_tests.jl")) end
@time @testset "The Spacetime Tests" begin
    include(joinpath(geometrydir, "spacetime_tests.jl")) end
@time @testset "The Rotations Tests" begin
    include(joinpath(geometrydir, "rotations_tests.jl")) end
@time @testset "The Body Tests" begin
    include(joinpath(geometrydir, "body_tests.jl")) end


elapsed = time() - start
println("Testing took", elapsed)
