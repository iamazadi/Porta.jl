export Signal
export data
export fps
export seconds
export chunks
export chunk
export dft
export fft

import WAV


"""
analyse(signal)

Converts a signal from the time domain to the frequency domain
with the given signal.
"""
function analyse(signal)
    N = size(signal, 1)
    f(ω) = begin
        scale = 1 / sqrt(N)
        estimate = 0
        for t = 0:N-1
            estimate += signal[t+1] * exp(-im * 2π * ω / N * t)
        end
        scale * estimate
    end
    Ω = Array{Complex}(undef, N)
    for ω = 0:N-1
        Ω[ω+1] = f(ω)
    end
    Ω
end


"""
synthesize(signal)

Converts a signal from the frequency domain to the time domain
with the given signal.
"""
function synthesize(signal)
    N = size(signal, 1)
    f(t) = begin
        scale = 1 / sqrt(N)
        estimate = 0
        for ω = 0:N-1
            estimate += signal[ω+1] * exp(im * 2π * ω / N * t)
        end
        scale * estimate
    end
    T = Array{Complex}(undef, N)
    for t = 0:N-1
        D[t+1] = f(t)
    end
    T
end


struct Signal
    data::Array{Float64}
    fps::Float64
end


Signal(s::String; c=1) = begin
    y, fps = WAV.wavread(s)
    #y = (y .+ 1) ./ 2 # Normalize the signal
    Signal(y[:, c], fps)
end


data(s::Signal) = s.data

fps(s::Signal) = s.fps

seconds(s::Signal) = Int(size(data(s), 1) ÷ fps(s))

chunks(s::Signal, cps::Int) = seconds(s) * cps

"""
chunk(s::Signal, i::Int, cps::Int)

Gets a chunk of a signal such that there are a certain number of chunks per
second with the given signal, the chunk ordinal number and the number of chunks
per second.
"""
function chunk(s::Signal, i::Int, cps::Int)
    samples_per_chunk = Int(fps(s) ÷ cps)
    window = 2^12
    start = (i - 1) * samples_per_chunk + 1
    finish = start + window
    total_samples = size(data(s), 1)
    if finish < total_samples
        return Signal(data(s)[start:finish-1], fps(s))
    else
        return Signal(data(s)[total_samples-window+1:end], fps(s))
    end
end

function fft(s::Signal)
    x = data(s)
    N = size(x, 1)
    if N % 2 > 0
        println("Must be a power of 2.")
        return analyse(x)
    elseif N ≤ 2
        return analyse(x)
    else
        e = fft(Signal(view(x, 2:2:N), fps(s)))
        o = fft(Signal(view(x, 1:2:N-1), fps(s)))
        r = convert(Array{Int64}, floor.(range(0, stop=N-1, length=N)))
        v = exp.(-im .* 2pi .* r ./ N)
        i = Integer(N ÷ 2)
        return [e .+ v[1:i] .* o; e .+ v[i+1:end] .* o]
    end
end

# Discrete Fourier transform
dft(s::Signal) = analyse(data(s))
