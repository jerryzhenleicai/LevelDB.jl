# Julia wrapper for header: /home/gkraemer/.julia/dev/LevelDB/deps/src/leveldb-1.20/include/leveldb/c.h
# Automatically generated using Clang.jl wrap_c


function leveldb_open(options, name, errptr)
    ccall((:leveldb_open, libleveldb), Ptr{leveldb_t}, (Ptr{leveldb_options_t}, Cstring, Ptr{Cstring}), options, name, errptr)
end

function leveldb_close(db)
    ccall((:leveldb_close, libleveldb), Cvoid, (Ptr{leveldb_t},), db)
end

function leveldb_put(db, options, key, keylen, val, vallen, errptr)
    ccall((:leveldb_put, libleveldb), Cvoid, (Ptr{leveldb_t}, Ptr{leveldb_writeoptions_t}, Cstring, Csize_t, Cstring, Csize_t, Ptr{Cstring}), db, options, key, keylen, val, vallen, errptr)
end

function leveldb_delete(db, options, key, keylen, errptr)
    ccall((:leveldb_delete, libleveldb), Cvoid, (Ptr{leveldb_t}, Ptr{leveldb_writeoptions_t}, Cstring, Csize_t, Ptr{Cstring}), db, options, key, keylen, errptr)
end

function leveldb_write(db, options, batch, errptr)
    ccall((:leveldb_write, libleveldb), Cvoid, (Ptr{leveldb_t}, Ptr{leveldb_writeoptions_t}, Ptr{leveldb_writebatch_t}, Ptr{Cstring}), db, options, batch, errptr)
end

function leveldb_get(db, options, key, keylen, vallen, errptr)
    ccall((:leveldb_get, libleveldb), Cstring, (Ptr{leveldb_t}, Ptr{leveldb_readoptions_t}, Cstring, Csize_t, Ptr{Csize_t}, Ptr{Cstring}), db, options, key, keylen, vallen, errptr)
end

function leveldb_create_iterator(db, options)
    ccall((:leveldb_create_iterator, libleveldb), Ptr{leveldb_iterator_t}, (Ptr{leveldb_t}, Ptr{leveldb_readoptions_t}), db, options)
end

function leveldb_create_snapshot(db)
    ccall((:leveldb_create_snapshot, libleveldb), Ptr{leveldb_snapshot_t}, (Ptr{leveldb_t},), db)
end

function leveldb_release_snapshot(db, snapshot)
    ccall((:leveldb_release_snapshot, libleveldb), Cvoid, (Ptr{leveldb_t}, Ptr{leveldb_snapshot_t}), db, snapshot)
end

function leveldb_property_value(db, propname)
    ccall((:leveldb_property_value, libleveldb), Cstring, (Ptr{leveldb_t}, Cstring), db, propname)
end

function leveldb_approximate_sizes(db, num_ranges, range_start_key, range_start_key_len, range_limit_key, range_limit_key_len, sizes)
    ccall((:leveldb_approximate_sizes, libleveldb), Cvoid, (Ptr{leveldb_t}, Cint, Ptr{Cstring}, Ptr{Csize_t}, Ptr{Cstring}, Ptr{Csize_t}, Ptr{UInt64}), db, num_ranges, range_start_key, range_start_key_len, range_limit_key, range_limit_key_len, sizes)
end

function leveldb_compact_range(db, start_key, start_key_len, limit_key, limit_key_len)
    ccall((:leveldb_compact_range, libleveldb), Cvoid, (Ptr{leveldb_t}, Cstring, Csize_t, Cstring, Csize_t), db, start_key, start_key_len, limit_key, limit_key_len)
end

function leveldb_destroy_db(options, name, errptr)
    ccall((:leveldb_destroy_db, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Cstring, Ptr{Cstring}), options, name, errptr)
end

function leveldb_repair_db(options, name, errptr)
    ccall((:leveldb_repair_db, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Cstring, Ptr{Cstring}), options, name, errptr)
end

function leveldb_iter_destroy(arg1)
    ccall((:leveldb_iter_destroy, libleveldb), Cvoid, (Ptr{leveldb_iterator_t},), arg1)
end

function leveldb_iter_valid(arg1)
    ccall((:leveldb_iter_valid, libleveldb), Cuchar, (Ptr{leveldb_iterator_t},), arg1)
end

function leveldb_iter_seek_to_first(arg1)
    ccall((:leveldb_iter_seek_to_first, libleveldb), Cvoid, (Ptr{leveldb_iterator_t},), arg1)
end

function leveldb_iter_seek_to_last(arg1)
    ccall((:leveldb_iter_seek_to_last, libleveldb), Cvoid, (Ptr{leveldb_iterator_t},), arg1)
end

function leveldb_iter_seek(arg1, k, klen)
    ccall((:leveldb_iter_seek, libleveldb), Cvoid, (Ptr{leveldb_iterator_t}, Cstring, Csize_t), arg1, k, klen)
end

function leveldb_iter_next(arg1)
    ccall((:leveldb_iter_next, libleveldb), Cvoid, (Ptr{leveldb_iterator_t},), arg1)
end

function leveldb_iter_prev(arg1)
    ccall((:leveldb_iter_prev, libleveldb), Cvoid, (Ptr{leveldb_iterator_t},), arg1)
end

function leveldb_iter_key(arg1, klen)
    ccall((:leveldb_iter_key, libleveldb), Cstring, (Ptr{leveldb_iterator_t}, Ptr{Csize_t}), arg1, klen)
end

function leveldb_iter_value(arg1, vlen)
    ccall((:leveldb_iter_value, libleveldb), Cstring, (Ptr{leveldb_iterator_t}, Ptr{Csize_t}), arg1, vlen)
end

function leveldb_iter_get_error(arg1, errptr)
    ccall((:leveldb_iter_get_error, libleveldb), Cvoid, (Ptr{leveldb_iterator_t}, Ptr{Cstring}), arg1, errptr)
end

function leveldb_writebatch_create()
    ccall((:leveldb_writebatch_create, libleveldb), Ptr{leveldb_writebatch_t}, ())
end

function leveldb_writebatch_destroy(arg1)
    ccall((:leveldb_writebatch_destroy, libleveldb), Cvoid, (Ptr{leveldb_writebatch_t},), arg1)
end

function leveldb_writebatch_clear(arg1)
    ccall((:leveldb_writebatch_clear, libleveldb), Cvoid, (Ptr{leveldb_writebatch_t},), arg1)
end

function leveldb_writebatch_put(arg1, key, klen, val, vlen)
    ccall((:leveldb_writebatch_put, libleveldb), Cvoid, (Ptr{leveldb_writebatch_t}, Cstring, Csize_t, Cstring, Csize_t), arg1, key, klen, val, vlen)
end

function leveldb_writebatch_delete(arg1, key, klen)
    ccall((:leveldb_writebatch_delete, libleveldb), Cvoid, (Ptr{leveldb_writebatch_t}, Cstring, Csize_t), arg1, key, klen)
end

function leveldb_writebatch_iterate(arg1, state, put, deleted)
    ccall((:leveldb_writebatch_iterate, libleveldb), Cvoid, (Ptr{leveldb_writebatch_t}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), arg1, state, put, deleted)
end

function leveldb_options_create()
    ccall((:leveldb_options_create, libleveldb), Ptr{leveldb_options_t}, ())
end

function leveldb_options_destroy(arg1)
    ccall((:leveldb_options_destroy, libleveldb), Cvoid, (Ptr{leveldb_options_t},), arg1)
end

function leveldb_options_set_comparator(arg1, arg2)
    ccall((:leveldb_options_set_comparator, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Ptr{leveldb_comparator_t}), arg1, arg2)
end

function leveldb_options_set_filter_policy(arg1, arg2)
    ccall((:leveldb_options_set_filter_policy, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Ptr{leveldb_filterpolicy_t}), arg1, arg2)
end

function leveldb_options_set_create_if_missing(arg1, arg2)
    ccall((:leveldb_options_set_create_if_missing, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Cuchar), arg1, arg2)
end

function leveldb_options_set_error_if_exists(arg1, arg2)
    ccall((:leveldb_options_set_error_if_exists, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Cuchar), arg1, arg2)
end

function leveldb_options_set_paranoid_checks(arg1, arg2)
    ccall((:leveldb_options_set_paranoid_checks, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Cuchar), arg1, arg2)
end

function leveldb_options_set_env(arg1, arg2)
    ccall((:leveldb_options_set_env, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Ptr{leveldb_env_t}), arg1, arg2)
end

function leveldb_options_set_info_log(arg1, arg2)
    ccall((:leveldb_options_set_info_log, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Ptr{leveldb_logger_t}), arg1, arg2)
end

function leveldb_options_set_write_buffer_size(arg1, arg2)
    ccall((:leveldb_options_set_write_buffer_size, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Csize_t), arg1, arg2)
end

function leveldb_options_set_max_open_files(arg1, arg2)
    ccall((:leveldb_options_set_max_open_files, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Cint), arg1, arg2)
end

function leveldb_options_set_cache(arg1, arg2)
    ccall((:leveldb_options_set_cache, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Ptr{leveldb_cache_t}), arg1, arg2)
end

function leveldb_options_set_block_size(arg1, arg2)
    ccall((:leveldb_options_set_block_size, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Csize_t), arg1, arg2)
end

function leveldb_options_set_block_restart_interval(arg1, arg2)
    ccall((:leveldb_options_set_block_restart_interval, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Cint), arg1, arg2)
end

function leveldb_options_set_compression(arg1, arg2)
    ccall((:leveldb_options_set_compression, libleveldb), Cvoid, (Ptr{leveldb_options_t}, Cint), arg1, arg2)
end

function leveldb_comparator_create(state, destructor, compare, name)
    ccall((:leveldb_comparator_create, libleveldb), Ptr{leveldb_comparator_t}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), state, destructor, compare, name)
end

function leveldb_comparator_destroy(arg1)
    ccall((:leveldb_comparator_destroy, libleveldb), Cvoid, (Ptr{leveldb_comparator_t},), arg1)
end

function leveldb_filterpolicy_create(state, destructor, create_filter, key_may_match, name)
    ccall((:leveldb_filterpolicy_create, libleveldb), Ptr{leveldb_filterpolicy_t}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), state, destructor, create_filter, key_may_match, name)
end

function leveldb_filterpolicy_destroy(arg1)
    ccall((:leveldb_filterpolicy_destroy, libleveldb), Cvoid, (Ptr{leveldb_filterpolicy_t},), arg1)
end

function leveldb_filterpolicy_create_bloom(bits_per_key)
    ccall((:leveldb_filterpolicy_create_bloom, libleveldb), Ptr{leveldb_filterpolicy_t}, (Cint,), bits_per_key)
end

function leveldb_readoptions_create()
    ccall((:leveldb_readoptions_create, libleveldb), Ptr{leveldb_readoptions_t}, ())
end

function leveldb_readoptions_destroy(arg1)
    ccall((:leveldb_readoptions_destroy, libleveldb), Cvoid, (Ptr{leveldb_readoptions_t},), arg1)
end

function leveldb_readoptions_set_verify_checksums(arg1, arg2)
    ccall((:leveldb_readoptions_set_verify_checksums, libleveldb), Cvoid, (Ptr{leveldb_readoptions_t}, Cuchar), arg1, arg2)
end

function leveldb_readoptions_set_fill_cache(arg1, arg2)
    ccall((:leveldb_readoptions_set_fill_cache, libleveldb), Cvoid, (Ptr{leveldb_readoptions_t}, Cuchar), arg1, arg2)
end

function leveldb_readoptions_set_snapshot(arg1, arg2)
    ccall((:leveldb_readoptions_set_snapshot, libleveldb), Cvoid, (Ptr{leveldb_readoptions_t}, Ptr{leveldb_snapshot_t}), arg1, arg2)
end

function leveldb_writeoptions_create()
    ccall((:leveldb_writeoptions_create, libleveldb), Ptr{leveldb_writeoptions_t}, ())
end

function leveldb_writeoptions_destroy(arg1)
    ccall((:leveldb_writeoptions_destroy, libleveldb), Cvoid, (Ptr{leveldb_writeoptions_t},), arg1)
end

function leveldb_writeoptions_set_sync(arg1, arg2)
    ccall((:leveldb_writeoptions_set_sync, libleveldb), Cvoid, (Ptr{leveldb_writeoptions_t}, Cuchar), arg1, arg2)
end

function leveldb_cache_create_lru(capacity)
    ccall((:leveldb_cache_create_lru, libleveldb), Ptr{leveldb_cache_t}, (Csize_t,), capacity)
end

function leveldb_cache_destroy(cache)
    ccall((:leveldb_cache_destroy, libleveldb), Cvoid, (Ptr{leveldb_cache_t},), cache)
end

function leveldb_create_default_env()
    ccall((:leveldb_create_default_env, libleveldb), Ptr{leveldb_env_t}, ())
end

function leveldb_env_destroy(arg1)
    ccall((:leveldb_env_destroy, libleveldb), Cvoid, (Ptr{leveldb_env_t},), arg1)
end

function leveldb_free(ptr)
    ccall((:leveldb_free, libleveldb), Cvoid, (Ptr{Cvoid},), ptr)
end

function leveldb_major_version()
    ccall((:leveldb_major_version, libleveldb), Cint, ())
end

function leveldb_minor_version()
    ccall((:leveldb_minor_version, libleveldb), Cint, ())
end
