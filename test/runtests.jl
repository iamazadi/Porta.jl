using Test
using Porta


const TOLERANCE = 1e-7


logicdir = "logic_tests"
linearalgebradir = "topology_tests/linearalgebra"
geometrydir = "geometry_tests"
bundlesdir = "bundles_tests"
computergraphicsdir = "computergraphics_tests"
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
    include(joinpath(computergraphicsdir, "body_tests.jl"))
    include(joinpath(computergraphicsdir, "ui_tests.jl"))
    include(joinpath(computergraphicsdir, "arrow_tests.jl"))
    include(joinpath(computergraphicsdir, "cylinder_tests.jl"))
    include(joinpath(computergraphicsdir, "sphere_tests.jl"))
    include(joinpath(computergraphicsdir, "hemisphere_tests.jl"))
    include(joinpath(computergraphicsdir, "torus_tests.jl"))
    include(joinpath(computergraphicsdir, "triad_tests.jl"))
    include(joinpath(computergraphicsdir, "whirl_tests.jl"))
    include(joinpath(computergraphicsdir, "frame_tests.jl"))
    include(joinpath(computergraphicsdir, "coloring_tests.jl"))
end


@time @testset "The Data Tests" begin
    include(joinpath(datadir, "signal_tests.jl"))
end

elapsed = time() - start
println("Testing took", elapsed)
