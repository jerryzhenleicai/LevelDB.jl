module LevelDB

export open_db
export close_db
export create_write_batch
export batch_put
export write_batch
export db_put
export db_get


function open_db(file_path, create_if_missing)
    options = ccall( (:leveldb_options_create, "libleveldb"), Ptr{Void}, ())
    if create_if_missing
        ccall( (:leveldb_options_set_create_if_missing, "libleveldb"), Void,
              (Ptr{Void}, Uint8), options, 1)
    end
    err = Ptr{Uint8}[0]
    db = ccall( (:leveldb_open, "libleveldb"), Ptr{Void},
               (Ptr{Void}, Ptr{Uint8}, Ptr{Ptr{Uint8}}) , options, file_path, err)

    if db == C_NULL
        error(bytestring(err[1]))
    end
    return db
end


function close_db(db)
    ccall( (:leveldb_close, "libleveldb"), Void, (Ptr{Void},), db)
end

function db_put(db, key, value, val_len)
    options = ccall( (:leveldb_writeoptions_create, "libleveldb"), Ptr{Void}, ())
    err = Ptr{Uint8}[0]
    ccall( (:leveldb_put, "libleveldb"), Void,
          (Ptr{Void}, Ptr{Void}, Ptr{Void}, Uint, Ptr{Uint8}, Uint, Ptr{Ptr{Uint8}} ),
          db, options,key, length(key), value, val_len, err)
    if err[1] != C_NULL
        error(bytestring(err[1]))
    end
end

# return an Uint8 array obj
function db_get(db, key)
    # leveldb_get will allocate the buffer for return value
    options = ccall( (:leveldb_readoptions_create, "libleveldb"), Ptr{Void}, ())
    err = Ptr{Uint8}[0]
    val_len = Csize_t[0]
    value = ccall( (:leveldb_get, "libleveldb"), Ptr{Uint8},
          (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Uint, Ptr{Csize_t},  Ptr{Ptr{Uint8}} ),
          db, options, key, length(key), val_len, err)
    if err[1] != C_NULL
        error(bytestring(err[1]))
    else
        s = pointer_to_array(value, (val_len[1],), true)
        s
    end
end


function create_write_batch()
    batch = ccall( (:leveldb_writebatch_create, "libleveldb"), Ptr{Void},())
    return batch
end



function batch_put(batch, key, value, val_len)
    ccall( (:leveldb_writebatch_put, "libleveldb"), Void,
          (Ptr{Uint8}, Ptr{Uint8}, Uint, Ptr{Uint8}, Uint),
          batch, key, length(key), value, val_len)
end

function write_batch(db, batch)
    options = ccall( (:leveldb_writeoptions_create, "libleveldb"), Ptr{Void}, ())
    err = Ptr{Uint8}[0]
    ccall( (:leveldb_write, "libleveldb"), Void,
          (Ptr{Void}, Ptr{Void}, Ptr{Void},  Ptr{Ptr{Uint8}} ),
          db, options, batch, err)
    if err[1] != C_NULL
        error(bytestring(err[1])) */
    end
end

end
