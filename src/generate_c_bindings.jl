# Generates the file libleveldb_api.jl containing all calls to libleveldb and
# libleveldb_common.jl, containing all custom types
# this file should NOT be included inside LevelDB.jl

using Clang
using LevelDB

const LIBCLANG_INCLUDE =
    joinpath(pathof(Clang), "..", "..", "deps",
             "usr", "include", "clang-c") |>
    normpath
const LIBCLANG_HEADERS =
    [joinpath(LIBCLANG_INCLUDE, header)
     for header in readdir(LIBCLANG_INCLUDE)
     if endswith(header, ".h")]

const HEADERS =
    joinpath(pathof(LevelDB), "..", "..",
             "deps", "src", "leveldb-1.20",
             "include", "leveldb", "c.h") |>
                 normpath

wc = init(
    headers           = [HEADERS],
    output_file       = joinpath(pathof(LevelDB), "src", "libleveldb_api.jl"),
    common_file       = joinpath(pathof(LevelDB), "src", "libleveldb_common.jl"),
    clang_includes    = vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),
    clang_args        = ["-I", joinpath(LIBCLANG_INCLUDE, "..")],
    header_wrapped    = (root, current)->root == current,
    header_library    = x -> "libleveldb",
    clang_diagnostics = true,
)

run(wc)
