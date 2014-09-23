
include("leveldb.jl")

using Base.Test

import leveldb.open_db
import leveldb.create_write_batch
import leveldb.batch_put
import leveldb.write_batch
import leveldb.db_put
import leveldb.db_get


db = open_db("level.db", true)
batch = create_write_batch()
val = "value10"
batch_put(batch, "key1", val, length(val))
write_batch(db, batch)

readback_value = bytestring(db_get(db, "key1"))

@test  readback_value == val

println("String read back OK")

# Now write a Float64 array

float_array = Float64[1.0, 2.0, 3.3, 4.4]

key = "FloatKey"

# each Float64 is 8 bytes
db_put(db, key, pointer(float_array), length(float_array) * 8)

readback_value = reinterpret(Float64,db_get(db, key))
@test float_array == readback_value

# assert the two arrays are in different memory block
# by modifying the original and the read-back copy should be different from it

float_array[1] = 100.0
@test float_array != readback_value
println("Floating point array read back OK")
