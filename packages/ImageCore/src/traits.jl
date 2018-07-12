"""
    pixelspacing(img) -> (sx, sy, ...)

Return a tuple representing the separation between adjacent pixels
along each axis of the image.  Defaults to (1,1,...).  Use
ImagesAxes for images with anisotropic spacing or to encode the
spacing using physical units.
"""
pixelspacing(img::AbstractArray{T,N}) where {T,N} = ntuple(d->1, Val(N))
# Some of these traits need to work recursively into "container" types
pixelspacing(img::AbstractMappedArray) = pixelspacing(parent(img))
pixelspacing(img::OffsetArray) = pixelspacing(parent(img))
@inline pixelspacing(img::SubArray) =
    _subarray_filter(pixelspacing(parent(img)), img.indices...)
@inline pixelspacing(img::Base.PermutedDimsArrays.PermutedDimsArray{T,N,perm}) where {T,N,perm} =
    _getindex_tuple(pixelspacing(parent(img)), perm)

"""
    spacedirections(img) -> (axis1, axis2, ...)

Return a tuple-of-tuples, each `axis[i]` representing the displacement
vector between adjacent pixels along spatial axis `i` of the image
array, relative to some external coordinate system ("physical
coordinates").

By default this is computed from `pixelspacing`, but you can set this
manually using ImagesMeta.
"""
spacedirections(img::AbstractArray) = _spacedirections(pixelspacing(img))
spacedirections(img::AbstractMappedArray) = spacedirections(parent(img))
spacedirections(img::OffsetArray) = spacedirections(parent(img))
@inline spacedirections(img::SubArray) =
    _subarray_filter(spacedirections(parent(img)), img.indices...)
@inline spacedirections(img::Base.PermutedDimsArrays.PermutedDimsArray{T,N,perm}) where {T,N,perm} =
    _getindex_tuple(spacedirections(parent(img)), perm)

function _spacedirections(ps::NTuple{N,Any}) where N
    ntuple(i->ntuple(d->d==i ? ps[d] : zero(ps[d]), Val(N)), Val(N))
end

"""
    sdims(img)

Return the number of spatial dimensions in the image. Defaults to the
same as `ndims`, but with ImagesAxes you can specify that some axes
correspond to other quantities (e.g., time) and thus not included by
`sdims`.
"""
sdims(img::AbstractArray) = length(coords_spatial(img))

"""
   coords_spatial(img)

Return a tuple listing the spatial dimensions of `img`.

Note that a better strategy may be to use ImagesAxes and take slices along the time axis.
"""
@inline coords_spatial(img::AbstractArray{T,N}) where {T,N} = ntuple(identity, Val(N))

coords_spatial(img::AbstractMappedArray) = coords_spatial(parent(img))
coords_spatial(img::OffsetArray) = coords_spatial(parent(img))
@inline coords_spatial(img::SubArray) =
    _subarray_offset(0, coords_spatial(parent(img)), img.indices...)
@inline coords_spatial(img::Base.PermutedDimsArrays.PermutedDimsArray{T,N,perm,iperm}) where {T,N,perm,iperm} =
    _getindex_tuple(coords_spatial(parent(img)), iperm)



"""
    nimages(img)

Return the number of time-points in the image array. Defaults to
1. Use ImagesAxes if you want to use an explicit time dimension.
"""
nimages(img::AbstractArray) = 1
nimages(img::AbstractMappedArray) = nimages(parent(img))
nimages(img::OffsetArray) = nimages(parent(img))
nimages(img::SubArray) = nimages(parent(img))
nimages(img::Base.PermutedDimsArrays.PermutedDimsArray) = nimages(parent(img))

"""
    size_spatial(img)

Return a tuple listing the sizes of the spatial dimensions of the
image. Defaults to the same as `size`, but using ImagesAxes you can
mark some axes as being non-spatial.
"""
size_spatial(img) = size(img)
size_spatial(img::AbstractMappedArray) = size_spatial(parent(img))
size_spatial(img::OffsetArray) = size_spatial(parent(img))
@inline size_spatial(img::SubArray) =
    _subarray_filter(size_spatial(parent(img)), img.indices...)
@inline size_spatial(img::Base.PermutedDimsArrays.PermutedDimsArray{T,N,perm}) where {T,N,perm} =
    _getindex_tuple(size_spatial(parent(img)), perm)

"""
    indices_spatial(img)

Return a tuple with the indices of the spatial dimensions of the
image. Defaults to the same as `indices`, but using ImagesAxes you can
mark some axes as being non-spatial.
"""
indices_spatial(img) = axes(img)
indices_spatial(img::AbstractMappedArray) = indices_spatial(parent(img))
@inline indices_spatial(img::SubArray) =
    _subarray_filter(indices_spatial(parent(img)), img.indices...)
@inline indices_spatial(img::Base.PermutedDimsArrays.PermutedDimsArray{T,N,perm}) where {T,N,perm} =
    _getindex_tuple(indices_spatial(parent(img)), perm)

#### Utilities for writing "simple algorithms" safely ####
# If you don't feel like supporting multiple representations, call these

"""
    assert_timedim_last(img)

Throw an error if the image has a time dimension that is not the last
dimension.
"""
assert_timedim_last(img::AbstractArray) = nothing
assert_timedim_last(img::AbstractMappedArray) = assert_timedim_last(parent(img))
assert_timedim_last(img::OffsetArray) = assert_timedim_last(parent(img))
assert_timedim_last(img::SubArray) = assert_timedim_last(parent(img))

widthheight(img::AbstractArray) = length(axes(img,2)), length(axes(img,1))

width(img::AbstractArray) = widthheight(img)[1]
height(img::AbstractArray) = widthheight(img)[2]


# Traits whose only meaningful definitions occur in ImageAxes, but for
# which we want nesting behavior
spatialorder(img::AbstractMappedArray) = spatialorder(parent(img))
spatialorder(img::OffsetArray) = spatialorder(parent(img))
@inline spatialorder(img::Base.PermutedDimsArrays.PermutedDimsArray{T,N,perm}) where {T,N,perm} =
    _getindex_tuple(spatialorder(parent(img)), perm)

# Utilities

@inline _subarray_filter(x, i::Real, inds...) =
    _subarray_filter(tail(x), inds...)
@inline _subarray_filter(x, i, inds...) =
    (x[1], _subarray_filter(tail(x), inds...)...)
_subarray_filter(x::Tuple{}) = ()

@inline _subarray_offset(off, x, i::Real, inds...) =
    _subarray_offset(off-1, tail(x), inds...)
@inline _subarray_offset(off, x, i, inds...) =
    (x[1]+off, _subarray_offset(off, tail(x), inds...)...)
_subarray_offset(off, x::Tuple{}) = ()

@inline _getindex_tuple(t::Tuple, inds::Tuple) =
    (t[inds[1]], _getindex_tuple(t, tail(inds))...)
_getindex_tuple(t::Tuple, ::Tuple{}) = ()
