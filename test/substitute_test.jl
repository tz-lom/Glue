
module Test_replace
using Test, Glue
using Glue: collect_providers, describe_provider

@artifact A1, A2, A3 = Int

@provider function P1(x::A1)::A2
    x
end

@provider function P2(x::A2)::A3
    x
end

@unimplemented U1(A1)::A2

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

        new_group = Glue.GroupProvider(Glue.ExecutionPlan([p1]), g1.call)

        @test collect_providers([G1, substitute(U1, P1), P2]) ==
              [new_group, describe_provider(P2)]
    end

end

end