#=
# PDF rendering

This file contains the functions necessary to render PDF files using Poppler and Cairo.

It implements the MakieTeX cached-document API.
=#

function CachedPDF(pdf::PDFDocument, page::Int = 0)
    pdf_bytes = Vector{UInt8}(getdoc(pdf))
    ptr = load_pdf(pdf_bytes)
    surf = page2recordsurf(ptr, page)
    dims = pdf_get_page_size(ptr, page)

    return CachedPDF(pdf, Ref(ptr), dims, surf, Ref{Tuple{Matrix{ARGB32}, Float64}}((Matrix{ARGB32}(undef, 0, 0), 0)))
end

function rasterize(pdf::CachedPDF, scale::Real = 1)
    if last(pdf.image_cache[]) == scale
        return first(pdf.image_cache[])
    else
        img = page2img(pdf, pdf.doc.page; scale)
        pdf.image_cache[] = (img, scale)
        return img
    end
end

function update_handle!(pdf::CachedPDF)
    pdf_bytes = Vector{UInt8}(getdoc(pdf))
    ptr = load_pdf(pdf_bytes)
    pdf.ptr[] = ptr
    return ptr
end

# Pure poppler pipeline - directly from PDF to Cairo surface.

"""
    load_pdf(pdf::String)::Ptr{Cvoid}
    load_pdf(pdf::Vector{UInt8})::Ptr{Cvoid}

Loads a PDF file into a Poppler document handle.

Input may be either a String or a `Vector{UInt8}`, each representing the PDF file in memory.  

!!! warn
    The String input does **NOT** represent a filename!
"""
load_pdf(pdf::String) = load_pdf(Vector{UInt8}(pdf))

function load_pdf(pdf::Vector{UInt8})::Ptr{Cvoid} # Poppler document handle

    # Use Poppler to load the document.
    document = ccall(
        (:poppler_document_new_from_data, Poppler_jll.libpoppler_glib),
        Ptr{Cvoid},
        (Ptr{Cchar}, Csize_t, Cstring, Ptr{Cvoid}),
        pdf, Csize_t(length(pdf)), C_NULL, C_NULL
    )

    if document == C_NULL
        error("The document at $path could not be loaded by Poppler!")
    end

    num_pages = pdf_num_pages(document)

    if num_pages != 1
        @warn "There were $num_pages pages in the document!  Selecting first page."
    end

    # Try to load the first page from the document, to test whether it is valid
    page = ccall(
        (:poppler_document_get_page, Poppler_jll.libpoppler_glib),
        Ptr{Cvoid},
        (Ptr{Cvoid}, Cint),
        document, 0 # page 0 is first page
    )

    if page == C_NULL
        error("Poppler was unable to read page 1 at index 0!  Please check your PDF.")
    end

    return document

end

# Rendering functions for the resulting Cairo surfaces and images

"""
    page2img(ct::Union{CachedTeX, CachedTypst}, page::Int; scale = 1, render_density = 1)

Renders the `page` of the given `CachedTeX` or `CachedTypst` object to an image, with the given `scale` and `render_density`.

This function reads the PDF using Poppler and renders it to a Cairo surface, which is then read as an image.
"""
function page2img(ct::Union{CachedTeX, CachedTypst, CachedPDF}, page::Int; scale = 1, render_density = 1)
    document = update_handle!(ct)
    page2img(document, page, size(ct); scale, render_density)
end

function page2img(document::Ptr{Cvoid}, page::Int, tex_dims::Tuple; scale = 1, render_density = 1)
    page = ccall(
        (:poppler_document_get_page, Poppler_jll.libpoppler_glib),
        Ptr{Cvoid},
        (Ptr{Cvoid}, Cint),
        document, page # page 0 is first page
    )

    w = ceil(Int, tex_dims[1] * render_density)
    h = ceil(Int, tex_dims[2] * render_density)

    img = fill(Colors.ARGB32(1,1,1,0), w, h)

    surf = CairoImageSurface(img)

    ccall((:cairo_surface_set_device_scale, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
        surf.ptr, render_density, render_density)

    ctx  = Cairo.CairoContext(surf)

    Cairo.set_antialias(ctx, Cairo.ANTIALIAS_BEST)

    Cairo.save(ctx)
    # Render the page to the surface using Poppler
    ccall(
        (:poppler_page_render, Poppler_jll.libpoppler_glib),
        Cvoid,
        (Ptr{Cvoid}, Ptr{Cvoid}),
        page, ctx.ptr
    )

    Cairo.restore(ctx)

    Cairo.finish(surf)

    return (permutedims(img))

end

firstpage2img(ct; kwargs...) = page2img(ct, 0; kwargs...)

function page2recordsurf(document::Ptr{Cvoid}, page::Int; scale = 1, render_density = 1)
    w, h = pdf_get_page_size(document, page)
    page = ccall(
        (:poppler_document_get_page, Poppler_jll.libpoppler_glib),
        Ptr{Cvoid},
        (Ptr{Cvoid}, Cint),
        document, page # page 0 is first page
    )

    surf = Cairo.CairoRecordingSurface()

    ctx  = Cairo.CairoContext(surf)

    Cairo.set_antialias(ctx, Cairo.ANTIALIAS_BEST)

    # Render the page to the surface
    ccall(
        (:poppler_page_render, Poppler_jll.libpoppler_glib),
        Cvoid,
        (Ptr{Cvoid}, Ptr{Cvoid}),
        page, ctx.ptr
    )

    Cairo.flush(surf)

    return surf

end

firstpage2recordsurf(ct; kwargs...) = page2recordsurf(ct, 0; kwargs...)

function recordsurf2img(ct::Union{CachedTeX, CachedTypst}, render_density = 1)

    # We can find the final dimensions (in pixel units) of the Rsvg image.
    # Then, it's possible to store the image in a native Julia array,
    # which simplifies the process of rendering.
    # Cairo does not draw "empty" pixels, so we need to fill here
    w = ceil(Int, ct.dims[1] * render_density)
    h = ceil(Int, ct.dims[2] * render_density)

    img = fill(Colors.ARGB32(0,0,0,0), w, h)

    # Cairo allows you to use a Matrix of ARGB32, which simplifies rendering.
    cs = Cairo.CairoImageSurface(img)
    ccall((:cairo_surface_set_device_scale, Cairo.libcairo), Cvoid, (Ptr{Nothing}, Cdouble, Cdouble),
    cs.ptr, render_density, render_density)
    c = Cairo.CairoContext(cs)

    # Render the parsed SVG to a Cairo context
    render_surface(c, ct.surf)

    # The image is rendered transposed, so we need to flip it.
    return rotr90(permutedims(img))
end

function render_surface(ctx::CairoContext, surf)
    Cairo.save(ctx)

    Cairo.set_source(ctx, surf,-0.0, 0.0)

    Cairo.paint(ctx)

    Cairo.restore(ctx)
    return
end
