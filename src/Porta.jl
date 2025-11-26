__precompile__()


module Porta

# The default tolerance for comparing the equality of two values.
const TOLERANCE = 1e-7

directory = "spacetime"
include(joinpath(directory, "abstractvectorspace.jl"))
include(joinpath(directory, "real2.jl"))
include(joinpath(directory, "real3.jl"))
include(joinpath(directory, "real4.jl"))
include(joinpath(directory, "determinant.jl"))
include(joinpath(directory, "tetrad.jl"))
include(joinpath(directory, "minkowskivectorspace.jl"))
include(joinpath(directory, "minkowskispacetime.jl"))
include(joinpath(directory, "spinvector.jl"))
include(joinpath(directory, "spintransformation.jl"))
include("quaternions.jl")
include("projection.jl")
include(joinpath(directory, "transformations.jl"))
include("dualquaternions.jl")
include("cliffordbundle.jl")
include("earth.jl")
include("nullcone.jl")
include("sprites.jl")
include("rotation.jl")
include("surface.jl")
include("whirl.jl")
include("basemap.jl")
include("scene.jl")
include("clutchingconstruction.jl")
include("tangentbundle.jl")
include("unicycle/telemetry.jl")
include("unicycle/recursiveleastsquares.jl")
include("unicycle/linearquadraticregulator.jl")
include("unicycle/graphicalmodel.jl")

end # module
