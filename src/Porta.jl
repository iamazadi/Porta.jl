__precompile__()


module Porta

dir = "./linearalgebra/"

include(dir * "innerproductreal.jl")
include(dir * "determinant.jl")
include(dir * "outerproductreal.jl")
include(dir * "real3.jl")
include(dir * "innerproductreal3.jl")
include(dir * "outerproductreal3.jl")
include(dir * "quaternion.jl")
include(dir * "innerproductquaternion.jl")
include(dir * "abstractalgebrautils.jl")
include("rotations.jl")
include("body.jl")
#include("basemap.jl")
#include("thehopffibration.jl")
#include("data.jl")
#include("signal.jl")

end # module
