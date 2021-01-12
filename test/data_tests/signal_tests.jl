filename = "audio"
extension = ".wav"
filepath = joinpath("..", "data", filename * extension)
@assert(isfile(filepath),
        "The test audio wave file does not exist in path $path.")
channel = 1 # the test audio file is mono
signal = Signal(filepath, channel = channel)

## get properties

framerate = getframerate(signal)
@test isapprox(framerate, 16000)
data = getdata(signal)
@test typeof(data) <: Array{Complex,1}

## get chunks
seconds = countseconds(signal)
@test seconds == 3

chunkspersecond = rand(24:30)
chunksnumber = countchunks(signal, chunkspersecond)
@test chunksnumber > 1

i = rand(1:chunksnumber)
chunk = getchunk(signal, i, chunkspersecond = chunkspersecond)
@test typeof(chunk) <: Signal
@test length(getdata(chunk)) > 1

## analyse and synthesize
frequencysignal = analyse(chunk)
@test typeof(getdata(frequencysignal)) <: Array{Complex,1}
timesignal = synthesize(frequencysignal)
@test typeof(getdata(timesignal)) <: Array{Complex,1}

## perform DFT and FFT
dft = performdft(chunk)
@test typeof(getdata(dft)) <: Array{Complex,1}
minisignal = Signal(getdata(signal)[1:128], framerate)
fft = performfft(minisignal)
@test typeof(getdata(fft)) <: Array{Complex,1}

samplesnumber = rand(3:5)
frequencies = getfftchunk(signal, i, chunkspersecond, samplesnumber)
@test typeof(frequencies) <: Signal
@test length(getdata(frequencies)) > 1
