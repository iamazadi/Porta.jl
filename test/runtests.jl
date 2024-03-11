using Test
using Porta


const TOLERANCE = 1e-8

start = time()

@time @testset "The Linear Algebra Tests" begin
    directory = "spacetime_tests"
    include(joinpath(directory, "real2_tests.jl"))
    include(joinpath(directory, "real3_tests.jl"))
    include(joinpath(directory, "real4_tests.jl"))
    include(joinpath(directory, "determinant_tests.jl"))
    include(joinpath(directory, "tetrad_tests.jl"))
    include(joinpath(directory, "minkowskivectorspace_tests.jl"))
    include(joinpath(directory, "minkowskispacetime_tests.jl"))
    include(joinpath(directory, "spinvector_tests.jl"))
end

@time @testset "The Numbers Tests" begin
    include("quaternions_tests.jl")
    include("dualquaternions_tests.jl")
end

@time @testset "The Bundles Tests" begin
    include("hopfbundle_tests.jl")
end

@time @testset "The Graphics Tests" begin
    include("earth_tests.jl")
    include("rotation_tests.jl")
    include("surface_tests.jl")
    include("whirl_tests.jl")
    include("basemap_tests.jl")
end

elapsed = time() - start
println("Testing took", elapsed)
