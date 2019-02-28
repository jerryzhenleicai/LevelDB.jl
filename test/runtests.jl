using Test
using LevelDB

# include("test_impl.jl")
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
    @test_throws KeyError db[[0x00]]
    close(db)
end

@testset "DB batching and iteration" begin
    db = LevelDB.DB("level.db.2", create_if_missing = true)
    d = Dict([0xa] => [0x1],
             [0xb] => [0x2],
             [0xc] => [0x3],
             [0xd] => [0x4],)

    db[keys(d)] = values(d)

    @test db[[0xa]] == [0x1]
    @test db[[0xb]] == [0x2]
    @test db[[0xc]] == [0x3]
    @test db[[0xd]] == [0x4]

    for (k, v) in db
        dv = d[k]
        @test v == dv
    end
    close(db)

    # nothing should happen here
    close(db)
end



@testset "DB Errors" begin
    @test_throws ErrorException LevelDB.DB("level.db.3")
end

run(`rm -rf level.db`)
run(`rm -rf level.db.2`)
run(`rm -rf level.db.3`)
