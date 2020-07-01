__precompile__()


module Porta

ladir = "./linearalgebra/"
geodir = "./geometry/"
emadir = "./ema/"

include(ladir * "innerproductreal.jl")
include(ladir * "determinant.jl")
include(ladir * "outerproductreal.jl")
include(ladir * "real3.jl")
include(ladir * "innerproductreal3.jl")
include(ladir * "outerproductreal3.jl")
include(ladir * "quaternion.jl")
include(ladir * "innerproductquaternion.jl")
include(ladir * "abstractalgebrautils.jl")
include(geodir * "riemannsphere.jl")
include("rotations.jl")
include("calculus.jl")
include(emadir * "data.jl")
include(emadir * "body.jl")
#include("thehopffibration.jl")
#include("data.jl")
#include("signal.jl")

end # module
