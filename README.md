# LevelDB
[![Build Status](https://api.travis-ci.org/jerryzhenleicai/LevelDB.jl.svg?branch=master)](https://www.travis-ci.org/jerryzhenleicai/LevelDB.jl)
[![codecov.io](http://codecov.io/github/jerryzhenleicai/LevelDB.jl/coverage.svg?branch=master)](http://codecov.io/github/jerryzhenleicai/LevelDB.jl?branch=master)

`LevelDB` is Google's open source on-disk key-value storage library that
provides an ordered mapping from string keys to binary values. In many
applications where only key based accesses are needed, it tends to be a faster
alternative than databases. LevelDB was written in C++ with a C calling API
included. This module provides a Julia interface to LevelDB using Julia's
`ccall` mechanism.

## Install LevelDB

You can build `LevelDB` from its source code at
https://github.com/google/leveldb. Please install the final dynamic library into
a system directory such as /usr/lib or make sure `libleveldb.so` is in one of
your `LD_LIBRARY_PATH` directories. If `libleveldb.so` is not installed, Julia
will try to download and build it automatically.

## Run Testing Code

```julia
(v1.1) pkg> test LevelDB
```
This will exercise batched and non-batched writes and reads for string and float array values.

## Create/Open/Close a LevelDB database

```julia
julia> db = LevelDB.DB(file_path; create_if_missing = false, error_if_exists = false)
```

Here `file_path` is the full path to a directory that hosts a `LevelDB` database.
`create_if_missing` is a boolean flag when true the database will be created if
it does not exist. `error_if_exists` is a boolean flag when true an error will
be thrown if the database already exists. The return value is a database object
for passing to read/write calls.

```julia
julia> close(db)
```

Close a database, `db` is the object returned from a `LevelDB.DB` call. A
directory can only be opened by a single `LevelDB.DB` at a time.


## Read and Write Operations

```julia
julia> db[key] = value
```
`key` and `value` are `Array{UInt8}`.

```julia
julia> db[key]
```

Return value is an `Array{UInt8}`, one can use the `reinterpret` function to
cast it into the right array type (see test code).

```julia
julia> delete!(db, key)
```

Delete a key from `db`.

## Batched Write

`LevelDB` supports grouping a number of put operations into a write batch, the
batch will either succeed as a whole or fail altogether, behaving like an atomic
update.

```julia
julia> db[keys] = values
```

`keys` and `values` must behave like iterators returning `Array{UInt8}`. Creates
a write batch internally which is then commited to `db`.

## Iterate

```julia
julia> for (key, value) in db
           #do something with the key value pair
       end
```
Iterate over all `key => value` pairs in a `LevelDB.DB`.


```julia
julia> for (key, value) in db_range_iterator(db, key1, key2)
           #do something with the key value pair
       end
```
Iterate over a range between key1 and key2 (inclusive)


## Authors

- Jerry Zhenlei Cai ( jpenguin at gmail dot com )
- Guido Kraemer

additional contributions by

- `@huwenshuo`
- `@tmlbl`
