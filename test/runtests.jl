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

function render_texample(cached, document, url)

    fig = Figure()

    lt = LTeX(fig[1, 1], convert(CachedPDF, cached(document(read(Downloads.download(url), String), false))))

    @test true

    resize_to_layout!(fig)

    filename = splitdir(splitext(url)[1])[2]

    save_test(joinpath(@__DIR__, "test_images", "texample", filename), fig)


    @test true

end


include("tex.jl")
include("typst.jl")
include("svg.jl")
include("pdf.jl")
