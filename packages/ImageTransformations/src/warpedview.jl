"""
    WarpedView(img, tform, [indices]) -> wv

Create a view of `img` that lazily transforms any given index `I`
passed to `wv[I]` to correspond to `img[tform(I)]`. This approach
is known as backward mode warping.

The optional parameter `indices` can be used to specify the
domain of the resulting `wv`. By default the indices are computed
in such a way that `wv` contains all the original pixels in
`img`. To do this `inv(tform)` has to be computed. If the given
transformation `tform` does not support `inv`, then the parameter
`indices` has to be specified manually.

see [`warpedview`](@ref) for more information.
"""
struct WarpedView{T,N,A<:AbstractArray,F<:Transformation,I<:Tuple,E<:AbstractExtrapolation} <: AbstractArray{T,N}
    parent::A
    transform::F
    indices::I
    extrapolation::E
end

function WarpedView(
        A::AbstractArray{T, N},
        tform::Transformation,
        inds=autorange(A, inv(tform)); kwargs...) where {T,N,}
    etp = box_extrapolation(A; kwargs...)
    tform = _round(tform)
    WarpedView{T,N,typeof(A),typeof(tform),typeof(inds),typeof(etp)}(A, tform, inds, etp)
end

Base.parent(A::WarpedView) = A.parent
@inline Base.axes(A::WarpedView) = A.indices

IndexStyle(::Type{T}) where {T<:WarpedView} = IndexCartesian()
@inline Base.getindex(A::WarpedView{T,N}, I::Vararg{Int,N}) where {T,N} =
    T(_getindex(A.extrapolation, A.transform(SVector(I))))
Base.size(A::WarpedView{T,N,TA,F}) where {T,N,TA,F}    = map(length,axes(A))
Base.size(A::WarpedView{T,N,TA,F}, d) where {T,N,TA,F} = length(axes(A,d))

Base.size(A::WarpedView{T,N,TA,F,NTuple{N,Base.OneTo{Int}}}) where {T,N,TA,F}    = map(length, A.indices)
Base.size(A::WarpedView{T,N,TA,F,NTuple{N,Base.OneTo{Int}}}, d) where {T,N,TA,F} = d <= N ? length(A.indices[d]) : 1

function Base.showarg(io::IO, A::WarpedView, toplevel)
    print(io, "WarpedView(")
    Base.showarg(io, parent(A), false)
    print(io, ", ")
    print(io, A.transform)
    if toplevel
        print(io, ") with eltype ", eltype(parent(A)))
    else
        print(io, ')')
    end
end
