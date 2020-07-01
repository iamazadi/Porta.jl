using FileIO
using Makie
using Porta


# test/data/speechproduction/mngu0/mngu0_s1_ema_basic_1.1.0/mngu0_s1_0001.ema
datadir = "./test/data/speechproduction/"
emadir = "mngu0/mngu0_s1_ema_basic_1.1.0/"
labdir = "mngu0/mngu0_s1_lab_1.1.1/"
emafilename = "mngu0_s1_0001.ema"
labfilename = "mngu0_s1_0001.lab"
sample = readest(datadir * emadir * emafilename, datadir * labdir * labfilename)
frames = length(sample.t)

scene = Scene(camera = cam3d!)
eye_position, lookat = [50.0; 0.0; 0.0], [0.0; 0.0; 0.0]
imagename = "articulators"
imagepath = datadir * imagename * ".jpg"

plane = getplane([0.0; 5.0; 3.5], ℍ([1.0; 0.0; 0.0; 0.0]), [1.0; 13.0; 13.0])
surface!(scene,
         plane[:, :, 1],
         plane[:, :, 2],
         plane[:, :, 3],
         color = load(imagepath),
         transparency = true,
         shading = false)

sprites = Node([getsprite(ℝ³(0, 0, 0), ℍ(0, ℝ³(1, 0, 0)))
               for i in 1:length(sample.ema)])
sprites_linesegments = @lift begin
    array = []
    for i in 1:length(sample.ema)
        s = map(x -> Point3f0(vec(x)), $sprites[i])
        push!(array, [s[1] => s[2], s[3] => s[4], s[5] => s[6]])
    end
    array
end
for i in 1:length(sample.ema)
    linesegments!(scene,
                  @lift($sprites_linesegments[i]),
                  color = [:red, :green, :blue],
                  linewidth=5)
end

utterance = Node("#")
h = getrotation([0.0; 0.0; 1.0], eye_position)
q = Quaternion(vec(h)[2:4]..., vec(h)[1])
label_scene = text!(scene,
                    utterance,
                    position = (0, 0),
                    textsize = 10,
                    font = "Blackchancery")[end]

center!(scene) # center the Scene on the display
update_cam!(scene, eye_position, lookat) # update eye position
scene.center = false # prevent scene from recentering on display
function animate(i)
    sprites[] = [getsprite(c.coordinates[i], c.orientation[i]) for c in sample.ema]
    search(i, s) = s.utt.utterances[findmin(abs.(s.utt.time .- s.t[i]))[2]]
    utterance[] = search(i, sample)
    translate!(label_scene, Vec3f0(lookat))
    rotate!(label_scene, q)
end

record(scene, "gallery/speechproduction.gif", 1:frames; framerate = 200) do i
    animate(i) # animate scene
end
