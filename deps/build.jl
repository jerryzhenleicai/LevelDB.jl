using BinDeps

@BinDeps.setup

version = "1.18"
url = "https://github.com/google/leveldb/archive/v$(version).tar.gz"

libleveldbjl = library_dependency("libleveldbjl")

provides(Sources, URI(url), libleveldbjl, unpacked_dir="leveldb-$(version)")

leveldbbuilddir = BinDeps.builddir(libleveldbjl)
leveldbsrcdir = joinpath(BinDeps.depsdir(libleveldbjl),"src", "leveldb-$version")
leveldblibdir = BinDeps.libdir(libleveldbjl)
leveldblibfile = joinpath(leveldblibdir,libleveldbjl.name*".so")

provides(BuildProcess,
    (@build_steps begin
        GetSources(libleveldbjl)
        CreateDirectory(leveldblibdir)
        @build_steps begin
            ChangeDirectory(leveldbsrcdir)
            FileRule(leveldblibfile, @build_steps begin
                `make`
                `cp libleveldb.so $(leveldblibfile)`
            end)
        end
    end), libleveldbjl, os = :Unix)

@BinDeps.install [ :libleveldbjl => :libleveldbjl]