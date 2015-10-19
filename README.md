# LevelDB

LevelDB is Google's open source on-disk key-value storage library that provides an ordered mapping from string keys to binary values. In many applications where only key based accesses are needed, it tends to be a faster alternative than databases.  LevelDB was written in C++ with a C calling API included. This module provides a Julia interface to LevelDB using Julia's  ccall mechanism.

## Install LevelDB

You can build LevelDB from its source code at https://github.com/google/leveldb. Please install the final dynamic library into a system directory such as /usr/lib or make sure libleveldb.so is in one of your LD_LIBRARY_PATH directories.


## Run Testing Code

```
julia test/runtests.jl
```
This will exercise batched and non-batched writes and reads for string and float array values.

## Create/Open/Close a LevelDB database

```
function open_db(file_path, create_if_missing)
```

Here file_path is the full path to a directory that hosts a LevelDB database, create_if_missing is a boolean flag when true the database will be created if it does not exist.  The return value is a database object for passing to read/write calls.

```
function close_db(db)
```
Close a database, db is the object returned from a open_db call.


## Read and Write Operations

```
function db_put(db, key, value, val_len)
```
key is a string, value is a pointer to a byte array, val_len is its length

```
function db_get(db, key)
```

Return value is a UInt8 array, one can use the reinterpret Julia function to cast it into the right array type (see test code).


```
function db_delete(db, key)
```


## Batched Write

LevelDB supports grouping a number of put operations into a WriteBatch, the batch will either succeed as a whole or fail altogether, behaving like an atomic update.

```
function create_write_batch()
```

Create a WriteBatch object.

```
function batch_put(batch, key, value, val_len)
```

Add one key value Put operation into a WriteBatch

```
function write_batch(db, batch)
```

Commit the WriteBatch into the database as an atomic write.

## General for loop

```
range = db_range(db, "key_start", "key_end")
for (k, v) in range
  #do something
end
```
Note: if you `break` the loop, you had to manually close the range by `range_close(range)`.

## Author

Jerry Zhenlei Cai ( jpenguin@gmail dot com )