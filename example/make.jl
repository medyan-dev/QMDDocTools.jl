import ExamplePkg
using QMDDocTools

gen_docstrings(ExamplePkg; outdir = @__DIR__)

run(`quarto render example`)

# The following could be used to deploy the docs to a GitHub page using Documenter.jl

# using Documenter
# deploydocs(;
#     dirname = "julia-docs",
#     target = "_site",
#     branch = "main",
#     repo="github.com/medyan-dev/medyan-dev.github.io.git",
#     devbranch = "main",
#     deploy_config=Documenter.GitHubActions(
#         "medyan-dev/medyan-dev.github.io",
#         get(ENV, "GITHUB_EVENT_NAME", ""),
#         get(ENV, "GITHUB_REF",        ""),
#     ),
# )