module TestCase0008

using ..Utils
using FunctionFusion
using Test

@artifact A1 = Int
@artifact A2 = Int

@unimplemented U1(A1)::A2


@test_throws "`U1` is an Unimplemented provider, you have to replace it with some implementation, see `@doc FunctionFusion.substitute" @algorithm generated[U1](
    A1,
)::A2

@verifyVisualization([U1], "0008")



end
