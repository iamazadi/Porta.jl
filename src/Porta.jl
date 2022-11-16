__precompile__()


module Porta


# The default tolerance for comparing the equality of two values.
const TOLERANCE = 1e-7


logicdir = "logic"
linearalgebradir = "topology/linearalgebra"
geometrydir = "geometry"
bundlesdir = "bundles"
computergraphicsdir = "computergraphics"
datadir = "data"


# commented out because it exports T
# include(joinpath(logicdir, "propositionallogic.jl"))
# include(joinpath(logicdir, "predicatelogic.jl"))

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
include(joinpath(bundlesdir, "planethopf.jl"))

include(joinpath(computergraphicsdir, "body.jl"))
include(joinpath(computergraphicsdir, "ui.jl"))
include(joinpath(computergraphicsdir, "arrow.jl"))
include(joinpath(computergraphicsdir, "cylinder.jl"))
include(joinpath(computergraphicsdir, "sphere.jl"))
include(joinpath(computergraphicsdir, "hemisphere.jl"))
include(joinpath(computergraphicsdir, "torus.jl"))
include(joinpath(computergraphicsdir, "triad.jl"))
include(joinpath(computergraphicsdir, "whirl.jl"))
include(joinpath(computergraphicsdir, "fiber.jl"))
include(joinpath(computergraphicsdir, "frame.jl"))
include(joinpath(computergraphicsdir, "twospinor.jl"))
include(joinpath(computergraphicsdir, "coloring.jl"))

include(joinpath(datadir, "signal.jl"))

end # module
