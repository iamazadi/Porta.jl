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
include("quaternions.jl")
include(joinpath(directory, "spintransformation.jl"))
include("dualquaternions.jl")
include("hopfbundle.jl")
include("earth.jl")
include("rotation.jl")
include("surface.jl")
include("whirl.jl")
include("basemap.jl")

end # module
