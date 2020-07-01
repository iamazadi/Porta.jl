datadir = "./data/speechproduction/"
emadir = "mngu0/mngu0_s1_ema_basic_1.1.0/"
labdir = "mngu0/mngu0_s1_lab_1.1.1/"
emafilename = "mngu0_s1_0001.ema"
labfilename = "mngu0_s1_0001.lab"
sample = readest(datadir * emadir * emafilename, datadir * labdir * labfilename)


plane = getplane([0.0; 5.0; 3.5], ℍ([1.0; 0.0; 0.0; 0.0]), [1.0; 13.0; 13.0])
sprite = getsprite(ℝ³(0, 0, 0), ℍ(0, ℝ³(1, 0, 0)))


p₁, p₂, p₃, p₄ = typeof(plane), typeof(sprite), size(sprite), size(plane)


@test p₁ == Array{Float64,3}
@test p₂ == Array{ℝ³,1}
@test p₃ == (6,)
@test p₄ == (2, 2, 3)


@test p₁ != Array{Float64,2}
@test p₂ != Array{ℝ³,3}
@test p₃ != (12,)
@test p₄ != (2, 2)
