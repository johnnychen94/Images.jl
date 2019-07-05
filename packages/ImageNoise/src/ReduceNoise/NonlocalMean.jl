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

* `λ::Float64` is the degree of filtering, larger `λ` produces a smoother result.

* `r_p::Int64` is the radius of image patch size. By default it's 2.

* `r_s::Int64` is the radius of search window, large `r_s` would slow down
the filtering significantly. By default it's `2r_p + 1`.

* If you pass `img` to `NonlocalMean`, it will be used to estimate `r_p` and `r_s`.

# Examples

```julia
img = testimage("lena_color_256")

n = AdditiveWhiteGaussianNoise(0.1)
noisy_img = apply_noise(img, n)

# use default filter arguments
f_denoise = NonlocalMean(0.1)
denoised_img = reduce_noise(noisy_img, f)

# estimate filter arguments with noisy_img
f_denoise = NonlocalMean(0.1, noisy_img)
denoised_img = reduce_noise(noisy_img, f)
```

See also: [`reduce_noise`](@ref), [`reduce_noise!`](@ref)

# References

[1] Buades, A., Coll, B., & Morel, J. M. (2005, June). A non-local algorithm for image denoising. In _2005 IEEE Computer Society Conference on Computer Vision and Pattern Recognition (CVPR'05)_ (Vol. 2, pp. 60-65). IEEE.
"""
struct NonlocalMean <: AbstractImageDenoiseAlgorithm
    """degree of filtering"""
    λ::Float64
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
    r_p, r_s, λ = f.r_p, f.r_s, f.λ^2
    kernel = make_kernel(f.r_p)

    img = of_eltype(floattype(eltype(img)), centered(img))
    out = centered(out)
    R = CartesianIndices(img) # indices without padding

    offset_p = Tuple(repeated(r_p, ndims(img)))
    img = padarray(img, Pad(:symmetric, offset_p, offset_p))
    offset_p = CartesianIndex(offset_p)
    offset_s = CartesianIndex(Tuple(repeated(r_s, ndims(img))))

    wsqeuclidean(k, w1, w2) = k*(w1-w2)^2
    d_temp = similar(kernel)
    for p in R
        patch_p = img[_colon(p-offset_p, p+offset_p)]

        wmax = 0 # set w[p, p] as wmax instead of 1
        ∑wq  = 0
        ∑w   = 0 # Z[p] in the docstring
        for q in _colon(R[max(p-offset_s, first(R))], R[min(p+offset_s, last(R))])
            p==q && continue # skip w[p, p]
            patch_q = img[_colon(q-offset_p, q+offset_p)] # faster than @view

            # calculate weight
            broadcast!(wsqeuclidean, d_temp, kernel, patch_p, patch_q)
            w = exp(-sum(d_temp)/λ)

            if w > wmax
                wmax=w
            end

            # weighted sum over q
            ∑wq += w*img[q]
            ∑w  += w;
        end
        # add w[p, p] in the end
        ∑wq += wmax*img[p]
        ∑w  += wmax

        out[p] = ∑wq / ∑w
    end
    return out
end

function (f::NonlocalMean)(out::AbstractArray{<:AbstractRGB, 2},
                           img::AbstractArray{<:AbstractRGB, 2})
    cv_out = channelview(out)
    cv_img = channelview(img)
    for i in 1:3
        f(view(cv_out, i, :, :), view(cv_img, i, :, :))
    end
end

(f::NonlocalMean)(out::AbstractArray{<:Color3, 2},
                  img::AbstractArray{<:Color3, 2}) =
    f(of_eltype(RGB, out), of_eltype(RGB, img))

""" gaussian-like kernel """
function make_kernel(r)
    kernel = centered(zeros(2r+1, 2r+1))
    R = CartesianIndices(kernel)
    for d in 1:r
        v = 1/(2d+1)^2
        for i in R[-d:d, -d:d]
            kernel[i] += v
        end
    end
    parent(kernel ./ sum(kernel))
end
