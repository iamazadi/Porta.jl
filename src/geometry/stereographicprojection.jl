export λmap
export compressedλmap


"""
    λmap(s)

Map from S³ into ℝ³ using stereographic projection with the given point `s`.
"""
λmap(q::Quaternion) = ℝ³(vec(q)[1:3] ./ (1 - vec(q)[4]))
compressedλmap(q::Quaternion) = begin
    #sigmoid(x::ℝ³) = exp.(vec(x)) ./ (1 .+ exp.(vec(x)))
    #ℝ³(2 .* (sigmoid(λmap(q)) .- 0.5))
    p = λmap(q)
    magnitude = norm(p)
    normalize(p) * tanh(magnitude)
end
λmap(s::S³) = λmap(Quaternion(s))
compressedλmap(s::S³) = compressedλmap(Quaternion(s))
