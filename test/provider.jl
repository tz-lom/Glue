module FunctionFusion_Test_Provider
using Test
using FunctionFusion: @artifact, @provider, FunctionFusion as FF

@testset "Provider" begin

    @artifact A1, A2, A3 = Int

    @provider function P1(a::A1, b::A2)::A3
        return a + b
    end

    function P2(a, b)
        return a + b
    end

    @provider P2(A1, A2)::A3

    @provider P3(a::A1, b::A2)::A3 = a + b

    function P4_incognito(a, b)
        return a + b
    end

    @provider P4 = P4_incognito(A1, A2)::A3

    @test FF.is_provider(P1) == true
    @test FF.is_provider(P2) == true
    @test FF.is_provider(P3) == true
    @test FF.is_provider(P4) == true
    @test FF.is_provider(P4_incognito) == false

end

end