import FileIO
import DataFrames
import CSV
import GLMakie
using LinearAlgebra
using Porta


resolution = (1920, 1080)
segments = 60
basemapsegments = 120
frames_number = 1440
 
modelname = "segment01"
makefigure() = GLMakie.Figure(resolution = resolution)
fig = GLMakie.with_theme(makefigure, GLMakie.theme_black())
pl = GLMakie.PointLight(GLMakie.Point3f(0), GLMakie.RGBf(20, 20, 20))
al = GLMakie.AmbientLight(GLMakie.RGBf(0.9, 0.9, 0.9))
backgroundcolor = GLMakie.RGBf(0.1019, 0.0196, 0)
lscene = GLMakie.LScene(fig[1, 1], show_axis=false, scenekw = (resolution = resolution, lights = [pl, al], backgroundcolor=backgroundcolor, clear=true))

cam = GLMakie.camera(lscene.scene) # this is how to access the scenes camera
eyeposition = GLMakie.Vec3f(cam.eyeposition[]...)
lookat = GLMakie.Vec3f(0, 0, 0)
up = GLMakie.Vec3f(0, 0, 1)
# GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)

colorref = FileIO.load("data/basemap_color.png")
basemap_color = FileIO.load("data/basemap_mask1.png")

## Load the Natural Earth data

attributespath = "data/naturalearth/geometry-attributes.csv"
nodespath = "data/naturalearth/geometry-nodes.csv"

countries = loadcountries(attributespath, nodespath)

country_name1 = "United States of America"
country_name2 = "South Africa"
country_name3 = "Iran"
country_name4 = "Turkey"
country_name5 = "Australia"
country_name6 = "New Zealand"
country_name7 = "France"
country_name8 = "Mexico"
country_name9 = "Morocco"
country_name10 = "South Korea"
country_nodes1 = Vector{Vector{Float64}}()
country_nodes2 = Vector{Vector{Float64}}()
country_nodes3 = Vector{Vector{Float64}}()
country_nodes4 = Vector{Vector{Float64}}()
country_nodes5 = Vector{Vector{Float64}}()
country_nodes6 = Vector{Vector{Float64}}()
country_nodes7 = Vector{Vector{Float64}}()
country_nodes8 = Vector{Vector{Float64}}()
country_nodes9 = Vector{Vector{Float64}}()
country_nodes10 = Vector{Vector{Float64}}()
for i in 1:length(countries["name"])
    if countries["name"][i] == country_name1
        global country_nodes1 = countries["nodes"][i]
        global country_nodes1 = convert(Vector{Vector{Float64}}, country_nodes1)
        println(typeof(country_nodes1))
        println(country_name1)
    end
    if countries["name"][i] == country_name2
        global country_nodes2 = countries["nodes"][i]
        println(country_name2)
    end
    if countries["name"][i] == country_name3
        global country_nodes3 = countries["nodes"][i]
        println(country_name3)
    end
    if countries["name"][i] == country_name4
        global country_nodes4 = countries["nodes"][i]
        println(country_name4)
    end
    if countries["name"][i] == country_name5
        global country_nodes5 = countries["nodes"][i]
        println(country_name5)
    end
    if countries["name"][i] == country_name6
        global country_nodes6 = countries["nodes"][i]
        println(country_name6)
    end
    if countries["name"][i] == country_name7
        global country_nodes7 = countries["nodes"][i]
        println(country_name7)
    end
    if countries["name"][i] == country_name8
        global country_nodes8 = countries["nodes"][i]
        println(country_name8)
    end
    if countries["name"][i] == country_name9
        global country_nodes9 = countries["nodes"][i]
        println(country_name9)
    end
    if countries["name"][i] == country_name10
        global country_nodes10 = countries["nodes"][i]
        println(country_name10)
    end
end

α = 0.5
color1 = getcolor(country_nodes1, colorref, α)
color2 = getcolor(country_nodes2, colorref, α)
color3 = getcolor(country_nodes3, colorref, α)
color4 = getcolor(country_nodes4, colorref, α)
color5 = getcolor(country_nodes5, colorref, α)
color6 = getcolor(country_nodes6, colorref, α)
color7 = getcolor(country_nodes7, colorref, α)
color8 = getcolor(country_nodes8, colorref, α)
color9 = getcolor(country_nodes9, colorref, α)
color10 = getcolor(country_nodes10, colorref, α)
w1 = [τmap(country_nodes1[i]) for i in eachindex(country_nodes1)]
w2 = [τmap(country_nodes2[i]) for i in eachindex(country_nodes2)]
w3 = [τmap(country_nodes3[i]) for i in eachindex(country_nodes3)]
w4 = [τmap(country_nodes4[i]) for i in eachindex(country_nodes4)]
w5 = [τmap(country_nodes5[i]) for i in eachindex(country_nodes5)]
w6 = [τmap(country_nodes6[i]) for i in eachindex(country_nodes6)]
w7 = [τmap(country_nodes7[i]) for i in eachindex(country_nodes7)]
w8 = [τmap(country_nodes8[i]) for i in eachindex(country_nodes8)]
w9 = [τmap(country_nodes9[i]) for i in eachindex(country_nodes9)]
w10 = [τmap(country_nodes10[i]) for i in eachindex(country_nodes10)]
θ = 3π / 2
whirl1 = Whirl(lscene, w1, [0.0 for i in 1:length(w1)], [θ for i in 1:length(w1)], segments, color1, transparency = false)
whirl2 = Whirl(lscene, w2, [0.0 for i in 1:length(w2)], [θ for i in 1:length(w2)], segments, color2, transparency = false)
whirl3 = Whirl(lscene, w3, [0.0 for i in 1:length(w3)], [θ for i in 1:length(w3)], segments, color3, transparency = false)
whirl4 = Whirl(lscene, w4, [0.0 for i in 1:length(w4)], [θ for i in 1:length(w4)], segments, color4, transparency = false)
whirl5 = Whirl(lscene, w5, [0.0 for i in 1:length(w5)], [θ for i in 1:length(w5)], segments, color5, transparency = false)
whirl6 = Whirl(lscene, w6, [θ for i in 1:length(w6)], [2π for i in 1:length(w6)], segments, color6, transparency = true)
whirl7 = Whirl(lscene, w7, [θ for i in 1:length(w7)], [2π for i in 1:length(w7)], segments, color7, transparency = true)
whirl8 = Whirl(lscene, w8, [θ for i in 1:length(w8)], [2π for i in 1:length(w8)], segments, color8, transparency = true)
whirl9 = Whirl(lscene, w9, [θ for i in 1:length(w9)], [2π for i in 1:length(w9)], segments, color9, transparency = true)
whirl10 = Whirl(lscene, w10, [θ for i in 1:length(w10)], [2π for i in 1:length(w10)], segments, color10, transparency = true)
frame1 = Basemap(lscene, x -> G(0, τmap(x)), basemapsegments, basemap_color, transparency = false)
frame2 = Basemap(lscene, x -> G(θ, τmap(x)), basemapsegments, basemap_color, transparency = false)

GLMakie.record(fig, joinpath("gallery", "$modelname.mp4"), 1:frames_number) do frame
    println("Frame: $frame")
    progress = frame / frames_number
    τ(x, ϕ) = begin
        g = convert_to_geographic(x)
        r, _ϕ, _θ = g
        _ϕ += ϕ
        z₁ = ℯ^(im * 0) * √((1 + sin(_θ)) / 2)
        z₂ = ℯ^(im * _ϕ) * √((1 - sin(_θ)) / 2)
        Quaternion([z₁; z₂])
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
    update!(whirl7, τ.(country_nodes7, ϕ), whirl7.θ1, whirl7.θ2)
    update!(whirl8, τ.(country_nodes8, ϕ), whirl8.θ1, whirl8.θ2)
    update!(whirl9, τ.(country_nodes9, ϕ), whirl9.θ1, whirl9.θ2)
    update!(whirl10, τ.(country_nodes10, ϕ), whirl10.θ1, whirl10.θ2)

    lookat = GLMakie.Vec3f(0, 0, 0)
    up = GLMakie.Vec3f(0, 0, 1)
    azimuth = 0 + 0.1 * sin(2π * progress) # set the view angle of the axis
    eyeposition = GLMakie.Vec3f((π / 2 + π / 4) .* convert_to_cartesian([1; azimuth; -π / 6])...)
    GLMakie.update_cam!(lscene.scene, eyeposition, lookat, up)
end
