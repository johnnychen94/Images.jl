using ImageNoise
using ImageCore, ImageTransformations, ImageQualityIndexes
using Test, ReferenceTests, TestImages, Random

include("testutils.jl")

@testset "ImageNoise" begin
# ApplyNoise
@info "Test: ApplyNoise"
include("ApplyNoise/AdditiveWhiteGaussianNoise.jl")

# ReduceNoise
@info "Test: ReduceNoise"
include("ReduceNoise/NonlocalMean.jl")
end

nothing
