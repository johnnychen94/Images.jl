module Images

import Base.Order: Ordering, ForwardOrdering, ReverseOrdering
import Base.Graphics: width, height
importall Base

using Color
using Cartesian

if isdefined(module_parent(Images), :Grid)
    import ..Grid.restrict
end

include("core.jl")
include("iterator.jl")
const have_imagemagick = include("ioformats/libmagickwand.jl")
include("io.jl")
include("scaling.jl")
include("labeledarrays.jl")
include("algorithms.jl")

export # types
    AbstractImage,
    AbstractImageDirect,
    AbstractImageIndexed,
    Image,
    ImageCmap,
    BitShift,
    ClipMin,
    ClipMax,
    ClipMinMax,
    LabeledArray,
    Overlay,
    OverlayImage,
    ScaleAutoMinMax,
    ScaleInfo,
    ScaleMinMax,
    ScaleNone,
    ScaleSigned,
    SliceData,

    # constants
    palette_fire,
    palette_gray32,
    palette_gray64,
    palette_rainbow,

    # core functions
    assert2d,
    assert_scalar_color,
    assert_timedim_last,
    assert_xfirst,
    assert_yfirst,
    colordim,
    colorspace,
    coords,
    coords_spatial,
    data,
    dimindex,
    dimindexes,
    getindexim,
    grayim,
    height,
    isdirect,
    isxfirst,
    isyfirst,
    limits,
    maxabsfinite,
    maxfinite,
    minfinite,
    ncolorelem,
    nimages,
    pixelspacing,
    properties,
    refim,
    rerange!,
    reslice!,
    restrict,
    sdims,
    size_spatial,
    share,
    sliceim,
    spatialorder,
    spatialpermutation,
    spatialproperties,
    storageorder,
    subim,
    timedim,
    width,
    widthheight,
    
    # io functions
    add_image_file_format,
    imread,
    imwrite,
    loadformat,
    
    # iterator functions
    first_index,
    iterate_spatial,
    parent,
    
    # color-related functions
    alphaval,
    blueval,
    greenval,
    redval,
    red,
    green,
    blue,
    hsi2rgb,
    imadjustintensity,
    indexedcolor,
    lut,
    ntsc2rgb,
    rgb2gray,
    rgb2hsi,
    rgb2ntsc,
    rgb2ycbcr,
    uint32color,
    uint32color!,
    ycbcr2rgb,
    
    # Scaling of intensity
    climdefault,
    float32sc,
    float64sc,
    sc,
    scale,
    scaleinfo,
    scaleminmax,
    scalesigned,
    uint8sc,
    uint16sc,
    uint32sc,

    # algorithms
    backdiffx,
    backdiffy,
    dilate,
    erode,
    opening,
    closing,
    forwarddiffx,
    forwarddiffy,
    gaussian2d,
    imaverage,
    imcomplement,
    imdog,
    imedge,
    imfilter,
    imfilter_gaussian,
    imfilter_gaussian!,
    imgaussiannoise,
    imlaplacian,
    imlineardiffusion,
    imlog,
    imROF,
    imstretch,
#     imthresh,
    label_components,
    label_components!,
    ncc,
    padarray,
    prewitt,
    sad,
    sadn,
    sobel,
    ssd,
    ssdn,

    # phantoms
    shepp_logan

@deprecate cairoRGB     uint32color!
@deprecate refim        getindexim
@deprecate scaledefault climdefault

end
