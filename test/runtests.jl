using MakieTeX
using MakieTeX.Makie
using CairoMakie
using Downloads

using Test

example_path = joinpath(@__DIR__, "test_images")
mkpath(example_path)

function save_test(filename, fig; kwargs...)

    save(joinpath(example_path, "$filename.png"), fig; px_per_unit=3, kwargs...)
    save(joinpath(example_path, "$filename.pdf"), fig; px_per_unit=1, kwargs...)
    save(joinpath(example_path, "$filename.svg"), fig; px_per_unit=0.75, kwargs...)

end

function render_texample(CachedType, DocType, url)

    fig = Figure()

    lt = LTeX(fig[1, 1], CachedType(DocType(read(Downloads.download(url), String), false)))

    @test true

    resize_to_layout!(fig)

    filename = splitdir(splitext(url)[1])[2]

    save_test(joinpath(@__DIR__, "test_images", "texample", filename), fig)


    @test true

end

function render_texample(url; assume = ".tex")
    ext = splitext(url)
    isempty(ext) && (ext = assume)
    if ext == ".tex"
        render_texample(CachedTeX, TeXDocument, url)
    elseif ext == ".typst"
        render_texample(CachedTypst, TypstDocument, url)
    elseif ext == ".svg"
        render_texample(CachedSVG, SVGDocument, url)
    elseif ext == ".pdf"
        render_texample(CachedPDF, PDFDocument, url)
    else
        error("Unknown file type: $ext")
    end
end


include("tex.jl")
include("typst.jl")
include("svg.jl")
include("pdf.jl")
