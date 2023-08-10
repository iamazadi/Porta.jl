using Test
using Porta


const TOLERANCE = 1e-8

start = time()

@time @testset "The Numbers Tests" begin
    include("quaternions_tests.jl")
    include("dualquaternions_tests.jl")
end

@time @testset "The Bundles Tests" begin
    include("hopfbundle_tests.jl")
end

@time @testset "The Graphics Tests" begin
    include("surface_tests.jl")
    include("whirl_tests.jl")
    include("frame_tests.jl")
    include("earth_tests.jl")
end

elapsed = time() - start
println("Testing took", elapsed)
