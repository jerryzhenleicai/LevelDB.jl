using Test
using LevelDB

Path = mktempdir(prefix="LevelDB-tests", cleanup=!Sys.iswindows())  # seems to fail in windows

@testset "DB basic operations" begin
    dbname = joinpath(Path, "L.db.0")
    @show dbname
    @test_throws ErrorException DB(dbname)

    db = LevelDB.DB(dbname, Vector{UInt8}, Vector{UInt8}, create_if_missing = true)
    close(db)
    @test !isopen(db)

    @test_throws ErrorException DB(dbname, Vector{UInt8}, Vector{UInt8}, error_if_exists = true)
    db = DB(dbname, Vector{UInt8}, Vector{UInt8})

    db[[0x00]] = [0x01]
    @info db[[0x00]]
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

@testset "DB basic operations - String" begin
    dbname = joinpath(Path, "L.db.1")
    @test_throws ErrorException LevelDB.DB(dbname)

    db = DB(dbname, create_if_missing = true)
    db["hola"] = "mundo!"
    @info db["hola"]
    @test db["hola"] == "mundo!"
    delete!(db, "hola")
    # as in Dict, deleting a non-existing key should not throw an error
    delete!(db, "hola")
    @test_throws KeyError db["hola"]
    close(db)
    @test db.handle        == C_NULL
    @test db.options       == C_NULL
    @test db.write_options == C_NULL
    @test db.read_options  == C_NULL
end

@testset "DB batching and iteration" begin
    dbname = joinpath(Path, "L.db.2")
    db = DB(dbname, Vector{UInt8}, Vector{UInt8}, create_if_missing = true)
    d = Dict([0xa] => [0x1],
             [0xb, 0xb] => [0x2],
             [0xc, 0xc] => [0x3],
             [0xd] => [0x4],
             [0xe] => [0x5])

    put_batch!(db, d)

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
    @test_throws ErrorException DB("level.db.3")
end

@testset "DB key range iterator" begin
    dbname = joinpath(Path, "L.db.3")
    db = DB(dbname, Vector{UInt8}, Vector{UInt8}, create_if_missing = true)
    d = Dict([0xa] => [0x1],
             [0xb, 0xb] => [0x2],
             [0xc, 0xc] => [0x3],
             [0xd] => [0x4],
             [0xe] => [0x5],
             )

    put_batch!(db, d)
 
    n = 0
    # Test a range iterator that begins with the second item in DB
    for (k, v) in Range(db, [0xb, 0xb], [0xd])
        @info k => v
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
    @info "after range"

    # Test a range iterator that begins with a non-existing  item in DB
    n = 0
    for (k, v) in Range(db, [0xb, 0xa], [0xc, 0xd])
        if n == 0
            @test v == [0x2]
        elseif n == 1
            @test v ==  [0x3]
        end
        n +=1
    end

    @test n == 2  # assert the iterator stopped at key 0xc 0xc
    
    @info "prev close db"
    close(db)
    @info "after close db"
end

