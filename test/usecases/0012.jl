module TestCase0012

using ..Utils
using Test
using FunctionFusion

@artifact A1, A2, A3 = String

@provider P1(a::A1)::A2 = "P1($a)"

@provider P2(a::A1)::A3 = "P2($a)"

@algorithm Alg1[P1](A1)::A2
@algorithm Alg2[P2](A1)::A3


@verifyVisualization([Alg1, Alg2, P1], "0012")


end