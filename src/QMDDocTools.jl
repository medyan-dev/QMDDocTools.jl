module QMDDocTools

export gen_docstrings

using DataStructures
using Markdown
using SHA

myhash(s) = bytes2hex(sha1(s))[1:16]

"""
Return a string of a Base.Docs.DocStr in Quarto style markdown

lstrip "public\\n\\n" if there.
"""
function formatdoc2qmd(d::Docs.DocStr; publickeyword="public\n\n")
    # print docstring into a string
    s = repr(Docs.parsedoc(d))
    # strip publickeyword
    if startswith(s, publickeyword)
        s = s[ncodeunits(publickeyword)+begin:end]
    end
    
    # first convert all starting ```\n to ```julia\n
    lines = split(string(s),"\n")
    inblock = false
    for (i,line) in enumerate(lines)
        if startswith(line,"```")
            if !inblock
                #edit line
                lines[i] = if line == "```"
                    "```julia"
                else
                    line
                end
                inblock = true
            else
                inblock = false
            end
        end
    end
    s = join(lines,"\n")
    # now add block around docs
    s = ":::{.callout-note appearance=\"minimal\"}\n"*s*"\n:::\n"
    s
end

"""
Return true if a docstring is public.

a docstring is public if it is exported from it's module,
or if it starts with `publickeyword` "public\\n\\n"
"""
function checkpublicdocstr(d::Docs.DocStr; publickeyword="public\n\n")::Bool
    # check if its exported
    b = d.data[:binding]
    if b.var in names(b.mod)
        return true
    else
        s = repr(Docs.parsedoc(d))
        if startswith(s, publickeyword)
            return true
        else
            return false
        end
    end
end


"""
Get the relative file path given an absolute project path and an absolute file path
Error if the file path isn't in the project path.
"""
function get_relative_path(filepath, projectpath)
    isabspath(projectpath) || error("projectpath $projectpath not absolute")
    isabspath(filepath) || error("filepath $filepath not absolute")
    isdirpath(filepath) && error("filepath $filepath is a directory")
    filepath[end-2:end] == ".jl" || error("file $filepath is not a julia file")
    # make projectpath end with a path seperator
    projectpath = joinpath(projectpath,"")
    startswith(filepath, projectpath) || error("$filepath doesn't start with $projectpath")
    filepath[ncodeunits(projectpath)+begin:end]
end

"""
Return modules with doc strings defined by a package including pkgmodule itself.
"""
function getpkgmodules(pkgmodule::Module)::Vector{Module}
    children = filter(x-> pkgmodule in split_module_path(x), Docs.modules)
    sort(children; by = repr)
end

"""
return vector of module and parents
"""
function split_module_path(m::Module)::Vector{Module}
    r = Module[m,]
    oldm = m
    m = parentmodule(m)
    while m !== oldm
        push!(r,m)
        oldm = m
        m = parentmodule(m)
    end
    r
end


"""
    gen_docstrings(pkgmodule::Module;
        outdir="",
        filterdocstr=checkpublicdocstr,
        docstringformatter=formatdoc2qmd,
    )
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
"""
function gen_docstrings(pkgmodule::Module;
        outdir="",
        filterdocstr=checkpublicdocstr,
        docstringformatter=formatdoc2qmd,
    )
    metadicts = Docs.meta.(getpkgmodules(pkgmodule))
    pkgpath = pkgdir(pkgmodule)
    srcfiles = DefaultDict{String, DefaultDict{String, Vector{Docs.DocStr}}}(()->(DefaultDict{String, Vector{Docs.DocStr}}([])))
    bindingfiles = DefaultDict{String, Vector{Docs.DocStr}}(()->[])
    for metadict in metadicts
        for (binding, md) in metadict
            #add file for binding
            bindingstr = repr(binding)
            ds = map(x->md.docs[x],md.order)
            for d in ds
                if filterdocstr(d)
                    absfilename = d.data[:path]
                    relfilename = get_relative_path(absfilename, pkgpath)
                    push!(srcfiles[relfilename][bindingstr],d)
                    push!(bindingfiles[bindingstr],d)
                end
            end
        end
    end
    # go through and sort srcfile sections by line numbers
    sortedsrcfiles = Dict{String, Vector{Vector{Docs.DocStr}}}()
    for (filename, bindingdict) in pairs(srcfiles)
        dss = collect(values(bindingdict))
        for ds in dss
            sort!(ds;alg = Base.Sort.DEFAULT_STABLE, by=d->d.data[:linenumber])
        end
        sortedsrcfiles[filename] = sort(dss; by=ds->(ds[begin].data[:linenumber],repr(ds[begin].data[:binding])))
    end
    #delete old docstrings
    rm(joinpath(outdir,"docstrings"); force=true, recursive=true)
    #write files
    for (filename, sections) in pairs(sortedsrcfiles)
        filepath = joinpath(outdir,"docstrings",filename[begin:end-2]*"qmd")
        mkpath(dirname(filepath))
        open(filepath,"w") do io
            println(io, "# ", replace(filename, "\\" => "/"))
            for section in sections
                bindingname = repr(section[begin].data[:binding])
                println(io, "## [`` $(bindingname) ``](/docstrings/$(myhash(bindingname)).qmd) {#$(myhash(bindingname))}")
                for d in section
                    println(io,docstringformatter(d))
                end
            end
        end
    end
    for (bindingname, section) in pairs(bindingfiles)
        filepath = joinpath(outdir,"docstrings",myhash(bindingname)*".qmd")
        mkpath(dirname(filepath))
        open(filepath,"w") do io
            println(io, "# `` $(bindingname) ``")
            for d in section
                typesigname = repr(d.data[:typesig])
                println(io, "##   `````` $(typesigname) ``````{shortcodes=false}  {#$(myhash(typesigname))}")
                println(io,docstringformatter(d))
            end
        end
    end
end
        

end