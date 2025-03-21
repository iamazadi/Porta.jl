import GeometryBasics
import GLMakie


export make_sprite
export parsetext
export parsescalar


"""
    find_centerofmass(stl)

Calculate the center of mass of a three-dimensional object with the given `stl` data.
"""
function find_centerofmass(stl::GeometryBasics.Mesh)
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


"""
    make_sprite(scene, parent, origin, rotation, scale, stl, colormap)

Instantiate a visual object in the `scene` with the given `parent` instance,
`origin` position, `rotation`, `scale`, `stl` object 3D file and `colormap`.
"""
function make_sprite(scene::GLMakie.Scene, parent::Any, origin::GLMakie.Point3f,
    rotation::ℍ, scale::Float64, stl::GeometryBasics.Mesh, colormap::Symbol)
    # the type of the parent object should be Union{GLMakie.Mesh, GLMakie.Scene}
    center_of_mass = find_centerofmass(stl)
    # Create a child transformation from the parent
    child = GLMakie.Transformation(parent)
    # get the transformation of the parent
    ptrans = GLMakie.Transformation(parent)

    # center the mesh to its origin, if we have one
    if !isnothing(origin)
        GLMakie.rotate!(child, GLMakie.Quaternion(rotation))
        GLMakie.scale!(child, scale, scale, scale)
        centered = stl.position .- GLMakie.Point3f(center_of_mass...)
        stl = GeometryBasics.Mesh(GeometryBasics.meta(centered, normals = stl.normals), GeometryBasics.faces(stl))
        GLMakie.translate!(child, origin) # translates the visual mesh in the viewport
    else
        # if we don't have an origin, we need to correct for the parents translation
        GLMakie.translate!(child, -ptrans.translation[])
    end
    # plot the part with transformation & color
    GLMakie.mesh!(scene, stl; color = [tri[1][2] for tri in stl for i in 1:3], colormap = colormap, transformation = child)
end


"""
    parsescalar(text, beginninglabel, endinglabel)

Parse a scalar value that begins with `beginninglabel` and ends with `endinglabel`, with the given `text` string.
"""
parsescalar(text::String, beginninglabel::String, endinglabel::String; type::DataType = Int) = begin
    scalar = nothing
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


"""
    parsetext(text, headers)

Parse the values of robot telemetry with the given `text` and `headers` list.
"""
parsetext(text::String, headers::Vector{String}) = begin
    readings = Dict()
    if length(text) > 30
        for header in eachindex(headers)
            scalar = parsescalar(text, "$(headers[header]): ", ", ", type = Float64)
            if !isnothing(scalar)
                readings[headers[header]] = scalar
            end
        end
    end
    readings
end