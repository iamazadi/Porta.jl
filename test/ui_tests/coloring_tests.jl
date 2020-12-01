hsv = [rand(1:360); rand(2)...]
rgb = hsvtorgb(hsv)

@test length(rgb) == 3
