

struct UnimplementedProvider <: AbstractProvider
    call::Function
    inputs::Tuple{Vararg{DataType}}
    output::Type{<:Artifact}

    function UnimplementedProvider(name, inputs, output)
        unique_inputs = Set(inputs)
        if length(unique_inputs) != length(inputs)
            error("Inputs must be unique for provider $name")
        end
        if output in unique_inputs
            error("Output type $output should not be an input for provider $name")
        end
        new(name, inputs, output)
    end
end

inputs(p::UnimplementedProvider) = p.inputs
outputs(p::UnimplementedProvider) = (p.output,)
storage(p::UnimplementedProvider) = p.output
# short_description(p::UnimplementedProvider) = extract_short_description(p.doc)

Base.show(io::IO, p::UnimplementedProvider) =
    print(io, "UnimplementedProvider $(p.call) [$(p.inputs...)]->$(p.output)")

function provide(p::UnimplementedProvider, _, _, _)
    error(
        "`$(p.call)` is an Unimplemented provider, you have to replace it with some implementation, see `@doc $(@__MODULE__).substitute`",
    )
end


"""
    @unimplemented name(Artifact, ...)::Artifact
   
Declares an Unimplemented provider with given inputs and output.
All inputs + output must be unique artifacts.
"""
macro unimplemented(func::Expr)
    @match func begin

        # Match the expression format of a pre-defined function with inputs and output
        Expr(:(::), [Expr(:call, [name, inputs...]), output]) => begin
            sname = QuoteNode(name)
            name = esc(name)
            artifacts = []
            inputs = map(x -> esc(make_artifact(artifacts, x)), inputs)
            output = esc(make_artifact(artifacts, output))
            return quote
                $(artifacts...)

                Core.@__doc__ $(name)() =
                    $provide($describe_provider($name), nothing, nothing, nothing)
                local definition = $FunctionFusion.UnimplementedProvider(
                    $name,
                    ($(inputs...),),
                    $output,
                )

                function FunctionFusion.describe_provider(::typeof($name))
                    return definition
                end

                $FunctionFusion.is_provider(::typeof($name)) = true
            end
        end
        _ => throw(DomainError(func, "Unsupported syntax"))
    end
end



