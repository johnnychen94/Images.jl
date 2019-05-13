module ImageNoise

using Distributions

include("NoiseAPI/NoiseAPI.jl")
import .NoiseAPI: AbstractImageFilter,
        remove_noise, remove_noise!,
        apply_noise, apply_noise!

end # module
