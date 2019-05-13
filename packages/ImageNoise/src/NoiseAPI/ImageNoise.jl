abstract type AbstractImageNoise <: AbstractImageFilter end

@filter_api apply_noise AbstractImageNoise
@filter_api remove_noise

"""
    apply_noise([::Type,] img, f::AbstractImageNoise, args...)

Add/Apply noise `f` to image `img`.

See also: [`apply_noise!`](@ref apply_noise!)
"""
apply_noise

"""
    apply_noise!([out,] img, f::AbstractImageNoise, args...)

Add/Apply noise `f` to image `img`.

If `out` is specified, it will be changed in place. Otherwise `img` will be changed in place.

See also: [`apply_noise`](@ref apply_noise)
"""
apply_noise!

"""
    remove_noise([::Type,] img, f::AbstractImageFilter, args...)

Remove noise of image `img` using algorithm `f`.

See also: [`remove_noise!`](@ref remove_noise!)
"""
remove_noise

"""
    remove_noise!([out,] img, f::AbstractImageFilter, args...)

Remove noise of image `img` using algorithm `f`.

If `out` is specified, it will be changed in place. Otherwise `img` will be changed in place.

See also: [`remove_noise`](@ref remove_noise)
"""
remove_noise!
