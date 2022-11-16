export constructtriad
export constructtorus
export constructsphere
export constructcylinder
export constructbox
export constructwhirl
export constructframe
export getplane
export constructfiber
export constructtwospinor
export transformg


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
    lspace1 = collect(range(float(π / 2), stop = float(-π / 2), length = segments))
    for i in 1:segments
        for j in 1:segments
            ϕ = lspace[i]
            θ = lspace1[j]
            array[j, i] = ℝ³(Cartesian(Geographic(radius, ϕ, θ)))
        end
    end
    map(x -> x + gettranslation(q), rotate(array, getrotation(q)))
end


"""
    constructhemisphere(q, radius)

Construct a hemisphere with the given configuration `q` and `radius`.
"""
function constructhemisphere(q::Biquaternion,
                             radius::Real;
                             segments::Int = 36)
    array = Array{ℝ³,2}(undef, segments, segments)
    lspace = collect(range(float(pi), stop = float(-pi), length = segments))
    lspace1 = collect(range(float(π / 2), stop = 0, length = segments))
    for i in 1:segments
        for j in 1:segments
            ϕ = lspace[i]
            θ = lspace1[j]
            array[j, i] = ℝ³(Cartesian(Geographic(radius, ϕ, θ)))
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


"""
    getactions(point,
               s2tos3map,
               s2tos2map;
               [top, [bottom, [s3rotation, [segments [, scale]]]]])

Take the integral along the Hopf fiber for getting a linear action space
under stereographic projection, with the given 'point' in the base space,
a map from the base space to the total space `s2tos3map`, a conformal map that
takes the base space to itself `s2tos2map`, `top` and `bottom` U(1) actions,
S³ rotation `s3rotation`, the number of `segments` and `scale`.
"""
function getactions(point::S²,
                    s2tos3map,
                    s2tos2map;
                    top::S¹ = U1(-pi),
                    bottom::S¹ = U1(pi),
                    s3rotation::S³ = Quaternion(1, 0, 0, 0),
                    segments::Int = 30,
                    scale::Real = 1.0)
    segments2 = 1000
    array = Array{Float64,2}(undef, segments2, 2)
    minaction = -π
    maxaction = π
    lspace = collect(range(minaction, stop = maxaction, length = segments2))
    array[:, begin] = lspace
    accumulator = 0
    getp(point, α, rotation, scale) = compressedλmap(rotate(S¹action(s2tos3map(s2tos2map(point)), U1(α)), rotation)) * scale
    α₁ = lspace[begin]
    p₁ = getp(point, α₁, s3rotation, scale)
    for i in 1:segments2
        α₂ = lspace[i]
        p₂ = getp(point, α₂, s3rotation, scale)
        accumulator += norm(p₂ - p₁)
        array[i, end] = accumulator
        α₁ = α₂
        p₁ = p₂
    end
    
    # decide based on cumulative length and then pick the corresponding actions from the array
    totalspan = maxaction - minaction
    normalizedtop = angle(top) / totalspan
    normalizedbottom = angle(bottom) / totalspan
    normalizedsegmentlength = (normalizedbottom - normalizedtop) / (segments - 1)
    actions = Array{Float64,1}(undef, segments)
    for i in 1:segments
        target = (normalizedtop + normalizedsegmentlength * (i - 1)) * accumulator
        for j in 1:segments2
            if array[j, end] ≥ target
                actions[i] = array[j, begin]
                break
            end
        end
    end
    actions
end


"""
    transformg(p, g₁, g₂, segments)

Transform G-acions by finding and applying affine parameters with the given point `p`
in the principal bundle, beginning gauge potential `g₁`, ending gauge potential `g₂`
and the number of segments.
"""
function transformg(p::ComplexPlane, g₁::U1, g₂::U1, segments::Int)
    intervals = 1000
    array = Array{Float64,2}(undef, intervals, 2)
    minaction, maxaction = 0, 2π
    lspace = collect(range(minaction, stop = maxaction, length = intervals))
    array[:, begin] = lspace
    accumulator = 0
    α₁ = lspace[begin]
    z = λ⁻¹map(πmap(Quaternion(p)))
    p₁ = compressedλmap(S¹action(z, U1(α₁)))
    array[begin, end] = 0
    for i in 2:intervals
        α₂ = lspace[i]
        p₂ = compressedλmap(S¹action(p, U1(α₂)))
        accumulator += norm(p₂ - p₁)
        array[i, end] = accumulator
        α₁ = α₂
        p₁ = p₂
    end
    
    # decide based on cumulative length and then pick the corresponding actions from the array
    totalspan = maxaction - minaction
    n₁ = angle(g₁) / totalspan
    n₂ = angle(g₂) / totalspan
    normalizedsegmentlength = (n₂ - n₁) / (segments - 1)
    actions = Array{U1,1}(undef, segments)
    for i in 1:segments
        target = (n₁ + normalizedsegmentlength * (i - 1)) * accumulator
        for j in 1:intervals
            if array[j, end] ≥ target
                actions[i] = U1(array[j, begin])
                break
            end
        end
    end
    actions
end


"""
    constructwhirl(points, gauge1, gauge2, configuration, segments, scale)

Construct a whirl with the given `points`, `gauge1`, `gauge2`, `configuration`, `segments` and `scale`.
"""
function constructwhirl(points::Array{ComplexPlane,1},
                        gauge1::Array{U1,1},
                        gauge2::Array{U1,1},
                        configuration::Biquaternion,
                        segments::Int,
                        scale::Float64)
    array = Array{ℝ³,2}(undef, length(points), segments)
    for (j, p) in enumerate(points)
        g₁ = gauge1[j]
        g₂ = gauge2[j]
        g = transformg(p, g₁, g₂, segments)
        for (i, α) in enumerate(g)
            array[j, i] = compressedλmap(S¹action(p, α)) * scale
        end
    end
    array = applyconfig(array, configuration)
    convert(Matrix{ℝ³}, array)
end


"""
    constructframe(section, configuration, segments, scale)

Construct a frame that is like an S³ cross-section under stereographic projection with the
given `section`, `configuration`, `segments` and `scale`.
"""
function constructframe(section::Any,
                        configuration::Biquaternion,
                        segments::Int,
                        scale::Float64)
    array = Array{ℝ³,2}(undef, segments, segments)
    lspaceϕ = collect(range(float(-pi), stop = float(pi), length = segments))
    lspaceθ = collect(range(float(pi / 2), stop = float(-pi / 2), length = segments))
    for (i, θ) in enumerate(lspaceθ)
        for (j, ϕ) in enumerate(lspaceϕ)
            p = Geographic(1, ϕ, θ)
            array[i, j] = compressedλmap(section(p)) * scale
        end
    end
    applyconfig(array, configuration)
end


"""
    constructfiber(point,
                   s2tos3map,
                   s2tos2map;
                   [radius, [top, [bottom, [s3rotation, [config, [segments [, scale]]]]]]])

Construct a Hopf fiber with the given `point` in the base space, , a map from the base space to
the total space `s2tos3map`, a conformal map that takes the base space to itself `s2tos2map`,
fiber sectional `radius`, `top` and `bottom` U(1) actions, S³ rotation `s3rotation`,
configuration `config`, the number of `segments` and `scale`.
"""
function constructfiber(point::S²,
                        s2tos3map,
                        s2tos2map;
                        radius::Float64 = 0.02,
                        top::S¹ = U1(-pi),
                        bottom::S¹ = U1(pi),
                        s3rotation::S³ = Quaternion(1, 0, 0, 0),
                        config::Biquaternion = Biquaternion(ℝ³(0, 0, 0)),
                        segments::Int = 30,
                        scale::Real = 1.0)
    segments2 = 10
    α₁ = U1(min(angle(top), angle(bottom)))
    α₂ = U1(max(angle(top), angle(bottom)))
    circle = [ℝ³(cos(α), sin(α), 0) for α in range(0, stop = 2π, length = segments2)] .* radius
    actions = getactions(point, s2tos3map, s2tos2map, top = α₁, bottom = α₂, s3rotation = s3rotation, segments = segments, scale = scale)
    getp(point, α, rotation, scale) = compressedλmap(rotate(S¹action(s2tos3map(s2tos2map(point)), U1(α)), rotation)) * scale
    array = Array{ℝ³,2}(undef, segments, segments2)
    n = ℝ³(0, 0, 1)
    for (i, α) in enumerate(actions)
        p₁ = getp(point, α, s3rotation, scale)
        p₂ = getp(point, α + α * 1e-2, s3rotation, scale)
        w = normalize(p₂ - p₁)
        q = Biquaternion(getrotation(n, w), p₁)
        array[i, :] = applyconfig(circle, q)
    end
    applyconfig(array, config)
end


"""
    constructtwospinor(point, gauge1, gauge2, configuration, radius, segments1, segments2)

Construct a 2-spinor with the given `point` in the principal bundle, `gauge1`, `gauge2`,
`configuration`, `radius`, `segments1` and `segments2`.
"""
function constructtwospinor(point::ComplexPlane, gauge1::U1, gauge2::U1, configuration::Biquaternion,
                            radius::Float64, segments1::Int, segments2::Int)
    angles = angle.([gauge1; gauge2])
    g₁, g₂ = U1(min(angles...)), U1(max(angles...))
    circle = [ℝ³(cos(α), sin(α), 0) for α in range(0, stop = 2π, length = segments2)] .* radius
    actions = transformg(point, g₁, g₂, segments1)
    getp(p::ComplexPlane, g::U1) = compressedλmap(S¹action(p, g))
    array = Array{ℝ³,2}(undef, segments1, segments2)
    n = ℝ³(0, 0, 1)
    ϵ = 1e-2
    for (i, g) in enumerate(actions)
        p₁ = getp(point, g)
        p₂ = getp(point, U1(angle(g) + ϵ))
        w = normalize(p₂ - p₁)
        q = Biquaternion(getrotation(n, w), p₁)
        array[i, :] = applyconfig(circle, q)
    end
    applyconfig(array, configuration)
end


getplane(p::Array{Float64}, q::Quaternion, s::Array{Float64}) = begin
    plane = Array{Float64,3}(undef, 2, 2, 3)
    plane[1, 1, :] = vec(rotate(ℝ³([0.0; -1.0; 1.0]), q)) .* s + p
    plane[1, 2, :] = vec(rotate(ℝ³([0.0; 1.0; 1.0]), q)) .* s + p
    plane[2, 1, :] = vec(rotate(ℝ³([0.0; -1.0; -1.0]), q)) .* s + p
    plane[2, 2, :] = vec(rotate(ℝ³([0.0; 1.0; -1.0]), q)) .* s + p
    plane
end
