struct SubstituteModifier <: ProviderModifier
    what::AbstractProvider
    with::AbstractProvider
end

function apply_modification(m::SubstituteModifier, a::AbstractProvider)
    if a == m.what
        return m.with
    else
        return a
    end
end

function substitute(what, with)
    return SubstituteModifier(describe_provider(what), describe_provider(with))
end

