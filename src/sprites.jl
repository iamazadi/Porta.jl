export constructtorus
export constructsphere


"""
    constructtorus(q, r, R)

Construct a torus of revolution with the given configuration `q`, the smaller radius `r`
and the bigger radius `R`.
"""
function constructtorus(q::Dualquaternion,
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
function constructsphere(q::Dualquaternion,
                         radius::Real;
                         segments::Int = 36)
    array = Array{ℝ³,2}(undef, segments, segments)
    lspace = collect(range(float(-pi), stop = float(pi), length = segments))
    lspace1 = collect(range(float(π / 2), stop = float(-π / 2), length = segments))
    for i in 1:segments
        for j in 1:segments
            ϕ = lspace[i]
            θ = lspace1[j]
            array[j, i] = convert_to_cartesian([radius; θ; ϕ])
        end
    end
    map(x -> x + gettranslation(q), rotate(array, getrotation(q)))
end