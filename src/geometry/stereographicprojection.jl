export σ


"""
    σ(h)

Map from S³ into ℝ³ using stereographic projection with the given point `h`.
"""
σ(h::ℍ) = ℝ³(h.a[1:3] ./ (1 - h.a[4]))
