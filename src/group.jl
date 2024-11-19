struct GroupProvider <: AbstractProvider
    # doc::Markdown.MD
    plan::ExecutionPlan
    call::Any
end

inputs(p::GroupProvider) = p.plan.inputs
outputs(p::GroupProvider) = p.plan.can_generate
storage(p::GroupProvider) = p.plan.can_generate
storage(::GroupProvider, artifact) = artifact
# short_description(p::GroupProvider) = extract_short_description(p.doc)

function Base.:(==)(left::GroupProvider, right::GroupProvider)
    return left.plan.providers == right.plan.providers
end

function provide(p::GroupProvider, result::Type, context, source)
    function inner_source(artifact)
        if artifact in p.plan.can_generate
            provider = p.plan.provider_for_artifact[artifact]
            provide(provider, artifact, context, inner_source)
        else
            source(artifact)
        end
    end

    provider = p.plan.provider_for_artifact[result]
    if result in p.plan.can_generate
        return quote
            $(inner_source(result))
        end
    else
        error("Can't provide $result")
    end
end

function apply_modification_iteratively(mod::ProviderModifier, group::GroupProvider)
    provider = apply_modification(mod, group)
    if provider == group
        new_providers =
            replace(p -> apply_modification_iteratively(mod, p), group.plan.providers)
        if new_providers != group.plan.providers
            return GroupProvider(ExecutionPlan(new_providers), group.call)
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
        $Glue.@context($ctx_name, $(plan.can_generate...))

        function $name() end
        const $group = $GroupProvider($plan, $name)

        $Glue.describe_provider(::typeof($name)) = $group
    end
end

macro group(name, providers...)
    # name = esc(name)
    # children = map(esc, children)


    # return quote

    #     $name(a::$artifact_type($input))::$artifact_type($output) = a

    #     const provider = Glue.PromoteProvider($name, $input, $output)


    #     function Glue.describe_provider(::typeof($name))
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