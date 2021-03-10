using BinDeps
using Libdl

@BinDeps.setup

version = "1.22"
url = "https://github.com/google/leveldb/archive/$(version).tar.gz"

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
		     `cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release .`
		     `cmake --build .`
                     `cp libleveldb.$(Libdl.dlext).$(version).0 $(leveldblibfile)`
            end)
        end
    end), libleveldb, os = :Unix)

@BinDeps.install Dict(:libleveldb => :libleveldb)
