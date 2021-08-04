@doc raw"""
    NonlocalMean(λ [, r_p=2, r_s=2r_p+1])
    NonlocalMean(λ, img)

Non-local mean denoising filter for additive white Gaussian noise using the
following formula:

```math
    y[p] = \sum_{q \in \mathscr{N}(r\_s, p)} w[p, q]x[q]
```

where `w[p, q]` represents the similarity of two patches centered in `p` and
`q`, calculated by

```math
    w[p, q] = \frac{1}{Z[p]}e^{-\frac{\lVert\mathscr{N}(r\_w, p) - \mathscr{N}(r\_w, q) \rVert^2_{2, a}}{λ^2}}
```

`Z[p]` is the normalizing constant so that `∑w` over `q` equals to `1`.

# Arguments

* `λ::Float32` is the degree of filtering, larger `λ` produces a smoother result.

* `r_p::Int` is the radius of image patch size. By default it's 2.

* `r_s::Int` is the radius of search window, large `r_s` would slow down
the filtering significantly. By default it's `2r_p + 1`.

* If you pass `img` to `NonlocalMean`, it will be used to estimate `r_p` and `r_s`.

# Examples

```julia
img = testimage("lena_color_256")

n = AdditiveWhiteGaussianNoise(0.1)
noisy_img = apply_noise(img, n)

# use default filter arguments
f_denoise = NonlocalMean(0.1)
denoised_img = reduce_noise(noisy_img, f_denoise)

# estimate filter arguments with noisy_img
f_denoise = NonlocalMean(0.1, noisy_img)
denoised_img = reduce_noise(noisy_img, f_denoise)
```

See also: [`reduce_noise`](@ref), [`reduce_noise!`](@ref)

# References

[1] Buades, A., Coll, B., & Morel, J. M. (2005, June). A non-local algorithm for image denoising. In _2005 IEEE Computer Society Conference on Computer Vision and Pattern Recognition (CVPR'05)_ (Vol. 2, pp. 60-65). IEEE.
"""
struct NonlocalMean <: AbstractImageDenoiseAlgorithm
    """degree of filtering"""
    λ::Float32
    """radius of image patch"""
    r_p::Int
    """radius of search window"""
    r_s::Int
    function NonlocalMean(λ, r_p, r_s)
        r_p >= 1 || throw(ArgumentError("radius of image patch r_p should >= 1, instead it's $(r_p)"))
        r_s >= 1 || throw(ArgumentError("radius of image patch r_p should >= 1, instead it's $(r_p)"))
        λ > 0 || @warn "λ is supposed to be positive"
        new(λ, r_p, r_s)
    end
end
NonlocalMean(λ, r_p=2) = NonlocalMean(λ, r_p, 2r_p+1)
NonlocalMean(λ, img::GenericImage) = NonlocalMean(λ, max(round.(size(img)./128)..., 1))

function (f::NonlocalMean)(out::AbstractArray{<:NumberLike, 2},
                           img::AbstractArray{<:NumberLike, 2})
    axes(out) == axes(img) || ArgumentError("Images should have the same axes.")
    r_p, r_s, λ = f.r_p, f.r_s, f.λ^2

    T = floattype(eltype(img))
    kernel = make_kernel(T, f.r_p)
    img = of_eltype(T, img)

    R = CartesianIndices(img) # indices without padding

    oₚ = ntuple(_->r_p, ndims(img))
    padded_axes = map(axes(img), oₚ) do ax, o
        first(ax)-o:last(ax)+o
    end
    img = PaddedView(zero(eltype(img)), img, padded_axes)
    Δₚ = CartesianIndex(oₚ)
    Δₛ = CartesianIndex(ntuple(_->r_s, ndims(img)))

    patch_p = zeros(T, size(kernel))
    for p in R
        # patch_p will be indexed for many times, thus preallocating it into a contiguous memeory layout
        # helps improve the performance
        patch_p .= @view img[_colon(p-Δₚ, p+Δₚ)]

        wmax = zero(T) # set w[p, p] as wmax instead of 1
        ∑wq  = zero(T)
        ∑w   = zero(T) # Z[p] in the docstring
        @inbounds @simd for q in _colon(max(first(R), p-Δₛ), min(p+Δₛ, last(R)))
            if p != q
                patch_q = @view img[_colon(q-Δₚ, q+Δₚ)]

                # calculate weight
                w = T(exp(-wsqeucliean(kernel, patch_p, patch_q)/λ))

                # weighted sum over q
                ∑wq += w*img[q]
                ∑w  += w;

                w > wmax && (wmax = w)
            end
        end
        # add w[p, p] in the end
        ∑wq += wmax*img[p]
        ∑w  += wmax

        out[p] = ∑wq / ∑w
    end
    return out
end

function (f::NonlocalMean)(out::AbstractArray{T, 2},
                           img::AbstractArray{T, 2}) where T<: AbstractRGB
    cv_out = channelview(out)
    cv_img = channelview(img)
    for i in 1:size(cv_img, 1)
        f(view(cv_out, i, :, :), view(cv_img, i, :, :))
    end
    return out
end

function (f::NonlocalMean)(out::AbstractArray{T, 2},
                  img::AbstractArray{T, 2}) where T<:Color3
    img = RGB.(img)
    tmp = similar(img)
    out .= f(tmp, img)
    # f(of_eltype(RGB, out), of_eltype(RGB, img))
end

""" gaussian-like kernel """
function make_kernel(T, r)
    kernel = OffsetArrays.centered(zeros(2r+1, 2r+1))
    R = CartesianIndices(kernel)
    for d in 1:r
        v = 1/(2d+1)^2
        for i in R[-d:d, -d:d]
            kernel[i] += v
        end
    end
    OffsetArrays.centered(T.(kernel ./ sum(kernel)))
end

""" weighted squared euclidean """
function wsqeucliean(W, X, Y)
    rst = zero(eltype(W))
    # use linear indexing
    @inbounds @simd for i = 1:length(W)
        rst += W[i] * _abs2(X[i] - Y[i])
    end
    return rst
end
