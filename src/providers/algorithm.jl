
struct AlgorithmProvider <: AbstractProvider
    call::Any
    context::Type
    context_outputs::Type
    inputs::Any
    output::Any
    plan::ExecutionPlan
end

function Base.:(==)(left::AlgorithmProvider, right::AlgorithmProvider)
    return left.plan == right.plan &&
           left.inputs == right.inputs &&
           left.output == right.output
end


inputs(p::AlgorithmProvider) = p.inputs
outputs(p::AlgorithmProvider) = (p.output,)
storage(p::AlgorithmProvider) = p.context_outputs

function provide(p::AlgorithmProvider, result::Type, context, parent)
    if result ∉ p.plan.can_generate # @todo: replace with output as it widens list of provided artifacts
        return parent(result)
    end

    function self(artifact)
        return provide(p, artifact, context, parent)
    end

    provider = p.plan.provider_for_artifact[result]
    nested_context = :($context[$(storage(p))])

    return provide(provider, result, nested_context, self)
end


function apply_modification_iteratively(mod::ProviderModifier, alg::AlgorithmProvider)
    provider = apply_modification(mod, alg)
    if provider == alg
        new_providers =
            replace(p -> apply_modification_iteratively(mod, p), alg.plan.providers)
        if new_providers != alg.plan.providers
            # define new algorithm
            # new_name = gensym(Symbol(nameof(alg.call), :Mutated))
            # defile_algorithm(new_name, new_providers, alg.inputs, alg.output; implement=false, implement!=false)
            return AlgorithmProvider(
                alg.call,
                alg.context,
                alg.context_outputs,
                alg.inputs,
                alg.output,
                ExecutionPlan(new_providers),
            )
        else
            return alg
        end
    else
        return apply_modification_iteratively(mod, provider)
    end
end

function define_algorithm(
    name,
    providers_list,
    args,
    output;
    implement = true,
    implement! = true,
)
    name! = Symbol(name, "!")

    providers = collect_providers(providers_list)

    ctx_name = Symbol(name, "Context")
    ctx_name_outputs = Symbol(name, "ContextOutputs")

    artifacts = Set()
    for provider in providers
        storage_container = storage(provider)
        if typeof(storage_container) <: Set
            union!(artifacts, storage_container)
        else
            push!(artifacts, storage_container)
        end
    end

    only_outputs = copy(artifacts)

    for arg in args
        push!(artifacts, arg)
    end


    inputs = []
    set_inputs = []
    for (i, arg) in enumerate(args)
        input = Symbol("input", i)
        push!(inputs, :($input::$(artifact_type(arg))))
        push!(set_inputs, :(context[$arg] = $input))
    end


    provider_definition = gensym(:provider)
    plan = ExecutionPlan(providers)


    if implement || implement!

        function source(artifact)
            if artifact in args
                return :(something(context[$artifact]))
            else
                provider = plan.provider_for_artifact[artifact]
                return provide(provider, artifact, :context, source)
            end
        end
        result = source(output)
    end

    if implement
        impl = quote
            function $name($(inputs...))
                local context = $ctx_name()
                $(set_inputs...)
                result = $result
                return result
            end
        end
    else
        impl = quote
            function $name($(inputs...))
                error($("$name is not implemented"))
            end
        end
    end

    if implement!
        impl! = quote
            function $name!(context::$ctx_name, $(inputs...))
                $(set_inputs...)
                result = $result
                return result
            end
        end
    else
        impl! = quote end
    end



    return quote

        $FunctionFusion.@context($ctx_name, $(artifacts...))
        $FunctionFusion.@context($ctx_name_outputs, $(only_outputs...))

        $impl

        $impl!

        const $provider_definition =
            $AlgorithmProvider($name, $ctx_name, $ctx_name_outputs, $args, $output, $plan)

        $FunctionFusion.describe_provider(::typeof($name)) = $provider_definition

    end
end

"""
    @algorithm name[Providers](Input,...)::Output[,Output...]

Generates function that implements the algorithm to compute given `Output`s from `Input`s using `Providers`
"""
macro algorithm(params...)

    implement = true
    implement! = true

    name = nothing
    providers = nothing
    args = nothing
    output = nothing

    for expr in params
        @match expr begin
            Expr(
                :(::),
                [Expr(:(call), [Expr(:ref, [name_, providers_...]), args_...]), output_],
            ) => begin
                name = name_
                providers = providers_
                args = args_
                output = output_
            end
            Expr(:(=), [:implement, false]) => begin
                implement = false
                implement! = false
            end
            _ => error("Unsupported syntax: $(expr)")
        end
    end

    if isnothing(name)
        error("No body was provided to @algorithm")
    end

    return quote
        Base.eval(
            $__module__,
            $define_algorithm(
                $(QuoteNode(name)),
                ($(map(esc, providers)...),),
                ($(map(esc, args)...),),
                $(esc(output));
                implement = $implement,
                implement! = $implement!,
            ),
        )
    end
end