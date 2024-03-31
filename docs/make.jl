using Documenter
using Porta  # your package name here

makedocs(
    sitename = "Porta",  # your package name here
    format = Documenter.HTML(prettyurls = false),  # optional
    pages = [
        "Introduction" => "index.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/iamazadi/Porta.jl.git",
)