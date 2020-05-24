export loadordownload

import FileIO


function loadordownload(localfname, url)
    path = "data/" * localfname
    FileIO.isfile(path) ? FileIO.load(path) : FileIO.load(FileIO.download(url, localfname))
end
