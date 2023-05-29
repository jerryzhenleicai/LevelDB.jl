module LevelDB

using LevelDB_jll
export DB, Range, put!, put_batch!, fetch, fetch_batch, del!, del_batch!

include("libleveldb_common.jl")
include("libleveldb_api.jl")

macro destroy_if_not_null(f, ptr)
    esc(quote
        if $ptr != C_NULL
          $f($ptr)
          $ptr = C_NULL
        end
    end)
end

macro check_err_ref(f, g = :())
    esc(quote
          err_ref = Ref{Cstring}(C_NULL)

          $f

          err_ptr = err_ref[]
          if err_ptr != C_NULL
              err_msg = err_ptr |> unsafe_string
              leveldb_free(convert(Ptr{Nothing}, err_ptr))

              $g

              error(err_msg)
          end
    end)
end


# This needs to be mutable, because handle == C_NULL is used to avoid double
# free
mutable struct DB{KeyType,ValueType}
    dir           :: String
    handle        :: Ptr{leveldb_t}
    options       :: Ptr{leveldb_options_t}
    write_options :: Ptr{leveldb_writeoptions_t}
    read_options  :: Ptr{leveldb_readoptions_t}
end

serializekey(::DB, data) = pointer(data), sizeof(data)
serializevalue(::DB, data) = pointer(data), sizeof(data)


function deserialize_(::Type{T}, data, len::Integer)::T where T
    p = convert(Ptr{T}, data)
    unsafe_load(p)
end

function deserialize_(::Type{Vector{T}}, data, len::Integer)::Vector{T} where T
    p = convert(Ptr{T}, data)
    unsafe_wrap(Vector{T}, p, len ÷ sizeof(T); own=true)
end

function deserialize_(::Type{String}, data, len::Integer)
    p = convert(Ptr{UInt8}, data)
    unsafe_string(p, len)
end


deserializekey(::DB{K,V}, data::Cstring, len::Integer) where {K,V} = deserialize_(K, data, len)
deserializevalue(::DB{K,V}, data::Cstring, len::Integer) where {K,V} = deserialize_(V, data, len)

"""
    LevelDB.DB(file_path, KeyType, ValueType; create_if_missing = false, error_if_exists = false)::LevelDB.DB

Opens or creates a `LevelDB` database at `file_path`.

# Parameters
- `file_path::String`: The full path to a directory that hosts a `LevelDB` database.
- `create_if_missing::Bool`: When `true` the database will be created if it does not exist.
- `error_if_exists::Bool`: When `true` an error will be thrown if the database already exists.

# Example
    db = LevelDB.DB(mktemp())
    db[[0x01]] = [0x0a]
    db[[0x02]] = [0x0b]

    db[[0x01]] # returns [0x0a]

    close(db)
"""
function DB(
        dir               :: String,
                          :: Type{KeyType} = String,
                          :: Type{ValueType} = String;
        create_if_missing :: Bool = false,
        error_if_exists   :: Bool = false
    ) where {KeyType,ValueType}
    options = _leveldb_options_create(create_if_missing = create_if_missing,
                                      error_if_exists   = error_if_exists)
    write_options = _leveldb_writeoptions_create()
    read_options  = _leveldb_readoptions_create()

    @check_err_ref handle = leveldb_open(options, dir, err_ref) begin
        leveldb_options_destroy(options)
        leveldb_writeoptions_destroy(write_options)
        leveldb_readoptions_destroy(read_options)
    end

    @assert        handle != C_NULL
    @assert       options != C_NULL
    @assert write_options != C_NULL
    @assert  read_options != C_NULL

    db = DB{KeyType,ValueType}(dir, handle, options, write_options, read_options)

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
    ### adjacent keys are stored in blocks (default: ~4096 uncompressed bytes). Bulk scans are faster with larger blocks, point reads of small values benefit from smaller block sizes.
    # leveldb_options_set_block_size
    ### cache frequently used blocks uncompressed block contents
    # leveldb_options_set_cache
    ### set the comparator that determines ordering of keys
    # leveldb_options_set_comparator
    ### Default: with compression
    # leveldb_options_set_compression
    # leveldb_options_set_max_open_files
    ### throw and error if DB exists
    # leveldb_options_set_error_if_exists
    ### create the DB if true
    # leveldb_options_set_create_if_missing
    # leveldb_options_set_write_buffer_size
    ### a filter policy can reduce the number of disk reads (a bloom filter with 10 bits/key reduces get reads for get calls by a factor of ~100)
    # leveldb_options_set_filter_policy
    ### raise an error as soon as internal corruption is detected, default: off
    # leveldb_options_set_paranoid_checks
    ### file operations are routed through and Env object
    # leveldb_options_set_env
    # leveldb_options_set_info_log

    leveldb_options_set_error_if_exists(o, error_if_exists)
    leveldb_options_set_create_if_missing(o, create_if_missing)

    return o
end

function _leveldb_writeoptions_create()
    o = leveldb_writeoptions_create()

    ## These are the possible options, TODO: figure out what they mean and add
    ## them one by one

    ### asynchronous writing (default) is much faster but in case of a crash some data may be lost
    # leveldb_writeoptions_set_sync

    return o
end

function _leveldb_readoptions_create()
    o = leveldb_readoptions_create()

    ## These are the possible options, TODO: figure out what they mean and add
    ## them one by one
    ### for disabling caching temporarily during bulk reads to avoid displacing data in cache
    # leveldb_readoptions_set_fill_cache
    ### snapshots are readonly views of a version of the DB, if NULL it is the current state. There are GetSnapshot and ReleaseSnapshot methods
    # leveldb_readoptions_set_snapshot
    ### if true forces checksum verification for all data reads, default is false
    # leveldb_readoptions_set_verify_checksums

    return o
end

Base.isopen(db::DB) = db.handle != C_NULL

function Base.close(db::DB)
    @destroy_if_not_null leveldb_close                db.handle
    @destroy_if_not_null leveldb_options_destroy      db.options
    @destroy_if_not_null leveldb_writeoptions_destroy db.write_options
    @destroy_if_not_null leveldb_readoptions_destroy  db.read_options
end

function Base.show(io::IO, db::DB)
    print(io, "LevelDB: ", db.dir)
end

@inline Base.getindex(db::DB, key) = fetch(db, key)

function fetch(db::DB{K,V}, key::K)::V where {K,V}
    val_size = Ref{Csize_t}(0)
    keyptr, keysize = serializekey(db, key)
    @check_err_ref res_ptr = leveldb_get(db.handle, db.read_options,
                                         keyptr, keysize,
                                         val_size, err_ref)

    size = val_size[]
    if size == 0
        throw(KeyError(key))
    end

    @assert val_size != C_NULL
    @assert res_ptr != C_NULL

    deserializevalue(db, res_ptr, size)
end

@inline Base.setindex!(db::DB, val, key) = put!(db, val, key)

function put!(db::DB{K,V}, val::V, key::K)::V where {K,V}
    keyptr, keysize = serializekey(db, key)
    valptr, valsize = serializevalue(db, val)
    @check_err_ref leveldb_put(db.handle, db.write_options,
                               keyptr, keysize,
                               valptr, valsize,
                               err_ref)
    val
end

Base.delete!(db::DB, key) = del!(db, key)

function del!(db::DB, key)
    keyptr, keysize = serializekey(db, key)
    @check_err_ref leveldb_delete(db.handle, db.write_options,
                                  keyptr, keysize,
                                  err_ref)
    db
end

function del_batch!(db::DB, keys)
    for i in keys
        delete!(db, i)
    end

    db
end

function fetch_batch(db::DB, keys)
    [db[k] for k in keys]
end

function put_batch!(db::DB, pairs)
    batch = leveldb_writebatch_create()

    for (key, val) in pairs
        keyptr, keysize = serializekey(db, key)
        valptr, valsize = serializevalue(db, val)
        leveldb_writebatch_put(batch,
                               keyptr, keysize, 
                               valptr, valsize)
    end

    @check_err_ref leveldb_write(db.handle, db.write_options, batch, err_ref) begin
        leveldb_writebatch_destroy(batch)
    end
    leveldb_writebatch_destroy(batch)

    pairs
end

# This needs to be mutable, because handle == C_NULL is used to avoid double
# free
abstract type AbstractIterator end

mutable struct Iterator <: AbstractIterator
    handle :: Ptr{leveldb_iterator_t}
end


function Iterator(db::DB)
    Iterator(leveldb_create_iterator(db.handle, db.read_options))
end

Base.IteratorEltype(::DB) = Base.HasEltype()
Base.eltype(::DB{K,V}) where {K,V} = Pair{K,V}
Base.IteratorSize(::DB) = Base.SizeUnknown()

Base.seekstart(it::Iterator) = leveldb_iter_seek_to_first(it.handle)
# Base.seekend(it::Iterator) = leveldb_iter_seek_to_last(it.handle)

function Base.close(it::AbstractIterator)
    @destroy_if_not_null leveldb_iter_destroy it.handle
end

is_valid(it::AbstractIterator) = it.handle != C_NULL && leveldb_iter_valid(it.handle) > 0x00

function get_key_val(db::DB, it::AbstractIterator)
    len = Ref{Csize_t}(0)
    keyptr = leveldb_iter_key(it.handle, len)
    key = deepcopy(deserializekey(db, keyptr, len[]))
    valptr = leveldb_iter_value(it.handle, len)
    val = deepcopy(deserializevalue(db, valptr, len[]))

    return key => val
end

function Base.iterate(db::DB, it=nothing)
    if it === nothing
        it = Iterator(db)
        seekstart(it)
    end

    if is_valid(it)
        kv = get_key_val(db, it)
        leveldb_iter_next(it.handle)
        return kv, it
    else
        close(it)
        return nothing
    end
end


"""
    LevelDB.Range(db::LevelDB.DB, key_start, key_end)::LevelDB.Range

Iterates over a subset of the data base

# Parameters
- `db::LevelDB.DB`: A `LevelDB.DB` object to iterate over.
- `key_start`: Iterate from here.
- `key_end`: Iterate until here.

# Example
    for (key, value) in LevelDB.Range(db, [0x01], [0x05])
        # do something with the key and value
    end
"""
struct Range{K,V}
    db :: DB{K,V}
    key_start::K
    key_end::K
end

Base.IteratorEltype(::Range) = Base.HasEltype()
Base.eltype(::Range{K,V}) where {K,V} = Pair{K,V}
Base.IteratorSize(::Range) = Base.SizeUnknown()



function Base.iterate(view::Range)
    it = Iterator(leveldb_create_iterator(view.db.handle, view.db.read_options))
    keyptr, keylen = serializekey(view.db, view.key_start)
    leveldb_iter_seek(it.handle, keyptr, keylen)
    if is_valid(it)
        kv = get_key_val(view.db, it)
        leveldb_iter_next(it.handle)
        return kv, it
    else
        close(it)
        return nothing
    end
end


function Base.iterate(view::Range, it::Iterator)
    if is_valid(it)
        # key is past the range?
        kv = get_key_val(view.db, it)
        if kv[1] > view.key_end
            close(it)
            return nothing
        else
            leveldb_iter_next(it.handle)
            return kv, it
        end
    else
        return nothing
    end
end

end # module LevelDB
