using Test
using Porta


const TOLERANCE = 1e-7


logicdir = "logic_tests"
linearalgebradir = "linearalgebra_tests"
geometrydir = "geometry_tests"
bundlesdir = "bundles_tests"
uidir = "ui_tests"
datadir = "data_tests"


start = time()


@time @testset "The Logic Tests" begin
    include(joinpath(logicdir, "propositionallogic_tests.jl"))
    include(joinpath(logicdir, "predicatelogic_tests.jl"))
end

@time @testset "The Linear Algebra Tests" begin
    include(joinpath(linearalgebradir, "determinant_tests.jl"))
    include(joinpath(linearalgebradir, "real3_tests.jl"))
    include(joinpath(linearalgebradir, "real4_tests.jl"))
end

@time @testset "The Geometry Tests" begin
    include(joinpath(geometrydir, "s1_tests.jl"))
    include(joinpath(geometrydir, "s2_tests.jl"))
    include(joinpath(geometrydir, "s3_tests.jl"))
    include(joinpath(geometrydir, "biquaternions_tests.jl"))
    include(joinpath(geometrydir, "stereographicprojection_tests.jl"))
    include(joinpath(geometrydir, "rotations_tests.jl"))
end

@time @testset "The Bundles Tests" begin
    include(joinpath(bundlesdir, "clifford_tests.jl"))
end


@time @testset "The UI Tests" begin
    include(joinpath(uidir, "body_tests.jl"))
    include(joinpath(uidir, "ui_tests.jl"))
    include(joinpath(uidir, "arrow_tests.jl"))
    include(joinpath(uidir, "cylinder_tests.jl"))
    include(joinpath(uidir, "sphere_tests.jl"))
    include(joinpath(uidir, "torus_tests.jl"))
    include(joinpath(uidir, "triad_tests.jl"))
    include(joinpath(uidir, "whirl_tests.jl"))
    include(joinpath(uidir, "frame_tests.jl"))
    include(joinpath(uidir, "coloring_tests.jl"))
end


@time @testset "The Data Tests" begin
    include(joinpath(datadir, "signal_tests.jl"))
end

elapsed = time() - start
println("Testing took", elapsed)
