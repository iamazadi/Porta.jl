export σ


"""
    σ(p)

Map from S³ into ℝ³ using stereographic projection.
"""
σ(p::ℍ) = ℝ³(p.a[1:3] ./ (1 - p.a[4]))
