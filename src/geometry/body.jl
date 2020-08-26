export constructtriad
export constructtorus
export constructsphere
export constructcylinder
export constructbox
export getplane


"""
    constructtriad(q [; length])

Construct a triad with the given configuration `q` and `length`.
"""
function constructtriad(q::Biquaternion; length::Float64 = 1.0)
    map(x -> x + gettranslation(q), rotate(ℝ³.([[0; 0; 0], [length; 0; 0],
                                                [0; 0; 0], [0; length; 0],
                                                [0; 0; 0], [0; 0; length]]),
                                           getrotation(q)))
end


"""
    constructtorus(q, r, R)

Construct a torus of revolution with the given configuration `q`, the smaller radius `r`
and the bigger radius `R`.
"""
function constructtorus(q::Biquaternion,
                        r::Real,
                        R::Real;
                        segments::Int = 36)
    array = Array{ℝ³,2}(undef, segments, segments)
    for i in 1:segments
        for j in 1:segments
            ϕ = i * 2pi / (segments - 1)
            θ = j * 2pi / (segments - 1)
            x₁ = (R + r * cos(ϕ)) * cos(θ)
            x₂ = (R + r * cos(ϕ)) * sin(θ)
            x₃ = r * sin(ϕ)
            array[i, j] = ℝ³(x₁, x₂, x₃)
        end
    end
    map(x -> x + gettranslation(q), rotate(array, getrotation(q)))
end


"""
    constructsphere(q, radius)

Construct a sphere with the given configuration `q` and `radius`.
"""
function constructsphere(q::Biquaternion,
                         radius::Real;
                         segments::Int = 36)
    array = Array{ℝ³,2}(undef, segments, segments)
    lspace = collect(range(float(-pi), stop = float(pi), length = segments))
    for i in 1:segments
        for j in 1:segments
            ϕ = lspace[i]
            θ = lspace[j] / 2
            array[i, j] = ℝ³(Cartesian(Geographic(ϕ, θ))) * float(radius)
        end
    end
    map(x -> x + gettranslation(q), rotate(array, getrotation(q)))
end


"""
    constructcylinder(q, height, radius)

Construct a cylinder with the given configuration `q`, `height` and `radius`.
"""
function constructcylinder(q::Biquaternion,
                           height::Float64,
                           radius::Float64;
                           segments::Int = 36)
    array = Array{ℝ³,2}(undef, segments, segments)
    lspace = collect(range(float(-pi), stop = float(pi), length = segments))
    for i in 1:segments
        for j in 1:segments
            α = lspace[j]
            x₁ = radius * cos(α)
            x₂ = radius * sin(α)
            x₃ = (i - 1) * height / (segments - 1)
            array[i, j] = ℝ³(x₁, x₂, x₃)
        end
    end
    map(x -> x + gettranslation(q), rotate(array, getrotation(q)))
end


"""
    constructbox(p, q, s)

Construct a box with the given translation `p`, rotation `q` and scale `s`.
"""
function constructbox(p::ℝ³, q::Quaternion, s::ℝ³)
    x, y, z = vec(s) ./ 2
    points = [ℝ³(-x, -y, -z) ℝ³(x, -y, -z) ℝ³(-x, -y, -z) ℝ³(x, -y, -z);
              ℝ³(-x, -y, +z) ℝ³(x, -y, +z) ℝ³(-x, -y, +z) ℝ³(x, -y, +z);
              ℝ³(-x, +y, +z) ℝ³(x, +y, +z) ℝ³(-x, +y, +z) ℝ³(x, +y, +z);
              ℝ³(-x, +y, -z) ℝ³(x, +y, -z) ℝ³(-x, +y, -z) ℝ³(x, +y, -z)]
    map(x -> x + p, rotate(points, q))
end


getplane(p::Array{Float64}, q::Quaternion, s::Array{Float64}) = begin
    plane = Array{Float64,3}(undef, 2, 2, 3)
    plane[1, 1, :] = vec(rotate(ℝ³([0.0; -1.0; 1.0]), q)) .* s + p
    plane[1, 2, :] = vec(rotate(ℝ³([0.0; 1.0; 1.0]), q)) .* s + p
    plane[2, 1, :] = vec(rotate(ℝ³([0.0; -1.0; -1.0]), q)) .* s + p
    plane[2, 2, :] = vec(rotate(ℝ³([0.0; 1.0; -1.0]), q)) .* s + p
    plane
end
