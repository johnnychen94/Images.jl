# usage example for package developer:
#
#     import EdgeDetectionAPI: AbstractEdgeThinningAlgorithm,
#                             thin_edges, thin_edges!

"""
    AbstractEdgeThinningAlgorithm <: AbstractImageFilter

A root type for `ImageEdgeDetection` package.

Any concrete edge thinning algorithm shall subtype it to support
[`thin_edges`](@ref) and [`thin_edges!`](@ref) APIs.

# Examples

All edge thinning algorithms in ImageEdgeDetection are called in the
following pattern:

```julia
# first generate an algorithm instance
f = NonmaximaSuppression()

# determine the image gradients
g₁, g₂ = imgradients(img, KernelFactors.scharr)

# determine the gradient magnitude
mag = hypot.(g₁, g₂)

# then pass the algorithm to `thin_edges`
thinned_edges = thin_edges(mag, g₁, g₂, f)

# or use in-place version `thin_edges!`
thinned_edges = zeros(eltype(mag), axes(mag))
thin_edges!(thinned_edges, mag, g₁, g₂, f)
```

For more examples, please check [`thin_edges`](@ref),
[`thin_edges!`](@ref) and concrete algorithms.
"""
abstract type AbstractEdgeThinningAlgorithm <: AbstractImageFilter end

thin_edges(mag::AbstractArray, g₁::AbstractArray, g₂::AbstractArray,
           f::AbstractEdgeThinningAlgorithm,
           args...; kwargs...) =
           f(zeros(eltype(mag), axes(mag)), mag, g₁, g₂, args... ; kwargs...)


function thin_edges(::Type{T},
                    mag::AbstractArray,
                    g₁::AbstractArray,
                    g₂::AbstractArray,
                    f::AbstractEdgeThinningAlgorithm,
                    args...; kwargs...) where T
         out = zeros(T, axes(mag))
         detect_edges!(out, mag, g₁, g₂, f, args...; kwargs...)
    return out
end

thin_edges!(out::AbstractArray, mag::AbstractArray, g₁::AbstractArray, g₂::AbstractArray,
            f::AbstractEdgeThinningAlgorithm,
            args...; kwargs...) =
         f(out, mag, g₁, g₂, args...; kwargs...)


### Docstrings

"""
    thin_edges!([out,] mag, g₁, g₂, f::AbstractEdgeThinningAlgorithm, args...; kwargs...)

    Isolate local maxima of gradient magnitude `mag` along the local gradient
    direction. The arguments `g₁` and `g₂` represent the  gradient in the first
    spatial dimension (y), and the second spatial dimension (x), respectively.

# Output

If `out` is specified, it will be changed in place. Otherwise `mag` will be changed in place.

# Examples

Just simply pass an algorithm to `thin_edges!`:

```julia
using TestImages, ImageFiltering
img =  Gray.(testimage("mandril"))

# Gradient in the first and second spatial dimension
g₁, g₂ = imgradients(img, KernelFactors.scharr)

# Gradient magnitude
mag = hypot.(g₁, g₂)

thinned_edges = zeros(eltype(mag), axes(mag))
thin_edges!(thinned_edges, mag, g₁, g₂, f)
```

For cases you just want to change `mag` in place, you don't necessarily need to manually
allocate `thinned_edges`; just use the convenient method:

```julia
thin_edges!(mag, g₁, g₂, f)
```

See also: [`thin_edges`](@ref)
"""
thin_edges!

"""
    thin_edges([T::Type,] mag, g₁, g₂, f::AbstractEdgeThinningAlgorithm, args...; kwargs...)

Using algorithm `f`, thin the edge-response based on the edge magnitude `mag`,
the  gradient in the first spatial dimension `g₁`, and the gradient in the
second spatial dimension `g₂`.

# Output

Returns an `Array{T}` representing the thinned edge response.

If `T` is not specified, then it's inferred.
# Examples

Just simply pass the input image and algorithm to `thin_edges`

```julia
using TestImages, ImageFiltering
img =  Gray.(testimage("mandril"))

# Gradient in the first and second spatial dimension
g₁, g₂ = imgradients(img, KernelFactors.scharr)

# Gradient magnitude
mag = hypot.(g₁, g₂)

thinned_edges = thin_edges(mag, g₁, g₂, f)
```

This reads as "`thin_edges` based on the edge response magnitude, and spatial gradients, using algorithm `f`".

You can also explicitly specify the return type:

```julia
thinned_edges_float32 = thin_edges(Gray{Float32}, mag, g₁, g₂, f)
```

See also [`thin_edges!`](@ref) for in-place edge thinning.
"""
thin_edges
