db = open_db("level.db", true)
batch = create_write_batch()
val = "value10"
batch_put(batch, "key1", val, length(val))
write_batch(db, batch)

@testset "Access" begin
    readback_value = String(db_get(db, "key1"))

    @test  readback_value == val

    db_delete(db, "key1")
    @test_throws KeyError db_get(db, "key1")

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
    db_delete(db, "FloatKey")
end

db_put(db, "key2", "v2", 2)
db_put(db, "key3", "v3", 2)

d = Dict(
         "key1" => "v1",
         "key2" => "v2",
         "key3" => "v3",
         "key4" => "v4"
)

for (k, v) in d
  db_put(db, k, v, length(v))
end

to_uint8(x::String) = unsafe_wrap(Array{UInt8, 1}, pointer(x), ncodeunits(x), own = false)
@testset "Ranges" begin
    for (k, v) in db_range(db, to_uint8("key1"), to_uint8("key5"))
        @test String(v) == d[String(k)]
    end

    for (k, v) in db_range(db)
        @test String(v) == d[String(k)]
    end

    for (k, v) in db_range(db, key_start = to_uint8("key1"))
        @test String(v) == d[String(k)]
    end

    for (k, v) in db_range(db, key_end = to_uint8("key5"))
        @test String(v) == d[String(k)]
    end

end

@testset "Errors" begin
    @test_throws ErrorException open_db("level.db", false)
    @test_throws ErrorException open_db("level.db.2", false)
    @test_broken !ispath("level.db.2")
end


close_db(db)
run(`rm -rf level.db`)
run(`rm -rf level.db.2`)
