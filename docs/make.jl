using Documenter, LevelDB

makedocs(;
    modules=[LevelDB],
    authors="Original authors and Eric S. Tellez",
    repo="https://github.com/sadit/LevelDB.jl/blob/{commit}{path}#L{line}",
    sitename="LevelDB.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", nothing) == "true",
        canonical="https://sadit.github.io/LevelDB.jl",
        assets=String[],
    ),
    pages=[
        "index" => "index.md"
    ],
)

deploydocs(;
    repo="github.com/sadit/LevelDB.jl",
    devbranch=nothing,
    branch = "gh-pages",
    versions = ["stable" => "v^", "v#.#.#", "dev" => "dev"]
)
