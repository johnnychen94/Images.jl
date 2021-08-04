module ApplyNoise

using Random
using ImageCore
using ImageCore.MappedArrays
using ImageCore: NumberLike, GenericGrayImage, GenericImage

import ..NoiseAPI: AbstractImageNoise, apply_noise, apply_noise!
import Base: show

# avoid InexactError for Bool array input by promoting it to float
apply_noise(img::AbstractArray{T},
            n::AbstractImageNoise,
            args...; kargs...) where T<:Union{Bool, Gray{Bool}} =
    apply_noise(of_eltype(floattype(eltype(img)), img), n, args...; kargs...)

include("AdditiveWhiteGaussianNoise.jl")

export
    apply_noise, apply_noise!,

    AdditiveWhiteGaussianNoise

end # end module
