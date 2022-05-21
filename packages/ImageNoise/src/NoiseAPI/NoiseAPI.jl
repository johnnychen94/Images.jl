# This is a temporary module to validate the ideas in
# https://github.com/JuliaImages/ImagesAPI.jl/pull/3
module NoiseAPI

"""
    AbstractImageAlgorithm

The root of image algorithms type system
"""
abstract type AbstractImageAlgorithm end

"""
    AbstractImageFilter <: AbstractImageAlgorithm

Filters are image algorithms whose input and output are both images
"""
abstract type AbstractImageFilter <: AbstractImageAlgorithm end

include("./utils.jl")
include("./ImageNoise.jl")

end
