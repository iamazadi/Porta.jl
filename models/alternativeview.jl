import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using ModelingToolkit, DifferentialEquations, Latexify
using Porta


resolution = (1920, 1080)
segments = 120
frames_number = 1440

modelname = "alternativeview"
makefigure() = GLMakie.Figure(resolution = resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=:white, clear=true))

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
eyeposition = GLMakie.Vec3f(cam.eyeposition[]...)
lookat = GLMakie.Vec3f(0, 0, 0)
up = GLMakie.Vec3f(0, 0, 1)
# GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask1.png")

## Load the Natural Earth data

attributespath = "./data/gdp/geometry-attributes.csv"
nodespath = "./data/gdp/geometry-nodes.csv"

countries = loadcountries(attributespath, nodespath)

country_name1 = "United States of America"
country_name2 = "South Africa"
country_name3 = "Iran"
country_name4 = "Turkey"
country_name5 = "Australia"
country_name6 = "New Zealand"
country_nodes1 = Vector{Vector{Float64}}()
country_nodes2 = Vector{Vector{Float64}}()
country_nodes3 = Vector{Vector{Float64}}()
country_nodes4 = Vector{Vector{Float64}}()
country_nodes5 = Vector{Vector{Float64}}()
country_nodes6 = Vector{Vector{Float64}}()
for i in 1:length(countries["name"])
    if countries["name"][i] == country_name1
        country_nodes1 = countries["nodes"][i]
        country_nodes1 = convert(Vector{Vector{Float64}}, country_nodes1)
        println(typeof(country_nodes1))
        println(country_name1)
    end
    if countries["name"][i] == country_name2
        country_nodes2 = countries["nodes"][i]
        println(country_name2)
    end
    if countries["name"][i] == country_name3
        country_nodes3 = countries["nodes"][i]
        println(country_name3)
    end
    if countries["name"][i] == country_name4
        country_nodes4 = countries["nodes"][i]
        println(country_name4)
    end
    if countries["name"][i] == country_name5
        country_nodes5 = countries["nodes"][i]
        println(country_name5)
    end
    if countries["name"][i] == country_name6
        country_nodes6 = countries["nodes"][i]
        println(country_name6)
    end
end

α = 0.1
color1 = getcolor(country_nodes1, colorref, α)
color2 = getcolor(country_nodes2, colorref, α)
color3 = getcolor(country_nodes3, colorref, α)
color4 = getcolor(country_nodes4, colorref, α)
color5 = getcolor(country_nodes5, colorref, α)
color6 = getcolor(country_nodes6, colorref, α)
w1 = [τmap(country_nodes1[i]) for i in eachindex(country_nodes1)]
w2 = [τmap(country_nodes2[i]) for i in eachindex(country_nodes2)]
w3 = [τmap(country_nodes3[i]) for i in eachindex(country_nodes3)]
w4 = [τmap(country_nodes4[i]) for i in eachindex(country_nodes4)]
w5 = [τmap(country_nodes5[i]) for i in eachindex(country_nodes5)]
w6 = [τmap(country_nodes6[i]) for i in eachindex(country_nodes6)]
θ = 3π / 2
whirl1 = Whirl(lscene, w1, [0.0 for i in 1:length(w1)], [θ for i in 1:length(w1)], segments, color1, transparency = true)
whirl2 = Whirl(lscene, w2, [0.0 for i in 1:length(w2)], [θ for i in 1:length(w2)], segments, color2, transparency = true)
whirl3 = Whirl(lscene, w3, [0.0 for i in 1:length(w3)], [θ for i in 1:length(w3)], segments, color3, transparency = true)
whirl4 = Whirl(lscene, w4, [0.0 for i in 1:length(w4)], [θ for i in 1:length(w4)], segments, color4, transparency = true)
whirl5 = Whirl(lscene, w5, [0.0 for i in 1:length(w5)], [θ for i in 1:length(w5)], segments, color5, transparency = true)
whirl6 = Whirl(lscene, w6, [0.0 for i in 1:length(w6)], [θ for i in 1:length(w6)], segments, color6, transparency = true)
frame1 = Frame(lscene, x -> G(0, τmap(x)), segments, basemap_color, transparency = false)
frame2 = Frame(lscene, x -> G(θ, τmap(x)), segments, basemap_color, transparency = true)

GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
    τ(x, ϕ) = begin
        g = convert_to_geographic(x)
        r, _ϕ, _θ = g
        _θ += ϕ
        z₁ = ℯ^(im * 0) * √((1 + sin(_θ)) / 2)
        z₂ = ℯ^(im * _ϕ) * √((1 - sin(_θ)) / 2)
        Quaternion([z₂; z₁])
    end
    ϕ = progress * 2π
    update!(frame1, x -> τ(x, ϕ))
    update!(frame2, x -> G(θ, τ(x, ϕ)))
    update!(whirl1, τ.(country_nodes1, ϕ), whirl1.θ1, whirl1.θ2)
    update!(whirl2, τ.(country_nodes2, ϕ), whirl2.θ1, whirl2.θ2)
    update!(whirl3, τ.(country_nodes3, ϕ), whirl3.θ1, whirl3.θ2)
    update!(whirl4, τ.(country_nodes4, ϕ), whirl4.θ1, whirl4.θ2)
    update!(whirl5, τ.(country_nodes5, ϕ), whirl5.θ1, whirl5.θ2)
    update!(whirl6, τ.(country_nodes6, ϕ), whirl6.θ1, whirl6.θ2)

    lookat = GLMakie.Vec3f(0, 0, 0)
    up = GLMakie.Vec3f(0, 0, 1)
    azimuth = -π / 2 + 0.3 * sin(2π * progress) # set the view angle of the axis
    eyeposition = GLMakie.Vec3f(π .* convert_to_cartesian([1; azimuth; π / 8])...)
    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
