module ImageNoise

using Reexport

include("NoiseAPI/NoiseAPI.jl")
include("ApplyNoise/ApplyNoise.jl")
include("ReduceNoise/ReduceNoise.jl")

@reexport using .ApplyNoise
@reexport using .ReduceNoise

end # module
