using Test
using LevelDB

run(`rm -rf level.db`)
run(`rm -rf level.db.2`)
run(`rm -rf level.db.3`)

@testset "DB basic operations" begin
    @test_throws ErrorException LevelDB.DB("level.db")

    db = LevelDB.DB("level.db", create_if_missing = true)
    close(db)
    @test !isopen(db)

    @test_throws ErrorException LevelDB.DB("level.db", error_if_exists = true)
    db = LevelDB.DB("level.db")

    db[[0x00]] = [0x01]
    @test db[[0x00]] == [0x01]
    delete!(db, [0x00])
    # as in Dict, deleting a non-existing key should not throw an error
    delete!(db, [0x00])
    @test_throws KeyError db[[0x00]]
    close(db)
    @test db.handle        == C_NULL
    @test db.options       == C_NULL
    @test db.write_options == C_NULL
    @test db.read_options  == C_NULL
end

@testset "DB batching and iteration" begin
    db = LevelDB.DB("level.db.2", create_if_missing = true)
    d = Dict([0xa] => [0x1],
             [0xb, 0xb] => [0x2],
             [0xc, 0xc] => [0x3],
             [0xd] => [0x4],
             [0xe] => [0x5])

    db[keys(d)] = values(d)

    @test db[[0xa]] == [0x1]
    @test db[[0xb, 0xb]] == [0x2]
    @test db[[0xc, 0xc]] == [0x3]
    @test db[[0xd]] == [0x4]
    @test db[[0xe]] == [0x5]

    function size_of(db)
        i = 0
        for (k, v) in db
            i += 1
        end
        i
    end
    @test size_of(db) == 5

    d2 = Dict{Vector{UInt8}, Vector{UInt8}}()
    for (k, v) in db
        d2[k] = v
    end
    @test d == d2

    for (k, v) in db
        delete!(db, k)
    end
    @test size_of(db) == 0

    close(db)
    @test db.handle        == C_NULL
    @test db.options       == C_NULL
    @test db.write_options == C_NULL
    @test db.read_options  == C_NULL

    # nothing should happen here
    close(db)
    @test db.handle        == C_NULL
    @test db.options       == C_NULL
    @test db.write_options == C_NULL
    @test db.read_options  == C_NULL
end



@testset "DB Errors" begin
    @test_throws ErrorException LevelDB.DB("level.db.3")
end


@testset "DB key range iterator" begin
    db = LevelDB.DB("level.db", create_if_missing = true)
    d = Dict([0xa] => [0x1],
             [0xb, 0xb] => [0x2],
             [0xc, 0xc] => [0x3],
             [0xd] => [0x4],
             [0xe] => [0x5],
             )

    db[keys(d)] = values(d)
    n = 0
    # Test a range iterator that begins with the second item in DB
    iter = LevelDB.RangeView(db, [0xb, 0xb], [0xd])
    for (k, v) in iter
        if n == 0
            @test v == [0x2]
        elseif n == 1
            @test v ==  [0x3]
        elseif n == 2
            @test v ==  [0x4]
        end
        n +=1
    end
    @test n == 3 # assert the iterator stopped at key 0xd

    # Test a range iterator that begins with a non-existing  item in DB
    n = 0
    iter = LevelDB.RangeView(db, [0xb, 0xa], [0xc, 0xd])
    for (k, v) in iter
        if n == 0
            @test v == [0x2]
        elseif n == 1
            @test v ==  [0x3]
        end
        n +=1
    end
    @test n == 2  # assert the iterator stopped at key 0xc 0xc

    close(db)

end

run(`rm -rf level.db`)
run(`rm -rf level.db.2`)
run(`rm -rf level.db.3`)
