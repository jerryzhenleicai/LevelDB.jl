using BinDeps
using Libdl

@BinDeps.setup

version = "1.20"
url = "https://github.com/google/leveldb/archive/v$(version).tar.gz"

libleveldb = library_dependency("libleveldb")

provides(Sources, URI(url), libleveldb, unpacked_dir="leveldb-$(version)")

leveldbbuilddir = BinDeps.builddir(libleveldb)
leveldbsrcdir = joinpath(BinDeps.depsdir(libleveldb),"src", "leveldb-$version")
leveldblibdir = BinDeps.libdir(libleveldb)
leveldblibfile = joinpath(leveldblibdir,libleveldb.name*".$(Libdl.dlext)")

provides(BuildProcess,
    (@build_steps begin
        GetSources(libleveldb)
        CreateDirectory(leveldblibdir)
        @build_steps begin
            ChangeDirectory(leveldbsrcdir)
            FileRule(leveldblibfile, @build_steps begin
                     `make`
                     `cp out-shared/libleveldb.$(Libdl.dlext).$(version) $(leveldblibfile)`
            end)
        end
    end), libleveldb, os = :Unix)

@BinDeps.install Dict(:libleveldb => :libleveldb)
