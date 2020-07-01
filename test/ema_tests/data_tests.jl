datadir = "./data/speechproduction/"
emadir = "mngu0/mngu0_s1_ema_basic_1.1.0/"
labdir = "mngu0/mngu0_s1_lab_1.1.1/"
emafilename = "mngu0_s1_0001.ema"
labfilename = "mngu0_s1_0001.lab"
sample = readest(datadir * emadir * emafilename, datadir * labdir * labfilename)


@test sample.t[1] < sample.t[2] < sample.t[3] < sample.t[4] < sample.t[5]
@test length(sample.ema) > 0
@test length(sample.taxdist) > 0
@test sample.utt.time[1] < sample.utt.time[2] < sample.utt.time[3]
@test length(sample.utt.time) == length(sample.utt.utterances)
@test sample.name == sample.utt.name
