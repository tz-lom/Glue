module TestCase0012

using ..Utils
using Test
using FunctionFusion

@artifact A1, A2, A3 = String

@provider P1(a::A1)::A2 = "P1($a)"

@provider P2(a::A1)::A3 = "P2($a)"

@algorithm Alg1(A1)::A2 = [P1]
@algorithm Alg2(A1)::A3 = [P2]


@verifyVisualization([Alg1, Alg2, P1], "0012")


end