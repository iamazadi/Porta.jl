import GLMakie
import FileIO
import Makie
import MeshIO
import GeometryBasics
import LinearAlgebra
import GLMakie.Quaternion
using Sockets
using Porta


GLMakie.Quaternion(q::Porta.Quaternion) = GLMakie.Quaternion(vec(q)[2:4]..., vec(q)[1])


parse3vector(text::String, beginninglabel::String, endinglabel::String, delimiter::String) = begin
    vector = []
    index = findfirst(beginninglabel, text)
    if !isnothing(index)
        _text = replace(text, text[begin:index[end]] => "")
        if length(_text) > 3
            index = findfirst(endinglabel, _text)
            if !isnothing(index)
                _text = replace(_text, _text[index[begin]:end] => "")
                if length(_text) > 3
                    _text = strip(_text)
                    items = split(_text, delimiter)
                    try
                        push!(vector, parse(Float64, items[1]))
                        push!(vector, parse(Float64, items[2]))
                        push!(vector, parse(Float64, items[3]))
                    catch e
                        println("Not parsed: $_text. $e")
                    end
                end
            end
        end
    end
    vector
end


parsescalar(text::String, beginninglabel::String, endinglabel::String; type::DataType = Int) = begin
    scalar = Nothing
    index = findfirst(beginninglabel, text)
    if !isnothing(index)
        _text = replace(text, text[begin:index[end]] => "")
        if length(_text) > 1
            index = findfirst(endinglabel, _text)
            if !isnothing(index)
                _text = replace(_text, _text[index[begin]:end] => "")
                if length(_text) > 0
                    _text = strip(_text)
                    try
                        scalar = parse(type, _text)
                    catch e
                        println("Not parsed: $_text. $e")
                    end
                end
            end
        end
    end
    scalar
end


parsetext(text::String) = begin
    readings = Dict()
    if length(text) > 30
        vector = parse3vector(text, "A1: ", "A2: ", ",")
        if length(vector) == 3
            readings["R1"] = vector
        end
        vector = parse3vector(text, "A2: ", "A3: ", ",")
        if length(vector) == 3
            readings["R2"] = vector
        end
        vector = parse3vector(text, "A3: ", "A4: ", ",")
        if length(vector) == 3
            readings["R3"] = vector
        end
        vector = parse3vector(text, "A4: ", "c1: ", ",")
        if length(vector) == 3
            readings["R4"] = vector
        end
        scalar = parsescalar(text, "c1: ", ", ")
        if !isnothing(scalar)
            readings["v1"] = scalar
        end
        scalar = parsescalar(text, "c2: ", ", ")
        if !isnothing(scalar)
            readings["v2"] = scalar
        end
    end
    readings
end


rotate(point::Vector{Float64}, q::Porta.Quaternion) = vec(conj(q) * Porta.Quaternion(0.0, (point)...) * q)[2:4]


mat33(q::Porta.Quaternion) = begin
    qw, qx, qy, qz = vec(q)
    [1.0 - 2(qy^2) - 2(qz^2) 	2qx * qy - 2qz * qw 	2qx * qz + 2qy * qw;
     2qx * qy + 2qz * qw 	1.0 - 2(qx^2) - 2(qz^2) 	2qy * qz - 2qx * qw;
     2qx * qz - 2qy * qw 	2qy * qz + 2qx * qw 	1.0 - 2(qx^2) - 2(qy^2)]
end


find_centerofmass(stl) = begin
    center_of_mass = [0.0; 0.0; 0.0]
    points_number = 0
    for tri in stl
        for point in tri
            center_of_mass = center_of_mass + point
            points_number += 1
        end
    end
    center_of_mass .* (1.0 / points_number)
end


make_sprite(scene, parent, origin, rotation, scale, stl, colormap) = begin
    center_of_mass = find_centerofmass(stl)
    # Create a child transformation from the parent
    child = GLMakie.Transformation(parent)
    # get the transformation of the parent
    ptrans = Makie.transformation(parent)

    # center the mesh to its origin, if we have one
    if !isnothing(origin)
        GLMakie.rotate!(child, rotation)
        GLMakie.scale!(child, scale, scale, scale)
        centered = stl.position .- GLMakie.Point3f(center_of_mass...)
        stl = GeometryBasics.Mesh(GeometryBasics.meta(centered; normals=stl.normals), GeometryBasics.faces(stl))
        GLMakie.translate!(child, origin) # translates the visual mesh in the viewport
    else
        # if we don't have an origin, we need to correct for the parents translation
        GLMakie.translate!(child, -ptrans.translation[])
    end
    # plot the part with transformation & color
    GLMakie.mesh!(scene, stl; color = [tri[1][2] for tri in stl for i in 1:3], colormap = colormap, transformation = child)
end
