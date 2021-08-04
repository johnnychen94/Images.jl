module ReduceNoise

using Base.Iterators
using ImageCore
using ImageCore.MappedArrays
using ImageCore.OffsetArrays
using ImageCore.PaddedViews
using ImageCore: NumberLike, GenericGrayImage, GenericImage
import ..NoiseAPI: AbstractImageDenoiseAlgorithm, reduce_noise, reduce_noise!

include("compat.jl")
include("NonlocalMean.jl")

export
    reduce_noise, reduce_noise!,

    # Non-local mean filter for gaussian noise
    NonlocalMean, get_NonlocalMean_rp

end # module
