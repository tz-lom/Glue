module TestCase0014

using ..Utils
using Test
using FunctionFusion

@artifact A1, A2, A3 = Int
@artifact I1 = Type{<:FunctionFusion.Artifact}
@artifact O1 = Int

@artifact I2 = Vector{DataType}
@artifact O2 = Vector{Int}


@provider P1()::A1 = 1
@provider P2()::A2 = 2
@provider P3()::A3 = 3

@switch_provider Switch1(I1)::O1 = [A1, A2, A3]
@algorithm Alg1(I1)::O1 = [P1, P2, P3, Switch1]

@switch_provider Switch2(I2)::O2 = [A1, A2, A3]
@algorithm Alg2(I2)::O2 = [P1, P2, P3, Switch2]

@test Alg1(A1) == 1
@test Alg1(A3) == 3

@test Alg2([A2, A1, A3]) == [2, 1, 3]

@verifyVisualization(Alg2, "0014")


end