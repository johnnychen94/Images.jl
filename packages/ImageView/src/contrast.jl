module ImageContrast

# using Base.Graphics
using Cairo
using Tk
using Winston
using Images

type ContrastSettings
    min
    max
end

type ContrastData
    imgmin
    imgmax
    phist::FramedPlot
    chist::Canvas
end

# The callback should have the syntax:
#    callback(cs)
# The callback's job is to replot the image with the new contrast settings
function contrastgui{T}(img::AbstractArray{T}, cs::ContrastSettings, callback::Function)
    win = Toplevel("Adjust contrast", 500, 300, true)
    contrastgui(win, img, cs, callback)
end

function contrastgui{T}(win::Tk.TTk_Container, img::AbstractArray{T}, cs::ContrastSettings, callback::Function)
    # Get initial values
    dat = img[:,:]
    immin = min(dat)
    immax = max(dat)
    if is(cs.min, nothing)
        cs.min = immin
    end
    if is(cs.max, nothing)
        cs.max = immax
    end
    cs.min = convert(T, cs.min)
    cs.max = convert(T, cs.max)

    # Set up GUI
    fwin = Frame(win)
    w = width(win.w)
    h = height(win.w)
    pack(fwin, expand=true, fill="both")

    max_slider = Slider(fwin, int(floor(immin)):int(ceil(immax))) # won't work for small float ranges
    set_value(max_slider, int(ceil(immax)))
    chist = Canvas(fwin, 2w/3, h)
    min_slider = Slider(fwin, int(floor(immin)):int(ceil(immax))) # won't work for small float ranges
    set_value(min_slider, int(floor(immin)))

    grid(max_slider, 1, 1, sticky="ew", padx=5)
    grid(chist, 2, 1, sticky="nsew", padx=5)
    grid(min_slider, 3, 1, sticky="ew", padx=5)
    grid_columnconfigure(fwin, 1, weight=1)
    grid_rowconfigure(fwin, 2, weight=1)
    
    emax = Entry(fwin, width=10)
    emin = Entry(fwin, width=10)
    set_value(emax, string(cs.max))
    set_value(emin, string(cs.min))
#    emax[:textvariable] = max_slider[:variable]
#    emin[:textvariable] = min_slider[:variable]
    
    fbuttons = Frame(fwin)
    zoom = Button(fbuttons, "Zoom")
    full = Button(fbuttons, "Full range")
    grid(zoom, 1, 1, sticky="we")
    grid(full, 2, 1, sticky="we")
    
    grid(emax, 1, 2, sticky="nw")
    grid(fbuttons, 2, 2, sticky="nw")
    grid(emin, 3, 2, sticky="nw")
    
    # Prepare the histogram
    nbins = iceil(min(sqrt(length(img)), 200))
    p = prepare_histogram(dat, nbins, immin, immax)
    
    # Store data we'll need for updating
    cdata = ContrastData(immin, immax, p, chist)
    
    function rerender()
        pcopy = deepcopy(cdata.phist)
        bb = Winston.limits(cdata.phist.content1)
        add(pcopy, Curve([cs.min, cs.max], [bb.ymin, bb.ymax], "linewidth", 10, "color", "white"))
        add(pcopy, Curve([cs.min, cs.max], [bb.ymin, bb.ymax], "linewidth", 5, "color", "black"))
        Winston.display(chist, pcopy)
        reveal(chist)
        callback(cs)
        Tk.update()
    end
    # If we have a image sequence, we might need to generate a new histogram.
    # So this function will be returned to the caller
    function replaceimage(newimg, minval = min(newimg), maxval = max(newimg))
        p = prepare_histogram(newimg, nbins, minval, maxval)
        cdata.imgmin = minval
        cdata.imgmax = maxval
        cdata.phist = p
        rerender()
    end

    # Set initial histogram scale
    setrange(cdata.chist, cdata.phist, cdata.imgmin, cdata.imgmax, rerender) 

    # All bindings
    bind(emin, "<Return>") do path
        try
            val = float64(get_value(emin))
            cs.min = convertsafely(typeof(cs.min), val)
            set_value(min_slider, val)
            rerender()
        catch
            set_value(emin, string(cs.min))
        end
    end
    bind(emax, "<Return>") do path
        try
            val = float64(get_value(emax))
            cs.max = convertsafely(typeof(cs.min), val)
            set_value(max_slider, val)
            rerender()
        catch
            set_value(emax, string(cs.max))
        end
    end
    bind(min_slider, "command") do path
        cs.min = convertsafely(typeof(cs.min), float(min_slider[:value]))
        set_value(emin, min_slider[:value])
        rerender()
    end
    bind(max_slider, "command") do path
        cs.max = convertsafely(typeof(cs.max), float(max_slider[:value]))
        set_value(emax, max_slider[:value])
        rerender()
    end
    bind(zoom, "command", path -> setrange(cdata.chist, cdata.phist, cdata.imgmin, cdata.imgmax, rerender))
    bind(full, "command", path -> setrange(cdata.chist, cdata.phist, min(cdata.imgmin, cs.min), max(cdata.imgmax, cs.max), rerender))

    replaceimage
end

convertsafely{T<:Integer}(::Type{T}, val) = convert(T, round(val))
convertsafely{T}(::Type{T}, val) = convert(T, val)

function prepare_histogram(img, nbins, immin, immax)
    e = immin:(immax-immin)/(nbins-1):immax*(1+1e-6)
    e, counts = hist(img[:], e)
    counts += 1   # because of log scaling
    x, y = stairs(e, counts)
    p = FramedPlot()
    setattr(p, "ylog", true)
    setattr(p.y, "draw_nothing", true)
    setattr(p.x2, "draw_nothing", true)
    setattr(p.frame, "tickdir", 1)
    add(p, FillBetween(x, ones(length(x)), x, y, "color", "black"))
    p
end

function stairs(xin::AbstractVector, yin::Vector)
    nbins = length(yin)
    if length(xin) != nbins+1
        error("Pass edges for x, and bin values for y")
    end
    xout = zeros(0)
    yout = zeros(0)
    sizehint(xout, 2nbins)
    sizehint(yout, 2nbins)
    push!(xout, xin[1])
    for i = 2:nbins
        xtmp = xin[i]
        push!(xout, xtmp)
        push!(xout, xtmp)
    end
    push!(xout, xin[end])
    for i = 1:nbins
        ytmp = yin[i]
        push!(yout, ytmp)
        push!(yout, ytmp)
    end
    xout, yout
end

function setrange(c::Canvas, p, minval, maxval, render::Function)
    setattr(p, "xrange", (minval, maxval))
    render()
end
    
end
