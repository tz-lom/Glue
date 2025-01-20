module TestCase0007

using ..Utils
using FunctionFusion

@artifact A1 = Int
@artifact A2 = Int


@provider function P1(a::A1)::A2
    return a + 1
end
@algorithm generated(A1)::A2 = [P1]


@algorithm generated2(A1)::A2 = [P1]

verifyEquals(generated, generated2, 1)



end
