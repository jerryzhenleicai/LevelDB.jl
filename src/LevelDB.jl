module LevelDB

using BinDeps

depsfile = joinpath(dirname(pathof(LevelDB)), "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("LevelDB not properly installed. Please run Pkg.build(\"LevelDB\")")
end

include("libleveldb_common.jl")
include("libleveldb_api.jl")

# This needs to be mutable, because handle == C_NULL is used to avoid double
# free
mutable struct DB
    dir           :: String
    handle        :: Ptr{leveldb_t}
    options       :: Ptr{leveldb_options_t}
    write_options :: Ptr{leveldb_writeoptions_t}
    read_options  :: Ptr{leveldb_readoptions_t}
end

function DB(
        dir           :: String;
        create_if_missing = false,
        error_if_exists = false
    )
    options = _leveldb_options_create(create_if_missing = create_if_missing,
                                      error_if_exists   = error_if_exists)
    write_options = _leveldb_writeoptions_create()
    read_options  = _leveldb_readoptions_create()

    err_ptr = Ref{Cstring}(C_NULL)

    handle = leveldb_open(options, dir, err_ptr)

    if err_ptr[] != C_NULL
        err_ptr[] |> unsafe_string |> error

        leveldb_free(err_ptr)
        # leveldb_close(handle)
        leveldb_options_destroy(options)
        leveldb_writeoptions_destroy(write_options)
        leveldb_readoptions_destroy(read_options)
    end

    @assert        handle != C_NULL
    @assert       options != C_NULL
    @assert write_options != C_NULL
    @assert  read_options != C_NULL

    db = DB(dir, handle, options, write_options, read_options)
    # finalizer(close, db)

    return db
end

function _leveldb_options_create(
    ;
    error_if_exists = false,
    create_if_missing = false
)
    o = leveldb_options_create()

    ## These are the possible options, TODO: figure out what they mean and add
    ## them one by one
    # leveldb_options_set_block_restart_interval
    # leveldb_options_set_block_size
    # leveldb_options_set_cache
    # leveldb_options_set_comparator
    # leveldb_options_set_compression
    # leveldb_options_set_max_open_files
    # leveldb_options_set_error_if_exists
    # leveldb_options_set_create_if_missing
    # leveldb_options_set_write_buffer_size
    # leveldb_options_set_filter_policy
    # leveldb_options_set_filter_policy

    leveldb_options_set_error_if_exists(o, error_if_exists)
    leveldb_options_set_create_if_missing(o, create_if_missing)

    return o
end

function _leveldb_writeoptions_create()
    o = leveldb_writeoptions_create()

    ## These are the possible options, TODO: figure out what they mean and add
    ## them one by one
    # leveldb_writeoptions_set_sync

    return o
end

function _leveldb_readoptions_create()
    o = leveldb_readoptions_create()

    ## These are the possible options, TODO: figure out what they mean and add
    ## them one by one
    # leveldb_readoptions_set_fill_cache
    # leveldb_readoptions_set_snapshot
    # leveldb_readoptions_set_verify_checksums

    return o
end

Base.isopen(db::DB) = db.handle != C_NULL

function Base.close(db::DB)
    if db.handle != C_NULL
        # leveldb_destroy_db DELETES the data base from disk!!!
        leveldb_close(db.handle)
        db.handle = C_NULL
    end

    if db.options != C_NULL
        leveldb_options_destroy(db.options)
        db.options = C_NULL
    end

    if db.write_options != C_NULL
        leveldb_writeoptions_destroy(db.write_options)
        db.write_options = C_NULL
    end

    if db.read_options != C_NULL
        leveldb_readoptions_destroy(db.read_options)
        db.read_options = C_NULL
    end
end

function Base.show(io::IO, db::DB)
    print(io, "LevelDB: ", db.dir)
end

function Base.getindex(db::DB, i::Vector{UInt8})
    val_size = Ref{Csize_t}(0)
    err_ptr = Ptr{Cstring}(0)
    res_ptr = leveldb_get(db.handle, db.read_options,
                          pointer(i), length(i),
                          val_size, err_ptr)

    if err_ptr != C_NULL
        err_msg = err_ptr |> unsafe_load |> unsafe_string
        leveldb_free(err_ptr)
        error(err_msg)
    end

    size = val_size[]
    if size == 0
        throw(KeyError(i))
    end

    @assert val_size != C_NULL
    @assert res_ptr != C_NULL

    res_ptr_uint8 = convert(Ptr{UInt8}, res_ptr)

    # NOTE: we own the memory, in theory libleveldb has to free `res_ptr`.
    unsafe_wrap(Vector{UInt8}, res_ptr_uint8, (size, ), own = true)
end

function Base.setindex!(db::DB, v::Vector{UInt8}, i::Vector{UInt8})
    err_ptr = Ptr{Cstring}(0)

    leveldb_put(db.handle, db.write_options,
                pointer(i), length(i),
                pointer(v), length(v),
                err_ptr)

    if err_ptr != C_NULL
        err_msg = err_ptr |> unsafe_load |> unsafe_string
        leveldb_free(err_ptr)
        error(err_msg)
    end

    return v
end

function Base.delete!(db::DB, i::Vector{UInt8})
    err_ptr = Ptr{Cstring}(0)

    leveldb_delete(db.handle, db.write_options,
                   pointer(i), length(i),
                   err_ptr)

    if err_ptr != C_NULL
        err_msg = err_ptr |> unsafe_load |> unsafe_string
        leveldb_free(err_ptr)
        error(err_msg)
    end

    return db
end

function Base.delete!(db, idxs)
    for i in idxs
        delete!(db, i)
    end

    return db
end

function Base.setindex!(db::DB, v, k)
    batch = leveldb_writebatch_create()

    for (kk, vv) in zip(k, v)
        leveldb_writebatch_put(batch,
                               pointer(kk), length(kk),
                               pointer(vv), length(vv))
    end

    err_ptr = Ptr{Cstring}(0)

    leveldb_write(db.handle, db.write_options, batch, err_ptr)

    if err_ptr != C_NULL
        err_msg = err_ptr |> unsafe_load |> unsafe_string
        leveldb_free(err_ptr)
        error(err_msg)
    end

    leveldb_writebatch_destroy(batch)
end

# This needs to be mutable, because handle == C_NULL is used to avoid double
# free
mutable struct Iterator
    handle :: Ptr{leveldb_iterator_t}
end

function Iterator(db::DB)
    it = Iterator(leveldb_create_iterator(db.handle, db.read_options))
    # finalizer(close, it)
    return it
end

Base.IteratorEltype(::DB) = Vector{UInt8}
Base.IteratorSize(::DB) = SizeUnknown()

Base.seekstart(it::Iterator) = leveldb_iter_seek_to_first(it.handle)
# Base.seekend(it::Iterator) = leveldb_iter_seek_to_last(it.handle)

function close(it::Iterator)
    if it.handle != C_NULL
        leveldb_iter_destroy(it.handle)
        it.handle = C_NULL
    end
end

isdone(it::Iterator) = leveldb_iter_valid(it.handle) > 0x00

function get_key_val(it::Iterator)

    key_size = Ref{Csize_t}(0)
    key_ptr = leveldb_iter_key(it.handle, key_size)
    key = unsafe_wrap(Vector{UInt8}, key_ptr, (key_size[], ), own = true)

    val_size = Ref{Csize_t}(0)
    val_ptr = leveldb_iter_value(it.handle, val_size)
    val = unsafe_wrap(Vector{UInt8}, val_ptr, (val_size[], ), own = true)

    return key => val
end

function Base.iterate(db::DB)

    it = Iterator(db)
    seekstart(it)

    if isdone(it)
        return nothing
    else
        kv = get_key_val(it)
        leveldb_iter_next(it.handle)
        return  kv, it
    end
end

function Base.iterate(db::DB, it::Iterator)
    if isdone(it)
        close(it)
        return nothing
    else
        kv = get_key_val(it)
        leveldb_iter_next(it.handle)
        kv, it
    end
end

end # module LevelDB
