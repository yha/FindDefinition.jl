using Test
using FindDefinition

include("bars.jl")

barspath = joinpath(@__DIR__, "bars.jl")


@testset "single macro call" begin
    bar1_methoddefs = FindDefinition.find_definitions(only(methods(Bar1.bar)))
    bar1_funcdefs = finddefs(Bar1.bar)
    @test length(bar1_methoddefs) == 1
    @test bar1_methoddefs == bar1_funcdefs
    def = only(bar1_funcdefs)
    @test string(def.file) == barspath
    @test def.line == 6
end

@testset "several calls" begin
    meths = methods(Bar2.bar)
    bar2_methoddefs = FindDefinition.find_definitions.(meths)
    bar2_funcdefs = finddefs(Bar2.bar)
    @test length(bar2_methoddefs) == 2
    @test length(bar2_methoddefs[1]) == 2
    @test length(bar2_methoddefs[2]) == 1
    @test length(bar2_funcdefs) == 2
    @test all( all( string(lnn.file) == barspath for lnn in defs )
                for defs in bar2_methoddefs )
    @test bar2_methoddefs[1][1].line == 12
    @test bar2_methoddefs[1][2].line == 13
    @test bar2_methoddefs[2][1].line == 14

    @test bar2_funcdefs[1].line == 13
    @test bar2_funcdefs[2].line == 14
end

@testset "several definitions in one macro" begin
    meths = methods(Bar2.multibar)
    @assert length(meths) == 3
    defs = finddefs(Bar2.multibar)
    @test length(defs) == 3
    @test defs[1] == defs[2] == defs[3]
    @test string(defs[1].file) == barspath
    @test defs[1].line == 15
end
