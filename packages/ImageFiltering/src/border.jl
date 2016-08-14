# module Border

using OffsetArrays, CatIndices
using Base: Indices, tail, fill_to_length

abstract AbstractBorder

"""
`Pad{Style,N}` is a type that stores choices about padding. `Style` is a
Symbol specifying the boundary conditions of the image, one of
`:replicate` (repeat edge values to infinity), `:circular` (image edges
"wrap around"), `:symmetric` (the image reflects between pixels), or
`:reflect` (the image reflects on the pixel grid). The default value is
`:replicate`. You can add custom boundary conditions by adding
addition methods for `padindex`.
"""
immutable Pad{Style,N} <: AbstractBorder
    lo::Dims{N}    # number to extend by on the lower edge for each dimension
    hi::Dims{N}    # number to extend by on the upper edge for each dimension
end

"""
    Pad{Style}(m, n, ...)

Pad the input image symmetrically, `m` pixels at the lower and upper edge of dimension 1, `n` pixels for dimension 2, and so forth.
"""
(::Type{Pad{Style}}){Style}(both::Int...) = Pad{Style}(both, both)
"""
    Pad{Style}((m,n))

Pad the input image symmetrically, `m` pixels at the lower and upper edge of dimension 1, `n` pixels for dimension 2.
"""
(::Type{Pad{Style}}){Style,N}(both::Dims{N}) = Pad{Style,N}(both, both)

(::Type{Pad{Style}}){Style  }(lo::Tuple{}, hi::Tuple{}) = Pad{Style,0}(lo, hi)

"""
    Pad{Style}(lo::Dims, hi::Dims)

Pad the input image by `lo` pixels at the lower edge, and `hi` pixels at the upper edge.
"""
(::Type{Pad{Style}}){Style,N}(lo::Dims{N}, hi::Dims{N}) = Pad{Style,N}(lo, hi)
(::Type{Pad{Style}}){Style,N}(lo::Dims{N}, hi::Tuple{}) = Pad{Style,N}(lo, ntuple(d->0,Val{N}))
(::Type{Pad{Style}}){Style,N}(lo::Tuple{}, hi::Dims{N}) = Pad{Style,N}(ntuple(d->0,Val{N}), hi)
(::Type{Pad{Style}}){Style,N}(inds::Indices{N}) = Pad{Style,N}(map(lo,inds), map(hi,inds))

(::Type{Pad{Style,N}}){Style,N}(lo::AbstractVector, hi::AbstractVector) = Pad{Style,N}((lo...,), (hi...,))
(::Type{Pad{Style}}){Style}(lo::AbstractVector, hi::AbstractVector) = Pad{Style}((lo...,), (hi...,))  # not inferrable


"""
    Pad{Style}(kernel)

Given a filter array `kernel`, determine the amount of padding from the `indices` of `kernel`.
"""
(::Type{Pad{Style}}){Style}(kernel::AbstractArray) = Pad{Style}(indices(kernel))
(::Type{Pad{Style}}){Style}(factkernel::Tuple) = Pad{Style}(extremize(indices(factkernel[1]), tail(factkernel)...))
(::Type{Pad{Style}}){Style}(factkernel::Tuple, img, ::FIR) = Pad{Style}(factkernel)
(::Type{Pad})(args...) = Pad{:replicate}(args...)

# Padding for FFT: round up to next size expressible as 2^m*3^n
function (::Type{Pad{Style}}){Style}(factkernel::Tuple, img, ::FFT)
    inds = extremize(indices(factkernel[1]), tail(factkernel)...)
    newinds = map(padfft, inds, map(length, indices(img)))
    Pad{Style}(newinds)
end
function padfft(indk::AbstractUnitRange, l::Integer)
    lk = length(indk)
    range(first(indk), nextprod([2,3], l+lk)-l+1)
end

function padindices{_,Style,N}(img::AbstractArray{_,N}, border::Pad{Style})
    warn("$border lacks the proper padding sizes for an array with $(ndims(img)) dimensions")
    padindices(img, Pad{Style}(fill_to_length(border.lo, 0, Val{N}),
                               fill_to_length(border.hi, 0, Val{N})))
end
function padindices{_,Style,N}(img::AbstractArray{_,N}, border::Pad{Style,N})
    _padindices(border, border.lo, indices(img), border.hi)
end
function padindices{P<:Pad}(img::AbstractArray, ::Type{P})
    throw(ArgumentError("must supply padding sizes to $P"))
end

# The 3-argument map is not inferrable, so do it manually
@inline _padindices(border, lo, inds, hi) =
    (padindex(border, lo[1], inds[1], hi[1]),
     _padindices(border, tail(lo), tail(inds), tail(hi))...)
_padindices(border, ::Tuple{}, ::Tuple{}, ::Tuple{}) = ()

"""
    padarray([T], img, border) --> imgpadded

Generate a padded image from an array `img` and a specification
`border` of the boundary conditions and amount of padding to
add. `border` can be a `Pad`, `Fill`, or `Inner` object.

Optionally provide the element type `T` of `imgpadded`.
"""
padarray(img::AbstractArray, border::Pad)  = padarray(eltype(img), img, border)
function padarray{T}(::Type{T}, img::AbstractArray, border::Pad)
    inds = padindices(img, border)
    # like img[inds...] except that we can control the element type
    dest = similar(img, T, map(Base.indices1, inds))
    Base._unsafe_getindex!(dest, img, inds...)
    dest
end
padarray{P}(img, ::Type{P}) = img[padindices(img, P)...]      # just to throw the nice error

# Make this a separate type because the dispatch almost surely needs to be different
immutable Inner{N} <: AbstractBorder
    lo::Dims{N}
    hi::Dims{N}
end

(::Type{Inner})(factkernel::Tuple, img, ::FIR) = Inner(factkernel)
(::Type{Inner})(factkernel::Tuple) = Inner(extremize(indices(factkernel[1]), tail(factkernel)...))
(::Type{Inner})(kernel::AbstractArray) = Inner(indices(kernel))
(::Type{Inner}){N}(inds::Indices{N}) = Inner{N}(map(lo,inds), map(hi,inds))

padarray(img, border::Inner) = padarray(eltype(img), img, border)
padarray{T}(::Type{T}, img::AbstractArray{T}, border::Inner) = copy(img)
padarray{T}(::Type{T}, img::AbstractArray, border::Inner) = convert(Array{T}, img)

"""
    Fill(val)
    Fill(val, lo, hi)

Pad the edges of the image with a constant value, `val`.

Optionally supply the extent of the padding, see `Pad`.
"""
immutable Fill{T,N} <: AbstractBorder
    value::T
    lo::Dims{N}
    hi::Dims{N}

    Fill(value::T) = new(value)
    Fill(value::T, lo::Dims{N}, hi::Dims{N}) = new(value, lo, hi)
end

Fill{T}(value::T) = Fill{T,0}(value)
Fill{T,N}(value::T, lo::Dims{N}, hi::Dims{N}) = Fill{T,N}(value, lo, hi)
Fill(value, lo::AbstractVector, hi::AbstractVector) = Fill(value, (lo...,), (hi...,))
Fill{T,N}(value::T, inds::Base.Indices{N}) = Fill{T,N}(value, map(lo,inds), map(hi,inds))
Fill(value, kernel::AbstractArray) = Fill(value, indices(kernel))
Fill(value, factkernel::Tuple) = Fill(value, extremize(indices(factkernel[1]), tail(factkernel)...))

(p::Fill)(kernel::AbstractArray, img, ::FIR) = Fill(p.value, kernel)
(p::Fill)(factkernel::Tuple, img, ::FIR) = Fill(p.value, factkernel)
function (p::Fill)(factkernel::Tuple, img, ::FFT)
    inds = extremize(indices(factkernel[1]), tail(factkernel)...)
    newinds = map(padfft, inds, map(length, indices(img)))
    Fill(p.value, newinds)
end

function padarray{T}(::Type{T}, img::AbstractArray, border::Fill)
    throw(ArgumentError("$border lacks the proper padding sizes for an array with $(ndims(img)) dimensions"))
end
function padarray{T,S,_,N}(::Type{T}, img::AbstractArray{S,N}, f::Fill{_,N})
    A = similar(arraytype(img, T), map((l,r,h)->first(r)-l:last(r)+h, f.lo, indices(img), f.hi))
    fill!(A, f.value)
    A[indices(img)...] = img
    A
end
padarray(img::AbstractArray, f::Fill) = padarray(eltype(img), img, f)

# There are other ways to define these, but using `mod` makes it safe
# for cases where the padding is bigger than length(inds)
padindex(border::Pad{:replicate}, lo::Integer, inds::AbstractUnitRange, hi::Integer) =
    vcat(fill(first(inds), lo), PinIndices(inds), fill(last(inds), hi))
padindex(border::Pad{:circular}, lo::Integer, inds::AbstractUnitRange, hi::Integer) =
    modrange(extend(lo, inds, hi), inds)
function padindex(border::Pad{:symmetric}, lo::Integer, inds::AbstractUnitRange, hi::Integer)
    I = [inds; reverse(inds)]
    I[modrange(extend(lo, inds, hi), 1:2*length(inds))]
end
function padindex(border::Pad{:reflect}, lo::Integer, inds::AbstractUnitRange, hi::Integer)
    I = [inds; last(inds)-1:-1:first(inds)+1]
    I[modrange(extend(lo, inds, hi), 1:2*length(inds)-2)]
end
"""
    padindex(border::Pad, lo::Integer, inds::AbstractUnitRange, hi::Integer)

Generate an index-vector to be used for padding. `inds` specifies the image indices along a particular axis; `lo` and `hi` are the amount to pad on the lower and upper, respectively, sides of this axis. `border` specifying the style of padding.

You can specialize this for custom `Pad{:name}` types to generate
arbitrary (cartesian) padding types.
"""
padindex

function inner(lo::Integer, inds::AbstractUnitRange, hi::Integer)
    first(inds)+lo:last(inds)-hi
end

lo(o::Integer) = max(-o, zero(o))
lo(r::AbstractUnitRange) = lo(first(r))

hi(o::Integer) = max(o, zero(o))
hi(r::AbstractUnitRange) = hi(last(r))

# extend(lo::Integer, inds::AbstractUnitRange, hi::Integer) = CatIndices.URange(first(inds)-lo, last(inds)+hi)
function extend(lo::Integer, inds::AbstractUnitRange, hi::Integer)
    newind = first(inds)-lo:last(inds)+hi
    OffsetArray(newind, newind)
end

# @inline flatten(t::Tuple) = _flatten(t...)
# @inline _flatten(t1::Tuple, t...) = (flatten(t1)..., flatten(t)...)
# @inline _flatten(t1,        t...) = (t1, flatten(t)...)
# _flatten() = ()

extremize(inds::Indices, kernel1::AbstractArray, kernels...) = extremize(_extremize(inds, indices(kernel1)), kernels...)
extremize(inds) = inds
_extremize(inds1, inds2) = map(__extremize, inds1, inds2)
__extremize(ind1, ind2) = min(first(ind1),first(ind2)):max(last(ind1),last(ind2))

modrange(x, r::AbstractUnitRange) = mod(x-first(r), length(r))+first(r)
modrange(A::AbstractArray, r::AbstractUnitRange) = map(x->modrange(x, r), A)

arraytype{T}(A::AbstractArray, ::Type{T}) = Array{T}  # fallback
arraytype(A::BitArray, ::Type{Bool}) = BitArray

interior(A::AbstractArray, kernel::AbstractArray) = _interior(indices(A), indices(kernel))
interior(A, factkernel::Tuple) = _interior(indices(A), extremize(indices(factkernel[1]), tail(factkernel)...))
function _interior{N}(indsA::NTuple{N}, indsk)
    indskN = fill_to_length(indsk, 0:0, Val{N})
    CartesianRange(CartesianIndex(map((ia,ik)->first(ia) + lo(ik), indsA, indskN)),
                   CartesianIndex(map((ia,ik)->last(ia)  - hi(ik), indsA, indskN)))
end

# end
