import Base.isapprox


export SpinVector


"""
    Represents a spin vector represented as the intersection of the future [past] null cone with the hyperplane T = 1 [T = -1].

fields: a and s.
"""
struct SpinVector <: VectorSpace
    a::𝕍
    s::Complex
    SpinVector(a::𝕍) = begin
        @assert(isnull(a), "The spin vector must be a null vector.")
        t, x, y, z = vec(a)
        x, y, z = vec(normalize(ℝ³(x, y, z)))
        X′, Y′ = x / (1.0 - z), y / (1.0 - z)
        s = X′ + im * Y′
        new(a, s)
    end
    SpinVector(a::ℝ³, futurepast::Int) = begin
        @assert(isapprox(norm(a), 1.0), "The direction must be in the unit sphere in the Euclidean 3-space.")
        @assert(!isapprox(futurepast, 0), "The future/past direction can be either +1 pr -1, but was given 0.")
        x, y, z = vec(a)
        t = futurepast > 0 ? +1.0 : -1.0
        a = 𝕍(t, x, y, z)
        x, y, z = vec(normalize(ℝ³(x, y, z)))
        X′, Y′ = x / (1.0 - z), y / (1.0 - z)
        s = X′ + im * Y′
        new(a, s)
    end
end


Base.isapprox(u::SpinVector, v::SpinVector) = isapprox(u.s, v.s) && isapprox(u.a, v.a)