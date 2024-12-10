
struct ComposedProvider <: AbstractProvider
    call::Function
    plan::ExecutionPlan
    container::Type
    remaps::Any
    inputs::Any
    outputs::Any

    function ComposedProvider(call, plan, ctx_name, remaps)
        remaps = Dict(remaps)
        rremaps = Dict(values(remaps) .=> keys(remaps))

        input_diff = setdiff(plan.inputs, values(remaps))
        if length(input_diff) > 0
            error("For compose $call inputs $input_diff are not described")
        end
        output_diff = setdiff(plan.outputs, keys(remaps))
        if length(output_diff) > 0
            error("For compose $call outputs $output_diff are not described")
        end

        inputs = Dict(map(i -> i => rremaps[i], collect(plan.inputs)))
        outputs = Dict(map(i -> remaps[i] => i, collect(plan.outputs)))

        # artifacts = union(plan.artifacts, keys(outputs))

        return new(call, plan, ctx_name, remaps, inputs, outputs)

    end
end

inputs(p::ComposedProvider) = values(p.inputs)
outputs(p::ComposedProvider) = keys(p.outputs)
storage(p::ComposedProvider) = Set((p.container, keys(p.outputs)...))

function Base.:(==)(left::ComposedProvider, right::ComposedProvider)
    return left.plan.providers == right.plan.providers && left.remaps == right.remaps
end

function provide(p::ComposedProvider, result::Type, context, source)
    function inner_source(artifact)
        if artifact in p.plan.inputs
            return provide(p, artifact, context, source)
        else
            provider = p.plan.provider_for_artifact[artifact]
            return provide(provider, artifact, :($context[$(p.container)]), inner_source)
        end
    end

    if result in p.plan.inputs
        return quote
            if isnothing($context[$(p.container)][$result])
                $context[$(p.container)][$result] = $(source(p.inputs[result]))
            end
            something($context[$(p.container)][$result])
        end
    elseif result in keys(p.outputs)
        return quote
            if isnothing($context[$result])
                $context[$result] = $(inner_source(p.outputs[result]))
            end
            something($context[$result])
        end
    elseif result in p.plan.artifacts
        return inner_source(result)
    else
        error("Can't provide $result")
    end
end



function apply_modification_iteratively(mod::ProviderModifier, composed::ComposedProvider)
    provider = apply_modification(mod, composed)
    if provider == composed
        new_providers =
            replace(p -> apply_modification_iteratively(mod, p), composed.plan.providers)

        if new_providers != composed.plan.providers
            return ComposedProvider(
                composed.call,
                ExecutionPlan(new_providers),
                composed.container,
                composed.remaps,
            )
        else
            return group
        end
    else
        return apply_modification_iteratively(mod, provider)
    end
end


function define_template(name, providers)
    providers = map(describe_provider, providers)
    plan = ExecutionPlan(providers)

    return quote
        function $name()
            return $plan
        end
    end
end

function implement_template(plan, name, remaps)
    ctx_name = Symbol(name, "Context")

    return quote
        $FunctionFusion.@context($ctx_name, $(plan.artifacts...))
        function $name()
            return $ComposedProvider($name, $plan, $ctx_name, $remaps)
        end
        $FunctionFusion.describe_provider($name) = $name()
    end
end

"""
    @template name providers...

Encapsulates algorithm for the re-use in many places
@todo: write better documentation when functionality is stable
"""
macro template(name, providers...)
    return quote
        Base.eval(
            $__module__,
            $FunctionFusion.define_template(
                $(QuoteNode(name)),
                ($(map(esc, providers)...),),
            ),
        )
    end
end


macro implement(name, template_name, remaps...)
    return quote
        Base.eval(
            $__module__,
            $FunctionFusion.implement_template(
                $(esc(template_name))(),
                $(QuoteNode(name)),
                ($(map(esc, remaps)...),),
            ),
        )
    end
end