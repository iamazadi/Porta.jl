import WAV

export Signal
export getdata
export getframerate
export analyse
export synthesize
export performdft
export performfft
export countseconds
export countchunks
export getchunk
export getfftchunk


"""
    Represents an audio signal.

fields: data and framerate.
"""
struct Signal
    data::Array{Complex,1}
    framerate::Float64
end


"""
    Signal(filepath [, channel])

Read a wave file and instantiate a Signal with the given `filepath` and
`channel`. Stereo audio files should contain 2 channels.
"""
Signal(filepath::String; channel::Int = 1) = begin
    data, framerate = WAV.wavread(filepath)
    Signal(Complex.(data[:, channel]), framerate)
end


getdata(signal::Signal) = signal.data
getframerate(signal::Signal) = signal.framerate


"""
    countseconds(signal)

Return the period of an audio signal in seconds with the given `signal`.
"""
function countseconds(signal::Signal)
    Int(length(getdata(signal)) ÷ getframerate(signal))
end


"""
    countchunks(signal, chunkspersecond)

Return the number of data chunks that an audio signal contains with the given
`signal` and chunks per second `chunkspersecond`.
"""
function countchunks(signal::Signal, chunkspersecond::Int)
    countseconds(signal) * chunkspersecond
end


"""
    analyse(signal)

Convert an audio signal from time domain to frequency domain with the given
`signal`.
"""
function analyse(signal::Signal)
    data = getdata(signal)
    framerate = getframerate(signal)
    N = length(data)
    f(ω) = begin
        scale = 1 / sqrt(N)
        estimate = 0
        for t = 0:N-1
            estimate += data[t+1] * exp(-im * 2π * ω / N * t)
        end
        scale * estimate
    end
    Ω = Array{Complex,1}(undef, N)
    for ω = 0:N-1
        Ω[ω+1] = f(ω)
    end
    Signal(Ω, framerate)
end


"""
    synthesize(signal)

Convert an audio signal from frequency domain to time domain with the given
`signal`.
"""
function synthesize(signal::Signal)
    data = getdata(signal)
    framerate = getframerate(signal)
    N = length(data)
    f(t) = begin
        scale = 1 / sqrt(N)
        estimate = 0
        for ω = 0:N-1
            estimate += data[ω+1] * exp(im * 2π * ω / N * t)
        end
        scale * estimate
    end
    T = Array{Complex,1}(undef, N)
    for t = 0:N-1
        T[t+1] = f(t)
    end
    Signal(T, framerate)
end


"""
    performdft(signal)

Perform a Discrete Fourier Transform (DFT) on an audio signal with the given
`signal`.
"""
function performdft(signal::Signal)
    analyse(signal)
end


"""
    performfft(signal)

Perform Fast Fourier Transform (FFT) on an audio signal with the given `signal`.
"""
function performfft(signal::Signal)
    data = getdata(signal)
    framerate = getframerate(signal)
    N = length(data)
    if N % 2 > 0
        println("The length of a data chunk must be a power of 2.")
        return analyse(signal)
    elseif N ≤ 2
        return analyse(signal)
    else
        e = getdata(performfft(Signal(view(data, 2:2:N), framerate)))
        o = getdata(performfft(Signal(view(data, 1:2:N-1), framerate)))
        r = convert(Array{Int64}, floor.(range(0, stop=N-1, length=N)))
        v = exp.(-im .* 2pi .* r ./ N)
        i = Integer(N ÷ 2)
        return Signal([e .+ v[1:i] .* o; e .+ v[i+1:end] .* o], framerate)
    end
end


"""
    getchunk(signal, i, [, chunkspersecond [, offset]])

Return a chunk of an audio signal with the given `signal`, the chunk ordinal
number `i` and the number of chunks per second `chunkspersecond`. The optional
arguments `offset` shifts the sampling window in the time dimension. Supply
`offset` for collecting multiple consecutive chunks and then taking the average.
"""
function getchunk(signal::Signal, i::Int; chunkspersecond::Int = 30,
                  offset::Int = 0)
    data = getdata(signal)
    framerate = getframerate(signal)
    samplesperchunk = Int(framerate ÷ chunkspersecond)
    window = 2^(Int(ceil(log2(samplesperchunk))))
    origin = (i - 1) * samplesperchunk + 1
    start = origin + offset
    finish = origin + window + offset
    totalsamples = size(data, 1)
    if finish ≤ totalsamples
        return Signal(data[start:finish-1], framerate)
    else
        return Signal(data[total_samples-window+1:end], framerate)
    end
end


"""
    getfftchunk(signal, i, chunkspersecond , samples)

Get a chunck of an audio signal under FFT by averaging over a number of
consecutive samples such that two consecutive samples differ only in a single
frame in the time dimension, with the given `signal`, the chunk cardinal number
`i`, the number of chunks per second `chunkspersecond` and the number of
consecutive `samples` to use before taking the average.
"""
function getfftchunk(signal::Signal, i::Int, chunkspersecond::Int, samples::Int)
    framerate = getframerate(signal)
    array = []
    for j in 1:samples
        sₜ = getdata(getchunk(signal, i, chunkspersecond = chunkspersecond,
                              offset = j))
        push!(array, getdata(performfft(Signal(sₜ, framerate))))
    end
    sum = array[1]
    for j in 2:samples
        sum = sum .+ array[j]
    end
    average = sum ./ samples
    Signal(average, framerate)
end
