module TestCase0011

using ..Utils
using Test
using FunctionFusion

@artifact A1, A2, A3, A4, A5, A6 = String

@provider P1(a::A1)::A2 = "P1($a)"

@provider P2(a::A2)::A3 = "P2($a)"

@provider P3(a::A3)::A4 = "P3($a)"

@group G1 = [P1, P2, P3]

@provider P4(a::A3)::A5 = "P4($a)"

@algorithm Alg(A1)::A5 = [G1, P4]

@test Alg("A1") == "P4(P2(P1(A1)))"

@verifyVisualization(Alg, "0011")


end