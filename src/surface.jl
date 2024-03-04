import GLMakie


export getsurface
export buildsurface
export updatesurface!


"""
    getsurface(observables, segments1, segments2)

Get the matrix of points of a 2-surface with the given tuple of `observables`, and the number of `segments1` and `segments2`.
"""
function getsurface(observable::Tuple{GLMakie.Observable{Matrix{Float64}},
                                      GLMakie.Observable{Matrix{Float64}},
                                      GLMakie.Observable{Matrix{Float64}}},
                    segments1::Int,
                    segments2::Int)
    y₁, y₂, y₃ = map(x -> GLMakie.to_value(x), observable)
    value = Matrix{Vector{<:Real}}(undef, segments1, segments2)
    for i in 1:segments1
        for j in 1:segments2
            index = (j - 1) * segments1 + i
            value[i, j] = [y₁[index]; y₂[index]; y₃[index]]
        end
    end
    value
end


"""
    buildsurface(scene, value, color, transparency)

Build a surface with the given `scene`, `value`, `color` and `transparency`.
"""
function buildsurface(scene::GLMakie.LScene,
                      value::Matrix{<:Vector{<:Real}},
                      color::Any;
                      transparency::Bool = false)
    x = GLMakie.Observable(map(x -> x[1] , value))
    y = GLMakie.Observable(map(x -> x[2] , value))
    z = GLMakie.Observable(map(x -> x[3] , value))
    GLMakie.surface!(scene, x, y, z, color = color, transparency = transparency)
    x, y, z
end


"""
    buildsurface(scene, value, color, visible, transparency)

Build a surface with the given `scene`, `value`, `color`, `visible` and `transparency`.
"""
function buildsurface(scene::GLMakie.LScene,
                      value::Matrix{<:Vector{<:Real}},
                      color::Any,
                      visible::GLMakie.Observable{Bool};
                      transparency::Bool = false)
    x = GLMakie.Observable(map(x -> x[1] , value))
    y = GLMakie.Observable(map(x -> x[2] , value))
    z = GLMakie.Observable(map(x -> x[3] , value))
    GLMakie.surface!(scene, x, y, z, color = color, transparency = transparency, visible = visible)
    x, y, z
end


"""
    updatesurface!(value, observable)

Update a surface with the given `value` and `observable`.
"""
function updatesurface!(value::Matrix{<:Vector{<:Real}},
                        observable::Tuple{GLMakie.Observable{Matrix{Float64}},
                                          GLMakie.Observable{Matrix{Float64}},
                                          GLMakie.Observable{Matrix{Float64}}})
    x, y, z = observable
    x[] = map(x -> x[1], value)
    y[] = map(x -> x[2], value)
    z[] = map(x -> x[3], value)
end