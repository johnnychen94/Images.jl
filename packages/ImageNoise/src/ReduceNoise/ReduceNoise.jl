module ReduceNoise

using Base.Iterators
using MappedArrays
using OffsetArrays
using ImageCore
using ImageCore: NumberLike, GenericGrayImage, GenericImage
using ImageFiltering
using ColorVectorSpace
import ..NoiseAPI: AbstractImageDenoiseAlgorithm, reduce_noise, reduce_noise!

include("compat.jl")
include("NonlocalMean.jl")

export
    reduce_noise, reduce_noise!,

    # Non-local mean filter for gaussian noise
    NonlocalMean, get_NonlocalMean_rp

end # module
