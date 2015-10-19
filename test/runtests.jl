using LevelDB
using Base.Test

db = open_db("level.db", true)
batch = create_write_batch()
val = "value10"
batch_put(batch, "key1", val, length(val))
write_batch(db, batch)

readback_value = bytestring(db_get(db, "key1"))

@test  readback_value == val

println("String read back OK")


db_delete(db, "key1")
@test isempty(db_get(db, "key1")) == true
println("Successfully deleted")


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



db_put(db, "key2", "v2", 2)
db_put(db, "key3", "v3", 2)

d = Dict(
  "key1" => "v1",
  "key2" => "v2",
  "key3" => "v3"
)

for (k, v) in d
  db_put(db, k, v, length(v))
end

for (k, v) in db_range(db, "key1", "key3")
  @test bytestring(v) == d[k]
end
println("Pass iterator")


close_db(db)
println("All Tests Passed.")
run(`rm -rf level.db`)
