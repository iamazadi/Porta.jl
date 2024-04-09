using Documenter
using Porta

makedocs(
    sitename = "Porta.jl",
    format = Documenter.HTML(prettyurls = false),  # optional
    pages = [
        "Home" => "index.md",
        "Hopf Fibration" => "hopffibration.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/iamazadi/Porta.jl.git",
)