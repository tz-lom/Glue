module FunctionFusion

export @artifact,
    @provider,
    @conditional,
    @promote,
    @algorithm,
    @compose,
    @group,
    @unimplemented,
    substitute

import Base
using Match

include("abstract.jl")
include("artifact.jl")
include("provider.jl")

include("execution_plan.jl")

include("context.jl")
include("conditional.jl")
include("composed.jl")
include("promote.jl")
include("unimplemented.jl")

include("group.jl")

include("algorithm.jl")


include("substitute.jl")


# @todo: extract into submodule
include("visualization.jl")




end # module FunctionFusion
