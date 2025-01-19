

struct CallableProvider <: AbstractProvider
    call::Function
    inputs::Tuple{Vararg{DataType}}
    output::Type{<:Artifact}

    function CallableProvider(call, inputs, output)
        name = Symbol(call)
        unique_inputs = Set(inputs)
        if length(unique_inputs) != length(inputs)
            error("Inputs must be unique for provider $name")
        end
        if output in unique_inputs
            error("Output type $output should not be an input for provider $name")
        end
        new(call, inputs, output)
    end
end

inputs(p::CallableProvider) = p.inputs
outputs(p::CallableProvider) = (p.output,)
storage(p::CallableProvider) = p.output
# short_description(p::CallableProvider) = extract_short_description(p.doc)

Base.show(io::IO, p::CallableProvider) =
    print(io, "CallableProvider $(nameof(p.call))$(p.inputs)::$(p.output)")

function provide(p::CallableProvider, result::Type, context, resolve)
    if (p.output != result)
        error("$p can't provide $result")
    end
    return quote
        if isnothing($context[$result])
            $context[$result] = $(p.call)($([resolve(i) for i in p.inputs]...))
        end
        something($context[$result])
    end
end



"""
    read_function_signature(func::Expr)::NamedTuple{(:name,:result,:arguments)}

Read the signature of a provider function and return a named tuple with the function's name, result type, and argument types.
"""
function read_function_signature(func::Expr)
    # Ensure the expression represents a function definition with an explicit return type
    if func.head != :function || typeof(func.args[1]) != Expr || func.args[1].head != :(::)
        throw(
            DomainError(
                func,
                "Function must be a function definition with an explicit return type",
            ),
        )
    end

    signature = func.args[1]
    name = signature.args[1].args[1]
    result = signature.args[2]

    # Extract the argument expressions
    arg_exprs = signature.args[1].args[2:end]
    # Preallocate the array for argument types
    arguments = Vector{Tuple{Symbol,Symbol}}(undef, length(arg_exprs))

    for (i, arg) in enumerate(arg_exprs)
        # Ensure each argument is a type-annotated expression
        if typeof(arg) != Expr || arg.head != :(::)
            throw(DomainError(func, "Argument #$i must be a type-annotated expression"))
        end
        # Extract the argument name and type
        arg_name = arg.args[1]
        arg_type = arg.args[2]
        arguments[i] = (arg_name, arg_type)
    end

    return (name = name, result = result, arguments = arguments)
end

"""
    # 1 
    @provider function name(arg::Artifact, ...)::Artifact
              ...
    end

    # 2
    @provider name(Artifact,...)::Artifact

    # 3
    @provider alias = name(Artifact, ...)::Artifact

Declares a provider with given inputs and output.
All inputs + output must be unique artifacts.

3 versions of the syntax are supported:
1 - function definition
2 - declare existing function as provider
3 - make an alias to existing function and declare it as a provider

"""
macro provider(func::Expr)
    # Helper function to extract the artifact type
    extract_type = (type) -> :($artifact_type($type))

    @match func begin
        # Match the expression format of a function definition
        Expr(:function, _) => begin
            # Read the function signature
            sig = read_function_signature(func)

            # Create a new function signature with artifact types
            new_signature = Expr(
                :(::),
                Expr(
                    :call,
                    sig.name,
                    map(
                        (args,) -> Expr(:(::), args[1], extract_type(args[2])),
                        sig.arguments,
                    )...,
                ),
                extract_type(sig.result),
            )

            # Copy the original function definition and replace the signature
            new_function = func
            new_function.args[1] = new_signature

            # Extract and escape inputs, name, and output
            inputs = map((arg) -> esc(arg[2]), sig.arguments)
            name = esc(sig.name)
            output = esc(sig.result)

            return quote
                Core.@__doc__ $(esc(new_function))

                local definition =
                    $FunctionFusion.CallableProvider($name, ($(inputs...),), $output)

                function $FunctionFusion.describe_provider(::typeof($name))
                    return definition
                end

                $FunctionFusion.is_provider(::typeof($name)) = true
            end
        end
        # Match the expression format of a short function definition
        Expr(:(=), [Expr(:(::), [Expr(:call, [name, args...]), result]), body]) => begin
            new_args =
                map((arg,) -> Expr(:(::), arg.args[1], extract_type(arg.args[2])), args)
            inputs = map((arg) -> esc(arg.args[2]), args)
            output = extract_type(result)

            esc_name = esc(name)

            new_function =
                Expr(:(=), Expr(:(::), Expr(:call, name, new_args...), output), body)

            return quote
                Core.@__doc__ $(esc(new_function))

                local definition = $FunctionFusion.CallableProvider(
                    $esc_name,
                    ($(inputs...),),
                    $(esc(result)),
                )

                function $FunctionFusion.describe_provider(::typeof($esc_name))
                    return definition
                end

                $FunctionFusion.is_provider(::typeof($esc_name)) = true
            end
        end

        # Match the expression format of a pre-defined function with inputs and output
        Expr(:(::), [Expr(:call, [name, inputs...]), output]) => begin
            name = esc(name)
            inputs = map(esc, inputs)
            output = esc(output)
            docname = gensym(:doc)
            return quote
                Core.@__doc__ $(esc(docname))() = nothing
                local definition =
                    $FunctionFusion.CallableProvider($name, ($(inputs...),), $output)
                Base.delete_method(Base.which($(esc(docname)), ()))

                function $FunctionFusion.describe_provider(::typeof($name))
                    return definition
                end

                $FunctionFusion.is_provider(::typeof($name)) = true
            end
        end
        # Match the expression format of a provider alias
        Expr(:(=), [name, Expr(:(::), [Expr(:call, [alias, inputs...]), output])]) => begin
            qname = QuoteNode(name)
            name = esc(name)
            alias = esc(alias)
            inputs = map(esc, inputs)
            output = esc(output)
            def = gensym(:definition)
            return quote

                Core.@__doc__ $name(args...) = $alias(args...)

                local definition =
                    $FunctionFusion.CallableProvider($name, ($(inputs...),), $output)

                function $FunctionFusion.describe_provider(::typeof($name))
                    return definition
                end

                $FunctionFusion.is_provider(::typeof($name)) = true
            end
        end
        _ => throw(DomainError(func, "Can't make provider with given definition"))
    end
end



