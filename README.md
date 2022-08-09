# QMDDocTools

[![Build Status](https://github.com/medyan-dev/QuartoDocTools.jl/workflows/CI/badge.svg)](https://github.com/medyan-dev/QuartoDocTools.jl/actions)

An opinionated set of tools to help document large Julia packages with [Quarto](https://quarto.org/)

This package doesn't aim to help integrate individual Quarto documents into an existing Documenter.jl generated site. 
Instead it helps integrate a Julia package's docstrings as part of a Quarto generated site.



```julia
    gen_docstrings(pkgmodule::Module;
        outdir="",
        filterdocstr=checkpublicdocstr,
        docstringformatter=formatdoc2qmd,
    )
```

Generate the files that contain the docstrings of the input `pkgmodule`.
The files are written to the subdirectory "docstrings" in `outdir`
The previous subdirectory "docstrings" in `outdir` is deleted

Docstrings are included if defined in `pkgmodule` or its child modules.
Docstrings are not included if `filterdocstr(d::Docs.DocStr)` returns false.
Docstrings are formatted to quarto flavor markdown with `docstringformatter(d::Docs.DocStr)`.
Each public binding will have a file in "docstrings" with the first 16 hex of the sha1 of the binding name and .qmd
Each source code file in the package that contains a public docstring will also have a file in "docstrings"
with the same name, but .jl replaced with .qmd.
The sections of the source code files will have identifiers of the first 16 hex of the sha1 of the binding name.


To link to the docstrings use the `docref` shortcode defined in `docref.lua`

See <https://quarto.org/docs/extensions/shortcodes.html> for general info on using short codes.

Here are some examples of using `docref`


## just binding

``{{< docref `Base.:+`>}}``

## binding and sig in one code block space separated

``{{< docref `Base.:+ Tuple{MEDYAN.Context, Any}`>}}``

## src and binding

``{{< docref `/docstrings/src/context.qmd` `Base.:+`>}}``

## label and binding

``{{< docref "test" `Base.:+ `>}}``

## label and binding and sig in one code block space separated

``{{< docref "test" `Base.:+  Tuple{MEDYAN.Context, Any}`>}}``

## label and src and binding

``{{< docref "test" `/docstrings/src/context.qmd` `Base.:+`>}}``
