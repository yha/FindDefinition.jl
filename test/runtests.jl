using Test
using FindDefinition

include("bars.jl")

barspath = joinpath(@__DIR__, "bars.jl")


@testset "single macro call" begin
    bar1_methoddefs = FindDefinition.find_definitions(only(methods(Bar1.bar)))
    bar1_func_lnns = finddefs(Bar1.bar)
    @test length(bar1_methoddefs) == 1
    @test [d.lnn for d in bar1_methoddefs] == bar1_func_lnns
    lnn = only(bar1_func_lnns)
    @test string(lnn.file) == barspath
    @test lnn.line == 6
end

@testset "several calls" begin
    meths = methods(Bar2.bar)
    bar2_methoddefs = FindDefinition.find_definitions.(meths)
    bar2_func_lnns = finddefs(Bar2.bar)
    @test length(bar2_methoddefs) == 2
    @test length(bar2_methoddefs[1]) == 2
    @test length(bar2_methoddefs[2]) == 1
    @test length(bar2_func_lnns) == 2
    @test all( all( string(d.lnn.file) == barspath for d in defs )
                for defs in bar2_methoddefs )
    @test bar2_methoddefs[1][1].lnn.line == 12
    @test bar2_methoddefs[1][2].lnn.line == 13
    @test bar2_methoddefs[2][1].lnn.line == 14

    @test bar2_func_lnns[1].line == 13
    @test bar2_func_lnns[2].line == 14
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
