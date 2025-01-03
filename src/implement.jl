
function provide(plan::ExecutionPlan, result::Type, context)
    if result in plan.inputs
        return :(something($context[$result]))
    end

    if !(result in plan.can_generate)
        error("Can't provide $result with $plan")
    end

    provider = plan.provider_for_artifact[result]

    function self(artifact)
        return provide(plan, artifact, context, self)
    end

    return provide(provider, result, context, self)
end

function provide(plan::ExecutionPlan, result::Type, context, parent)
    if result in plan.inputs
        return :(something($context[$result]))
    end

    if !(result in plan.can_generate)
        return parent(result)
    end

    provider = plan.provider_for_artifact[result]

    function self(artifact)
        return provide(plan, artifact, context, self)
    end

    return provide(provider, result, context, self)
end
