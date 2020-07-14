__precompile__()


module Porta


# The default tolerance for comparing the equality of two numbers.
const TOLERANCE = 1e-10


groupsdir = "symmetrygroups"
#fieldsdir = "fields"


include(joinpath(groupsdir, "u1.jl"))
#include(joinpath(groupsdir, "su2.jl"))
#include(joinpath(fieldsdir, "complex.jl"))


end # module
