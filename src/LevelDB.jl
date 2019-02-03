module LevelDB

using BinDeps

depsfile = joinpath(dirname(pathof(LevelDB)), "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("LevelDB not properly installed. Please run Pkg.build(\"LevelDB\")")
end

# TODO: exporting these will be removed
export open_db
export close_db
export create_write_batch
export batch_put
export write_batch
export db_put
export db_get
export db_delete
export db_range
export range_close

include("impl.jl")

mutable struct DB
    dir::String
    handle::Ptr{Nothing}

    function DB(dir::String; create_if_missing = false)
        db = open_db(dir, create_if_missing)
        new(dir, db)
    end
end
function Base.show(io::IO, db::DB)
    println(io, "LevelDB: ", db.dir)
end

Base.isopen(db::DB) = db.handle != C_NULL
function Base.close(db::DB)
    isopen(db) && close_db(db.handle)
    db.handle = C_NULL
    nothing
end

Base.getindex(db::DB, i::Vector{UInt8}) = db_get(db.handle, i)
Base.setindex!(db::DB, v::Vector{UInt8}, i::Vector{UInt8}) = db_put(db.handle, i, v, length(v))
Base.delete!(db::DB, i::Vector{UInt8}) = db_delete(db.handle, i)
function Base.delete!(db, idxs)
    for i in idxs
        delete!(db, i)
    end
end

function Base.setindex!(db::DB, v, k)
    batch = create_write_batch()
    for (kk, vv) in zip(k, v)
        batch_put(batch, kk, vv, length(vv))
    end
    write_batch(db.handle, batch)
end

Base.iterate(db::DB) = db.handle |> db_range |> iterate

function Base.iterate(db::DB, state::Range)
    if isdone(state)
        return nothing
    else
        k = iter_key(state.iter)
        v = iter_value(state.iter)
        iter_next(state.iter)
        return (k => v, state)
    end
end

end # module LevelDB
