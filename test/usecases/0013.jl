module TestCase0013

using ..Utils
using Test
using FunctionFusion

@artifact A1, A2, A3 = String
@artifact B1 = Bool

@provider P1(a::A1)::A2 = "P1($a)"

@callback_provider P2()::AP2 = P1

@provider function P3(c::AP2, b::B1)::A3
    if b
        return c()
    else
        return "Nothing"
    end
end

@algorithm Alg1(A1, B1)::A3 = [P1, P2, P3]


@test Alg1("A1", false) == "Nothing"
@test Alg1("A1", true) == "P1(A1)"

@verifyVisualization(Alg1, "0013")


end