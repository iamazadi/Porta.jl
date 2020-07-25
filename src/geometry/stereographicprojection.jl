export σ


"""
    σ(h)

Map from S³ into ℝ³ using stereographic projection with the given point `h`.
"""
σ(h::ℍ) = ℝ³(vec(h)[1:3] ./ (1 - vec(h)[4]))
