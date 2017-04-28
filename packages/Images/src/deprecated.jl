export
    AbstractImage,
    AbstractImageDirect,
    AbstractImageIndexed,
    Image,
    LabeledArray,
    Overlay,
    OverlayImage,
    BitShift,
    ClampMin,
    ClampMax,
    ClampMinMax,
    Clamp,
    Clamp01NaN,
    MapInfo,
    MapNone,
    ScaleAutoMinMax,
    ScaleMinMax,
    ScaleMinMaxNaN,
    ScaleSigned,
    SliceData

const yx = ["y", "x"]
const xy = ["x", "y"]

SliceData(args...) = error("SliceData has been removed, please use julia's regular indexing operations")
reslice!(args...) = error("reslice! has been removed, along with SliceData; please use julia's regular indexing operations")
rerange!(args...) = error("reslice! has been removed, along with SliceData; please use julia's regular indexing operations")

# These should have been deprecated long ago
@deprecate uint32color(img) immap(mapinfo(UInt32, img), img)
@deprecate uint32color!(buf, img::AbstractArray) map!(mapinfo(UInt32, img), buf, img)
@deprecate uint32color!(buf, img::AbstractArray, mi::MapInfo) map!(mi, buf, img)
@deprecate uint32color!{T,N}(buf::Array{UInt32,N}, img::AbstractArray{T,N}) map!(mapinfo(UInt32, img), buf, img)
@deprecate uint32color!{T,N,N1}(buf::Array{UInt32,N}, img::ChannelView{T,N1}) map!(mapinfo(UInt32, img), buf, img, Val{1})
@deprecate uint32color!{T,N}(buf::Array{UInt32,N}, img::AbstractArray{T,N}, mi::MapInfo) map!(mi, buf, img)
@deprecate uint32color!{T,N,N1}(buf::Array{UInt32,N}, img::ChannelView{T,N1}, mi::MapInfo) map!(mi, buf, img, Val{1})

@deprecate flipx(img) flipdim(img, 2)
@deprecate flipy(img) flipdim(img, 1)
@deprecate flipz(img) flipdim(img, 3)

@deprecate ando3 KernelFactors.ando3
@deprecate ando4 KernelFactors.ando3
@deprecate ando5 KernelFactors.ando3
@deprecate gaussian2d() Kernel.gaussian(0.5)
@deprecate gaussian2d(σ::Number) Kernel.gaussian(σ)
@deprecate gaussian2d(σ::Number, filter_size) Kernel.gaussian((σ,σ), (filter_size...,))
@deprecate imaverage KernelFactors.boxcar
@deprecate imdog Kernel.DoG
@deprecate imlog Kernel.LoG
@deprecate imlaplacian Kernel.Laplacian

@deprecate extremefilt!(A::AbstractArray, ::Base.Order.ForwardOrdering, region=coords_spatial(A)) extremefilt!(A, max, region)
@deprecate extremefilt!(A::AbstractArray, ::Base.Order.ReverseOrdering, region=coords_spatial(A)) extremefilt!(A, min, region)
@deprecate extremefilt!{C<:AbstractRGB}(A::AbstractArray{C}, ::Base.Order.ForwardOrdering, region=coords_spatial(A)) extremefilt!(A, (x,y)->mapc(max,x,y), region)
@deprecate extremefilt!{C<:AbstractRGB}(A::AbstractArray{C}, ::Base.Order.ReverseOrdering, region=coords_spatial(A)) extremefilt!(A, (x,y)->mapc(min,x,y), region)

function restrict{S<:String}(img::AbstractArray, region::Union{Tuple{String,Vararg{String}}, Vector{S}})
    depwarn("restrict(img, strings) is deprecated, please use restrict(img, axes) with an AxisArray", :restrict)
    so = spatialorder(img)
    regioni = Int[]
    for i = 1:length(region)
        push!(regioni, require_dimindex(img, region[i], so))
    end
    restrict(img, regioni)
end

function magnitude_phase(img::AbstractArray, method::AbstractString, border::AbstractString="replicate")
    f = ImageFiltering.kernelfunc_lookup(method)
    depwarn("magnitude_phase(img, method::AbstractString, [border]) is deprecated, use magnitude_phase(img, $f, [border]) instead", :magnitude_phase)
    magnitude_phase(img, f, border)
end

Base.@deprecate_binding LabeledArray ColorizedArray
@deprecate ColorizedArray{T,N}(intensity::AbstractArray{T,N}, label::AbstractArray, colors::Vector{RGB}) ColorizedArray(intensity, IndirectArray(label, colors))

@deprecate imcomplement(img::AbstractArray) complement.(img)

function canny{T<:NumberLike}(img_gray::AbstractMatrix{T}, sigma::Number = 1.4, upperThreshold::Number = 0.90, lowerThreshold::Number = 0.10; percentile::Bool = true)
    depwarn("canny(img, sigma, $upperThreshold, $lowerThreshold; percentile=$percentile) is deprecated.\n Please use canny(img, ($upperThreshold, $lowerThreshold), sigma) or canny(img, (Percentile($(100*upperThreshold)), Percentile($(100*lowerThreshold))), sigma)",:canny)
    if percentile
        canny(img_gray, (Percentile(100*upperThreshold), Percentile(100*lowerThreshold)), sigma)
    else
        canny(img_gray, (upperThreshold, lowerThreshold), sigma)
    end
end

function imcorner(img::AbstractArray, threshold, percentile;
                  method::Function = harris, args...)
    if percentile == true # NB old function didn't require Bool, this ensures conversion
        depwarn("imcorner(img, $threshold, true; ...) is deprecated. Please use imcorner(img, Percentile($(100*threshold)); ...) instead.", :imcorner)
        imcorner(img, Percentile(100*threshold); method=method, args...)
    else
        depwarn("imcorner(img, $threshold, false; ...) is deprecated. Please use imcorner(img, $threshold; ...) instead.", :imcorner)
        imcorner(img, threshold; method=method, args...)
    end
end
