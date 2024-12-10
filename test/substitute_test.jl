
module Test_substitute
using Test, FunctionFusion
using FunctionFusion: collect_providers, describe_provider

@artifact A1, A2, A3, AA1, AA2 = Int

@provider function P1(x::A1)::A2
    x
end

@provider function P2(x::A2)::A3
    x
end

@provider function PP1(x::AA1)::AA2
    x
end

@unimplemented U1(A1)::A2

@unimplemented U2(AA1)::AA2

@compose C1 U2

@group G1 U1


@testset "substitute" begin

    @testset "simple" begin
        @test collect_providers([substitute(U1, P1), U1]) == [describe_provider(P1)]
    end

    @testset "order and other providers are irrelevant" begin
        @test collect_providers([U1, substitute(U1, P1), P2]) ==
              [describe_provider(P1), describe_provider(P2)]
    end

    @testset "groups are handled correctly" begin
        p1 = describe_provider(P1)
        g1 = describe_provider(G1)

        new_group =
            FunctionFusion.GroupProvider(FunctionFusion.ExecutionPlan([p1]), g1.call)

        @test collect_providers([G1, substitute(U1, P1), P2]) ==
              [new_group, describe_provider(P2)]
    end

    @testset "composed is handled correctly" begin
        pp1 = describe_provider(PP1)
        c1 = describe_provider(C1(A1 => AA1, AA2 => A2))

        new_composed = FunctionFusion.ComposedProvider(
            c1.call,
            FunctionFusion.ExecutionPlan([pp1]),
            c1.container,
            c1.remaps,
        )

        @test collect_providers([C1(A1 => AA1, AA2 => A2), substitute(U2, PP1), P2]) ==
              [new_composed, describe_provider(P2)]
    end


    @testset "duplicates are elliminated is expanded correctly" begin
        expected = [describe_provider(P1), describe_provider(P2)]

        @test collect_providers([P1, P2, P1]) == expected

    end

    @testset "array is expanded correctly" begin
        a = [[[P1], P2]]
        expected = [describe_provider(P1), describe_provider(P2)]

        @test collect_providers([a]) == expected
    end
end

end