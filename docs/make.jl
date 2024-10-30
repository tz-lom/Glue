using Documenter, Glue

# ENV["JULIA_DEBUG"] = Documenter

makedocs(
    sitename = "Glue.jl",
    modules = [Glue],
    authors = "Yury Nuzhdin",
    format = Documenter.HTML(prettyurls = haskey(ENV, "CI")),
    checkdocs = :exports,
    pages = ["Introduction" => "index.md", "Public API" => "api.md"],
)

deploydocs(repo = "github.com/tz-lom/Glue.jl.git")
