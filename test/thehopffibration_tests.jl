import Porta
import Test

samples = 360
segments = 30
radius = 0.01
basepoints = convert(Array{Complex}, fill(2im, samples))
fiberactions = [fill(0, samples) fill(2pi, samples)]
q = Porta.ℍ([cos(0); sin(0) .* [sqrt(3)/3; sqrt(3)/3; sqrt(3)/3]])
p = [0.0; 0.0; 0.0]
h = Porta.⭕(basepoints, fiberactions, segments, radius, q, p)
segments2 = Integer(segments ÷ 3)
Test.@test size(h.m) == (samples, segments, segments2, 3)
Test.@test size(h.c) == size(h.m)
