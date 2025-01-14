module TestCase0005

using ..Utils
using FunctionFusion

@artifact A1, A2, A3 = Int

@provider P1(a::A1)::A2 = a + 1

@provider P2(a::A2)::A3 = a * 10

@artifact F1_in = Int
@artifact F1_out = Int

# @template C1 P1 P2
# @implement C1_impl C1 F1_in => A1 A3 => F1_out

@algorithm N1[P1, P2](A1)::A3

@invoke_with I1 = N1{A1 => F1_in,A3 => F1_out}
# FunctionFusion.@context I1Context F1_out N1ContextOutputs
# I1 = FunctionFusion.InvokeProvider(
#     N1,
#     I1Context,
#     FunctionFusion.describe_provider(N1),
#     Dict(F1_in => A1),
#     Dict(A3 => F1_out),
# )



@algorithm generated[I1](F1_in)::F1_out

function expected(a::Int)::Int
    return (a + 1) * 10
end

verifyEquals(generated, expected, 1)

@verifyVisualization(generated, "0005")


end