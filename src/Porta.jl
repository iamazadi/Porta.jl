__precompile__()


module Porta

# The default tolerance for comparing the equality of two values.
const TOLERANCE = 1e-7

include("quaternions.jl")
include("dualquaternions.jl")
include("hopfbundle.jl")
include("surface.jl")
include("whirl.jl")
include("basemap.jl")
include("earth.jl")
include("rotation.jl")

end # module
