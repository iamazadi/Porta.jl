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
segments = 48
speed = 1
factor = 0.0025
scale = 1.0
radius = 0.005
number = 720
frames = 3600
basemapradius = 0.325
basemapsegments = 2segments
basepointradius = 0.01
basepointsegments = 10
basepointtransparency = true
exportmode = ["gif", "frames", "video"]
exportmode = exportmode[2]
modelname = "spinor2"


# The scene object that contains other visual objects
scene = Makie.Scene(backgroundcolor = :black,
                               show_axis = false,
                               resolution = resolution)


fmap(b::S²) = b


"""
    getpointonpath(t)

Get a point on a path on S² with the given parameter `t`. t ∈ [0, 1].
"""
getpointonpath(t::Real) = begin
    t = t * 12π
    d = ℯ^cos(t) - 2cos(4t) - sin(t / 12)^5
    x, y = sin(t) * d, cos(t) * d
    ComplexLine(x + im * y)
end


"""
    getbutterflycurve(points)

Get butterfly curve by Temple H. Fay (1989) with the given number of `points`.
"""
function getbutterflycurve(points::Int)
    array = Array{ComplexLine,1}(undef, points)
    # 0 ≤ t ≤ 12π
    for i in 1:points
        t = (i - 1) / points * 12π
        d = ℯ^cos(t) - 2cos(4t) - sin(t / 12)^5
        x, y = sin(t) * d, cos(t) * d
        array[i] = ComplexLine(x + im * y)
    end
    array
end


quaternionicrgb(p::Quaternion, q::Quaternion, s::Real, v::Real) = begin
    hue = acos(dot(p, q)) / π
    hsvtorgb([hue * 360; s; v])
end


"""
    getpoints(z [, segments])

Get a circle of point in the base space with the given center `z` in the Riemann
sphere. The optional argument `segments` determines how many points should the
circle have.
"""
function getpoints(z::S²; segments::Int = 30)
    g = Geographic(z)
    r, ϕ, θ = vec(g)
    lspace = collect(range(float(-pi), stop = float(pi), length = segments))
    array = Array{Geographic,1}(undef, segments)
    for i in 1:segments
        ϕ′, θ′ = g.ϕ + factor * cos(lspace[i]), g.θ + factor * sin(lspace[i])
        array[i] = Geographic(r, ϕ′, θ′)
    end
    array
end


A(s, p::S²) = begin
    z = s(p)
    z₀, z₁ = vec(ComplexPlane(z))
    r = vec(z) # radial
    f = [-r[2]; r[1]; -r[4]; r[3]] # fiber tangent
    X₀, X₁ = vec(ComplexPlane(Quaternion(f)))
    1/2 * (conj(z₀) * X₀ - z₀ * conj(X₀) + conj(z₁) * X₁ - z₁ * conj(X₁))
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
    B = -pi/7
    P = π / 2 - π / 4
    Q = 0
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


#basemapconfig = Biquaternion(ℝ³(0, -1.25, 0))
basemapconfig = Biquaternion(Quaternion(1, 0, 0, 0), ℝ³(-0.9 + basemapradius / 2, -√2 - basemapradius / 2, 0))
basemapcolor = Makie.RGBAf(0.8, 0.8, 0.8, 0.2)
#basemapcolor = load("gallery/mars_1k_color.jpg")
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
    # hue = (i - 1) / number * 360
    # rgb = hsvtorgb([hue, 1, 1])
    solidcolors[i] = Makie.RGBAf(rgb..., 0.7)
    ghostcolors[i] = Makie.RGBAf(rgb..., 0.1)
    sphere = Sphere(basemapconfig * config,
                    scene,
                    radius = basepointradius,
                    segments = basepointsegments,
                    color = solidcolors[i],
                    transparency = basepointtransparency)
    basepoints[i] = sphere
end

#bundleconfig = Biquaternion(ℝ³(0, 1.25, 0))
bundleconfig = Biquaternion(ℝ³(0, 0, 0))
s3rotation = Quaternion(1, 0, 0, 0)
solidfibers = Array{Fiber,1}(undef, number)
ghostfibers = Array{Fiber,1}(undef, number)
solidtop = U1(0)
solidbottom = U1(2π)
ghosttop = U1(0)
ghostbottom = U1(2π)
for i in 1:number
    point = curvepoints[i]
    transparency = false
    solidfiber = Fiber(scene,
                       point,
                       λ⁻¹map,
                       fmap,
                       radius = radius,
                       top = solidtop,
                       bottom = solidbottom,
                       s3rotation = s3rotation,
                       config = bundleconfig,
                       segments = segments,
                       color = solidcolors[i],
                       transparency = transparency,
                       scale = scale)
    solidfibers[i] = solidfiber
    transparency = true
    ghostfiber = Fiber(scene,
                       point,
                       λ⁻¹map,
                       fmap,
                       radius = radius,
                       top = ghosttop,
                       bottom = ghostbottom,
                       s3rotation = s3rotation,
                       config = bundleconfig,
                       segments = segments,
                       color = ghostcolors[i],
                       transparency = transparency,
                       scale = scale)
    ghostfibers[i] = ghostfiber
end

basespacepoints = Array{ComplexLine,1}(undef, number)
phases = Array{U1,2}(undef, number, 2)
s3rotations = Array{Quaternion,1}(undef, number)

len = 0.1
width = 0.01
transparency = false
tail, head = ℝ³(rand(3)), ℝ³(rand(3))
arrows = []
for i in 1:number
    push!(arrows, Arrow(tail, head, scene, width = width, color = solidcolors[i]))
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

B = SU2(Quaternion(π / 8, ℝ³(Cartesian(Geographic(1, π / 3, π / 4)))))
# ComplexPlane(0.9238795325112867 + 0.13529902503654928im, 0.2343447855778369 + 0.27059805007309845im)

L₁ = [Complex(0) Complex(1); Complex(1) Complex(0)]
L₂ = [Complex(0) Complex(-im); Complex(im) Complex(0)]
L₃ = [Complex(1) Complex(0); Complex(0) Complex(-1)]
rotation = 2π
frames = 360
ϵ = rotation / frames
g = L₃ # group2algebra(B, ϵ)
q₂ = g

for i in 1:frames
    h = group2algebra(exponentiate(g, i * ϵ - π), 1.0)
    q = rotate(h, ComplexPlane(B))
    q₂ = q
    println(q)
    if i % (frames / 4) == 0.0
        println("")
    end
end

# ComplexPlane(-0.010686830141843868 + 0.7131691405919512im, -0.612279177876824 + 0.34115945964803246im)
# ComplexPlane(-0.6123681646060238 + 0.356191878306672im, -0.0022871329322613106 - 0.7057813725427761im)
# ComplexPlane(-0.35355339059327384 - 0.6123724356957946im, -0.7071067811865475 + 4.336808689942018e-19im)
# ComplexPlane(0.6123680128847738 - 0.3562382883042756im, 0.002327401029800577 + 0.7057579485532132im)
# ComplexPlane(0.35355339059327384 + 0.6123724356957946im, 0.7071067811865475 - 8.673617379884035e-19im)
# ComplexPlane(-0.6123680128847738 + 0.3562382883042756im, -0.0023274010298005776 - 0.7057579485532132im)

println(q₀)
println(Quaternion(q))


"""
    animate(i)

Update the state of observables with the given frame number `i`.
"""
function animate(i::Int)
    step = (i - 1) / frames
    τ = step * rotation
    global q = rotate(q, e)
    
    for (index, item) in enumerate(curvepoints)
        z = item
        h = rotate(λ⁻¹map(z), q)
        z = πmap(h)
        q₂ = Quaternion(1, 0, 0, 0)
        rgb = quaternionicrgb(h, q₂, 0.8 + 0.2 * rand(), 0.8 + 0.2 * rand())
        solidcolors[index] = Makie.RGBAf(rgb..., 0.5 + 0.3 * rand())
        ghostcolors[index] = Makie.RGBAf(rgb..., 0.1 + 0.1 * rand())

        basespacepoints[index] = z
        phases[index, 1] = U1(0)
        phases[index, 2] = U1(τ - 2π)
    end
    for (index, item) in enumerate(basepoints)
        z = basespacepoints[index]
        p = ℝ³(Cartesian(z)) * basemapradius
        config = Biquaternion(p)
        update(item, basemapconfig * config)
        update(item, solidcolors[index])
    end
    for (index, item) in enumerate(solidfibers)
        top = phases[index, 1]
        bottom = phases[index, 2]
        update(item, curvepoints[index], q, radius, top, bottom)
        update(item, solidcolors[index])
    end
    for (index, item) in enumerate(ghostfibers)
        top = U1(0)
        bottom = U1(2π)
        update(item, curvepoints[index], q, radius, top, bottom)
        update(item, ghostcolors[index])
    end

    # update tangent vectors
    for (index, item) in enumerate(arrows)
        w = basespacepoints[index]
        tail = ℝ³(Cartesian(w)) * basemapradius
        initial = ℝ³(0, 0, 1) * basemapradius
        q = getrotation(normalize(tail), normalize(initial))
        α = phases[index, 2]
        head = initial + ℝ³(1, 0, 0) * (1 / 10)
        head = rotate(head, q)
        q = Quaternion(angle(α), normalize(tail))
        head = rotate(head, q)
        tail, head = applyconfig([tail; head], basemapconfig)
        update(item, tail, head - tail)
        update(item, ghostcolors[index])
    end
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
        step = (i - 1) / frames
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
    end
end
