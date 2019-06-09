"""
    @filter_api api_name [filter_type=AbstractImageFilter]

This macro it generate two methods:

* `api_name([::Type,] img, f::filter_type, args...; kwargs...)`
* `api_name!([out,] img, f::filter_type, args...; kwargs...)`

For in-place method `api_name!`, `out` will be changed after calling the method.
When `out` is not explicitly passed, `img` will be changed after calling the method.

!!! info

    * Any api implementation needs to support a `f(out, in, args...)` method.
    * This macro is designed to be used in ImagesAPIs, and not downstream packages

## Example:

### 1. register the api in ImagesAPI.jl

```julia
abstract type AbstractImageNoise <: AbstractImageFilter end
@filter_api apply_noise AbstractImageNoise
```

### 2. implement the api in ImageNoise.jl
```julia
import Main.ImagesAPI: AbstractImageNoise, AbstractImageFilter, apply_noise, apply_noise!

export
    apply_noise, apply_noise!,
    AbstractImageNoise,
    AdditiveWhiteGaussianNoise

struct AdditiveWhiteGaussianNoise{T<:AbstractFloat} <: AbstractImageNoise
    mean::T
    std::T
end

function (noise::AdditiveWhiteGaussianNoise)(out, in::AbstractArray)
    @. out = in + noise.std * randn(eltype(out), size(in)) + noise.mean
end
```

### 3. user call the API in a consistent way
```julia
using ImageNoise
noise = AdditiveWhiteGaussianNoise(0.0, 0.1)

# simple usage
apply_noise(ones(3,3), noise)

# inplace changing
img = ones(3,3)
apply_noise!(img, noise)

# preallocation output
img = ones(3,3)
out = zeros(3, 3)
apply_noise!(out, img, noise)
```
"""
macro filter_api(func_name, filter_type = AbstractImageFilter)
    inplace_func_name = Symbol(String(func_name) * "!")
    # TODO: there's little performance improvement on inplce operation over normal one
    @eval begin
        function $(inplace_func_name)(out, img, f::$(filter_type), args...; kwargs...)
            f(out, img, args...; kwargs...)
            out
        end

        function $(inplace_func_name)(img, f::$(filter_type), args...; kwargs...)
            tmp = copy(img)
            f(img, tmp, args...; kwargs...)
        end

        function $(func_name)(::Type{T}, img, f::$(filter_type), args...; kwargs...) where T
            out = Array{T}(undef, size(img))
            $(inplace_func_name)(out, img, f, args...; kwargs...)
            return out
        end

        function $(func_name)(img, f::$(filter_type), args...; kwargs...)
            $(func_name)(eltype(img), img, f, args...; kwargs...)
        end
    end
end
