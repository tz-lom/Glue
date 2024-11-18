

struct UnimplementedProvider <: AbstractProvider
    call::Function
    doc::Markdown.MD
    inputs::Tuple{Vararg{DataType}}
    output::Type{<:Artifact}

    function UnimplementedProvider(name, doc::Markdown.MD, inputs, output)
        unique_inputs = Set(inputs)
        if length(unique_inputs) != length(inputs)
            error("Inputs must be unique for provider $name")
        end
        if output in unique_inputs
            error("Output type $output should not be an input for provider $name")
        end
        new(name, doc, inputs, output)
    end
end

inputs(p::UnimplementedProvider) = p.inputs
outputs(p::UnimplementedProvider) = (p.output,)
storage(p::UnimplementedProvider) = p.output
short_description(p::UnimplementedProvider) = extract_short_description(p.doc)

Base.show(io::IO, p::UnimplementedProvider) =
    print(io, "UnimplementedProvider $(p.call) [$(p.inputs...)]->$(p.output)")

function provide(p::UnimplementedProvider, _, _, _)
    error(
        "`$(p.call)` is an Unimplemented provider, you have to replace it with some implementation, see `@doc $(@__MODULE__).replace`",
    )
end


"""
    @unimplemented name(arg::Artifact, ...)::Artifact
   
Declares an Unimplemented provider with given inputs and output.
All inputs + output must be unique artifacts.
"""
macro unimplemented(func::Expr)
    @match func begin

        # Match the expression format of a pre-defined function with inputs and output
        Expr(:(::), [Expr(:call, [name, inputs...]), output]) => begin
            sname = QuoteNode(name)
            name = esc(name)
            inputs = map(esc, inputs)
            output = esc(output)
            return quote
                Core.@__doc__ $(name)() =
                    $provide($describe_provider($name), nothing, nothing, nothing)
                local definition = $Glue.UnimplementedProvider(
                    $name,
                    Base.Docs.doc(Base.Docs.Binding($__module__, $sname)),
                    ($(inputs...),),
                    $output,
                )

                function Glue.describe_provider(::typeof($name))
                    return definition
                end

                $Glue.is_provider(::typeof($name)) = true
            end
        end
        _ => throw(
            DomainError(func, "Can't make unimplemented provider from given definition"),
        )
    end
end



