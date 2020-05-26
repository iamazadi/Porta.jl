import Porta
import Test

samples = 36
markerradius = 0.01
segments = 36
basecenter = [0.0; 0.0; 0.0]
basecolor = [0.3; 0.3; 0.3]
baseradius = 1.0
markercenter = [rand(samples) rand(samples) rand(samples)]
markercolor = [rand(samples) rand(samples) rand(samples)]
basemap = Porta.🌐(basecenter,
                   basecolor,
                   baseradius,
                   markercenter,
                   markercolor,
                   markerradius,
                   segments)
Test.@test size(basemap.basemanifold) == (segments, segments, 3)
Test.@test size(basemap.basecolor) == size(basemap.basemanifold)
Test.@test size(basemap.markermanifold) == (samples, segments, segments, 3)
Test.@test size(basemap.markercolor) == size(basemap.markermanifold)
