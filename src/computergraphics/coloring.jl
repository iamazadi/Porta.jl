export hsvtorgb


"""
   hsvtorgb(color)

Convert a `color` from HSV space to RGB.
"""
hsvtorgb(color) = begin
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
