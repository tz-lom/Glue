module TestCase0010

using ..Utils
using FunctionFusion

@artifact A1, A2, A3, A4, A5, A6 = String

@provider P1(a::A1)::A2 = "P1($a)"

@provider P2(a::A2)::A3 = "P2($a)"

@algorithm Alg1(A1)::A3 = [P1, P2]

@provider P3(a::A3)::A4 = "P3($a)"

@algorithm Alg2(A1)::A4 = [Alg1, P3]

@provider P4(a::A4)::A5 = "P4($a)"

@algorithm Alg3(A1)::A5 = [Alg2, P4]

@verifyVisualization(Alg3, "0010")


end