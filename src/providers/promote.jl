struct PromoteProvider <: AbstractProvider
    call::Function
    input::Type{<:Artifact}
    output::Type{<:Artifact}

    function PromoteProvider(call, input, output)
        if input == output
            error("You shouldn't promote artifact $input to the same artifact")
        elseif artifact_type(input) !== artifact_type(output)
            error(
                "You shouldn't promote artifact $input to an artifact of a different type",
            )
        end
        return new(call, input, output)
    end
end

inputs(p::PromoteProvider) = (p.input,)
outputs(p::PromoteProvider) = (p.output,)
storage(p::PromoteProvider) = p.output

function provide(p::PromoteProvider, result::Type, storage, source)
    if (p.output != result)
        error("$p can't provide $result")
    end
    return quote
        if isnothing($storage[$result])
            $storage[$result] = $(source(p.input))
        end
        something($storage[$result])
    end
end

"""
    @promote name(Input)::Output

Defines promote provider that assigns data from the `Input` Artifact to the `Output` Artifact.
Both Artifacts have to share same data type.
"""
macro promote(expr)
    return @match expr begin
        Expr(:(::), [Expr(:call, [name, input]), output]) => begin
            artifacts = []
            name = esc(name)
            input = esc(make_artifact(artifacts, input))
            output = esc(make_artifact(artifacts, output))
            return quote
                $(artifacts...)

                $name(a::$artifact_type($input))::$artifact_type($output) = a

                const provider = FunctionFusion.PromoteProvider($name, $input, $output)

                function FunctionFusion.describe_provider(::typeof($name))
                    return provider
                end
            end
        end
        _ => throw(DomainError(expr, "Unsupported syntax"))
    end
end
