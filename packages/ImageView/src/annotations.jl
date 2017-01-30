# Once this stabilizes, migrate to a Graphics layer? Only if that supports text, which seems unlikely.
using Colors
using Graphics

abstract AbstractAnnotation

# Use this type when you want your annotation to be linked to particular data-coordinates
# (for example, to highlight a particular data point)
# devicebb(data) returns a BoundingBox in device coordinates, userbb(data) returns one in user coordinates.
# It's up to the draw() function to decide how to exploit these (most commonly, with set_coords())
type AnchoredAnnotation{T} <: AbstractAnnotation
    devicebb::Function
    userbb::Function
    data::T
    valid::Bool
end
AnchoredAnnotation{T}(devicebb::Function, userbb::Function, data::T) =
    AnchoredAnnotation{T}(devicebb, userbb, data, true)

# Use this type when you want your annotation to appear at a specific point on the screen, regardless
# of zoom/resize state (e.g., a scale bar)
type FloatingAnnotation{T} <: AbstractAnnotation
    devicebb::Function
    data::T
end
# FloatingAnnotation{T}(devicebb::Function, data::T) = AnchoredAnnotation{T}(devicebb, data)

type AnnotationScalebarFixed{T}
    width::T   # Probably has units
    height::T
    getsize::Function   # syntax w,h = getsize(width,height)
    centerx::Float64
    centery::Float64
    color::Color
end

## Text annotations

type AnnotationText
    x::Float64
    y::Float64
    z::Float64
    t::Float64
    string::AbstractString
    color::Color
    fontfamily::String
    fontoptions::String
    fontsize::Integer
    fontdesc::String
    angle::Float64
    halign::String
    valign::String
    markup::Bool
    scale::Bool
end

function AnnotationText(x::Real, y::Real, str::AbstractString;
                        z = NaN, t = NaN,
                        color = RGB(0,0,0), angle = 0.0, fontfamily = "sans", fontsize = 10,
                        fontoptions = "",  halign = "center", valign = "center",
                        markup = false, scale=true)
    AnnotationText(Float64(x), Float64(y), Float64(z),
                   Float64(t), str, color, fontfamily, fontoptions,
                   fontsize, fontdescription(fontfamily, fontoptions, fontsize),
                   Float64(angle), halign, valign, markup, scale)
end

fontdescription(fontfamily, fontoptions, fontsize) =
    string(fontfamily, " ", fontoptions, " ", fontsize)


## Point annotations

type AnnotationPoints{T}
    pts::T
    z::Float64
    t::Float64
    size::Float64
    shape::Char
    color::Color
    linewidth::Float64
    linecolor::Color
    scale::Bool
end

function AnnotationPoints{R<:Real}(xys::Vector{Tuple{R,R}}=Tuple{Float64,Float64}[];
                                   z = NaN, t = NaN, size=10.0, shape::Char='x', color = RGB(1,1,1),
                                   linewidth=1.0, linecolor=color, scale::Bool=false)
    AnnotationPoints{typeof(xys)}(xys, z, t, float(size), shape, to_colorant(color),
                                  float(linewidth), to_colorant(linecolor), scale)
end

function AnnotationPoints{R<:Real}(xys::Matrix{R}; z = NaN, t = NaN, size=10.0,
                                   shape::Char='x', color = RGB(1,1,1), linewidth=1.0,
                                   linecolor=color, scale::Bool=false)
    AnnotationPoints{Matrix{R}}(xys, z, t, float(size),
                                shape, to_colorant(color), float(linewidth),
                                to_colorant(linecolor), scale)
end

function AnnotationPoint(xy::Tuple{Real,Real}; z = NaN, t = NaN, size=10.0,
                         shape::Char='x', color = RGB(1,1,1), linewidth=1.0,
                         linecolor=color, scale::Bool=false)
    AnnotationPoints{Tuple{Float64,Float64}}((Float64(xy[1]),Float64(xy[2])),
                                             z, t, float(size), shape,
                                             to_colorant(color), float(linewidth),
                                             to_colorant(linecolor), scale)
end

AnnotationPoint(x::Real, y::Real; args...) =
    AnnotationPoint((Float64(x), Float64(y)); args...)

## Line annotations

type AnnotationLines{R<:Union{Real, Tuple{Real, Real}}, T}
    lines::T
    z::Float64
    t::Float64
    linecolor::Color
    linewidth::Float64
    coordinate_order::Vector{Int}

    function AnnotationLines(lines::T, z, t, linecolor, linewidth, coord_order_str)
        ord = sortperm(coord_order_str.data)
        @assert coord_order_str[ord] == "xxyy"
        new(lines, z, t, linecolor, linewidth, ord)
    end
end

function AnnotationLines{R<:Real}(lines::Vector{Tuple{Tuple{R, R},Tuple{R, R}}}=
                                  Tuple{Tuple{Float64, Float64},Tuple{Float64, Float64}}[];
                                  z = NaN, t = NaN, color=RGB(1,1,1),
                                  linewidth=1.0, coord_order="xyxy")
    AnnotationLines{R,Vector{Tuple{Tuple{R,R},Tuple{R, R}}}}(lines, z, t, color,
                                                             linewidth, coord_order)
end

function AnnotationLines{R<:Real}(lines::Matrix{R}; z = NaN, t = NaN, color=RGB(1,1,1),
                                  linewidth=1.0, coord_order="xyxy")
    AnnotationLines{R, Matrix{R}}(lines, z, t, color, linewidth, coord_order)
end

function AnnotationLine{R<:Real}(line::Tuple{Tuple{R,R},Tuple{R,R}};
                                 z = NaN, t = NaN, color=RGB(1,1,1), linewidth=1.0)
    AnnotationLines{R,Tuple{Tuple{R,R},Tuple{R,R}}}(line, z, t, color, linewidth, "xyxy")
end

AnnotationLine(pt1::Tuple{Real,Real}, pt2::Tuple{Real,Real}; args...) =
    AnnotationLine((pt1, pt2); args...)

function AnnotationLine(c1::Real, c2::Real, c3::Real, c4::Real; coord_order="xyxy", args...)
    ord = sortperm(coord_order.data)
    @assert coord_order[ord] == "xxyy"
    (x1,x2,y1,y2) = [c1,c2,c3,c4][ord]
    AnnotationLine((Float64(x1), Float64(y1)),
                   (Float64(x2), Float64(y2)); args...)
end

## Box annotations

type AnnotationBox
    left::Float64
    top::Float64
    right::Float64
    bottom::Float64
    z::Float64
    t::Float64
    linecolor::Color
    linewidth::Float64
end

function AnnotationBox(c1::Real, c2::Real, c3::Real, c4::Real; z = NaN, t = NaN,
                       color=RGB(1,1,1), linewidth=1.0, coord_order="xyxy")
    ord = sortperm(coord_order.data)
    @assert coord_order[ord] == "xxyy"
    (x1, x2, y1, y2) = [c1, c2, c3, c4][ord]
    (x1, x2) = minmax(x1, x2)
    (y1, y2) = minmax(y1, y2)
    AnnotationBox(x1, y1, x2, y2, z, t, color, linewidth)
end

function AnnotationBox(pt1::Tuple{Real, Real}, pt2::Tuple{Real, Real};
                       coord_order="xyxy", args...)
    AnnotationBox(pt1..., pt2...; coord_order=coord_order, args...)
end

AnnotationBox(bb::BoundingBox; args...) = AnnotationBox(bb.xmin, bb.ymin, bb.xmax, bb.ymax; args...)

##############

setvalid!(ann::AnchoredAnnotation, z, t) = (ann.valid = annotation_isvalid(ann.data, z, t))

function annotation_isvalid(dat::Union{AnnotationText,
                                       AnnotationPoints,
                                       AnnotationLines,
                                       AnnotationBox}, z, t)
    (isnan(dat.z) || round(dat.z) == z) && (isnan(dat.t) || round(dat.t) == t)
end

annotation_isvalid(x, z, t) = true

function setvalid!(ann::FloatingAnnotation, z, t)
end

function draw(c::Canvas, ann::AnchoredAnnotation)
    if ann.valid
        ctx = getgc(c)
        Graphics.save(ctx)
        data = ann.data
        set_coords(ctx, ann.devicebb(data), ann.userbb(data))
        scale_x = width(ann.userbb(data))/width(ann.devicebb(data))
        scale_y = height(ann.userbb(data))/height(ann.devicebb(data))
        draw_anchored(ctx, data, scale_x, scale_y)
        restore(ctx)
    end
end

function draw{T}(c::Canvas, ann::FloatingAnnotation{AnnotationScalebarFixed{T}})
    ctx = getgc(c)
    Graphics.save(ctx)
    data = ann.data
    set_coords(ctx, ann.devicebb(data), BoundingBox(0,1,0,1))
    set_source(ctx, data.color)
    w, h = data.getsize(data.width, data.height)
    bb = BoundingBox(-w/2+data.centerx, w/2+data.centerx, -h/2+data.centery, h/2+data.centery)
    rectangle(ctx, bb)
    fill(ctx)
    restore(ctx)
end

function draw_anchored(ctx::CairoContext, data::AnnotationText, scale_x, scale_y)
    set_source(ctx, data.color)
    if data.scale && scale_x != 1
        fontdesc = fontdescription(data.fontfamily, data.fontoptions, round(Int,data.fontsize/scale_x))
    else
        fontdesc = data.fontdesc
    end
    Cairo.set_font_face(ctx, fontdesc)
    Cairo.text(ctx, data.x-0.5, data.y-0.5, data.string, halign = data.halign, valign = data.valign,
               angle = data.angle, markup = data.markup)
end

function draw_anchored(ctx::CairoContext, data::AnnotationPoints, scale_x, scale_y)
    set_line_width(ctx, data.linewidth)
    set_source(ctx, data.linecolor)
    if data.scale
        sz_x = sz_y = data.size
    else
        sz_x =  scale_x * data.size
        sz_y =  scale_y * data.size
    end
    draw_pts(ctx, data.pts, sz_x, sz_y, data.shape, data.color, data.linecolor)
end

draw_pts(ctx::CairoContext, pt::NTuple{2}, args...) = draw_pt(ctx, pt, args...)

function draw_pts{R<:Real}(ctx::CairoContext, pts::Vector{Tuple{R,R}}, args...)
    for pt in pts
        draw_pt(ctx, pt, args...)
    end
end

function draw_pts(ctx::CairoContext, pts::Matrix, args...)
    @assert size(pts,1) == 2
    for i in 1:size(pts,2)
        pt = pts[:,i]
        draw_pt(ctx, pt, args...)
    end
end


function draw_pt(ctx::CairoContext, pt, sz_x, sz_y, shape::Char, color::Color, linecolor::Color)
    x::Float64,y::Float64 = pt
    hsz_x = sz_x/2
    hsz_y = sz_y/2

    if (shape == '.') | (shape == 'o')
        move_to(ctx, x, y)
        if sz_x == sz_y
            new_sub_path(ctx)
            circle(ctx, x, y, sz_x)
        else
            # draw an ellipse
            Graphics.save(ctx)
            translate(ctx, x, y)
            scale(ctx, sz_x, sz_y)
            new_sub_path(ctx)
            circle(ctx, 0, 0, 1);
            restore(ctx)
        end
        if shape == '.'
            set_source(ctx, color)
            fill_preserve(ctx)
            set_source(ctx, linecolor)
        end
    elseif (shape == 'x') | (shape == '*') | (shape == '+')
        if (shape == 'x') | (shape == '*')
            move_to(ctx, x-hsz_x, y-hsz_y)
            line_to(ctx, x+hsz_x, y+hsz_y)
            move_to(ctx, x-hsz_x, y+hsz_y)
            line_to(ctx, x+hsz_x, y-hsz_y)
        end
        if (shape == '+') | (shape == '*')
            move_to(ctx, x-hsz_x, y)
            line_to(ctx, x+hsz_x, y)
            move_to(ctx, x, y-hsz_y)
            line_to(ctx, x, y+hsz_y)
        end
    end

    stroke(ctx)
end

function draw_anchored(ctx::CairoContext, data::AnnotationLines, args...)
    set_line_width(ctx, data.linewidth)
    set_source(ctx, data.linecolor)
    draw_lines(ctx, data.lines, data.coordinate_order)
end

draw_lines(ctx::CairoContext, line::Tuple{Tuple{Real, Real},Tuple{Real, Real}}, _) =
    draw_line(ctx, line)

function draw_lines{R<:Real}(ctx::CairoContext,
                             lines::Vector{Tuple{Tuple{R, R},Tuple{R, R}}}, _)
    for line in lines
        draw_line(ctx, line)
    end
end

function draw_lines{R<:Real}(ctx::CairoContext, lines::Matrix{R}, coordinate_order)
    for i in 1:size(lines, 2)
        pt = tuple(lines[coordinate_order,i]...)
        draw_line(ctx, pt)
    end
end

function draw_lines{R<:Tuple{Real,Real}}(ctx::CairoContext, lines::Matrix{R}, _)
    for i in 1:size(lines, 2)
        pt = tuple(lines[:,i]...)
        draw_line(ctx, pt)
    end
end

function draw_line(ctx::CairoContext, line::Tuple{Tuple{Real, Real},Tuple{Real, Real}})
    (x1, y1), (x2, y2) = line
    move_to(ctx, x1, y1)
    line_to(ctx, x2, y2)
    stroke(ctx)
end

function draw_line(ctx::CairoContext, line::Tuple{Real, Real, Real, Real})
    x1, y1, x2, y2 = line
    move_to(ctx, x1, y1)
    line_to(ctx, x2, y2)
    stroke(ctx)
end

## Box

function draw_anchored(ctx::CairoContext, data::AnnotationBox, args...)
    set_line_width(ctx, data.linewidth)
    set_source(ctx, data.linecolor)
    draw_box(ctx, data.top, data.bottom, data.left, data.right)
end

function draw_box(ctx::CairoContext, top, bottom, left, right)
    move_to(ctx, left, top)
    line_to(ctx, right, top)
    line_to(ctx, right, bottom)
    line_to(ctx, left, bottom)
    line_to(ctx, left, top)
    stroke(ctx)
end

to_colorant(c::Colorant) = c
to_colorant(str::AbstractString) = parse(Colorant, str)
