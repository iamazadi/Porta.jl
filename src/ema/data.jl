export readest


"""
    parseheader(path)

Read and parse the header from file object with the given path.
"""
function parseheader(path)
    # defaults
    datatype = "binary"
    byteorder = 'l'
    rows = 0
    columns = 0
    channelnames = []
    getvalue(x) = strip(x[findfirst(' ', x):end])
    lines = readlines(path)
    if length(lines) == 0
        println("Found zero lines: $path.")
    elseif strip(lines[1]) != "EST_File Track"
        println("Not an EST Track file: $path.")
    else
        index = 2
        line = strip(lines[index])
        while line != "EST_Header_End"
            if line == "DataType ascii"
                datatype = "ascii"
            elseif line == "DataType binary"
                datatype = "binary"
            elseif line == "ByteOrder 01"
                byteorder = "<"
            elseif line == "ByteOrder 10"
                byteorder = ">"
            elseif occursin("NumChannels", line)
                columns = parse(Int64, getvalue(line))
            elseif occursin("NumFrames", line)
                rows = parse(Int64, getvalue(line))
            elseif occursin("Channel_", line)
                push!(channelnames, getvalue(line))
            end
            index += 1
            line = strip(lines[index])
        end
    end
    datatype, rows, columns, byteorder, convert(Array{String}, channelnames)
end


struct Channel
    coordinates::Array{ℝ³}
    orientation::Array{ℍ}
    rms::Array{Float64}
    newflag::Array{Float64}
    name::String
end


struct Utterance
    time::Array{Float64}
    utterances::Array{String}
    name::String
end

# ema, utt, wav
struct Sample
    t::Array{Float64}
    ema::Array{Channel}
    utt::Utterance
    taxdist::Array{Float64}
    name::String
end


"""
    getutterance(path::String)

Get utterance with the given file path.
"""
function getutternace(path::String)
    time = []
    utterances = []
    name = ""
    gettime(x) = begin
        i = findall(isequal(' '), x)
        parse(Float64, strip(x[i[1]:i[2]]))
    end
    getutt(x) = begin
        i = findall(isequal(' '), x)
        withtab = strip(x[i[3]:end])
    end
    for line in eachline(path)
        if startswith(line, "filename")
            v = strip(line[findfirst(' ', line):end])
            name = v[nextind(v, findlast('/', v)):prevind(v, lastindex(v), 5)]
        end
    end
    io = open(path)
    readuntil(io, "#\n", keep=true)
    line = readline(io)
    while strip(line) != ""
        push!(time, gettime(line))
        push!(utterances, getutt(line))
        line = readline(io)
    end
    close(io)
    Utterance(time, utterances, name)
end


"""
    getsample(data::Array{Float64,2}, channelnames::Array{String}, samplename::String)

Get a sample with the given data, channel names and sample name.
"""
function getsample(data::Array{Float64,2},
                   channelnames::Array{String},
                   samplename::String,
                   labpath::String)
    time = data[:, 1]
    taxdist = similar(time)
    channels = []
    validind(x) = x == nothing ? 1 : x
    getlabel(x) = strip(x[validind(findfirst(' ' , x)):end])
    getname(x) = strip(x[begin:prevind(x, validind(findlast('_', x)))])
    getflag(x) = strip(x[nextind(x, validind(findlast('_', x))):end])
    for i in 1:length(channelnames)
        label = getlabel(channelnames[i])
        name = getname(label)
        if label == "taxdist"
            taxdist = data[:, i]
            continue
        elseif length(findall(x -> x.name == name, channels)) > 0
            continue # no duplicates
        end
        px, py, pz = similar(time), similar(time), similar(time)
        ox, oy, oz = similar(time), similar(time), similar(time)
        coordinates = Array{ℝ³}(undef, length(time))
        orientation = Array{ℍ}(undef, length(time))
        rms, newflag = similar(time), similar(time)
        indices = findall(x -> occursin(name, x), channelnames)
        for j in indices
            flag = getflag(getlabel(channelnames[j]))
            if flag == "rms"
                rms = data[:, j+2]
            elseif flag == "newflag"
                newflag = data[:, j+2]
            elseif in(flag, ["px", "tx"])
                px = data[:, j+2]
            elseif in(flag, ["py", "ty"])
                py = data[:, j+2]
            elseif in(flag, ["pz", "tz"])
                pz = data[:, j+2]
            elseif in(flag, ["ox", "rx"])
                ox = data[:, j+2]
            elseif in(flag, ["oy", "ry"])
                oy = data[:, j+2]
            elseif in(flag, ["oz", "rz"])
                oz = data[:, j+2]
            else
                println("Found an unexpected flag.")
            end
        end
        coordinates = [ℝ³(row) for row in eachrow([px py pz])]
        orientation = [ℍ(ℝ³(row)) for row in eachrow([ox oy oz])]
        push!(channels, Channel(coordinates, orientation, rms, newflag, name))
    end
    utterance = getutternace(labpath)
    Sample(time, channels, utterance, taxdist, samplename)
end


"""
    readest(path::String)

Read data from EST Track format file with the given path.
"""
function readest(path::String, labpath::String)
    datatype, rows, columns, byteorder, channelnames = parseheader(path)
    io = open(path)
    readuntil(io, "EST_Header_End\n", keep=true)
    data = Array{Float32,2}(undef, columns+2, rows)
    if datatype == "binary"
        read!(io, data)
    else
        println("Not a binary EST Track: $path.")
    end
    name = path[nextind(path, findlast('/', path)):prevind(path, lastindex(path), 5)]
    getsample(convert(Array{Float64,2}, transpose(data)), channelnames, name, labpath)
end
