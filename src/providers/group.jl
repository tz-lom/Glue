struct GroupProvider <: AbstractProvider
    # doc::Markdown.MD
    call::Any
    context::Type{<:AbstractContext}
    plan::ExecutionPlan
end

inputs(p::GroupProvider) = p.plan.inputs
outputs(p::GroupProvider) = p.plan.can_generate
storage(p::GroupProvider) = p.context
# short_description(p::GroupProvider) = extract_short_description(p.doc)

function Base.:(==)(left::GroupProvider, right::GroupProvider)
    return left.context == right.context && left.plan.providers == right.plan.providers
end

function provide(p::GroupProvider, result::Type, context, parent)
    if result ∉ p.plan.can_generate
        return parent(result)
    end

    function self(artifact)
        return provide(p, artifact, context, parent)
    end

    provider = p.plan.provider_for_artifact[result]
    nested_context = :($context[$(storage(p))])
    return provide(provider, result , nested_context, self)
end

function apply_modification_iteratively(mod::ProviderModifier, group::GroupProvider)
    provider = apply_modification(mod, group)
    if provider == group
        new_providers =
            replace(p -> apply_modification_iteratively(mod, p), group.plan.providers)
        if new_providers != group.plan.providers
            return GroupProvider(group.call, group.context, ExecutionPlan(new_providers))
        else
            return group
        end
    else
        return apply_modification_iteratively(mod, provider)
    end
end

function define_group(name, providers)
    providers = map(describe_provider, providers)
    ctx_name = Symbol(name, "Context")
    plan = ExecutionPlan(providers)

    group = gensym(:group)

    return quote
        $FunctionFusion.@context($ctx_name, $(plan.can_generate...))

        function $name() end
        const $group = $GroupProvider($name, $ctx_name, $plan)

        $FunctionFusion.describe_provider(::typeof($name)) = $group
    end
end

macro group(name, providers...)
    # name = esc(name)
    # children = map(esc, children)


    # return quote

    #     $name(a::$artifact_type($input))::$artifact_type($output) = a

    #     const provider = FunctionFusion.PromoteProvider($name, $input, $output)


    #     function FunctionFusion.describe_provider(::typeof($name))
    #         return provider
    #     end
    # end
    return quote
        Base.eval(
            $__module__,
            define_group($(QuoteNode(name)), ($(map(esc, providers)...),)),
        )
    end
end