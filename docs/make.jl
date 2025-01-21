using Documenter, FunctionFusion

# ENV["JULIA_DEBUG"] = Documenter

makedocs(
    sitename = "FunctionFusion.jl",
    modules = [FunctionFusion],
    authors = "Yury Nuzhdin",
    format = Documenter.HTML(prettyurls = haskey(ENV, "CI")),
    checkdocs = :exports,
    pages = [
        "Introduction" => "index.md",
        "Public API" => "api.md",
        "Macro convention" => "macros_convention.md",
    ],
)

deploydocs(repo = "github.com/tz-lom/FunctionFusion.jl.git")
