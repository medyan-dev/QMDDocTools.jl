using SafeTestsets
@safetestset "ExampleEmptyPkg" begin
    #packages with no documentation won't create any files or directories.
    using QMDDocTools
    using Test
    import Pkg 
    Pkg.develop(;path="ExampleEmptyPkg/")
    import ExampleEmptyPkg
    gen_docstrings(ExampleEmptyPkg; outdir=joinpath("testresults", "emptypkg"))
    @test isdir(joinpath("testresults", "emptypkg"))==false
end

@safetestset "ExamplePkg" begin
    using QMDDocTools
    using Test
    using DeepDiffs
    import Pkg 
    Pkg.develop(;path="ExamplePkg/")
    import ExamplePkg
    testresultpath = joinpath("testresults", "examplepkg")
    expectedresultpath = joinpath("expectedresults", "examplepkg")
    gen_docstrings(ExamplePkg; outdir=testresultpath)
    testresultdict = Dict()
    for (root, dirs, files) in walkdir(testresultpath)
        for f in files
            fname = joinpath(root[ncodeunits(testresultpath)+2:end], f)
            testresultdict[fname] = read(joinpath(root, f), String)
        end
    end
    expectedresultdict = Dict()
    for (root, dirs, files) in walkdir(expectedresultpath)
        for f in files
            fname = joinpath(root[ncodeunits(expectedresultpath)+2:end], f)
            expectedresultdict[fname] = read(joinpath(root, f), String)
        end
    end
    diffresult = deepdiff(expectedresultdict,testresultdict)
    if !isempty(changed(diffresult))
        @info diffresult
        @test isempty(changed(diffresult))
    end
end