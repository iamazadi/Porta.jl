__precompile__()


module Porta


# The default tolerance for comparing the equality of two values.
const TOLERANCE = 1e-10


logicdir = "logic"
linearalgebradir = "linearalgebra"
geometrydir = "geometry"


include(joinpath(logicdir, "propositionallogic.jl"))
include(joinpath(logicdir, "predicatelogic.jl"))


include(joinpath(linearalgebradir, "abstractvectorspace.jl"))
include(joinpath(linearalgebradir, "determinant.jl"))
include(joinpath(linearalgebradir, "real3.jl"))
include(joinpath(linearalgebradir, "quaternion.jl"))


include(joinpath(geometrydir, "riemannsphere.jl"))
include(joinpath(geometrydir, "stereographicprojection.jl"))
include(joinpath(geometrydir, "spacetime.jl"))
include(joinpath(geometrydir, "rotations.jl"))
include(joinpath(geometrydir, "body.jl"))


end # module
