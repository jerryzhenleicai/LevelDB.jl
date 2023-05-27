module LevelDB

using LevelDB_jll

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
mutable struct DB
    dir           :: String
    handle        :: Ptr{leveldb_t}
    options       :: Ptr{leveldb_options_t}
    write_options :: Ptr{leveldb_writeoptions_t}
    read_options  :: Ptr{leveldb_readoptions_t}
end

"""
    LevelDB.DB(file_path; create_if_missing = false, error_if_exists = false)::LevelDB.DB

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
        dir               :: String;
        create_if_missing :: Bool = false,
        error_if_exists   :: Bool = false
    )
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

    db = DB(dir, handle, options, write_options, read_options)

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

function Base.getindex(db::DB, i::Vector{UInt8})
    val_size = Ref{Csize_t}(0)
    @check_err_ref res_ptr = leveldb_get(db.handle, db.read_options,
                                         pointer(i), length(i),
                                         val_size, err_ref)

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
    @check_err_ref leveldb_put(db.handle, db.write_options,
                               pointer(i), length(i),
                               pointer(v), length(v),
                               err_ref)
    return v
end

function Base.delete!(db::DB, i::Vector{UInt8})
    @check_err_ref leveldb_delete(db.handle, db.write_options,
                                  pointer(i), length(i),
                                  err_ref)
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

    @check_err_ref leveldb_write(db.handle, db.write_options, batch, err_ref) begin
        leveldb_writebatch_destroy(batch)
    end

    leveldb_writebatch_destroy(batch)
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

Base.IteratorEltype(::DB) = Vector{UInt8}
Base.IteratorSize(::DB) = SizeUnknown()

Base.seekstart(it::Iterator) = leveldb_iter_seek_to_first(it.handle)
# Base.seekend(it::Iterator) = leveldb_iter_seek_to_last(it.handle)

Base.close(it::AbstractIterator) = @destroy_if_not_null leveldb_iter_destroy it.handle

is_valid(it::AbstractIterator) = it.handle != C_NULL && leveldb_iter_valid(it.handle) > 0x00

function get_key_val(it::AbstractIterator)

    # key
    key_size = Ref{Csize_t}(0)
    key_ptr = leveldb_iter_key(it.handle, key_size)

    key_size_val = key_size[]
    key = Vector{UInt8}(undef, key_size_val)
    unsafe_copyto!(pointer(key), convert(Ptr{UInt8}, key_ptr), key_size_val)

    # value
    val_size = Ref{Csize_t}(0)
    val_ptr = leveldb_iter_value(it.handle, val_size)

    val_size_val = val_size[]
    val = Vector{UInt8}(undef, val_size_val)
    unsafe_copyto!(pointer(val), convert(Ptr{UInt8}, val_ptr), val_size_val)

    return key => val
end

function Base.iterate(db::DB)

    it = Iterator(db)
    seekstart(it)

    if is_valid(it)
        kv = get_key_val(it)
        leveldb_iter_next(it.handle)
        return  kv, it
    else
        close(it)
        return nothing
    end
end

function Base.iterate(db::DB, it::Iterator)
    if is_valid(it)
        kv = get_key_val(it)
        leveldb_iter_next(it.handle)
        return kv, it
    else
        close(it)
        return nothing
    end
end


####################################################
# iterator that iterates over a range of keys of the DB
###
mutable struct RangeIterator <: AbstractIterator
    handle :: Ptr{leveldb_iterator_t}
    key_start::Vector{UInt8}
    key_end::Vector{UInt8}
end


"""
    LevelDB.RangeView(db::LevelDB.DB, key_start::Vector{UInt8}, key_end::Vector{UInt8})::LevelDB.RangeView

Iterates over a subset of the data base

# Parameters
- `db::LevelDB.DB`: A `LevelDB.DB` object to iterate over.
- `key_start::Vector{UInt8}`: Iterate from here.
- `key_end::Vector{UInt8}`: Iterate until here.

# Example
    for (key, value) in LevelDB.RangeView(db, [0x01], [0x05])
        # do something with the key and value
    end
"""
mutable struct RangeView
    db :: DB
    key_start::Vector{UInt8}
    key_end::Vector{UInt8}
end

Base.IteratorEltype(::RangeView) = Vector{UInt8}
Base.IteratorSize(::RangeView) = SizeUnknown()


is_valid(it::RangeIterator) = it.handle != C_NULL && leveldb_iter_valid(it.handle) > 0x00

function Base.iterate(view::RangeView)
    it = RangeIterator(
                       leveldb_create_iterator(view.db.handle, view.db.read_options),
                       view.key_start, view.key_end)

    leveldb_iter_seek(it.handle, pointer(it.key_start), length(it.key_start))
    if is_valid(it)
        kv = get_key_val(it)
        leveldb_iter_next(it.handle)
        return kv, it
    else
        close(it)
        return nothing
    end
end


function Base.iterate(view::RangeView, it::RangeIterator)
    if is_valid(it)
        # key is past the range?
        kv = get_key_val(it)
        if kv[1] > it.key_end
            close(it)
            return nothing
        else
            leveldb_iter_next(it.handle)
            return  kv, it
        end
    else
        return nothing
    end
end


end # module LevelDB
