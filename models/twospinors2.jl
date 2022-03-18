import LinearAlgebra
import FileIO
import GeometryBasics
import Observables
import Makie
import GLMakie

using Porta


startframe = 1
FPS = 60
resolution = (3840, 2160)
segments1 = 48
segments2 = 9
speed = 1
factor = 0.0025
scale = 1.0
radius = 0.002
number = 720
frames = 3600
basemapradius = 0.325
basemapsegments = 2segments1
basepointradius = 0.004
basepointtransparency = false
exportmode = ["gif", "frames", "video"]
exportmode = exportmode[2]
modelname = "twospinorsalpha3"


# The scene object that contains other visual objects
scene = Makie.Scene(backgroundcolor = :black,
                               show_axis = false,
                               resolution = resolution)


quaternionicrgb(p::Quaternion, q::Quaternion, s::Real, v::Real) = begin
    hue = acos(dot(p, q)) / π
    hsvtorgb([hue * 360; s; v])
end


"""
    getflower(;N=4, A=.5, B=-pi/7, P=pi/2, Q=0, number=300)

Calculates the x, y and z points of a flower in the base space.
with the given number of petals N, the fattness of the petals A,
the height of the petals B, the latitude of the flower P,
the rotation of the flower Q, and the total number of points in the grid.
"""
function getflower(;N=4, A=.5, B=-pi/7, P=pi/2, Q=0, number=300)
    N = 6
    A = .5
    B = -pi/6
    P = π / 2 - π / 6
    Q = -π / 3
    t = range(0, stop = 2pi, length = number)
    az = 2pi .* t + A .* cos.(N .* 2pi .* t) .+ Q
    po = B .* sin.(N .* 2pi .* t) .+ P
    x = cos.(az).*sin.(po)
    y = sin.(az).*sin.(po)
    z = cos.(po)
    points = Array{Geographic}(undef, number)
    for i in 1:number
        points[i] = Geographic(Cartesian(x[i], y[i], z[i]))
    end
    points
end


A(s, p::S²) = begin
    z = s(p)
    z₀, z₁ = vec(ComplexPlane(z))
    r = vec(z) # radial
    f = [-r[2]; r[1]; -r[4]; r[3]] # fiber tangent
    X₀, X₁ = vec(ComplexPlane(Quaternion(f)))
    1/2 * (conj(z₀) * X₀ - z₀ * conj(X₀) + conj(z₁) * X₁ - z₁ * conj(X₁))
end


A(p::ComplexPlane) = begin
    z₀, z₁ = vec(p)
    r = vec(Quaternion(p)) # radial
    f = [-r[2]; r[1]; -r[4]; r[3]] # fiber tangent
    X₀, X₁ = vec(ComplexPlane(Quaternion(f)))
    1/2 * (conj(z₀) * X₀ - z₀ * conj(X₀) + conj(z₁) * X₁ - z₁ * conj(X₁))
end


basemapconfig = Biquaternion(Quaternion(1, 0, 0, 0), ℝ³(-0.9 + basemapradius / 2, -√2 - basemapradius / 2, 0))
basemapcolor = Makie.RGBAf(0.25, 0.25, 0.25, 0.25)
basemaptransparency = true
basemap = Sphere(basemapconfig,
                 scene,
                 radius = basemapradius,
                 segments = basemapsegments,
                 color = basemapcolor,
                 transparency = basemaptransparency)

curvepoints = getflower(number = number)
solidcolors = Array{Makie.RGBAf,1}(undef, number)
ghostcolors = similar(solidcolors)
basepoints = Array{Sphere,1}(undef, number)
for i in 1:number
    config = Biquaternion(ℝ³(Cartesian(curvepoints[i])) * basemapradius)
    q₁ = λ⁻¹map(curvepoints[i])
    q₂ = Quaternion(1, 0, 0, 0)
    rgb = quaternionicrgb(q₁, q₂, 1, 1)
    solidcolors[i] = Makie.RGBAf(rgb..., 0.7)
    ghostcolors[i] = Makie.RGBAf(rgb..., 0.1)
    sphere = Sphere(basemapconfig * config,
                    scene,
                    radius = basepointradius,
                    segments = segments2,
                    color = solidcolors[i],
                    transparency = basepointtransparency)
    basepoints[i] = sphere
end

bundleconfig = Biquaternion(ℝ³(0, 0, 0))
solidspinors = Array{Twospinor,1}(undef, number)
ghostspinors = Array{Twospinor,1}(undef, number)
solidgauge1 = U1(0)
solidgauge2 = U1(2π)
ghostgauge1 = U1(0)
ghostgauge2 = U1(2π)
spinors = Array{ComplexPlane,1}(undef, number)
for i in 1:number
    transparency = false
    point = ComplexPlane(λ⁻¹map(curvepoints[i]))
    spinors[i] = point
    solidspinor = Twospinor(scene,
                            point,
                            gauge1 = solidgauge1,
                            gauge2 = solidgauge2,
                            configuration = bundleconfig,
                            radius = radius,
                            segments1 = segments1,
                            segments2 = segments2,
                            color = solidcolors[i],
                            transparency = transparency)
    solidspinors[i] = solidspinor
    transparency = true
    ghostspinor = Twospinor(scene,
                            point,
                            gauge1 = ghostgauge1,
                            gauge2 = ghostgauge2,
                            configuration = bundleconfig,
                            radius = radius,
                            segments1 = segments1,
                            segments2 = segments2,
                            color = ghostcolors[i],
                            transparency = transparency)
    ghostspinors[i] = ghostspinor
end

basespacepoints = Array{ComplexLine,1}(undef, number)

width = 2basepointradius
tail, head = ℝ³(rand(3)), ℝ³(rand(3))
arrows = []
for i in 1:number
    push!(arrows, Arrow(tail, head, scene, width = width, color = solidcolors[i], transparency = false))
end

tori = []
for i in 1:number
    push!(tori, Torus(Biquaternion(tail), scene, r = basepointradius, R = 0.15,
                      segments = 30, color = solidcolors[i], transparency = true))
end


group2algebra(A::SU2, r::Float64) = begin
    τ₃ = -0.5 .* [im 0; 0 -im]
    (-2 * r) .* (A.a * τ₃ * LinearAlgebra.inv(A.a))
end


exponentiate(M::Array{<:Complex,2}, t::Float64) = begin
    eigenvalues = LinearAlgebra.eigvals(M)
    eigenvectors = LinearAlgebra.eigvecs(M)
    S = eigenvectors
    S⁻¹ = LinearAlgebra.inv(S)
    e = LinearAlgebra.Diagonal(eigenvalues) .* t
    S = convert.(Complex{BigFloat}, S)
    S⁻¹ = convert.(Complex{BigFloat}, S⁻¹)
    e = convert.(Complex{BigFloat}, e)
    G = S * ℯ.^e * S⁻¹
    z₁, z₂ = G[1,1], G[1,2]
    v = LinearAlgebra.normalize([real(z₁); imag(z₁); real(z₂); imag(z₂)])
    z₁, z₂ = Complex{Float64}(v[1] + im * v[2]), Complex{Float64}(v[3] + im * v[4])
    G = [z₁ -conj(z₂); z₂ conj(z₁)]
    SU2(G)
end


L₁ = [Complex(0) Complex(1); Complex(1) Complex(0)]
L₂ = [Complex(0) Complex(-im); Complex(im) Complex(0)]
L₃ = [Complex(1) Complex(0); Complex(0) Complex(-1)]
rotation = 4π
# operator = exponentiate(L₃, 0.0)
ϵ = float(π / 2)


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i::Int)
    step = i / frames
    τ = step * rotation
    ψ = Int(τ ÷ ϵ)
    θ = τ % ϵ

    for index in 1:number
        solidspinor = solidspinors[index]
        ghostspinor = ghostspinors[index]
        p = spinors[index]
        operator = exponentiate(group2algebra(SU2(p), 0.0), 0.0)
        q₁ = [exponentiate(group2algebra(operator, 1.0), ϵ) for x in 1:ψ]
        q = exponentiate(group2algebra(operator, 1.0), θ)
        for item in q₁
            q = SU2(normalize(Quaternion(item * q)))
        end
        p = ComplexPlane(normalize(Quaternion(SU2(p) * q)))
        α = A(p)
        g₁ = U1(0)
        g₂ = U1(α)
        g₃ = U1(2π)
        update(solidspinor, p, g₁, g₂)
        update(ghostspinor, p, g₂, g₃)
        rgb = quaternionicrgb(Quaternion(p), Quaternion(1, 0, 0, 0), 0.75 + 0.25 * rand(), 0.75 + 0.25 * rand())
        rgb = 0.8 .* rgb + 0.2 .* rand(3)
        solidcolor = Makie.RGBAf(rgb..., 0.5 + 0.2 * rand())
        ghostcolor = Makie.RGBAf(rgb..., 0.2 + 0.2 * rand())
        update(solidspinor, solidcolor)
        update(ghostspinor, ghostcolor)

        basepointmarker = basepoints[index]
        p = πmap(Quaternion(p))
        p = ℝ³(Cartesian(p)) * basemapradius
        configuration = Biquaternion(p)
        update(basepointmarker, basemapconfig * configuration)
        update(basepointmarker, solidcolor)

        arrow = arrows[index]
        initial = ℝ³(0, 0, basemapradius)
        q₁ = Biquaternion(getrotation(normalize(initial), normalize(p)))
        q₂ = Biquaternion(Quaternion(angle(α), p))
        q₃ = Biquaternion(initial + ℝ³(0.15, 0, 0))
        tail = p
        head = gettranslation(q₁ * q₂ * q₃)
        tail, head = applyconfig([tail; head], basemapconfig)
        update(arrow, tail, head - tail)
        update(arrow, solidcolor)

        torus = tori[index]
        q₁ = Biquaternion(p)
        q₂ = Biquaternion(getrotation(normalize(p), normalize(initial)))
        update(torus, basemapconfig * q₁ * q₂)
        update(torus, ghostcolor)
    end

    # n = ℝ³(1, 0, 0)
    # v = ℝ³(0, 0, 2) * √2
    # q = Quaternion(τ / 4, ℝ³(0, 1, 0))
    # v = rotate(v, q)
    # # update eye position
    # # scene.camera.eyeposition.val
    # upvector = GeometryBasics.Vec3f0(vec(n)...)
    # eyeposition = GeometryBasics.Vec3f0(vec(v)...)
    # lookat = GeometryBasics.Vec3f0(0, 0, 0)
    # Makie.update_cam!(scene, eyeposition, lookat, upvector)
    # scene.center = false # prevent scene from recentering on display
end


n = ℝ³(1, 0, 0)
v = ℝ³(0, 0, 2) * √2
# update eye position
# scene.camera.eyeposition.val
upvector = GeometryBasics.Vec3f0(vec(n)...)
eyeposition = GeometryBasics.Vec3f0(vec(v)...)
lookat = GeometryBasics.Vec3f0(0, 0, 0)
Makie.update_cam!(scene, eyeposition, lookat, upvector)
scene.center = false # prevent scene from recentering on display
if exportmode ∈ ["gif", "video"]
    outputextension = exportmode == "gif" ? "gif" : "mkv"
    Makie.record(scene, "gallery/$modelname.$outputextension",
                            framerate = FPS) do io
        for i in startframe:frames
            animate(i) # animate the scene
            Makie.recordframe!(io) # record a new frame
            step = (i - 1) / frames
            println("Completed step $(100step).\n")
        end
    end
elseif exportmode == "frames"
    directory = joinpath("gallery", modelname)
    !isdir(directory) && mkdir(directory)
    directory = joinpath("gallery", modelname)
    !isdir(directory) && mkdir(directory)
    for i in startframe:frames
        start = time()
        animate(i) # animate the scene
        elapsed = time() - start
        sleep(0.1)
        println("Generating frame $i took $elapsed (s).")

        start = time()

        paddingnumber = length(digits(frames))
        imageid = lpad(i, paddingnumber, "0")
        imagename = "$(modelname)_$(resolution[2])p_$(FPS)fps_$imageid.jpeg"
        filepath = joinpath(directory, imagename)
        FileIO.save(filepath,
                    scene;
                    resolution = resolution,
                    pt_per_unit = 400.0,
                    px_per_unit = 400.0)
        elapsed = time() - start
        sleep(0.1)
        println("Saving file $filepath took $elapsed (s).")
        step = i / frames
        println("Completed step $(100step).\n")

        stitch() = begin
            part = i ÷ (frames / 3)
            exportdir = joinpath(directory, "export")
            !isdir(exportdir) && mkdir(exportdir)
            WxH = "$(resolution[1])x$(resolution[2])"
            #WxH = "1920x1080"
            commonpart = "$(modelname)_$(resolution[2])p_$(FPS)fps"
            inputname = "$(commonpart)_%0$(paddingnumber)d.jpeg"
            inputpath = joinpath(directory, inputname)
            outputname = "$(commonpart)_$(part).mp4"
            outputpath = joinpath(exportdir, outputname)
            command1 = `ffmpeg -y -f image2 -framerate $FPS -i $inputpath -s $WxH -pix_fmt yuvj420p $outputpath`
            run(command1)
        end

        if isapprox(i % (frames / 3), 0)
            stitch()
            sleep(1)
        end
        # break
    end
end
