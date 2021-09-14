function transform_density!(out::GenericGrayImage, img::GenericGrayImage, edges::AbstractRange, newvals::AbstractVector)
    first_edge, last_edge = first(edges), last(edges)
    first_newval, last_newval = first(newvals), last(newvals)
    inv_step_size = 1/step(edges)
    function transform(val)
        val = gray(val)
        if val >= last_edge
            return last_newval
        elseif val < first_edge
            return first_newval
        else
            index = floor(Int, (val-first_edge)*inv_step_size) + 1
            @inbounds newval = newvals[index]
            return newval
        end
    end
    map!(transform, out, img)
end

function build_lookup(cdf, minval::T, maxval::T) where T
    first_cdf = first(cdf)
    # Scale the new intensity value to so that it lies in the range [minval, maxval].
    scale = (maxval - minval) / (cdf[end] - first_cdf)
    if T <: Integer
        return T[ceil(minval + (x - first_cdf) * scale) for x in cdf]
    end
    return T[minval + (x - first_cdf) * scale for x in cdf]
end

function construct_pdfs(img::GenericGrayImage, targetimg::AbstractArray, edges::AbstractRange)
    _, histogram = build_histogram(img, edges)
    _, target_histogram = build_histogram(targetimg, edges)
    return edges, histogram / sum(histogram), target_histogram / sum(target_histogram)
end

function construct_pdfs(img::GenericGrayImage, targetimg::AbstractArray, nbins::Integer = 256)
    if eltype(img) <: AbstractGray
        imin, imax = 0, 1
    else
        imin, imax = min(minfinite(img), minfinite(targetimg)), max(maxfinite(img), maxfinite(targetimg))
    end
    edges, histogram = build_histogram(img, nbins, minval = imin, maxval = imax)
    _, target_histogram = build_histogram(targetimg, edges)
    return edges, histogram / sum(histogram), target_histogram / sum(target_histogram)
end

function lookup_icdf(cdf::AbstractArray, targetcdf::AbstractArray)
    lookup_table = zeros(Int, length(cdf))
    i = 1
    for j = 1:length(cdf)
        p = cdf[j]
        while i < length(targetcdf) && targetcdf[i+1] <= p
            i += 1
        end
        lookup_table[j] = i
    end
    lookup_table
end

function cdf2pdf!(pdf::AbstractArray, cdf::AbstractArray)
    pdf[1] = cdf[1]
    for i = length(cdf)-1:-1:2
        pdf[i] = cdf[i] - cdf[i-1]
    end
end
