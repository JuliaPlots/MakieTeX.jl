import Makie: inherit

# This code has basically been adapted from the Label code in the main repo.

Makie.@Block LTeX begin
    @attributes begin
        "The LaTeX code to be compiled and drawn.  Can be a String, a TeXDocument or a CachedTeX."
        tex = "\\LaTeX"
        "The density of pixels rendered (1 means 1 px == 1 pt)"
        render_density::Int = 1
        "Controls if the graphic is visible."
        visible::Bool = true
        "A scaling factor to resize the graphic."
        scale::Float32 = 1.0
        "The horizontal alignment of the graphic in its suggested boundingbox"
        halign = :center
        "The vertical alignment of the graphic in its suggested boundingbox"
        valign = :center
        "The counterclockwise rotation of the graphic in radians."
        rotation::Float32 = 0f0
        "The extra space added to the sides of the graphic boundingbox."
        padding = (0f0, 0f0, 0f0, 0f0)
        "The height setting of the graphic."
        height = Auto()
        "The width setting of the graphic."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The align mode of the graphic in its parent GridLayout."
        alignmode = Inside()
    end
end

Makie.@Block LTypst begin
    @attributes begin
        "The Typst code to be compiled and drawn.  Can be a String, a TypstDocument or a CachedTypst."
        typst = "\\Typst"
        "The density of pixels rendered (1 means 1 px == 1 pt)"
        render_density::Int = 1
        "Controls if the graphic is visible."
        visible::Bool = true
        "A scaling factor to resize the graphic."
        scale::Float32 = 1.0
        "The horizontal alignment of the graphic in its suggested boundingbox"
        halign = :center
        "The vertical alignment of the graphic in its suggested boundingbox"
        valign = :center
        "The counterclockwise rotation of the graphic in radians."
        rotation::Float32 = 0f0
        "The extra space added to the sides of the graphic boundingbox."
        padding = (0f0, 0f0, 0f0, 0f0)
        "The height setting of the graphic."
        height = Auto()
        "The width setting of the graphic."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight::Bool = true
        "The align mode of the graphic in its parent GridLayout."
        alignmode = Inside()
    end
end

LTeX(x, tex; kwargs...) = LTeX(x; tex = tex, kwargs...)
LTypst(x, typst; kwargs...) = LTypst(x; typst = typst, kwargs...)

code(lt::LTeX) = lt.tex
code(lt::LTypst) = lt.typst

img!(::Type{LTeX}, args...; kwargs...) = teximg!(args...; kwargs...)
img!(::Type{LTypst}, args...; kwargs...) = typstimg!(args...; kwargs...)

_to_cached(::Type{LTeX}, x) = CachedTEX(x)
_to_cached(::Type{LTypst}, x) = CachedTypst(x)
_to_cached(::Type, x::AbstractDocument) = Cached(x)

function Makie.initialize_block!(l::T) where T <: Union{LTeX, LTypst}

    _code = code(l)
    topscene = l.blockscene
    layoutobservables = l.layoutobservables

    textpos = Observable([Point3f(0, 0, 0)])
    scale = Observable([Vec2f(1.0, 1.0)])

    cached = lift(collect ∘ tuple ∘ (x -> _to_cached(T, x)), _code)

    t = img!(T,
        topscene, cached; position = textpos, visible = l.visible,
        scale = scale, align = (:bottom, :left),
        rotations = l.rotation,
        markerspace = :pixel,
        inspectable = false
    )

    textbb = Ref(BBox(0, 1, 0, 1))

    onany(_code, l.scale, l.rotation, l.padding) do code, scale, rotation, padding
        textbb[] = rotatedrect(Makie.Rect2f(0,0,(t[1][][1].dims .* scale)...), rotation)
        autowidth = Makie.width(textbb[]) + padding[1] + padding[2]
        autoheight = Makie.height(textbb[]) + padding[3] + padding[4]
        layoutobservables.autosize[] = (autowidth, autoheight)
    end

    onany(layoutobservables.computedbbox, l.padding, l.scale) do bbox, padding, _scale

        tw = Makie.width(textbb[])
        th = Makie.height(textbb[])

        box = bbox.origin[1]
        boy = bbox.origin[2]

        tx = box + padding[1] + 0.5 * tw
        ty = boy + padding[3] + 0.5 * th

        textpos[] = [Makie.Point3f(tx, ty, 0)]
        scale[] = [(bbox.widths ./ textbb[].widths) .* _scale]
    end


    # trigger first update, otherwise bounds are wrong somehow
    notify(_code)
    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    return l
end


# function MakieLayout.layoutable(::Type{LTeX}, fig_or_scene, tex; kwargs...)
#     MakieLayout.layoutable(LTeX, fig_or_scene; tex = tex, kwargs...)
# end
#
# function MakieLayout.layoutable(::Type{LTeX}, fig_or_scene; bbox = nothing, kwargs...)
#     # this is more or less copied from MakieLayout.Label
#     topscene = MakieLayout.get_topscene(fig_or_scene)
#     topscene.raw = Scene(topscene; raw = true)
#     default_attrs = MakieLayout.default_attributes(LTeX, topscene).attributes
#     theme_attrs = MakieLayout.subtheme(topscene, :LTeX)
#     attrs = MakieLayout.merge!(MakieLayout.merge!(Attributes(kwargs), theme_attrs), Attributes(default_attrs))
#
#     # @extract attrs (tex, textsize, font, color, visible, halign, valign,
#     #     rotation, padding)
#     @extract attrs (tex, dpi, textsize, visible, padding, halign, valign, rotation)
#
#
#     layoutobservables = LayoutObservables{LTeX}(
#         attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
#         halign, valign, attrs.alignmode; suggestedbbox = bbox
#     )
#
#     # This is Point3f0 in Label
#     textpos = Observable(Point3f0(0))
#
#     cached_tex = @lift CachedTeX($tex, $dpi)
#
#     # this is just a hack until boundingboxes in abstractplotting are perfect
#     alignobs = lift(halign, rotation) do h, rot
#         # left align the text if it's not rotated and left aligned
#         if rot == 0 && (h == :left || h == 0.0)
#             (:left, :center)
#         else
#             (:center, :center)
#         end
#     end
#
#     t = teximg!(
#         topscene, cached_tex; position = textpos, visible = visible,
#         textsize = textsize, dpi = dpi, align = alignobs, rotation = rotation
#     )
#
#     textbb = Ref(BBox(0, 1, 0, 1))
#
#     # Label
#     onany(cached_tex, textsize, rotation, padding) do _, textsize, rotation, padding
#         # rotation is applied via a model matrix which isn't used in the bbox calculation
#         # so we need to deal with it here
#         bb = boundingbox(t)
#         R = Makie.Mat3f0(
#              cos(rotation), sin(rotation), 0,
#             -sin(rotation), cos(rotation), 0,
#             0, 0, 1
#         )
#         points = map(p -> R * p, unique(Makie.coordinates(bb)))
#         new_bb = Makie.xyz_boundingbox(identity, points)
#         textbb[] = FRect2D(new_bb)
#         # textbb[] = FRect2D(boundingbox(t))
#         autowidth  = Makie.width(textbb[]) + padding[1] + padding[2]
#         autoheight = Makie.height(textbb[]) + padding[3] + padding[4]
#         layoutobservables.autosize[] = (autowidth, autoheight)
#     end
#
#     onany(layoutobservables.computedbbox, padding) do bbox, padding
#         tw = Makie.width(textbb[])
#         th = Makie.height(textbb[])
#
#         box = bbox.origin[1]
#         boy = bbox.origin[2]
#
#         # this is also part of the hack to improve left alignment until
#         # boundingboxes are perfect
#         tx = if rotation[] == 0 && (halign[] == :left || halign[] == 0.0)
#             box + padding[1]
#         else
#             box + padding[1] + 0.5 * tw
#         end
#         ty = boy + padding[3] + 0.5 * th
#
#         textpos[] = Point3f0(tx, ty, 0)
#     end
#
#     # trigger first update, otherwise bounds are wrong somehow
#     padding[] = padding[]
#     # trigger bbox
#     layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]
#
#     lt = LTeX(fig_or_scene, layoutobservables, attrs, Dict(:tex => t))
#
#     lt
# end
