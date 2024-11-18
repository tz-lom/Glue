module TestCase0007

using ..Utils
using Glue
using Test

@artifact A1 = Int
@artifact A2 = Int

@unimplemented U1(A1)::A2


@test_throws "`U1` is an Unimplemented provider, you have to replace it with some implementation, see `@doc Glue.replace" @algorithm generated[U1](
    A1,
)::A2



end
