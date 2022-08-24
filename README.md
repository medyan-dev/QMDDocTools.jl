# QMDDocTools

[![Build Status](https://github.com/medyan-dev/QuartoDocTools.jl/workflows/CI/badge.svg)](https://github.com/medyan-dev/QuartoDocTools.jl/actions)

An opinionated set of tools to help document large Julia packages with [Quarto](https://quarto.org/)

This package doesn't aim to help integrate individual Quarto documents into an existing Documenter.jl generated site. 
Instead it helps integrate a Julia package's docstrings as part of a Quarto generated site.

## Julia functions

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

## `docref` filter

To link to the docstrings use the `docref` filter defined in `_extensions/docref/docref.lua`

This filter matches to any links with a `@ref` target. It is mostly compatible with `@ref` in julia flavored markdown, with a few differences, for one, it cannot be used to link to other sections. Use quarto's built-in features for that: see <https://quarto.org/docs/websites/index.html#linking>

Also, it is better to write the full binding, including all modules.

You can add a meta section defining CurrentModule to the top of a file.

For example:

```
---
CurrentModule: MEDYAN
---
```

Then if a binding referenced in the file doesn't have any periods, `MEDYAN.` in this example is prepended to the binding.

Source code file names shouldn't contain any # characters, or any characters that could be an issue being in a url.

See <https://quarto.org/docs/extensions/filters.html> for more info on using filters.

Here is an example `format` section of a `_quarto.yml` file.

```
format:
  html:
    filters:
      - docref.lua
      - quarto
    theme: cosmo
    css: styles.css
    toc: true
```

Here are some examples of using the `docref` filter


## Just binding

``[`Base.:+`](@ref)``

## Binding and sig in one code block # separated

Note, sig is space sensitive.

``[`Base.:+#Tuple{MEDYAN.Context, Any}`](@ref)``

## Label with binding

``[test](@ref "#MEDYAN.Context")``

## Label with binding and sig in one code block # separated

``[test](@ref "#Base.:+#Tuple{MEDYAN.Context, Any}")``

## Label with src and binding

``[test](@ref "/docstrings/src/context.qmd#Base.:+")``
