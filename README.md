# LevelDB
[![CI](https://github.com/sadit/LevelDB.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/sadit/LevelDB.jl/actions/workflows/ci.yml)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://sadit.github.io/LevelDB.jl)

`LevelDB` is Google's open source on-disk key-value storage library that
provides an ordered mapping from string keys to binary values. In many
applications where only key based accesses are needed, it tends to be a faster
alternative than databases. LevelDB was written in C++ with a C calling API
included. This module provides a Julia interface to LevelDB using the `LevelDB_jll` and Julia's
`ccall` mechanism.

This package is based on the [`LevelDB`](https://github.com/jerryzhenleicai/LevelDB.jl) package.
The main difference is the use of `LevelDB_jll` and the use of Strings and any kind of Arrays as key and values.
More over, the API was made more explicit to be able to handle different data types.
It mantains the dictionary interface for one key operations.

NOTE: If you're considering using `LevelDB` for a fresh project,
  - please see this [comparison](https://mozilla.github.io/firefox-browser-architecture/text/0017-lmdb-vs-leveldb.html) with [`LMDB`](https://www.symas.com/lmdb) (a Julia package is also available [`LMDB.jl`](https://github.com/wildart/LMDB.jl)).
  - On the other hand, `LevelDB` has builtin compression and it is less painful whenever using `mmap` becomes an issue.


## Install `LevelDB.jl`

```julia
] add https://github.com/sadit/LevelDB.jl
```

## Run Testing Code

```julia
] test LevelDB
```

## Using 

```
using LevelDB
```

```julia
julia> db = DB(file_path; create_if_missing = false, error_if_exists = false)
```

Here `file_path` is the full path to a directory that hosts a `LevelDB` database.
`create_if_missing` is a boolean flag when true the database will be created if
it does not exist. `error_if_exists` is a boolean flag when true an error will
be thrown if the database already exists. The return value is a database object
for passing to read/write calls.

```julia
julia> close(db)
```

Close a database, `db` is the object returned from a `DB` call. A
directory can only be opened by a single `DB` at a time.

By default, key and values have `String` type. You can specify String keys and vector values as follows:

```julia
db = DB(file_path, String, Vector{Float32}; create_if_missing = false, error_if_exists = false)
```

## Read and Write Operations

```julia
julia> db[key] = value
```

```julia
julia> db[key]
```

As in the `LevelDB.jl` version, you can use `Array{UInt8}` and use the `reinterpret` function to
cast it into the right array type (see test code). However, in this package this can be shortened just specifying
the types when the database is opened; it can also support `String` objects painless.

```julia
julia> delete!(db, key)
```

Delete a key from `db`.

## Batches

`LevelDB` supports grouping a number of put operations into a write batch, the
batch will either succeed as a whole or fail altogether, behaving like an atomic
update.

```julia
julia> put_batch!(db, pairs)
```

Creates a write batch internally which is then commited to `db`.

Batch deletions.
```julia
julia> del_batch!(db, keys)
```

Fetch many keys (not necessarily sequential)
```julia
julia> fetch_batch!(db, keys)
```


## Iterate

```julia
julia> for (key, value) in db
           #do something with the key value pair
       end
```
Iterate over all `key => value` pairs in a `DB`.


```julia
julia> for (key, value) in Range(db, keylow, keyhigh)
           #do something with the key value pair
       end
```
Iterate over a range between key1 and key2 (inclusive)

```julia
julia> for (key, value) in Prefix(db, keyprefix)
           #do something with the key value pair
       end
```
Iterate over a range defined by a prefix

## Authors
- Eric S. Tellez (donsadit@gmail.com)
- Jerry Zhenlei Cai ( jpenguin at gmail dot com )
- Guido Kraemer
- `@huwenshuo`
- `@tmlbl`
