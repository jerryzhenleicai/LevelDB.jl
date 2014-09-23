# LevelDB

LevelDB is Google's open source on-disk key-value storage library that provides an ordered mapping from string keys to binary values. In many applications where only key based accesses are needed, it tends to be a faster alternative than databases.  LevelDB is written in C++ with a C API included. This module provides a Julia interface to LevelDB using the ccall mechanism.

## Install LevelDB

You can build LevelDB from its source code at https://github.com/google/leveldb. Please install the final dynamic library into a system directory such as /usr/lib or make sure libleveldb.so is in one of your LD_LIBRARY_PATH directories.


## Run Testing Code

This module consists of two Julia source files. leveldb.jl is the main source file, test_leveldb.jl contains testing code.


## Create a LevelDB database


```
function open_db(file_path, create_if_missing)

Here file_path is the full path to a directory that hosts a LevelDB database, create_if_missing is a boolean flag when true the database will be created if it does not exist.  The return value is a database object for passing to read/write calls.
