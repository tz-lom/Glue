module TestCase0007

using ..Utils
using Glue

@artifact A1 = Int
@artifact A2 = Int


@provider function P1(a::A1)::A2
    return a + 1
end
@algorithm generated[P1](A1)::A2


@algorithm generated2[P1](A1)::A2

verifyEquals(generated, generated2, 1)



end
