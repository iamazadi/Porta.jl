export σmap


"""
    σmap(s)

Map from S³ into ℝ³ using stereographic projection with the given point `s`.
"""
σmap(q::Quaternion) = ℝ³(vec(q)[1:3] ./ (1 - vec(q)[4]))
σmap(s::S³) = σmap(Quaternion(s))
