# by lazarusA 
using AssociatedLegendrePolynomials, GLMakie
using GeometryBasics, LinearAlgebra, StatsBase
using Makie: get_dim, surface_normals
ϵ = 1e-7
# thanks to @jkrumbiegel for the lift
let
    function Y(θ, ϕ, l, m)
        if m < 0
            return (-1)^m * √2 * Nlm(l, abs(m)) * Plm(l, abs(m), cos(θ)) * sin(abs(m)*ϕ)
        elseif m == 0
            return sqrt((2*l+1)/4π)*Plm(l, m, cos(θ))
        else
            return (-1)^m * √2 * Nlm(l, m) * Plm(l, m, cos(θ)) * cos(m*ϕ)
        end
    end
    function getMesh(x,y,z)
        positions = vec(map(CartesianIndices(z)) do i
        GeometryBasics.Point{3, Float32}(
            get_dim(x, i, 1, size(z)),
            get_dim(y, i, 2, size(z)),
            z[i])
        end)
        faces = decompose(GLTriangleFace, Rect2D(0f0, 0f0, 1f0, 1f0), size(z))
        normals = surface_normals(x, y, z)
        vertices = GeometryBasics.meta(positions; normals=normals)
        meshObj = GeometryBasics.Mesh(vertices, faces)
        meshObj
    end
    function Π(v, n)
        v - dot(v, n) / norm(n)^2 * n
    end
    function multiply(q₁, q₂)
        z₁ = Complex(q₁[1], q₁[2])
        z₂ = Complex(q₁[3], q₁[4])
        A = [z₁ -conj(z₂); z₂ conj(z₁)]
        w₁ = Complex(q₂[1], q₂[2])
        w₂ = Complex(q₂[3], q₂[4])
        B = [w₁ -conj(w₂); w₂ conj(w₁)]
        C = A * B
        x₁, x₂ = C[1,1], C[2,1]
        [real(x₁); imag(x₁); real(x₂); imag(x₂)]
    end
    d(Φ, p) = begin
        rows = length(p)
        D = Array{Float64,1}(undef, rows)
        E = Array{Float64,2}(I, rows, rows) .* ϵ
        P = repeat(p, 1, rows)
        P′ = P + E
        for i in 1:rows
            D[i] = (Φ(P′[:, i]) - Φ(P[:, i])) ./ ϵ
        end
        D
    end
    directional(Φ, p, x) = begin
        rows = length(x)
        D = Array{Float64,1}(undef, rows)
        E = Array{Float64,2}(I, rows, rows) .* ϵ
        P = repeat(x, 1, rows)
        P′ = P + E
        for i in 1:rows
            D[i] = (Φ(p, P′[:, i]) - Φ(p, P[:, i])) ./ ϵ
        end
        D
    end
    getz₀(longitude, latitude, phase) = ℯ^(im * (longitude + phase)) * √((1 - sin(latitude)) / 2)
    getz₁(longitude, latitude, phase) = ℯ^(im * phase) * √((1 + sin(latitude)) / 2)
    TS³(z₀, z₁) =  begin
        # initialization
        X₀ = Complex(rand() + im * rand())
        X₁ = Complex(rand() + im * rand())
        getloss(z, x) = begin
            z₀ = Complex(z[1] + im * z[2])
            z₁ = Complex(z[3] + im * z[4])
            X₀ = Complex(x[1] + im * x[2])
            X₁ = Complex(x[3] + im * x[4])
            abs(conj(z₀) * X₀ + conj(z₁) * X₁)
        end
        x = [real(X₀); imag(X₀); real(X₁); imag(X₁)]
        z = [real(z₀); imag(z₀); real(z₁); imag(z₁)]
        loss = getloss(z, x)
        threshold = 1e-4
        η = 1e-2
        iterations = 150
        i = 0
        while loss > threshold && i < iterations
            g = directional(getloss, z, x)
            X₀ = Complex(x[1] - η * g[1] + im * (x[2] - η * g[2]))
            X₁ = Complex(x[3] - η * g[3] + im * (x[4] - η * g[4]))
            x = [real(X₀); imag(X₀); real(X₁); imag(X₁)]
            loss = getloss(z, x)
            i += 1
        end
        X₀, X₁
    end
    connection1form(z₀, z₁) = begin
        X₀, X₁ = TS³(z₀, z₁)
        1/2 * (conj(z₀) * X₀ - z₀ * conj(X₀) + conj(z₁) * X₁ - z₁ * conj(X₁))
    end
    tangent_tail(x, f) = [x[1]; x[2]; f(x)]
    tangent_head(x, f, ξ) = begin
        dΦ = d(f, x)
        ξΦ = dot(dΦ, ξ)
        dξΦ = dΦ .* ξ
        [dξΦ[1]; dξΦ[2]; (f([x[1] + dξΦ[1] * ϵ; x[2] + dξΦ[2] * ϵ]) - f(x)) ./ ϵ] .* ξΦ
    end
    f₁(i) = begin
        √(1 - (i[1])^2 - (i[2])^2)
    end
    f₂(i) = -f₁(i)

    segments = 200
    radius = 0.05
    # Grids of polar and azimuthal angles
    θ = LinRange(0, π, segments)
    ϕ = LinRange(0, 2π, segments)
    xx = [sin(θ)*sin(ϕ) for θ in θ, ϕ in ϕ]
    yy = [sin(θ)*cos(ϕ) for θ in θ, ϕ in ϕ]
    zz = [cos(θ)        for θ in θ, ϕ in ϕ]

    l = Node(4)
    m = Node(1)

    lon = Node(1.0)
    lat = Node(1.0)
    ang = Node(1.0)
    vector = Node([1.0; 0.0; 0.0])

    #w₀ = @lift(ℯ^(im * $ang) * sqrt((1 + sin($lat)) / 2))
    #w₁ = @lift(ℯ^(im * ($lon + $ang)) * sqrt((1 - sin($lat)) / 2))
    #w = @lift($w₁ / $w₀)
    w = lift(lon, lat) do lon, lat
        a₁ = cos(lat) * cos(lon)
        a₂ = cos(lat) * sin(lon)
        a₃ = sin(lat)
        a₁ / (1 - a₃) + im * a₂ / (1 - a₃)
    end
    fiber = lift(lon, lat, ang) do lon, lat, ang
        points = [[lon; lat] + [cos(i); sin(i)] .* radius for i in range(0, stop = 2π, length = segments)]
        ψ = range(0, stop = ang, length = segments)
        xyz(ψ, point) = begin
            v₀ = getz₀(point[1], point[2], ψ)
            v₁ = getz₁(point[1], point[2], ψ)
            q₁, q₂ = real(v₀), imag(v₀)
            q₃, q₄ = real(v₁), imag(v₁)
            q = [q₁; q₂; q₃; q₄]
            p = q[1:3] ./ (1 - q₄)
            magnitude = norm(p)
            normalize(p) * tanh(magnitude)
        end
        a = [xyz(i, j) for i in ψ, j in points]
        a₁ = map(i -> i[1], a)
        a₂ = map(i -> i[2], a)
        a₃ = map(i -> i[3], a)
        a₁, a₂, a₃
    end
    fiber₁ = @lift($fiber[1])
    fiber₂ = @lift($fiber[2])
    fiber₃ = @lift($fiber[3])

    fiber2 = lift(lon, lat, ang) do lon, lat, ang
        points = [[lon; lat] + [cos(i); sin(i)] .* radius for i in range(0, stop = 2π, length = segments)]
        ψ = range(ang, stop = 2π, length = segments)
        xyz(ψ, point) = begin
            v₀ = getz₀(point[1], point[2], ψ)
            v₁ = getz₁(point[1], point[2], ψ)
            q₁, q₂ = real(v₀), imag(v₀)
            q₃, q₄ = real(v₁), imag(v₁)
            q = [q₁; q₂; q₃; q₄]
            p = q[1:3] ./ (1 - q₄)
            magnitude = norm(p)
            normalize(p) * tanh(magnitude)
        end
        a = [xyz(i, j) for i in ψ, j in points]
        a₁ = map(i -> i[1], a)
        a₂ = map(i -> i[2], a)
        a₃ = map(i -> i[3], a)
        a₁, a₂, a₃
    end
    fiber2₁ = @lift($fiber2[1])
    fiber2₂ = @lift($fiber2[2])
    fiber2₃ = @lift($fiber2[3])

    tail = lift(w) do w
        u, v = real(w), imag(w)
        denominator = u^2 + v^2 + 1
        u = 2u / denominator
        v = 2v / denominator
        f = abs(w) ≤ 1 ? f₂ : f₁
        tangent_tail([u; v], f)
    end
    xconst = lift(w, tail) do w, tail
        u, v = real(w), imag(w)
        denominator = u^2 + v^2 + 1
        u = 2u / denominator
        v = 2v / denominator
        f = abs(w) ≤ 1 ? f₂ : f₁
        normalize(tangent_head([u; v], f, [1; 0]))
    end
    yconst = lift(w, tail) do w, tail
        u, v = real(w), imag(w)
        denominator = u^2 + v^2 + 1
        u = 2u / denominator
        v = 2v / denominator
        f = abs(w) ≤ 1 ? f₂ : f₁
        normalize(tangent_head([u; v], f, [0; 1]))
    end
    head = lift(w, ang, tail, xconst, yconst) do w, ang, tail, x, y
        # parallel transport
        #v = to_value(vector)
        #n = normalize(cross(x, y))
        #if -1 < dot(x, y) < 1
        #    projected = Π(v, n)
        #else
        #    projected = v
        #end
        #projected = normalize(projected)
        #vector[] = projected
        #projected
        u, v = real(w), imag(w)
        denominator = u^2 + v^2 + 1
        u = 2u / denominator
        v = 2v / denominator
        f = abs(w) ≤ 1 ? f₂ : f₁
        normalize(tangent_head([u; v], f, [cos(ang); sin(ang)]))

        #p₁ = [lon; lat]
        #p₂ = p₁ + [0.1; 0.1]
        #v₀ = ℯ^(im * (p₁[1] + ψ)) * sqrt((1 - sin(p₁[2])) / 2)
        #v₁ = ℯ^(im * ψ) * sqrt((1 + sin(p₁[2])) / 2)
        
    end
    connectiontail = lift(lon, lat, ang) do lon, lat, ang
        point = [lon; lat]
        v₀ = getz₀(point[1], point[2], ang)
        v₁ = getz₁(point[1], point[2], ang)
        q₁, q₂ = real(v₀), imag(v₀)
        q₃, q₄ = real(v₁), imag(v₁)
        q = [q₁; q₂; q₃; q₄]
        p = q[1:3] ./ (1 - q₄)
        magnitude = norm(p)
        normalize(p) * tanh(magnitude)
    end
    connectionhead = lift(lon, lat, ang) do lon, lat, ang
        point = [lon; lat]
        v₀ = getz₀(point[1], point[2], ang)
        v₁ = getz₁(point[1], point[2], ang)
        oneform = connection1form(v₀, v₁)
        v₀, v₁ = oneform * v₀, oneform * v₁
        q₁, q₂ = real(v₀), imag(v₀)
        q₃, q₄ = real(v₁), imag(v₁)
        q = [q₁; q₂; q₃; q₄]
        p = q[1:3] ./ (1 - q₄)
        magnitude = norm(p)
        h = normalize(p) * tanh(magnitude)
        t = to_value(connectiontail)
        h - t
    end


    tails₁ = @lift([$tail[1], $tail[1], $tail[1]])
    tails₂ = @lift([$tail[2], $tail[2], $tail[2]])
    tails₃ = @lift([$tail[3], $tail[3], $tail[3]])
    heads₁ = @lift([$head[1], $xconst[1], $yconst[1]])
    heads₂ = @lift([$head[2], $xconst[2], $yconst[2]])
    heads₃ = @lift([$head[3], $xconst[3], $yconst[3]])

    conn_tail₁ = @lift([$connectiontail[1]])
    conn_tail₂ = @lift([$connectiontail[2]])
    conn_tail₃ = @lift([$connectiontail[3]])
    conn_head₁ = @lift([$connectionhead[1]])
    conn_head₂ = @lift([$connectionhead[2]])
    conn_head₃ = @lift([$connectionhead[3]])

    x₁ = @lift(xx .* 0.1 .+ $tail[1])
    y₁ = @lift(yy .* 0.1 .+ $tail[2])
    z₁ = @lift(zz .* 0.1 .+ $tail[3])

    ambient =  Vec3f0(0.75, 0.75, 0.75)
    cmap = (:dodgerblue, :white) # how to include this into menu options?
    with_theme(theme_black()) do
        fig = Figure(resolution = (1400, 800))
        menu = Menu(fig, options = ["Spectral_11", "viridis", "heat", "plasma", "magma", "inferno"])
        Ygrid = lift(l, m) do l, m
            [Y(θ, ϕ, l, m) for θ in θ, ϕ in ϕ]
        end
        Ylm = @lift(abs.($Ygrid))
        Ygrid2 = @lift(vec($Ygrid))

        ax1 = Axis3(fig, aspect = :data, perspectiveness = 0.5, elevation = π/8, azimuth = 2.225π)
        ax2 = Axis3(fig, aspect = :data, perspectiveness = 0.5, elevation = π/8, azimuth = 2.225π)
        pltobj1 = mesh!(ax1, getMesh(xx, yy, zz), color = Ygrid2, colormap = cmap, ambient = ambient)
        pltobj3 = mesh!(ax1, @lift(getMesh($x₁, $y₁, $z₁)), color = :gold, colormap = cmap, ambient = ambient)
        pltobj4 = arrows!(ax1, tails₁, tails₂, tails₃, heads₁, heads₂, heads₃, color = [:red, :silver, :gray], lengthscale = 0.3f0)
        pltobj5 = mesh!(ax2, @lift(getMesh($fiber₁, $fiber₂, $fiber₃)), color = :red, colormap = cmap, ambient = ambient)
        pltobj6 = mesh!(ax2, @lift(getMesh($fiber2₁, $fiber2₂, $fiber2₃)), color = Ygrid2, colormap = cmap, ambient = ambient)
        pltobj7 = arrows!(ax2, conn_tail₁, conn_tail₂, conn_tail₃, conn_head₁, conn_head₂, conn_head₃, color = [:gold], lengthscale = 1.0f0)
        cbar = Colorbar(fig, pltobj1, label = "Yₗₘ(θ,ϕ)", width = 11, tickalign = 1, tickwidth = 1)
        fig[1,1] = ax1
        fig[1,2] = ax2
        fig[1,3] = cbar
        round3(n) = round(n, sigdigits = 3)
        degree(n) = round3(180(n / π))
        fig[0,1:2] = Label(fig, @lift("Hopf fiber: longitude = $(degree($lon)), latitude = $(degree($lat)), S¹action = $(degree($ang))."), textsize = 20)
        fig[2, 0] = vgrid!(
            Label(fig, "Colormap", width = nothing),
            menu; tellheight = false, width = 100)
        on(menu.selection) do s
            pltobj1.colormap = s
            pltobj3.colormap = s
            pltobj4.colormap = s
            pltobj5.colormap = s
            pltobj6.colormap = s
            pltobj7.colormap = s
        end
        sl3 = Slider(fig[end+1, 2:3], range = range(-π, stop = π, length = 100))
        sl4 = Slider(fig[end+1, 2:3], range = range(-π/2, stop = 0.99 * π/2, length = 100))
        sl5 = Slider(fig[end+1, 2:3], range = range(0, stop = 2π, length = 100))
        set_close_to!(sl3, to_value(lon))
        set_close_to!(sl4, to_value(lat))
        set_close_to!(sl5, to_value(ang))
        connect!(lon, sl3.value)
        connect!(lat, sl4.value)
        connect!(ang, sl5.value)
        tight_ticklabel_spacing!(cbar)
        display(fig)
        framerate = 30
        totaltime = 30
        timestamps = range(0, totaltime, step=1/framerate)

        record(fig, joinpath("gallery", "connection1form_a.mp4"), timestamps;
            framerate = framerate) do t
            step = t / totaltime
            longitude = π/2
            latitude = π/4
            action = step * 2π
            #set_close_to!(sl3, longitude)
            #set_close_to!(sl4, latitude)
            set_close_to!(sl5, action)
        end
    end
end