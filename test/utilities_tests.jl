hsv = [rand(1:360); rand(); rand()]
rgb = convert_hsvtorgb(hsv)
@test 0 ≤ rgb[1] ≤ 1 && 0 ≤ rgb[2] ≤ 1 && 0 ≤ rgb[3] ≤ 1


q = ℍ(normalize(ℝ⁴(rand(4))))
@test norm(project(q)) ≤ 1