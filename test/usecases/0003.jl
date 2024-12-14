module TestCase0003

using ..Utils
using FunctionFusion

@artifact A1 = Int
@artifact A2 = Int
@artifact A3 = Int

@provider function P1(a::A1)::A2
    return a + 1
end

@provider function P2(a::A2)::A3
    return a * 10
end

@artifact F1_in = Int
@artifact F1_out = Int

@template C1 P1 P2
@implement C1_impl C1 F1_in => A1 A3 => F1_out
# where {(F1_in => A1, A3 => F1_out)}


@algorithm generated[C1_impl](F1_in)::F1_out

function expected(a::Int)::Int
    return (a + 1) * 10
end

verifyEquals(generated, expected, 1)

verifyVisualization(generated, "0003")


end