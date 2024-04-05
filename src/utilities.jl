export convert_hsvtorgb
export project


"""
   hsvtorgb(color)

Convert a `color` from HSV space to RGB.
"""
convert_hsvtorgb(color) = begin
    H, S, V = color
    C = V * S
    X = C * (1 - Base.abs((H / 60) % 2 - 1))
    m = V - C
    if 0 ≤ H < 60
        R′, G′, B′ = C, X, 0
    elseif 60 ≤ H < 120
        R′, G′, B′ = X, C, 0
    elseif 120 ≤ H < 180
        R′, G′, B′ = 0, C, X
    elseif 180 ≤ H < 240
        R′, G′, B′ = 0, X, C
    elseif 240 ≤ H < 300
        R′, G′, B′ = X, 0, C
    elseif 300 ≤ H < 360
        R′, G′, B′ = C, 0, X
    else
        R′, G′, B′ = rand(3)
    end
    R, G, B = R′ + m, G′ + m, B′ + m
    [R; G; B]
end


"""
    project(q)

Take the given point `q` ∈ S³ ⊂ ℂ² into the Euclidean space E³ ⊂ ℝ³ using stereographic projection.
"""
function project(q::Quaternion)
    v = ℝ³(vec(q)[2], vec(q)[3], vec(q)[4]) * (1.0 / (1.0 - vec(q)[1]))
    normalize(v) * tanh(norm(v))
end