__precompile__()


module Porta


# The default tolerance for comparing the equality of two values.
const TOLERANCE = 1e-10


logicdir = "logic"
#groupsdir = "symmetrygroups"
#fieldsdir = "fields"


include(joinpath(logicdir, "propositionallogic.jl"))
include(joinpath(logicdir, "predicatelogic.jl"))
#include(joinpath(groupsdir, "u1.jl"))
#include(joinpath(groupsdir, "su2.jl"))
#include(joinpath(fieldsdir, "complex.jl"))


end # module
