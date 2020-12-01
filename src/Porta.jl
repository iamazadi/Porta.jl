__precompile__()


module Porta


# The default tolerance for comparing the equality of two values.
const TOLERANCE = 1e-7


logicdir = "logic"
linearalgebradir = "linearalgebra"
geometrydir = "geometry"
bundlesdir = "bundles"
uidir = "ui"
datadir = "data"


include(joinpath(logicdir, "propositionallogic.jl"))
include(joinpath(logicdir, "predicatelogic.jl"))

include(joinpath(linearalgebradir, "abstractvectorspace.jl"))
include(joinpath(linearalgebradir, "determinant.jl"))
include(joinpath(linearalgebradir, "real3.jl"))
include(joinpath(linearalgebradir, "real4.jl"))

include(joinpath(geometrydir, "s1.jl"))
include(joinpath(geometrydir, "s2.jl"))
include(joinpath(geometrydir, "s3.jl"))
include(joinpath(geometrydir, "biquaternions.jl"))
include(joinpath(geometrydir, "stereographicprojection.jl"))
include(joinpath(geometrydir, "rotations.jl"))

include(joinpath(bundlesdir, "clifford.jl"))

include(joinpath(uidir, "body.jl"))
include(joinpath(uidir, "ui.jl"))
include(joinpath(uidir, "arrow.jl"))
include(joinpath(uidir, "cylinder.jl"))
include(joinpath(uidir, "sphere.jl"))
include(joinpath(uidir, "torus.jl"))
include(joinpath(uidir, "triad.jl"))
include(joinpath(uidir, "whirl.jl"))
include(joinpath(uidir, "frame.jl"))
include(joinpath(uidir, "coloring.jl"))

include(joinpath(datadir, "signal.jl"))


end # module
