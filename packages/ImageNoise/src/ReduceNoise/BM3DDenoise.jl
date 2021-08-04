using UUIDs
const BM3DDenoise = Base.PkgId(UUID("95fb3b36-088a-43fb-bb1b-b1f34fadbd7d"), "BM3DDenoise")

# Rewrite from ImageIO.jl
function checked_import(pkgid)
    Base.root_module_exists(pkgid) && return Base.root_module(pkgid)
    # If not available, load the library or throw an error.
    Base.require(pkgid)
end


@doc raw"""
    BM3D(σ [, config=bm3d_config()])

The BM3D(sparse 3D transform-domain collaborative filtering) denoising algorithm.

# Arguments

* `σ::Float64` is the variance of the noise.

* `config::bm3d_config` is `BM3DDenoise.bm3d_config`.

# Examples

```julia
img = testimage("lena_color_256")

n = AdditiveWhiteGaussianNoise(0.1)
noisy_img = apply_noise(img, n)

# use default arguments
f_denoise = BM3D(0.1)
denoised_img = reduce_noise(noisy_img, f_denoise)
```

See also: [`reduce_noise`](@ref), [`reduce_noise!`](@ref)
"""
struct BM3D <: AbstractImageDenoiseAlgorithm
    """degree of filtering"""
    σ::Float64
    """bm3d_config"""
    config
    function BM3D(σ, config)
        σ > 0 || @warn "σ is supposed to be positive"
        new(σ, config)
    end
end
BM3D(σ) = BM3D(σ, Base.invokelatest(checked_import(BM3DDenoise).bm3d_config))

function (f::BM3D)(out::AbstractArray{T},
                           img::AbstractArray) where T
    axes(out) == axes(img) || ArgumentError("Images should have the same axes.")
    out .= T.(Base.invokelatest(checked_import(BM3DDenoise).bm3d, img, f.σ, f.config))
    return out
end