using Documenter
using Porta

makedocs(
    sitename = "Porta.jl",
    format = Documenter.HTML(prettyurls = false, size_threshold = nothing),  # optional
    pages = [
        "Home" => "index.md",
        "Hopf Fibration" => "hopffibration.md",
        "News Report" => "newsreport.md",
        "Reaction Wheel Unicycle" => "reactionwheelunicycle.md",
        "Ordinary Differential Equations" => "ordinarydifferentialequations.md",
        "Multivariable Calculus" => "multivariablecalculus.md",
        "The Maxwell Field (Persian)" => "maxwellfield_persian.md",
        "The Shape Operator" => "shapeoperator.md",
        "The Unicycle (Persian)" => "reactionwheelunicycle_persian.md",
        "Infrared Communication" => "infraredcommunication.md"
    ],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/iamazadi/Porta.jl.git",
)