module FunctionFusion

export @artifact,
    @provider,
    @conditional,
    @promote,
    @algorithm,
    @template,
    @implement,
    @group,
    @unimplemented,
    @use,
    substitute

import Base
using Match

include("artifact.jl")
include("providers/abstract.jl")
include("providers/callable.jl")

include("execution_plan.jl")

include("context.jl")
include("providers/conditional.jl")
# include("composed.jl")
include("providers/promote.jl")
include("providers/unimplemented.jl")

include("providers/group.jl")

include("providers/algorithm.jl")
include("providers/invoke.jl")


include("substitute.jl")

include("implement.jl")


# @todo: extract into submodule
include("visualization.jl")




end # module FunctionFusion
