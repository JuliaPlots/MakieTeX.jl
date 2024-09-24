import{_ as e,c as i,o as a,a6 as t}from"./chunks/framework.D9_xqL9a.js";const s="/MakieTeX.jl/previews/PR49/assets/vzfifgk.RmS76gRA.png",u=JSON.parse('{"title":"MakieTeX.jl","description":"","frontmatter":{"layout":"home","hero":{"name":"MakieTeX","text":"","tagline":"Plotting vector images in Makie","actions":[{"theme":"brand","text":"Introduction","link":"/index"},{"theme":"alt","text":"View on Github","link":"https://github.com/JuliaPlots/MakieTeX.jl"},{"theme":"alt","text":"Available formats","link":"/formats"}]},"features":[{"icon":"<img width=\\"64\\" height=\\"64\\" src=\\"https://rawcdn.githack.com/JuliaLang/julia-logo-graphics/f3a09eb033b653970c5b8412e7755e3c7d78db9e/images/juliadots.iconset/icon_512x512.png\\" alt=\\"Julia code\\"/>","title":"TeX, PDF, SVG","details":"Renders vector formats like TeX, PDF and SVG with no external dependencies","link":"/formats"}]},"headers":[],"relativePath":"index.md","filePath":"index.md","lastUpdated":null}'),n={name:"index.md"},o=t(`<p style="margin-bottom:2cm;"></p><div class="vp-doc" style="width:80%;margin:auto;"><h1 id="MakieTeX.jl" tabindex="-1">MakieTeX.jl <a class="header-anchor" href="#MakieTeX.jl" aria-label="Permalink to &quot;MakieTeX.jl {#MakieTeX.jl}&quot;">​</a></h1><p>MakieTeX is a package that allows users to plot vector images - PDF, SVG, and TeX (which compiles to PDF) directly in Makie. It exposes two approaches: the <code>teximg</code> recipe which plots any LaTeX-like object, and the <code>CachedDocument</code> API which allows users to plot documents directly as <code>scatter</code> markers.</p><p>To see a list of all exported functions, types, and macros, see the <a href="./@ref api">API</a> page.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> MakieTeX, CairoMakie</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">teximg</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">raw</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">\\b</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">egin{align*}</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">\\f</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">rac{1}{2} </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">\\t</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">imes </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">\\f</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">rac{1}{2} = </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">\\f</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">rac{1}{4}</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">\\e</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">nd{align*}</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+s+'" alt=""></p><h2 id="Principle-of-operation" tabindex="-1">Principle of operation <a class="header-anchor" href="#Principle-of-operation" aria-label="Permalink to &quot;Principle of operation {#Principle-of-operation}&quot;">​</a></h2><h3 id="Rendering" tabindex="-1">Rendering <a class="header-anchor" href="#Rendering" aria-label="Permalink to &quot;Rendering {#Rendering}&quot;">​</a></h3><p>Rendering can occur either to a bitmap (for GL backends) or to a Cairo surface (for CairoMakie). Both of these have APIs (<a href="./@ref"><code>rasterize</code></a> and <a href="./@ref"><code>draw_to_cairo_surface</code></a>).</p><p>Each rendering format has its own complexities, so the rendering pipelines are usually separate. SVG uses librsvg while PDF and EPS use Poppler directly. TeX uses the available local TeX renderer (if not, <code>tectonic</code> is bundled with MakieTeX) and Typst uses Typst_jll.jl to render to a PDF, which then each follow the Poppler pipeline.</p><h3 id="Makie" tabindex="-1">Makie <a class="header-anchor" href="#Makie" aria-label="Permalink to &quot;Makie {#Makie}&quot;">​</a></h3><p>When rendering to Makie, MakieTeX rasterizes the document to a bitmap by default via the Makie attribute conversion pipeline (specifically <code>Makie.to_spritemarker</code>), and then Makie treats it like a general image scatter marker.</p><p><strong>HOWEVER</strong>, when rendering with CairoMakie, there is a function hook to get the correct marker for <em>Cairo</em> specifically, ignoring the default Makie conversion pipeline. This is <code>CairoMakie.cairo_scatter_marker</code>, and we overload it in <code>MakieTeX.MakieTeXCairoMakieExt</code> to get the correct marker. This also allows us to apply styling to SVG elements, but again <strong>ONLY IN CAIROMAKIE</strong>! This is a bit of an incompatibility and a breaking of the implicit promise from Makie that rendering should be the same across backends, but the tradeoff is (to me, at least) worth it.</p></div>',2),r=[o];function l(h,p,c,d,k,g){return a(),i("div",null,r)}const f=e(n,[["render",l]]);export{u as __pageData,f as default};
