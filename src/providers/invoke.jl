struct InvokeProvider <: AbstractProvider
    call::Any
    context::Type
    algorithm::AlgorithmProvider
    forward_substitutions::Dict{Type,Type}
    backward_substitutions::Dict{Type,Type}

    function InvokeProvider(call, context, algorithm, substitutions)
        dict = Dict(substitutions)
        return new(
            call,
            context,
            describe_provider(algorithm),
            Dict(zip(values(dict), keys(dict))),
            dict,
        )
    end
end

function Base.:(==)(left::InvokeProvider, right::InvokeProvider)
    return left.algorithm == right.algorithm &&
           left.backward_substitutions == right.backward_substitutions
end


inputs(p::InvokeProvider) = replace(inputs(p.algorithm), p.backward_substitutions...)
outputs(p::InvokeProvider) = replace(outputs(p.algorithm), p.backward_substitutions...)
storage(p::InvokeProvider) = p.context

function provide(p::InvokeProvider, result::Type, context, parent)
    function subst(artifact)
        return parent(get(p.backward_substitutions, artifact, artifact))
    end

    nested_context = :($context[$(p.context)])
    return quote
        if isnothing($nested_context[$result])
            $context[$(p.context)][$result] = $(provide(
                p.algorithm,
                get(p.forward_substitutions, result, result),
                nested_context,
                subst,
            ))
        end
        something($nested_context[$result])
    end
end


function apply_modification_iteratively(mod::ProviderModifier, inv::InvokeProvider)
    provider = apply_modification(mod, inv)
    if provider == inv
        new_algorithm = apply_modification_iteratively(mod, inv.algorithm)
        if new_algorithm != inv.algorithm

            return InvokeProvider(
                inv.call,
                inv.context,
                new_algorithm,
                inv.backward_substitutions,
            )
        else
            return inv
        end
    else
        return apply_modification_iteratively(mod, provider)
    end
end

function define_invoke(name, algorithm, algorithm_name, substitutions)
    provider = gensym(:provider)
    context_name = Symbol(name, :Context)

    algorithm_p = describe_provider(algorithm)

    out = replace(outputs(algorithm_p), substitutions...)

    return quote
        $FunctionFusion.@context $context_name $(storage(algorithm_p)) $(out...)

        function $name()
            error($("$name shall not be called directly"))
        end

        const $provider =
            $InvokeProvider($name, $context_name, $algorithm_name, $substitutions)

        $FunctionFusion.describe_provider(::typeof($name)) = $provider
    end
end

"""
    @invoke InvokeName = AlgorithmName{Substitutions}
"""
macro use(expr::Expr)
    return @match expr begin
        Expr(:(=), [name, Expr(:curly, [algorithm, substitutions...])]) => begin


            subst = Tuple([QuoteNode(x.args[2]) => QuoteNode(x.args[3]) for x in substitutions])

            quote
                Base.eval(
                    $__module__,
                    define_invoke(
                        $(QuoteNode(name)),
                        $(esc(algorithm)),
                        $(QuoteNode(algorithm)),
                        $(esc(:($(substitutions...),))),
                    ),
                )
            end
        end
        _ => error("Unsupported syntax $expr")
    end
end