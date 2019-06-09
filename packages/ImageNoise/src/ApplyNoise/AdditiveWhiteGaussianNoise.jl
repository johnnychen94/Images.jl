"""
    AdditiveWhiteGaussianNoise <: AbstractImageNoise
    AdditiveWhiteGaussianNoise([μ=0.0], σ)

apply white gaussian noise to image

For gray images, it uses the following formula:

    out = clamp01.(in .+ σ .* randn(size(in)) .+ μ)

RGB images are treated as 3D-gray images, generic Color3 images will be
converted to RGB images first.

# Examples
```julia
img = testimage("lena_gray_256")
n = AdditiveWhiteGaussianNoise(0.1)
out = apply_noise(img, n)
```

See also: [`apply_noise`](@ref), [`apply_noise!`](@ref)

# References
[1] Wikipedia contributors. (2019, March 8). Additive white Gaussian noise. In _Wikipedia, The Free Encyclopedia_. Retrieved 14:32, June 9, 2019, from https://en.wikipedia.org/w/index.php?title=Additive_white_Gaussian_noise&oldid=886818982
"""
struct AdditiveWhiteGaussianNoise <: AbstractImageNoise
    """mean"""
    μ::Float64
    """standard deviation"""
    σ::Float64

    function AdditiveWhiteGaussianNoise(μ, σ)
        σ >= zero(σ) || throw(ArgumentError("std σ should be non-negative"))
        new(μ, σ)
    end
end
const AWGN = AdditiveWhiteGaussianNoise
AWGN(σ::Real) = AWGN(zero(σ), σ)

show(io::IO, n::AWGN) = println(io, "AdditiveWhiteGaussianNoise(μ=", n.μ, ", σ=", n.σ, ")")

function (n::AWGN)(out::AbstractArray{T},
                   in::GenericGrayImage;
                   rng::Union{AbstractRNG, Nothing} = nothing
                   ) where T<:Number
    if rng === nothing
        _rand = x->randn(floattype(T), size(x))
    else
        _rand = x->randn(rng, floattype(T), size(x))
    end
    out .= clamp01.(in .+ n.σ .* _rand(in) .+ n.μ)
end

for T in (AbstractGray, AbstractRGB)
    @eval function (n::AWGN)(out::AbstractArray{<:$T},
                             in::GenericImage;
                             rng::Union{AbstractRNG, Nothing} = nothing)
        n(channelview(out), channelview(in); rng=rng)
    end
end

# Since generic Color3 aren't vector space, they are converted to RGB images
(n::AWGN)(out::AbstractArray{<:Color3},
         in::GenericImage;
         rng::Union{AbstractRNG, Nothing} = nothing) =
    n(channelview(of_eltype(RGB, out)),
      channelview(of_eltype(RGB, in));
      rng=rng)
