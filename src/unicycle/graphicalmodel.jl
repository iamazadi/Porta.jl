using FileIO
using LinearAlgebra
using GLMakie

export Unicycle
export updatemodel
export mat33


x̂ = ℝ³([1.0; 0.0; 0.0])
ŷ = ℝ³([0.0; 1.0; 0.0])
ẑ = ℝ³([0.0; 0.0; 1.0])
ê = [Vec3f(vec(x̂)), Vec3f(vec(ŷ)), Vec3f(vec(ẑ))]


"""
    Represents the graphical components of a balancing unicycle.

fields: origin, pivot, p1, p2, B_O_R, O_B_R, A1_B_R, B_A1_R, A2_B_R, B_A2_R, P, X, sphere1, sphere2, graphpoints1, graphpoints2, graphpoints3,
        robot, rollingwheel, reactionwheel, acceleration_vector_tails, acceleration_vector_heads, sensor1frame_tails, sensor1frame_heads,
        sensor2frame_tails, sensor2frame_heads, pivot_ps, pivot_ns, pivot_observable, point1_observable, point2_observable, maxplotnumber,
        timeaxiswindow, chassisrotation, segments, arrowscale, smallarrowscale, axis1, axis2, and axis3.
"""
struct Unicycle
    origin::Point3f
    pivot::Point3f
    p1::Point3f
    p2::Point3f
    B_O_R::Matrix{Float64}
    O_B_R::Matrix{Float64}
    A1_B_R::Matrix{Float64}
    B_A1_R::Matrix{Float64}
    A2_B_R::Matrix{Float64}
    B_A2_R::Matrix{Float64}
    P::Matrix{Float64}
    X::Matrix{Float64}
    sphere1::Tuple{Observable{Matrix{Float64}}, Observable{Matrix{Float64}}, Observable{Matrix{Float64}}}
    sphere2::Tuple{Observable{Matrix{Float64}}, Observable{Matrix{Float64}}, Observable{Matrix{Float64}}}
    graphpoints1::Observable{Vector{Vector{Point{2, Float32}}}}
    graphpoints2::Observable{Vector{Vector{Point{2, Float32}}}}
    graphpoints3::Observable{Vector{Vector{Point{2, Float32}}}}
    robot::Mesh
    rollingwheel::Mesh
    reactionwheel::Mesh
    acceleration_vector_tails::Observable{Vector{Point{3, Float32}}}
    acceleration_vector_heads::Observable{Vector{Vec{3, Float32}}}
    sensor1frame_tails::Observable{Vector{Point{3, Float32}}}
    sensor1frame_heads::Observable{Vector{Vec{3, Float32}}}
    sensor2frame_tails::Observable{Vector{Point{3, Float32}}}
    sensor2frame_heads::Observable{Vector{Vec{3, Float32}}}
    pivot_ps::Observable{Vector{Point{3, Float32}}}
    pivot_ns::Observable{Vector{Vec{3, Float32}}}
    pivot_observable::Observable{Point{3, Float32}}
    point1_observable::Observable{Point{3, Float32}}
    point2_observable::Observable{Point{3, Float32}}
    maxplotnumber::Int
    timeaxiswindow::Float64
    chassisrotation::ℍ
    segments::Int
    arrowscale::Float64
    smallarrowscale::Float64
    axis1::Axis
    axis2::Axis
    axis3::Axis
    Unicycle(origin::Point3f, pivot::Point3f, p1::Point3f, p2::Point3f, B_O_R::Matrix{Float64}, B_A1_R::Matrix{Float64}, B_A2_R::Matrix{Float64},
             chassis_scale::Float64, rollingwheel_scale::Float64, reactionwheel_scale::Float64, rollingwheel_origin::Point3f,
             reactionwheel_origin::Point3f, chassis_stl_path::String, rollingwheel_stl_path::String, reactionwheel_stl_path::String,
             lscene::LScene, ax1::Axis, ax2::Axis, ax3::Axis, arrowscale::Float64, smallarrowscale::Float64, linewidth::Float64,
             arrowsize::Vec3f, markersize::Int, ballsize::Float64, segments::Int, chassis_colormap::Symbol, rollingwheel_colormap::Symbol,
             reactionwheel_colormap::Symbol, maxplotnumber::Int, timeaxiswindow::Float64) = begin

        P = [[1.0; vec(p1 - pivot)] [1.0; vec(p2 - pivot)]]
        X = transpose(P) * inv(P * transpose(P))

        chassis_origin = deepcopy(origin)        
        chassis_qx = ℍ(π / 2, x̂)
        chassis_qy = ℍ(0.0, ŷ)
        chassis_qz = ℍ(0.0, ẑ)
        chassis_q0 = chassis_qx * chassis_qy * chassis_qz
        chassisrotation = chassis_q0
        rollingwheel_qx = ℍ(0.0, x̂)
        rollingwheel_qy = ℍ(0.0, ŷ)
        rollingwheel_qz = ℍ(0.0, ẑ) # the axis of rotation
        rollingwheel_q0 = rollingwheel_qx * rollingwheel_qy * rollingwheel_qz
        rollingwheel_rotation = rollingwheel_q0
        reactionwheel_qx = ℍ(0.0, x̂)
        reactionwheel_qy = ℍ(0.0, ŷ)
        reactionwheel_qz = ℍ(0.0, ẑ) # the axis of rotation
        reactionwheel_q0 = reactionwheel_qx * reactionwheel_qy * reactionwheel_qz
        reactionwheel_rotation = reactionwheel_q0

        graphpoints1 = Observable([Point2f[(0, 0)], Point2f[(0, 0)]])
        graphpoints2 = Observable([Point2f[(0, 0)], Point2f[(0, 0)]])
        graphpoints3 = Observable([Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)], Point2f[(0, 0)]])

        x_euler_angle_raw_lineobject = scatter!(ax1, @lift(($graphpoints1)[1]), color=:green, markersize = markersize)
        y_euler_angle_raw_lineobject = scatter!(ax2, @lift(($graphpoints2)[1]), color=:blue, markersize = markersize)
        x_euler_angle_estimate_lineobject = scatter!(ax1, @lift(($graphpoints1)[2]), color=:lightgreen, markersize = markersize)
        y_euler_angle_estimate_lineobject = scatter!(ax2, @lift(($graphpoints2)[2]), color=:lightblue, markersize = markersize)
        P0_lineobject = scatter!(ax3, @lift(($graphpoints3)[1]), color=:lavenderblush, markersize = markersize)
        P1_lineobject = scatter!(ax3, @lift(($graphpoints3)[2]), color=:plum1, markersize = markersize)
        P2_lineobject = scatter!(ax3, @lift(($graphpoints3)[3]), color=:thistle, markersize = markersize)
        P3_lineobject = scatter!(ax3, @lift(($graphpoints3)[4]), color=:orchid2, markersize = markersize)
        P4_lineobject = scatter!(ax3, @lift(($graphpoints3)[5]), color=:mediumorchid1, markersize = markersize)
        P5_lineobject = scatter!(ax3, @lift(($graphpoints3)[6]), color=:magenta2, markersize = markersize)
        P6_lineobject = scatter!(ax3, @lift(($graphpoints3)[7]), color=:lavenderblush4, markersize = markersize)
        P7_lineobject = scatter!(ax3, @lift(($graphpoints3)[8]), color=:magenta3, markersize = markersize)
        P8_lineobject = scatter!(ax3, @lift(($graphpoints3)[9]), color=:plum4, markersize = markersize)
        P9_lineobject = scatter!(ax3, @lift(($graphpoints3)[10]), color=:mediumorchid4, markersize = markersize)
        P10_lineobject = scatter!(ax3, @lift(($graphpoints3)[11]), color=:mediumpurple4, markersize = markersize)
        P11_lineobject = scatter!(ax3, @lift(($graphpoints3)[12]), color=:purple4, markersize = markersize)
        # xeuler_lineobjects = [x_euler_angle_raw_lineobject, x_euler_angle_estimate_lineobject]
        # yeuler_lineobjects = [y_euler_angle_raw_lineobject, y_euler_angle_estimate_lineobject]
        # pmatrix_lineobjects = [P0_lineobject, P1_lineobject, P2_lineobject, P3_lineobject, P4_lineobject, P5_lineobject, P6_lineobject, P7_lineobject, P8_lineobject, P9_lineobject, P10_lineobject, P11_lineobject]

        chassis_stl = load(chassis_stl_path)
        reactionwheel_stl = load(reactionwheel_stl_path)
        rollingwheel_stl = load(rollingwheel_stl_path)

        pivot_observable = Observable(pivot)
        point1_observable = Observable(p1)
        point2_observable = Observable(p2)

        robot = make_sprite(lscene.scene, lscene.scene, chassis_origin, chassisrotation, chassis_scale, chassis_stl, chassis_colormap, transparency = true)
        rollingwheel = make_sprite(lscene.scene, robot, rollingwheel_origin, rollingwheel_rotation, rollingwheel_scale, rollingwheel_stl, rollingwheel_colormap, transparency = true)
        reactionwheel = make_sprite(lscene.scene, robot, reactionwheel_origin, reactionwheel_rotation, reactionwheel_scale, reactionwheel_stl, reactionwheel_colormap, transparency = true)

        pivotball = meshscatter!(lscene, pivot_observable, markersize=ballsize, color=:gold)

        R1 = [0.0; 0.0; -1.0] .* arrowscale
        R2 = [0.0; 0.0; -1.0] .* arrowscale
        R1_tail = vec(p1)
        R2_tail = vec(p2)

        acceleration_vector_tails = Observable([Point3f(R1_tail...), Point3f(R2_tail...)])
        acceleration_vector_heads = Observable([Vec3f(R1...), Vec3f(R2...)])
        acceleration_vector_colors = [:orange, :olive]
        arrows!(lscene,
            acceleration_vector_tails, acceleration_vector_heads, fxaa=true, # turn on anti-aliasing
            color = acceleration_vector_colors,
            linewidth=linewidth, arrowsize=arrowsize,
            align=:origin
        )

        pivotball = meshscatter!(lscene, pivot_observable, markersize = ballsize, color = :gold)
        ball1 = meshscatter!(lscene, point1_observable, markersize = ballsize, color = acceleration_vector_colors[1])
        ball2 = meshscatter!(lscene, point2_observable, markersize = ballsize, color = acceleration_vector_colors[2])

        pivot_ps = Observable([pivot_observable[], pivot_observable[], pivot_observable[]])
        pivot_ns = Observable(map(x -> x .* smallarrowscale, ê))
        sensor1frame_tails = Observable([point1_observable[], point1_observable[], point1_observable[]])
        sensor2frame_tails = Observable([point2_observable[], point2_observable[], point2_observable[]])
        sensor1frame_heads = Observable(map(x -> Vec3f(B_O_R * x .* smallarrowscale), [B_A1_R * ê[1], B_A1_R * ê[2], B_A1_R * ê[3]]))
        sensor2frame_heads = Observable(map(x -> Vec3f(B_O_R * x .* smallarrowscale), [B_A2_R * ê[1], B_A2_R * ê[2], B_A2_R * ê[3]]))

        arrowcolors = [:red, :green, :blue]
        arrows!(lscene,
            pivot_ps, pivot_ns, fxaa=true, # turn on anti-aliasing
            color = arrowcolors,
            linewidth = linewidth, arrowsize = arrowsize,
            align = :origin
        )
        arrows!(lscene,
            sensor1frame_tails, sensor1frame_heads, fxaa=true, # turn on anti-aliasing
            color = arrowcolors,
            linewidth = linewidth, arrowsize = arrowsize,
            align = :origin
        )
        arrows!(lscene,
            sensor2frame_tails, sensor2frame_heads, fxaa=true, # turn on anti-aliasing
            color = arrowcolors,
            linewidth = linewidth, arrowsize = arrowsize,
            align = :origin
        )

        lspaceθ = range(π / 2, stop = -π / 2, length = segments)
        lspaceϕ = range(-π, stop = float(π), length = segments)
        sphere_radius_p1 = norm(p1 - pivot)
        sphere_radius_p2 = norm(p2 - pivot)
        spherematrix_p1 = [ℝ³(p1) + convert_to_cartesian([sphere_radius_p1; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ]
        spherematrix_p2 = [ℝ³(p2) + convert_to_cartesian([sphere_radius_p2; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ]
        sphere_color_p1 = [RGBAf(1.0, 0.64, 0.0, 0.75) for ϕ in lspaceϕ, θ in lspaceθ]
        sphere_color_p2 = [RGBAf(0.5, 0.5, 0.0, 0.75) for ϕ in lspaceϕ, θ in lspaceθ]
        sphereobservable_p1 = buildsurface(lscene, spherematrix_p1, sphere_color_p1, transparency = true)
        sphereobservable_p2 = buildsurface(lscene, spherematrix_p2, sphere_color_p2, transparency = true)

        default_ylims = [-π / 8; π / 8]
        ylims!(ax1, default_ylims[1], default_ylims[2])
        ylims!(ax2, default_ylims[1], default_ylims[2])
        ylims!(ax3, -1e2, 1e2)
        O_B_R = convert(Matrix{Float64}, inv(B_O_R))
        A1_B_R = convert(Matrix{Float64}, inv(B_A1_R))
        A2_B_R = convert(Matrix{Float64}, inv(B_A2_R))
        new(origin, pivot, p1, p2, B_O_R, O_B_R, A1_B_R, B_A1_R, A2_B_R, B_A2_R, P, X, sphereobservable_p1, sphereobservable_p2,
            graphpoints1, graphpoints2, graphpoints3, robot, rollingwheel, reactionwheel, acceleration_vector_tails,
            acceleration_vector_heads, sensor1frame_tails, sensor1frame_heads, sensor2frame_tails, sensor2frame_heads,
            pivot_ps, pivot_ns, pivot_observable, point1_observable, point2_observable, maxplotnumber, timeaxiswindow, chassisrotation,
            segments, arrowscale, smallarrowscale, ax1, ax2, ax3)
    end
end


"""
    mat33(q)

Convert the given Quaternion number `q` to a three by three square matrix representation.
"""
function mat33(q::ℍ)
    qw, qx, qy, qz = vec(q)
    [1.0-2(qy^2)-2(qz^2) 2qx*qy-2qz*qw 2qx*qz+2qy*qw;
        2qx*qy+2qz*qw 1.0-2(qx^2)-2(qz^2) 2qy*qz-2qx*qw;
        2qx*qz-2qy*qw 2qy*qz+2qx*qw 1.0-2(qx^2)-2(qy^2)]
end


function updatemodel(unicycle::Unicycle, readings::Dict)
    acc1 = [readings["AX1"]; readings["AY1"]; readings["AZ1"]]
    acc2 = [readings["AX2"]; readings["AY2"]; readings["AZ2"]]
    P0 = readings["P0"]
    P1 = readings["P1"]
    P2 = readings["P2"]
    P3 = readings["P3"]
    P4 = readings["P4"]
    P5 = readings["P5"]
    P6 = readings["P6"]
    P7 = readings["P7"]
    P8 = readings["P8"]
    P9 = readings["P9"]
    P10 = readings["P10"]
    P11 = readings["P11"]
    roll = readings["roll"]
    pitch = readings["pitch"]
    rolling_angle = readings["encB"]
    reaction_angle = -readings["encT"]

    R1 = acc1
    R2 = acc2

    # M = [B_A1_R * R1 B_A2_R * R2]
    # ĝ = (M*X)[:, 1]
    ĝ = deepcopy(R1)
    β = atan(-ĝ[1], √(ĝ[2]^2 + ĝ[3]^2))
    γ = atan(ĝ[2], ĝ[3])

    x_euler_angle_raw = β
    x_euler_angle_estimate = roll
    y_euler_angle_raw = -γ
    y_euler_angle_estimate = pitch
    # @assert(isapprox(β, roll, atol = 1e-2), "The roll angle $roll is not equal to beta $β.")
    # @assert(isapprox(-γ, pitch, atol = 1e-2), "The pitch angle $pitch is not equal to minus gamma -$γ.")
    # println("roll: $roll, γ: $γ, pitch: $pitch, β: $β.")
    # println("x_euler_angle_raw: $x_euler_angle_raw, x_euler_angle_estimate: $x_euler_angle_estimate, y_euler_angle_raw: $y_euler_angle_raw, y_euler_angle_estimate: $y_euler_angle_estimate.")
    q = ℍ(roll, x̂) * ℍ(pitch, ŷ)
    # O_B_R = unicycle.O_B_R * mat33(q)
    O_B_R = mat33(q)
    B_O_R = inv(O_B_R)

    # g = q * chassis_q0
    # rotate!(robot, Quaternion(g))
    unicycle.pivot_observable[] = Point3f(O_B_R * (unicycle.pivot - unicycle.origin) + unicycle.origin)
    unicycle.point1_observable[] = Point3f(O_B_R * (unicycle.p1 - unicycle.origin) + unicycle.origin)
    unicycle.point2_observable[] = Point3f(O_B_R * (unicycle.p2 - unicycle.origin) + unicycle.origin)

    sphere_radius_p1 = norm(unicycle.p1 - unicycle.pivot)
    sphere_radius_p2 = norm(unicycle.p2 - unicycle.pivot)
    lspaceθ = range(π / 2, stop = -π / 2, length = unicycle.segments)
    lspaceϕ = range(-π, stop = float(π), length = unicycle.segments)
    matrix1 = [ℝ³(to_value(unicycle.point1_observable)) + convert_to_cartesian([sphere_radius_p1; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ]
    matrix2 = [ℝ³(to_value(unicycle.point2_observable)) + convert_to_cartesian([sphere_radius_p2; θ; ϕ]) for ϕ in lspaceϕ, θ in lspaceθ]
    updatesurface!(matrix1, unicycle.sphere1)
    updatesurface!(matrix2, unicycle.sphere2)

    unicycle.acceleration_vector_tails[] = [Point3f(unicycle.point1_observable[]...), Point3f(unicycle.point2_observable[]...)]
    unicycle.acceleration_vector_heads[] = map(x -> x .* unicycle.arrowscale, [Vec3f(O_B_R * unicycle.B_A1_R * R1...), Vec3f(O_B_R * unicycle.B_A2_R * R2...)])

    unicycle.sensor1frame_tails[] = [Point3f(unicycle.point1_observable[]...), Point3f(unicycle.point1_observable[]...), Point3f(unicycle.point1_observable[]...)]
    unicycle.sensor2frame_tails[] = [Point3f(unicycle.point2_observable[]...), Point3f(unicycle.point2_observable[]...), Point3f(unicycle.point2_observable[]...)]

    unicycle.sensor1frame_heads[] = map(x -> Vec3f(O_B_R * x .* norm(R1) .* unicycle.smallarrowscale), [unicycle.B_A1_R * ê[1], unicycle.B_A1_R * ê[2], unicycle.B_A1_R * ê[3]])
    unicycle.sensor2frame_heads[] = map(x -> Vec3f(O_B_R * x .* norm(R2) .* unicycle.smallarrowscale), [unicycle.B_A2_R * ê[1], unicycle.B_A2_R * ê[2], unicycle.B_A2_R * ê[3]])

    # plot the x-Euler and y-Euler angles
    _graphpoints1 = unicycle.graphpoints1[]
    _graphpoints2 = unicycle.graphpoints2[]
    _x_euler_angle_raw_points = _graphpoints1[1]
    _y_euler_angle_raw_points = _graphpoints2[1]
    _x_euler_angle_estimate_points = _graphpoints1[2]
    _y_euler_angle_estimate_points = _graphpoints2[2]
    timestamp = readings["time"] 
    push!(_x_euler_angle_raw_points, Point2f(timestamp, x_euler_angle_raw))
    push!(_y_euler_angle_raw_points, Point2f(timestamp, y_euler_angle_raw))
    push!(_x_euler_angle_estimate_points, Point2f(timestamp, x_euler_angle_estimate))
    push!(_y_euler_angle_estimate_points, Point2f(timestamp, y_euler_angle_estimate))
    # plot the P Matrix
    _graphpoints3 = unicycle.graphpoints3[]
    _P0points = _graphpoints3[1]
    _P1points = _graphpoints3[2]
    _P2points = _graphpoints3[3]
    _P3points = _graphpoints3[4]
    _P4points = _graphpoints3[5]
    _P5points = _graphpoints3[6]
    _P6points = _graphpoints3[7]
    _P7points = _graphpoints3[8]
    _P8points = _graphpoints3[9]
    _P9points = _graphpoints3[10]
    _P10points = _graphpoints3[11]
    _P11points = _graphpoints3[12]
    push!(_P0points, Point2f(timestamp, P0))
    push!(_P1points, Point2f(timestamp, P1))
    push!(_P2points, Point2f(timestamp, P2))
    push!(_P3points, Point2f(timestamp, P3))
    push!(_P4points, Point2f(timestamp, P4))
    push!(_P5points, Point2f(timestamp, P5))
    push!(_P6points, Point2f(timestamp, P6))
    push!(_P7points, Point2f(timestamp, P7))
    push!(_P8points, Point2f(timestamp, P8))
    push!(_P9points, Point2f(timestamp, P9))
    push!(_P10points, Point2f(timestamp, P10))
    push!(_P11points, Point2f(timestamp, P11))
    number = length(_x_euler_angle_raw_points)
    maxplotnumber = unicycle.maxplotnumber
    if number > maxplotnumber
        _x_euler_angle_raw_points = _x_euler_angle_raw_points[number-maxplotnumber+1:end]
        _y_euler_angle_raw_points = _y_euler_angle_raw_points[number-maxplotnumber+1:end]
        _x_euler_angle_estimate_points = _x_euler_angle_estimate_points[number-maxplotnumber+1:end]
        _y_euler_angle_estimate_points = _y_euler_angle_estimate_points[number-maxplotnumber+1:end]
        # P matrix graph
        _P0points = _P0points[number-maxplotnumber+1:end]
        _P1points = _P1points[number-maxplotnumber+1:end]
        _P2points = _P2points[number-maxplotnumber+1:end]
        _P3points = _P3points[number-maxplotnumber+1:end]
        _P4points = _P4points[number-maxplotnumber+1:end]
        _P5points = _P5points[number-maxplotnumber+1:end]
        _P6points = _P6points[number-maxplotnumber+1:end]
        _P7points = _P7points[number-maxplotnumber+1:end]
        _P8points = _P8points[number-maxplotnumber+1:end]
        _P9points = _P9points[number-maxplotnumber+1:end]
        _P10points = _P10points[number-maxplotnumber+1:end]
        _P11points = _P11points[number-maxplotnumber+1:end]
        @assert(length(_x_euler_angle_raw_points) == maxplotnumber)
        unicycle.graphpoints1[] = [_x_euler_angle_raw_points, _x_euler_angle_estimate_points]
        unicycle.graphpoints2[] = [_y_euler_angle_raw_points, _y_euler_angle_estimate_points]
        unicycle.graphpoints3[] = [_P0points, _P1points, _P2points, _P3points, _P4points, _P5points, _P6points, _P7points, _P8points, _P9points, _P10points, _P11points]
    else
        unicycle.graphpoints1[] = [_x_euler_angle_raw_points, _x_euler_angle_estimate_points]
        unicycle.graphpoints2[] = [_y_euler_angle_raw_points, _y_euler_angle_estimate_points]
        unicycle.graphpoints3[] = [_P0points, _P1points, _P2points, _P3points, _P4points, _P5points, _P6points, _P7points, _P8points, _P9points, _P10points, _P11points]
    end
    P_parameters = []
    for x in to_value(unicycle.graphpoints3[])
        for y in x
            push!(P_parameters, y[2])
        end
    end
    timeaxiswindow = unicycle.timeaxiswindow
    xlims!(unicycle.axis1, timestamp - timeaxiswindow, timestamp)
    xlims!(unicycle.axis2, timestamp - timeaxiswindow, timestamp)
    xlims!(unicycle.axis3, timestamp - timeaxiswindow, timestamp)
    ylims1 = [min(map(x -> x[2], _x_euler_angle_estimate_points)...) - 0.01; max(map(x -> x[2], _x_euler_angle_estimate_points)...) + 0.01]
    ylims2 = [min(map(x -> x[2], _y_euler_angle_estimate_points)...) - 0.01; max(map(x -> x[2], _y_euler_angle_estimate_points)...) + 0.01]
    ylims3 = [min(P_parameters...) - 0.01; max(P_parameters...) + 0.01]
    ylims!(unicycle.axis1, ylims1[1], ylims1[2])
    ylims!(unicycle.axis2, ylims2[1], ylims2[2])
    ylims!(unicycle.axis3, ylims3[1], ylims3[2])
    #######

    # q = ℍ(roll, x̂) * ℍ(pitch, ŷ)
    # O_B_R = mat3(q)

    g = q * unicycle.chassisrotation
    GLMakie.rotate!(unicycle.robot, Quaternion(g))
    unicycle.pivot_observable[] = Point3f(O_B_R * (unicycle.pivot - unicycle.origin) + unicycle.origin)

    unicycle.pivot_ps[] = [Point3f(unicycle.pivot_observable[]...), Point3f(unicycle.pivot_observable[]...), Point3f(unicycle.pivot_observable[]...)]
    unicycle.pivot_ns[] = map(x -> Vec3f(B_O_R * x .* unicycle.smallarrowscale), ê)
    rq = Quaternion(ℍ(reaction_angle, x̂))
    mq = Quaternion(ℍ(rolling_angle, ẑ))
    GLMakie.rotate!(unicycle.rollingwheel, mq)
    GLMakie.rotate!(unicycle.reactionwheel, rq)
end