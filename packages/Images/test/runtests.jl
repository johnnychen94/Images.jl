include("core.jl")
include("scaling.jl")
include("algorithms.jl")
include("io.jl")
include("readnrrd.jl")
@linux_only include("readremote.jl")
@windows_only include("readremote.jl")
@osx_only include("readOSX.jl")
