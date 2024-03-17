"""
    SpinVector(q)

Transform a quaternion nuber to a spin vector.
"""
function SpinVector(q::Quaternion)
    t, x, y, z = vec(q)
    t = √(x^2 + y^2 + z^2)
    SpinVector(𝕍(t, x, y, z))
end


"""
    Quaternion(v)

Perform a trick to convert `q` to a Quaternion number.
"""
Quaternion(v::SpinVector) = Quaternion(vec(v.nullvector)[1], normalize(v.cartesian))