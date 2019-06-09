abstract type AbstractImageNoise <: AbstractImageFilter end
abstract type AbstractImageDenoiseAlgorithm <: AbstractImageFilter end

@filter_api apply_noise AbstractImageNoise
@filter_api reduce_noise AbstractImageDenoiseAlgorithm

"""
    apply_noise([::Type,] img, n::AbstractImageNoise, args...; rng=GLOBAL_RNG, kwargs...)

Add/Apply noise `n` to image `img`.

# Examples

```julia
n = AdditiveWhiteGaussianNoise(0.1)
img = testimage("lena_gray_256")
apply_noise(img, n)

# sometimes we need to pass `rng` keyword argument to
# generate reproducible noise
apply_noise(img, n; rng = MersenneTwister(0))
```

See also: [`apply_noise!`](@ref apply_noise!)
"""
apply_noise

"""
    apply_noise!([out,] img, n::AbstractImageNoise, args...; rng=GLOBAL_RNG, kwargs...)

Add/Apply noise `n` to image `img`.

If `out` is specified, it will be changed in place. Otherwise `img` will be changed in place.

# Examples

```julia
n = AdditiveWhiteGaussianNoise(0.1)
img = testimage("lena_gray_256")
apply_noise!(img, n)

# sometimes we need to pass `rng` keyword argument to
# generate reproducible noise
apply_noise!(img, n; rng = MersenneTwister(0))
```

See also: [`apply_noise`](@ref apply_noise)
"""
apply_noise!

"""
    reduce_noise([::Type,] img, f::AbstractImageDenoiseAlgorithm, args...)

Remove noise of image `img` using algorithm `f`.

See also: [`reduce_noise!`](@ref reduce_noise!)
"""
reduce_noise

"""
    reduce_noise!([out,] img, f::AbstractImageDenoiseAlgorithm, args...)

Remove noise of image `img` using algorithm `f`.

If `out` is specified, it will be changed in place. Otherwise `img` will be changed in place.

See also: [`reduce_noise`](@ref reduce_noise)
"""
reduce_noise!
