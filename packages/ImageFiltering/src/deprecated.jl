using Base.depwarn

function padarray(img::AbstractArray, prepad::Union{Vector{Int},Dims}, postpad::Union{Vector{Int},Dims}, border::AbstractString, value)
    if border == "value"
        depwarn("string-valued borders are deprecated, use `padarray(img, Fill(value, prepad, postpad))` instead, where the padding entries are Dims-tuples", :padarray)
        return padarray(img, Fill(value, (prepad...,), (postpad...,)))
    end
    padarray(img, prepad, postpad, border)
end

function padarray(img::AbstractArray, prepad::Union{Vector{Int},Dims}, postpad::Union{Vector{Int},Dims}, border::AbstractString)
    if border ∈ ["replicate", "circular", "reflect", "symmetric"]
        depwarn("string-valued borders are deprecated, use `padarray(img, Pad{:$border})(prepad, postpad)` instead, where the padding entries are Dims-tuples", :padarray)
        return padarray(img, Pad{Symbol(border)}((prepad...,), (postpad...,)))
    elseif border == "inner"
        depwarn("string-valued borders are deprecated, use `padarray(img, Inner)` instead", :padarray)
        return padarray(img, Inner())
    else
        throw(ArgumentError("$border not a recognized border"))
    end
end

padarray(img::AbstractArray, padding::Union{Vector{Int},Dims}, border::AbstractString = "replicate") = padarray(img, padding, padding, border)
padarray{T<:Number}(img::AbstractArray{T}, padding::Union{Vector{Int},Dims}, value::T) = padarray(img, padding, padding, "value", value)

function padarray{T,n}(img::AbstractArray{T,n}, padding::Union{Vector{Int},Dims}, border::AbstractString, direction::AbstractString)
    if direction == "both"
        return padarray(img, padding, padding, border)
    elseif direction == "pre"
        return padarray(img, padding, zeros(Int, n), border)
    elseif direction == "post"
        return padarray(img, zeros(Int, n), padding, border)
    end
end

function padarray{T<:Number,n}(img::AbstractArray{T,n}, padding::Vector{Int}, value::T, direction::AbstractString)
    if direction == "both"
        return padarray(img, padding, padding, "value", value)
    elseif direction == "pre"
        return padarray(img, padding, zeros(Int, n), "value", value)
    elseif direction == "post"
        return padarray(img, zeros(Int, n), padding, "value", value)
    end
end

function imfilter(img::AbstractArray, kern, border::AbstractString, value)
    if border == "value"
        depwarn("string-valued borders are deprecated, use `imfilter(img, kern, Fill(value))` instead", :imfilter)
        return imfilter(img, kern, Fill(value))
    end
    imfilter(img, kern, border)
end

function imfilter(img::AbstractArray, kern, border::AbstractString)
    if border ∈ ["replicate", "circular", "reflect", "symmetric"]
        depwarn("string-valued borders are deprecated, use `imfilter(img, kern, Pad{:$border}())` instead", :imfilter)
        return imfilter(img, kern, Pad{Symbol(border)}())
    elseif border == "inner"
        depwarn("string-valued borders are deprecated, use `imfilter(img, kern, Inner())` instead", :imfilter)
        return imfilter(img, kern, Inner())
    else
        throw(ArgumentError("$border not a recognized border"))
    end
end

export imfilter_fft
function imfilter_fft(img, kern, border::AbstractString, value)
    if border == "value"
        depwarn("string-valued borders are deprecated, use `imfilter(img, kern, Fill(value), Algorithm.FFT())` instead", :imfilter_fft)
        return imfilter(img, kern, Fill(value), Algorithm.FFT())
    elseif border ∈ ["replicate", "circular", "reflect", "symmetric"]
        depwarn("string-valued borders are deprecated, use `imfilter(img, kern, Pad{:$border}(), Algorithm.FFT())` instead", :imfilter_fft)
        return imfilter(img, kern, Pad{Symbol(border)}(), Algorithm.FFT())
    elseif border == "inner"
        depwarn("string-valued borders are deprecated, use `imfilter(img, kern, Inner, Algorithm.FFT())` instead", :imfilter_fft)
        return imfilter(img, kern, Inner(), Algorithm.FFT())
    else
        throw(ArgumentError("$border not a recognized border"))
    end
end

imfilter_fft(img, filter) = imfilter_fft(img, filter, "replicate", 0)
imfilter_fft(img, filter, border) = imfilter_fft(img, filter, border, 0)

export imfilter_gaussian
function imfilter_gaussian(img, sigma; emit_warning=true, astype=nothing)
    if astype != nothing
        depwarn("imfilter_gaussian(img, sigma; astype=$astype, kwargs...) is deprecated; use `imfilter($astype, img, IIRGaussian(sigma; kwargs...))` instead, possibly with `Pad{:na}()`", :imfilter_gaussian)
        factkernel = KernelFactors.IIRGaussian(astype, sigma; emit_warning=emit_warning)
        return imfilter(astype, img, factkernel, Pad{:na}())
    end
    depwarn("imfilter_gaussian(img, sigma; kwargs...) is deprecated; use `imfilter(img, IIRGaussian(sigma; kwargs...))` instead, possibly with `Pad{:na}()`", :imfilter_gaussian)
    factkernel = KernelFactors.IIRGaussian(sigma; emit_warning=emit_warning)
    imfilter(_eltype(Float64, eltype(img)), img, factkernel, Pad{:na}())
end

_eltype{T,C<:Colorant}(::Type{T}, ::Type{C}) = base_colorant_type(C){T}
_eltype{T,R<:Real}(::Type{T}, ::Type{R}) = T
