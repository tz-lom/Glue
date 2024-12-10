
struct AlgorithmProvider <: AbstractProvider
    call::Any
    context::Any
    inputs::Any
    output::Any
    providers::Any
end

inputs(p::AlgorithmProvider) = p.inputs
outputs(p::AlgorithmProvider) = (p.output,)
storage(p::AlgorithmProvider) = p.context

# function provide(p::AlgorithmProvider, result, context, source)
# @warn "alg provide" result context source
# return source(result)
# end

function define_algorithm(name, providers_list, args, output)
    name! = Symbol(name, "!")

    providers = collect_providers(providers_list)

    ctx_name = Symbol(name, "Context")
    artifacts = Set()
    for arg in args
        push!(artifacts, arg)
    end
    for provider in providers
        storage_container = storage(provider)
        if typeof(storage_container) <: Set
            union!(artifacts, storage_container)
        else
            push!(artifacts, storage_container)
        end
    end


    inputs = []
    set_inputs = []
    for (i, arg) in enumerate(args)
        input = Symbol("input", i)
        push!(inputs, :($input::$(artifact_type(arg))))
        push!(set_inputs, :(context[$arg] = $input))
    end

    plan = ExecutionPlan(providers)

    function source(artifact)
        if artifact in args
            return :(something(context[$artifact]))
        else
            provider = plan.provider_for_artifact[artifact]
            return provide(provider, artifact, :context, source)
        end
    end

    result = source(output)
    provider = gensym(:provider)


    return quote

        $FunctionFusion.@context($ctx_name, $(artifacts...))

        function $name($(inputs...))
            local context = $ctx_name()
            $(set_inputs...)
            result = $result
            return result

        end

        function $name!(context::$ctx_name, $(inputs...))
            $(set_inputs...)
            result = $result
            return result
        end

        const $provider = $AlgorithmProvider($name, $ctx_name, $args, $output, $providers)

        $FunctionFusion.describe_provider(::typeof($name)) = $provider

    end
end

"""
    @algorithm name[Providers](Input,...)::Output[,Output...]

Generates function that implements the algorithm to compute given `Output`s from `Input`s using `Providers`
"""
macro algorithm(expr::Expr)
    return @match expr begin
        Expr(:(::), [Expr(:(call), [Expr(:ref, [name, providers...]), args...]), output]) =>
            begin
                quote
                    Base.eval(
                        $__module__,
                        define_algorithm(
                            $(QuoteNode(name)),
                            ($(map(esc, providers)...),),
                            ($(map(esc, args)...),),
                            $(esc(output)),
                        ),
                    )
                end
            end
        _ => error("Unsupported syntax: $(expr)")
    end
end