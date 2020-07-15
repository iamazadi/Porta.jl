using Test
using Porta


logicdir = "logic_tests"
#groupsdir = "symmetrygroups_tests"
#fieldsdir = "fields_tests"


start = time()


@time @testset "The Propositional Logic Tests" begin
    include(joinpath(logicdir, "propositionallogic_tests.jl")) end
#@time @testset "The Axioms Tests" begin include(joinpath(logicdir, "axioms_tests.jl")) end
#@time @testset "The U(1) Tests" begin include(joinpath(groupsdir, "u1_tests.jl")) end
#@time @testset "The SU(2) Tests" begin include(joinpath(groupsdir, "su2_tests.jl")) end
#@time @testset "The Complex Tests" begin
#    include(joinpath(fieldsdir, "complex_tests.jl")) end


elapsed = time() - start
println("Testing took", elapsed)
