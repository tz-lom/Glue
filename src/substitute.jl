struct Substitutemodifier <: ProviderModifier
    what::AbstractProvider
    with::AbstractProvider
end

function apply_modification(m::Substitutemodifier, a::AbstractProvider)
    if a == m.what
        return m.with
    else
        return a
    end
end

function apply_modification(m::Substitutemodifier, g::GroupProvider)
    new_providers = replace(g.plan.providers, m.what => m.with)
    if new_providers != g.plan.providers
        return GroupProvider(ExecutionPlan(new_providers), g.call)
    else
        return g
    end
end

function substitute(what, with)
    return Substitutemodifier(describe_provider(what), describe_provider(with))
end

